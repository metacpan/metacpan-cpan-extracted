#!perl
use strict;
use Test::More tests => 7;

BEGIN { use_ok('DateTime::Util::Calc', 'min', 'max') }

is(min(-2, 0), -2);
is(max(-2, 0), 0);
is(min(23,23), 23);
is(max(23,23), 23);
is(min(0, 10), 0);
is(max(0, 10), 10);
