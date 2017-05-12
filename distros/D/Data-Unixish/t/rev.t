#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'rev',
    tests => [
        {in=>[1..10], args=>{}, out=>[reverse 1..10]},
    ],
);

done_testing;
