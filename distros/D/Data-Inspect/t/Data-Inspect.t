# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Inspect.t'

#########################

use strict;
use warnings;

use Config;
use Test::More;

# The testing of STDOUT only works if this Perl is configured to
# support in-memory filehandles.
BEGIN {
  my $tests = 11;
  if ($] >= 5.008 and $Config{useperlio}) { $tests += 4; }
  plan tests => $tests;
}

BEGIN { use_ok('Data::Inspect', 'p') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Create an object
my $insp = Data::Inspect->new;
isa_ok($insp, 'Data::Inspect');

# Set the sort_keys option
$insp->set_option('sort_keys', 'cmp');

# Inspect the object itself
is($insp->inspect($insp),
   '#<Inspect options={"sort_keys" => "cmp", "truncate_strings" => undef}>');

# Let's inspect a simple array and a simple hash
my @array = (1, 2, "foo", 5.67);
my %hash  = (a => 'b', c => 3.45);

is($insp->inspect(\@array), '[1, 2, "foo", "5.67"]');
is($insp->inspect(\%hash),  '{"a" => "b", "c" => "3.45"}');

# Inspect a common class
use IO::Dir;
my $dir = IO::Dir->new('.');
like($insp->inspect($dir), qr/^#<IO::Dir #<GLOB NAME="GEN0" SCALAR=\\undef HASH=\{"io_dir_path" => "\."} IO=#<IO::(?:Handle|File) #<IO>> GLOB=#<CIRCULAR REFERENCE 0x[\da-f]+> PACKAGE="Symbol">>$/);

# Create a simple hash-based package and one with an inspect method
package Simple;

sub new { my ($c,%a) = @_; bless \%a, $c }

package Inspectable;

sub new { my ($c,%a) = @_; bless \%a, $c }
sub inspect { "#<Inspectable id=$_[0]->{id}>" }

package Inspectable::Recursive;

sub new { my ($c,%a) = @_; bless \%a, $c }
sub inspect { "#<Inspectable::Recursive hash=".
		$_[1]->inspect($_[0]->{hash}).">" }

package main;

# Check instances of these look correct
my $simple = Simple->new(id => 42, foo => 'bar');
my $inspectable = Inspectable->new(id => 42, foo => 'bar');
my $recursive = Inspectable::Recursive->new(id => 42, hash => {foo => 'bar'});

is($insp->inspect($simple), '#<Simple {"foo" => "bar", "id" => 42}>');
is($insp->inspect($inspectable), '#<Inspectable id=42>');
is($insp->inspect($recursive),
   '#<Inspectable::Recursive hash={"foo" => "bar"}>');

# Check the truncating of strings
is($insp->inspect("Supercalifragilisticexpialidocious"),
   '"Supercalifragilisticexpialidocious"');
$insp->set_option('truncate_strings', 10);
is($insp->inspect("Supercalifragilisticexpialidocious"),
   '"Supercalif..."');

# Finally, we need to check the printing works.

if ($] >= 5.008 and $Config{useperlio}) {

# Open an in-memory filehandle to print things into
  my $output;
  open(my $ofh, '>', \$output);
  select $ofh;

  $insp->p(\@array);
  is($output, qq{[1, 2, "foo", "5.67"]\n});
  $insp->p(\%hash);
  is($output, qq{[1, 2, "foo", "5.67"]\n{"a" => "b", "c" => "3.45"}\n});
  close $ofh;

  open($ofh, '>', \$output);
  select $ofh;
  $insp->p(\@array, \%hash);
  is($output, qq{[1, 2, "foo", "5.67"]\n{"a" => "b", "c" => "3.45"}\n});
  close $ofh;

  open($ofh, '>', \$output);
  select $ofh;
  p \@array, \@array;	 # can't test the hash because of key ordering
  is($output, qq{[1, 2, "foo", "5.67"]\n[1, 2, "foo", "5.67"]\n});
  close $ofh;

}
