#!/perl

use 5.010;
use strict;
use utf8;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

local $ENV{LANG} = "C";

test_dux_func(
    func => 'grep',
    tests => [
        {
            name => 'simple',
            args => { callback => sub { $_ % 2 } },
            in   => [ 1 .. 10 ],
            out  => [ 1, 3, 5, 7, 9 ],
        },
        {
            name => 'index',
            args => { callback => sub { $. % 2 } },
            in   => [ 1 .. 10 ],
            out  => [ 2, 4, 6, 8, 10 ],
        },
        {
            name => 'regexp',
            args => { callback => qr{cat} },
            in   => [ qw/category dogma cataclysm catalyst/ ],
            out  => [ qw/category       cataclysm catalyst/ ],
        },
        {
            name => 'accept code string',
            args => { callback => '$. % 2' },
            in   => [ 1 .. 10 ],
            out  => [ 2, 4, 6, 8, 10 ],
            func_dies => 1, # because cond only accepts string code over cli
            skip_cli => 0,  # to test that cli accepts string code
        },
    ],
);

done_testing;
