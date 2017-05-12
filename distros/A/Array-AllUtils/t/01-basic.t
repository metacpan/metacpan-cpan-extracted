#!perl

use Array::AllUtils qw(first firstidx);
use Test::More 0.98;

subtest first => sub {
    is_deeply((first {$_ % 2} [2,3,4]), 3);
    is_deeply((first {$_ > 4} [2,3,4]), undef);
};

subtest firstidx => sub {
    is_deeply((firstidx {$_ % 2} [2,3,4]), 1);
    is_deeply((firstidx {$_ > 4} [2,3,4]), -1);
};

done_testing;
