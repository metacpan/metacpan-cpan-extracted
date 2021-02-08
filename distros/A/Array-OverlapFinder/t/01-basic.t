#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Array::OverlapFinder qw(find_overlap combine_overlap);

subtest find_overlap => sub {
    is_deeply([find_overlap([5,6,7,8],[9,10])], []);
    is_deeply([find_overlap({detail=>1},
                            [5,6,7,8],[9,10])], [[], undef]);

    is_deeply([find_overlap([5,6,7,8],[8,9,10])], [8]);
    is_deeply([find_overlap({detail=>1},
                            [5,6,7,8],[8,9,10])], [[8], 3]);

    is_deeply([find_overlap([5,6,7,8],[5,6,7])], [5,6,7,8]);
    is_deeply([find_overlap({detail=>1},
                            [5,6,7,8],[5,6,7])], [[5,6,7,8], 0]);

    is_deeply([find_overlap([5,6,7,8],[5,6,7,8])], [5,6,7,8]);
    is_deeply([find_overlap({detail=>1},
                            [5,6,7,8],[5,6,7,8])], [[5,6,7,8], 0]);

    is_deeply([find_overlap([5,6,7,8],[5,6,7,8,9])], [5,6,7,8]);
    is_deeply([find_overlap({detail=>1},
                            [5,6,7,8],[5,6,7,8,9])], [[5,6,7,8], 0]);

    is_deeply([find_overlap([5,6,7,8],[5,6,9,10])], []);
    is_deeply([find_overlap({detail=>1},
                            [5,6,7,8],[5,6,9,10])], [[], undef]);

    # 3+ seqs
    is_deeply([find_overlap([5,6,7,8],[7,8,9],[9,10,11])], [[7,8], [9]]);
    is_deeply([find_overlap({detail=>1},
                            [5,6,7,8],[7,8,9],[9,10,11])], [[7,8], 2, [9], 4]);

};

subtest combine_overlap => sub {
    is_deeply([combine_overlap([5,6,7,8],[9,10])], [5,6,7,8,9,10]);
    is_deeply([combine_overlap({detail=>1},
                               [5,6,7,8],[9,10])], [[5,6,7,8,9,10], [], undef]);

    is_deeply([combine_overlap([5,6,7,8],[8,9,10])], [5,6,7,8,9,10]);
    is_deeply([combine_overlap({detail=>1},
                               [5,6,7,8],[8,9,10])], [[5,6,7,8,9,10], [8], 3]);

    is_deeply([combine_overlap([5,6,7,8],[5,6,7])], [5,6,7,8]);
    is_deeply([combine_overlap({detail=>1},
                               [5,6,7,8],[5,6,7])], [[5,6,7,8], [5,6,7,8], 0]);

    is_deeply([combine_overlap([5,6,7,8],[5,6,7,8])], [5,6,7,8]);
    is_deeply([combine_overlap({detail=>1},
                               [5,6,7,8],[5,6,7,8])], [[5,6,7,8], [5,6,7,8], 0]);

    is_deeply([combine_overlap([5,6,7,8],[5,6,7,8,9])], [5,6,7,8,9]);
    is_deeply([combine_overlap({detail=>1},
                               [5,6,7,8],[5,6,7,8,9])], [[5,6,7,8,9], [5,6,7,8], 0]);

    is_deeply([combine_overlap([5,6,7,8],[5,6,9,10])], [5,6,7,8,5,6,9,10]);
    is_deeply([combine_overlap({detail=>1},
                               [5,6,7,8],[5,6,9,10])], [[5,6,7,8,5,6,9,10], [], undef]);

    # 3+ seqs
    is_deeply([combine_overlap([5,6,7,8],[7,8,9],[9,10,11])], [5,6,7,8,9,10,11]);
    is_deeply([combine_overlap({detail=>1},
                               [5,6,7,8],[7,8,9],[9,10,11])], [[5,6,7,8,9,10,11], [7,8], 2, [9], 4]);
};

DONE_TESTING:
done_testing;
