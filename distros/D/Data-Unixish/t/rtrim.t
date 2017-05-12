#!/perl

use 5.010;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'rtrim',
    tests => [
        {in =>[" x", "a \n", "b  \nc \n", ["d "]],
         args=>{},
         out=>[" x", "a\n", "b\nc\n", ["d "]]},
        {in =>[" x", "a\n", "b  \nc \n", ["d "]],
         args=>{strip_newline=>1},
         out=>[" x", "a", "b\nc", ["d "]]},
    ],
);

done_testing;
