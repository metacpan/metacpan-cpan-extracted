#!/perl

use 5.010001;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.98;

test_dux_func(
    func => 'splice',
    tests => [
        {in =>[["a","b","c"],["d","e"],"f,g"],
         args=>{offset=>1},
         out=>[["a"],["d"],["f,g"]]},
        {in =>[["a","b","c"],["d","e"],"f,g"],
         args=>{offset=>1, length=>1},
         out=>[["a","c"],["d"],["f,g"]]},
        {in =>[["a","b","c"],["d","e"],"f,g"],
         args=>{offset=>1, length=>1, list=>["x","y"]},
         out=>[["a","x","y","c"],["d","x","y"],["f,g","x","y"]]},
    ],
);

done_testing;
