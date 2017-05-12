#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'ltrim',
    tests => [
        {in =>["x ", "\na ", "  b\n c\n", [" d"]],
         args=>{},
         out=>["x ", "\na ", "b\nc\n", [" d"]]},
        {in =>["x ", "\na ", "  b\n c\n", [" d"]],
         args=>{strip_newline=>1},
         out=>["x ", "a ", "b\nc\n", [" d"]]},
    ],
);

done_testing;
