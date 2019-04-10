#!perl

use strict;
use warnings;
use Test::More 0.98;
use Test::Number::Delta within => 1e-3;

use Algorithm::Retry::Constant;

#subtest "required arguments" => sub {
#};

subtest "basics" => sub {
    my $ar = Algorithm::Retry::Constant->new(
        delay            => 2,
        delay_on_success => 1,
    );

    is($ar->success(1), 1);
    is($ar->success(1), 1);
    is($ar->failure(1), 2);
    is($ar->failure(1), 2);
    is($ar->failure(2), 2); # test consider_actual_delay = 0
    is($ar->failure(4), 2); # test consider_actual_delay = 0

    # test using real timestamps
    $ar = Algorithm::Retry::Constant->new(
        delay            => 2,
        delay_on_success => 1,
    );
    delta_ok($ar->success, 1);
    delta_ok($ar->failure, 2);
};

# XXX test jitters

DONE_TESTING:
done_testing;
