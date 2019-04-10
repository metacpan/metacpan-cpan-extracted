#!perl

use strict;
use warnings;
use Test::More 0.98;

use Algorithm::Retry::Fibonacci;

#subtest "required arguments" => sub {
#};

# XXX test attr: max_attempts

subtest "attr: initial_delay1, initial_delay2, max_delay, delay_on_success" => sub {
    my $ar = Algorithm::Retry::Fibonacci->new(
        delay_on_success => 1,
        initial_delay1 => 2,
        initial_delay2 => 3,
        max_delay => 20,
    );

    is($ar->failure(1),  2);
    is($ar->failure(1),  3);
    is($ar->failure(1),  5);
    is($ar->failure(8),  8); # test consider_actual_delay=0
    is($ar->failure(8), 13);
    is($ar->failure(8), 20);
    is($ar->success(8),  1);
};

# XXX test attr: jitter_factor

DONE_TESTING:
done_testing;
