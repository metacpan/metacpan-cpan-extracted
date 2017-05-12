#!/perl

use 5.010;
use strict;
use utf8;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

local $ENV{LANG} = "C";

test_dux_func(
    func => 'map',
    tests => [
        {
            name => 'simple',
            args => { callback => sub { int($_) } },
            in   => [ "2.2", "3.3", "4.4", "5.5" ],
            out  => [ 2 .. 5 ],
        },
        {
            name => 'index',
            args => { callback => sub { int($.) } },
            in   => [ "2.2", "3.3", "4.4", "5.5" ],
            out  => [ 0 .. 3 ],
            skip_itemfunc => 1,
        },
        {
            name => 'returning a list',
            args => { callback => sub { split /\./ } },
            in   => [ "2.2", "3.3", "4.4", "5.5" ],
            out  => [ 2, 2, 3, 3, 4, 4, 5, 5 ],
        },
        {
            name => 'accept code string',
            args => { callback => 'split /\./' },
            in   => [ "2.2", "3.3", "4.4", "5.5" ],
            out  => [ 2, 2, 3, 3, 4, 4, 5, 5 ],
            func_dies => 1, # because cond only accepts string code over cli
            skip_cli => 0,  # to test that cli accepts string code
        },
    ],
);

done_testing;
