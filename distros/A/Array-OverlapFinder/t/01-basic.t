#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Array::OverlapFinder qw(find_overlap combine_overlap);

subtest find_overlap => sub {
    is_deeply([find_overlap([5,6,7,8],[9,10])], []);
    is_deeply([find_overlap([5,6,7,8],[9,10], 'detail')], [[], undef]);

    is_deeply([find_overlap([5,6,7,8],[8,9,10])], [8]);
    is_deeply([find_overlap([5,6,7,8],[8,9,10], 'detail')], [[8], 3]);

    is_deeply([find_overlap([5,6,7,8],[5,6,7])], [5,6,7,8]);
    is_deeply([find_overlap([5,6,7,8],[5,6,7], 'detail')], [[5,6,7,8], 0]);

    is_deeply([find_overlap([5,6,7,8],[5,6,7,8])], [5,6,7,8]);
    is_deeply([find_overlap([5,6,7,8],[5,6,7,8], 'detail')], [[5,6,7,8], 0]);

    is_deeply([find_overlap([5,6,7,8],[5,6,7,8,9])], [5,6,7,8]);
    is_deeply([find_overlap([5,6,7,8],[5,6,7,8,9], 'detail')], [[5,6,7,8], 0]);

    is_deeply([find_overlap([5,6,7,8],[5,6,9,10])], []);
    is_deeply([find_overlap([5,6,7,8],[5,6,9,10], 'detail')], [[], undef]);
};

subtest combine_overlap => sub {
    is_deeply([combine_overlap([5,6,7,8],[9,10])], [5,6,7,8,9,10]);
    is_deeply([combine_overlap([5,6,7,8],[9,10], 'detail')], [[5,6,7,8,9,10], [], undef]);

    is_deeply([combine_overlap([5,6,7,8],[8,9,10])], [5,6,7,8,9,10]);
    is_deeply([combine_overlap([5,6,7,8],[8,9,10], 'detail')], [[5,6,7,8,9,10], [8], 3]);

    is_deeply([combine_overlap([5,6,7,8],[5,6,7])], [5,6,7,8]);
    is_deeply([combine_overlap([5,6,7,8],[5,6,7], 'detail')], [[5,6,7,8], [5,6,7,8], 0]);

    is_deeply([combine_overlap([5,6,7,8],[5,6,7,8])], [5,6,7,8]);
    is_deeply([combine_overlap([5,6,7,8],[5,6,7,8], 'detail')], [[5,6,7,8], [5,6,7,8], 0]);

    is_deeply([combine_overlap([5,6,7,8],[5,6,7,8,9])], [5,6,7,8,9]);
    is_deeply([combine_overlap([5,6,7,8],[5,6,7,8,9], 'detail')], [[5,6,7,8,9], [5,6,7,8], 0]);

    is_deeply([combine_overlap([5,6,7,8],[5,6,9,10])], [5,6,7,8,5,6,9,10]);
    is_deeply([combine_overlap([5,6,7,8],[5,6,9,10], 'detail')], [[5,6,7,8,5,6,9,10], [], undef]);
};

DONE_TESTING:
done_testing;
