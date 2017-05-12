#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'sum',
    tests => [
        {in=>[1, " 2", "3\n", "4 ", " 5a"], args=>{}, out=>[10]},
    ],
);

done_testing;
