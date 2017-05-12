#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'lcfirst',
    tests => [
        {
            args => {},
            in   => ["AB", "ab", "aB", "Ab", ["aB"]],
            out  => ["aB", "ab", "aB", "ab", ["aB"]],
        },
    ],
);

done_testing;
