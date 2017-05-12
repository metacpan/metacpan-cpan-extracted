#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'trim',
    tests => [
        {in =>["x", "\n a \n", "  b  \n c \n", [" d "]],
         args=>{},
         out=>["x", "\na\n", "b\nc\n", [" d "]]},
        {in =>["x", "\n a\n", "  b  \n c \n", [" d "]],
         args=>{strip_newline=>1},
         out=>["x", "a", "b\nc", [" d "]]},
    ],
);

done_testing;
