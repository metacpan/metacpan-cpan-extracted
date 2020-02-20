#!perl

use strict;
use warnings;
use Test::More 0.98;

use Data::Throttler_CHI;
use CHI;

my $t = Data::Throttler_CHI->new(
    max_items => 3,
    interval  => 2,
    cache     => CHI->new(driver=>"Memory", global=>1),
);

is($t->try_push, 1);
is($t->try_push, 1);
is($t->try_push, 1);
is($t->try_push, 0);
is($t->try_push, 0);
sleep 3;
is($t->try_push, 1);

DONE_TESTING:
done_testing;
