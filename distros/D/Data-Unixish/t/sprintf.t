#!/perl

use 5.010;
use strict;
use utf8;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

{
    local $ENV{LANG} = 'C';
    local $ENV{LC_ALL} = 'C';
    local $ENV{LC_NUMERIC} = 'C';

    test_dux_func(
        func => 'sprintf',
        tests => [
            {
                name => 'scalar, skip_non_number, skip_array',
                args => {format=>'%04.1f', skip_non_number=>1, skip_array=>1},
                in   => [1, "2x", [3.1], undef],
                out  => ["01.0", "2x", [3.1], undef],
            },
            {
                name => 'array',
                args => {format=>'%03s %04s'},
                in   => [1, "2x", [1, 2], undef],
                out  => ["001 0000", "02x 0000", "001 0002", undef],
            },
        ],
    );
}

done_testing;
