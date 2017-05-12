#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.98;

test_dux_func(
    func => 'linum',
    tests => [
        {
            name => 'defaults',
            in   => ["a", "b \nc\n ", ["d"], "e"],
            args => {},
            out  => ["   1|a", "   2|b \n   3|c\n    | ", ["d"], "   5|e"],
        },
        {
            name => 'blank_empty_lines=0',
            in   => ["a", "b \nc\n ", ["d"], "e"],
            args => {blank_empty_lines=>0},
            out  => ["   1|a", "   2|b \n   3|c\n   4| ", ["d"], "   5|e"],
        },
        {
            name => 'format',
            in   => ["a"],
            args => {format=>'%s:'},
            out  => ["1:a"],
        },
    ],
);

done_testing;
