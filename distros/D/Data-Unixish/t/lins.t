#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.98;

test_dux_func(
    func => 'lins',
    tests => [
        {in =>["a", " b\nc", "", ["d"]],
         args=>{text=>"xx"},
         out=>["xxa", "xx b\nxxc", "xx", ["d"]]},
    ],
);

done_testing;
