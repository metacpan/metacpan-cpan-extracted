#!perl
use strict;
use Test::More tests => 4;

BEGIN { use_ok('DateTime::Util::Calc', 'polynomial') }

ok(polynomial(1, 2, 3, 4) == 9);
ok(polynomial(2, -1, 2, -3, 4) == 23);
ok(polynomial(0, 1, 2, 3, 4) == 1);
