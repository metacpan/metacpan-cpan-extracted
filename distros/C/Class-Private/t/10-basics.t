#!perl -T

use strict;
use Test::More tests => 5;
use Test::NoWarnings;

use Class::Private;

my $foo = Class::Private->new;

$foo->{bar} = 1;

is($foo->{bar}, 1, '$foo->{var} should be 1 in main');

{

package Bar;
use Test::More;

ok(!defined $foo->{bar}, '$foo->{var} should be undefined in Bar');

$foo->{bar} = 2;

}

package main;

is($foo->{bar}, 1, '$foo->{bar} should be 1 in main');
is($foo->{'Bar::bar'}, 2, '$foo->{\'Bar::bar\'} should be 2');
