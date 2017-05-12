#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'uc',
    tests => [
        {
            args => {},
            in   => ["AB", "ab", "aB", "Ab", ["aB"]],
            out  => ["AB", "AB", "AB", "AB", ["aB"]],
        },
    ],
);

done_testing;
