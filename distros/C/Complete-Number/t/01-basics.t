#!perl

use 5.010;
use strict;
use warnings;

use Complete::Number qw(complete_int complete_float);
use Test::More 0.98;

subtest complete_int => sub {
    is_deeply(complete_int(), [sort {$a cmp $b} -9 .. 9]);
    is_deeply(complete_int(min=>1 , max=>5 ), [1..5]);
    is_deeply(complete_int(xmin=>1, xmax=>5), [2..4]);
    is_deeply(complete_int(word=>10), [10, 100..109]);
    # XXX more tests
};

subtest complete_float => sub {
    is_deeply(complete_float(), [sort {$a cmp $b} -9 .. 9]);
    # XXX more tests
};

done_testing;
