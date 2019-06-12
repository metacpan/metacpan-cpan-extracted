#!perl

use strict;
use warnings;
use Test::More 0.98;

use Algorithm::Backoff::MIMD;

#subtest "required arguments" => sub {
#};

# XXX test attr: max_attempts

subtest "attr: initial_delay, delay_multiple_on_failure, delay_multiple_on_success, max_delay, min_delay" => sub {
    my $ar = Algorithm::Backoff::MIMD->new(
        delay_multiple_on_failure => 2,
        delay_multiple_on_success => 0.5,
        initial_delay => 3,
        min_delay => 2,
    );

    is($ar->failure(1),  3);
    is($ar->failure(1),  6);
    is($ar->failure(1),  12);
    is($ar->success(1),  6);
    is($ar->success(1),  3);
    is($ar->success(1),  2);
    is($ar->success(1),  2);
    is($ar->success(1),  2);
    is($ar->failure(1),  4);
    is($ar->failure(1),  8);
};

# XXX test attr: jitter_factor

DONE_TESTING:
done_testing;
