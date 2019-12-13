#!/perl

use 5.010001;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.98;

test_dux_func(
    func => 'split',
    tests => [
        {in =>["a,b,c","d,e"],
         args=>{pattern=>',', fixed_string=>1},
         out=>[["a","b","c"], ["d","e"]]},
        # XXX: test regex
        # XXX: test limit option
    ],
);

done_testing;
