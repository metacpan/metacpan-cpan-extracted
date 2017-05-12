#!/perl

use 5.010;
use strict;
use utf8;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

local $ENV{LANG} = "C";

test_dux_func(
    func => 'chain',
    tests => [
        {
            name => 'empty',
            args => { functions => [] },
            in   => [ 1000, 2000 ],
            out  => [ 1000, 2000 ],
        },
        {
            name => 'one func',
            args => { functions => ["trim"] },
            in   => [ "  a", "b " ],
            out  => [ "a", "b" ],
        },
    ],
);

done_testing;
