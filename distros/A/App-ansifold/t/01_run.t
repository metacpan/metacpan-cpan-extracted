use v5.14;
use warnings;

use Test::More;

use lib '.';
use t::Util;

is(ansifold('/dev/null')->{result} >> 8, 0, "/dev/null");
is(ansifold('--invalid')->{result} >> 8, 2, "invalid option");

done_testing;
