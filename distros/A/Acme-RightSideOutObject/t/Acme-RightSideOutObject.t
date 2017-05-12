# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Acme-RightSideOutObject.t'

#########################

use strict;
use warnings;

use Test::More tests => 6;

package My::Class;

use Class::InsideOut qw( public readonly private register id );

public     name => my %name;    # accessor: name()
readonly   ssn  => my %ssn;     # read-only accessor: ssn()
private    age  => my %age;     # no accessor

sub new { register( shift ) }

sub greeting {
  my $self = shift;
  return "Hello, my name is $name{ id $self }";
}

package main;

BEGIN { use_ok('Acme::RightSideOutObject') };

ok(defined &guts, 'Exports guts()');
my $io = My::Class->new or die;
$io->name("Fred");
ok($io->greeting() eq 'Hello, my name is Fred', 'Class::InsideOut accessors');
my $other_io = guts($io);
ok($other_io->{name} eq 'Fred', "Attribute read");
$other_io->{name} = 'Dork Face';
ok($io->greeting() eq 'Hello, my name is Dork Face', 'Data written to hash propogates');
ok($other_io->greeting() eq 'Hello, my name is Dork Face', 'Calling methods on the right side out object');


