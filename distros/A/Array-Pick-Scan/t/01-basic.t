#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::RandomResult;

use Array::Iter 'array_iter';
use Array::Pick::Scan 'random_item', 'pick';

subtest 'random_item (old name)' => sub {
    is_deeply([random_item([], 1)], []);
};

subtest 'pick' => sub {
    is_deeply([pick([], 1)], []);

    # array source
    results_look_random { pick([1..10], 1) } runs=>100, between=>[1,10];
    # iterator source
    results_look_random { my $iter = array_iter([1..10]); pick($iter, 1) } runs=>100, between=>[1,10];

    # opts option
    is_deeply([random_item(["a"], 1, {pos=>1})], [0]);
};

DONE_TESTING:
done_testing;
