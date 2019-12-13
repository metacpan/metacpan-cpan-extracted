#!/perl

use 5.010001;
use strict;
use warnings;
use Test::Data::Unixish;
use Test::More 0.98;

test_dux_func(
    func => 'join',
    tests => [
        {in =>[["a","b","c"], ["d","e"], "f,g"],
         args=>{},
         out=>["abc","de","f,g"]},
        {in =>[["a","b","c"], ["d","e"], "f,g"],
         args=>{string=>', '},
         out=>["a, b, c","d, e","f,g"]},
    ],
);

done_testing;
