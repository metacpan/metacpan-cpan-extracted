#!perl -w

use strict;
use Test::More tests => 8;

use Acme::Numbers;
is(one.point."", 1, "Trailing point");
is(point.one."", 0.1, "Preceding point");
# TODO two .points
is(one.point.five."", 1.5, "something point something");
is(one.point.fifty.five."", 1.55, "Big little after point");
is(one.point.five.five."", 1.55, "Chain small numbers");
is(one.point.zero.five."", 1.05, "point zero");
is(one.point.four.zero.eight."", 1.408, "something zero something");
is(zero.point.zero.five."", 0.05, "zero point zero something");
