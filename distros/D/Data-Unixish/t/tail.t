#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'tail',
    tests => [
        {in=>[1..20], args=>{}, out=>[11..20]},
        {in=>[1..20], args=>{items=>2}, out=>[19..20]},
        {in=>[1..20], args=>{items=>1}, out=>[20]},
        {in=>[1..20], args=>{items=>0}, out=>[]},
    ],
);

done_testing;
