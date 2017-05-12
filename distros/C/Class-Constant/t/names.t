#!perl -T

use Test::More tests => 3;

use Class::Constant
    ALPHA            => "alpha",
    ALPHA_UNDERSCORE => "alpha with underscore",
    ALPHA_NUMBER_0   => "alpha with numbers";

is(ALPHA,            "alpha");
is(ALPHA_UNDERSCORE, "alpha with underscore");
is(ALPHA_NUMBER_0,   "alpha with numbers");
