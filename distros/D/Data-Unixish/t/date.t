#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'date',
    tests => [
        {in=>[qw/942585808 1342585808/], args=>{format=>'%Y'}, out=>[qw/1999 2012/]},
    ],
);

done_testing;
