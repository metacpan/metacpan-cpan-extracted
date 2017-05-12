#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.98;

test_dux_func(
    func => 'wrap',
    tests => [
        {in =>["xxxx xxxx xxxx xxxx xxxx"],
         args=>{width=>20},
         out=>["xxxx xxxx xxxx xxxx\nxxxx"]},
    ],
);

done_testing;
