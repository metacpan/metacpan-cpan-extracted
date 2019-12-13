#!/perl

use 5.010001;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.98;

test_dux_func(
    func => 'count',
    tests => [
        {in =>["z", "zz", "zzz", "", "o", []],
         args=>{pattern=>'z', fixed_string=>1},
         out=>[1, 2, 3, 0, 0, 0]},
    ],
);

done_testing;
