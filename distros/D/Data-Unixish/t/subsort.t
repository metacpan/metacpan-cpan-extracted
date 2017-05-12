#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'subsort',
    tests => [
        {in=>[qw/t1 t10 t2/], args=>{routine=>'naturally'}, out=>[qw/t1 t2 t10/]},
        {in=>[qw/t1 T10 t2/], args=>{routine=>'naturally', ci=>1}, out=>[qw/t1 t2 T10/]},
        {in=>[qw/t1 T10 t2/], args=>{routine=>'naturally', ci=>1, reverse=>1}, out=>[qw/T10 t2 t1/]},
    ],
);

done_testing;
