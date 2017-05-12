#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'lc',
    tests => [
        {
            args => {},
            in   => ["AB", "ab", "aB", "Ab", ["aB"]],
            out  => ["ab", "ab", "ab", "ab", ["aB"]],
        },
    ],
);

done_testing;
