#!perl -T

use Test::More tests => 10;

use Class::Constant ZERO, ONE, TWO, THREE, FOUR, FIVE;

# is() uses eq, and thus stringifies
is(ZERO, 0);
is(ONE, 1);
is(TWO, 2);
is(THREE, 3);
is(FOUR, 4);
is(FIVE, 5);

use Class::Constant FIFTY => 50, FIFTY_ONE, FIFTY_TWO, ONE_HUNDRED => 100;

is(FIFTY, 50);
is(FIFTY_ONE, 51);
is(FIFTY_TWO, 52);
is(ONE_HUNDRED, 100);
