#!perl

use strict;
use Test::More tests => 7;

use Acme::Numbers;
is(one."", 1, "Single digits");
# TODO what to do with twelve.one
is(twelve."", 12, "Double digits");
is(eleven.hundred."", 1100, "Small, big");
is(seventy.billion."", 70_000_000_000_000, "Very big");
is(sixty.two.thousand."", 62_000, "Big, small, big");
is(five.hundred.and.fifty.seven."", 557, "Use of 'and'");
is(two.hundred.and.twenty.thousand."", 220_000, "Larger number at end after 'and'");

