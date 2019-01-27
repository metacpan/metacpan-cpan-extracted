#!perl

use strict;
use warnings;
use Test::More 0.98;

use Data::Decrement qw(decr);

is(decr("9"), "8");
is(decr("100"), "099");
is(decr(-100), -101);

is(decr("BAa0"), "AZz9");
is(decr("AAa0"), "AAa0"); # warns

DONE_TESTING:
done_testing;
