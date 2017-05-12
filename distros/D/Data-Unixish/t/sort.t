#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'sort',
    tests => [
        {in=>[qw/a C b d/], args=>{}, out=>[qw/C a b d/]},
        {in=>[qw/a C b d/], args=>{ci=>1}, out=>[qw/a b C d/]},
        {in=>[qw/a C b d/], args=>{reverse=>1}, out=>[qw/d b a C/]},
        {in=>[qw/a C b d/], args=>{ci=>1, reverse=>1}, out=>[qw/d C b a/]},
        {in=>[qw/a C 2 -1/], args=>{numeric=>1}, out=>[qw/-1 C a 2/]},
        {in=>[qw/a C 2 -1/], args=>{numeric=>1, ci=>1}, out=>[qw/-1 a C 2/]},
    ],
);

done_testing;
