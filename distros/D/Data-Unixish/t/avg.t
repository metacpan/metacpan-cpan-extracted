#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'avg',
    tests => [
        {in=>[1, " 2", "3\n", "4 ", " 5a"], args=>{}, out=>[2]},
    ],
);

done_testing;
