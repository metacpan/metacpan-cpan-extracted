# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 10;
use File::Temp qw/tempfile/;

use Acme::Chef;

ok(1, "Module compiled."); # If we made it this far, we're ok.

#########################

my $testname        = 'STDIN-Test';
my $expected_result = ' 10';

local $/ = undef;
my $code = <DATA>;

my $compiled = Acme::Chef->compile( $code );
ok(ref $compiled eq 'Acme::Chef', "$testname code compiled.");

local $| = 1;
*OLDSTDIN = *STDIN;

(*STDIN) = tempfile(UNLINK => 1);

print STDIN "10\n";
print STDIN "10\n";
print STDIN "10\n";
seek STDIN, 0, 0;
ok(1, "Redirected STDIN for testing.");

my $result = $compiled->execute();
ok($result eq $expected_result, "Correct result.");

my $dump = $compiled->dump();
ok((defined $dump and not ref $dump), "Dumped.");

local $@ = undef;
my $reconstructed = eval $dump;
ok((not $@ and ref $reconstructed eq 'Acme::Chef'), "Reconstruction from dump successful.");

$result = $reconstructed->execute();
ok($result eq $expected_result, "Correct result after reconstruction.");

$dump = $compiled->dump('autorun');
ok((defined $dump and not ref $dump), "Dumped with autorun enabled.");

ok((not $@ and $result eq $expected_result), "Correct result after reconstruction.");

close STDIN;
*STDIN = *OLDSTDIN;
ok(1, "Restored STDIN.");

__DATA__

STDIN stew.

Read flour from STDIN and output it.

Ingredients.
flour

Method.
Take flour from refrigerator.
Put flour into mixing bowl.
Pour contents of the mixing bowl into the baking dish.
Refrigerate for 1 hour.



