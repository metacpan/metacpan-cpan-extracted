#!perl

use strict;
use warnings;
use Test::More 0.98;

use Algorithm::Backoff::LIMD;

#subtest "required arguments" => sub {
#};

# XXX test attr: max_attempts

subtest "attr: initial_delay, delay_increment_on_failure, delay_multiple_on_success, max_delay, min_delay" => sub {
    my $ar = Algorithm::Backoff::LIMD->new(
        delay_increment_on_failure => 4,
        delay_multiple_on_success  => 0.2,
        initial_delay => 2,
        min_delay => 1,
    );

    is($ar->failure(1),  2);
    is($ar->failure(1),  6);
    is($ar->failure(1),  10);
    is($ar->success(1),  2);
    is($ar->success(1),  1);
    is($ar->success(1),  1);
    is($ar->failure(1),  5);
    is($ar->failure(1),  9);
};

# XXX test attr: jitter_factor

DONE_TESTING:
done_testing;
