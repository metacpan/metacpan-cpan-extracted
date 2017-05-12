#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'head',
    tests => [
        {in=>[1..20], args=>{}, out=>[1..10]},
        {in=>[1..20], args=>{items=>2}, out=>[1..2]},
        {in=>[1..20], args=>{items=>1}, out=>[1]},
        {in=>[1..20], args=>{items=>0}, out=>[]},
    ],
);

done_testing;
