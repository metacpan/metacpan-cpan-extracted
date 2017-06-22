#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Array::Sample::Partition qw(sample_partition);

subtest "basics" => sub {
    is_deeply([sample_partition([], 0)], []);
    is_deeply([sample_partition([], 1)], []);

    is_deeply([sample_partition([qw/a/], 0)], []);
    is_deeply([sample_partition([qw/a/], 1)], [qw/a/]);

    is_deeply([sample_partition([qw/a b/], 1)], [qw/b/]);
    is_deeply([sample_partition([qw/a b/], 2)], [qw/a b/]);

    is_deeply([sample_partition([qw/a b c/], 1)], [qw/b/]);
    is_deeply([sample_partition([qw/a b c/], 2)], [qw/b c/]);
    is_deeply([sample_partition([qw/a b c/], 3)], [qw/a b c/]);

    is_deeply([sample_partition([qw/a b c/], 1)], [qw/b/]);
    is_deeply([sample_partition([qw/a b c/], 2)], [qw/b c/]);
    is_deeply([sample_partition([qw/a b c/], 3)], [qw/a b c/]);
};

subtest "opt:pos=1" => sub {
    is_deeply([sample_partition([qw/a b/], 1, {pos=>1})], [1]);
    is_deeply([sample_partition([qw/a b/], 2, {pos=>1})], [0,1]);
};

DONE_TESTING:
done_testing;
