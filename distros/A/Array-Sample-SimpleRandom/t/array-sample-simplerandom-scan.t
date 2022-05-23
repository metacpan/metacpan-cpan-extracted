#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Array::Sample::SimpleRandom::Scan qw(sample_simple_random_no_replacement);

subtest "sample_simple_random_no_replacement" => sub {
    is_deeply([sample_simple_random_no_replacement([], 0)], []);
    is_deeply([sample_simple_random_no_replacement([], 1)], []);

    is_deeply([sample_simple_random_no_replacement([qw/a/], 0)], []);
    is_deeply([sample_simple_random_no_replacement([qw/a/], 1)], [qw/a/]);

    is_deeply([sample_simple_random_no_replacement([qw/a b/], 0)], []);
    #is_deeply([sample_simple_random_no_replacement([qw/a b/], 1)], [qw/a/]);
};

DONE_TESTING:
done_testing;
