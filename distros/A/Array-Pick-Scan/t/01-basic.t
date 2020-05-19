#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::RandomResult;

use Array::Iter 'array_iter';
use Array::Pick::Scan 'random_item';

results_look_random { random_item([1..10], 1) } runs=>100, between=>[1,10];
results_look_random { my $iter = array_iter([1..10]); random_item($iter, 1) } runs=>100, between=>[1,10];

DONE_TESTING:
done_testing;
