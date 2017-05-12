#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.98;

test_dux_func(
    func => 'indent',
    tests => [
        {
            name => 'default',
            in   => ["a", " b\nc", "", ["d"]],
            args => {},
            out  => ["    a", "     b\n    c", "    ", ["d"]],
        },
        {
            name => 'num opt',
            in   => ["a", " b\nc", "", ["d"]],
            args => {num=>2},
            out  => ["  a", "   b\n  c", "  ", ["d"]],
        },
        {
            name => 'tab opt',
            in   => ["a", " b\nc", "", ["d"]],
            args => {num=>2, tab=>1},
            out  => ["\t\ta", "\t\t b\n\t\tc", "\t\t", ["d"]],
        },
    ],
);

done_testing;
