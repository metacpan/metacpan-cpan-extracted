#!perl

use strict;
use warnings;
use Test::More 0.98;

use Algorithm::Retry::ExponentialBackoff;

#subtest "required arguments" => sub {
#};

# XXX test attr: max_attempts

subtest "attr: initial_delay, max_delay, delay_on_success" => sub {
    my $ar = Algorithm::Retry::ExponentialBackoff->new(
        delay_on_success => 1,
        initial_delay => 5,
        max_delay => 100,
    );

    is($ar->failure(1), 5);
    is($ar->failure(1), 10);
    is($ar->failure(1), 20);
    is($ar->failure(8), 33); # timestamp
    is($ar->failure(8), 80);
    is($ar->failure(8), 100);
    is($ar->success(8), 1);
};

subtest "attr: exponent_base" => sub {
    my $ar = Algorithm::Retry::ExponentialBackoff->new(
        initial_delay => 5,
        exponent_base => 3,
    );
    is($ar->failure(1), 5);
    is($ar->failure(1), 15);
    is($ar->failure(1), 45);
};

# XXX test attr: jitter_factor

DONE_TESTING:
done_testing;
