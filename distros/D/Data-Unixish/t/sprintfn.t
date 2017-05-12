#!/perl

use 5.010;
use strict;
use utf8;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'sprintfn',
    tests => [
        {
            args => {format=>'%(n)03s'},
            in   => [{n=>1}, {n=>"2x"}, "", undef],
            out  => ["001", "02x", "", undef],
        },
    ],
);

done_testing;
