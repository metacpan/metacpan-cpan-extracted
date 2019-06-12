#!perl

use strict;
use warnings;
use Test::More 0.98;

use Algorithm::Backoff::LILD;

#subtest "required arguments" => sub {
#};

# XXX test attr: max_attempts

subtest "attr: initial_delay, delay_increment_on_failure, delay_increment_on_success, max_delay, min_delay" => sub {
    my $ar = Algorithm::Backoff::LILD->new(
        delay_increment_on_failure  => 4,
        delay_increment_on_success => -5,
        initial_delay => 3,
        min_delay => 1,
    );

    is($ar->failure(1),  3);
    is($ar->failure(1),  7);
    is($ar->failure(1),  11);
    is($ar->success(1),  6);
    is($ar->success(1),  1);
    is($ar->success(1),  1);
    is($ar->success(1),  1);
    is($ar->failure(1),  5);
    is($ar->failure(1),  9);
};

# XXX test attr: jitter_factor

DONE_TESTING:
done_testing;
