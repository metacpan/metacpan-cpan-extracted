#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Algorithm::Backoff::Constant;

# XXX test max_attempts for each strategy
subtest "attr: max_attempts" => sub {
    my $ar;

    $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
        max_attempts => 0,
    );
    isnt($ar->failure(1), -1);
    isnt($ar->failure(2), -1);
    isnt($ar->failure(3), -1);

    $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
        max_attempts => 1,
    );
    is($ar->failure(1), -1);

    $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
        max_attempts => 2,
    );
    isnt($ar->failure(1), -1);
    is  ($ar->failure(1), -1);
    $ar->success(1);
    isnt($ar->failure(1), -1);
    is  ($ar->failure(1), -1);
};

# XXX test max_actual_duration for each strategy
subtest "attr: max_actual_duration" => sub {
    my $ar;

    $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
        max_actual_duration => 4,
        max_attempts => 3,
        _start_timestamp => 0,
    );
    isnt($ar->failure(0), -1);
    isnt($ar->failure(2), -1);
    is  ($ar->failure(4), -1);
};

# XXX test consider_actual_delay for each strategy
subtest "attr: consider_actual_delay" => sub {
    my $ar;

    $ar = Algorithm::Backoff::Constant->new(
        consider_actual_delay => 1,
        delay => 2,
        max_attempts => 0,
    );

    is($ar->failure(1), 2);

    # we didn't wait, so the delay is now 2+2 = 4
    is($ar->failure(1), 4);

    # we now waited for 5 seconds, so delay is now 2-1 = 1
    is($ar->failure(6), 1);

    # we now waited for 2 seconds, so delay is now 2-1 = 1
    is($ar->failure(8), 1);

    # we now waited for 3 seconds, so delay is now 2-2 = 0
    is($ar->failure(11), 0);
};

# XXX test jitter_factor for each strategy
subtest "attr: jitter_factor" => sub {
    my $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
        delay_on_success => 3,
        jitter_factor => 0.1,
    );

    rand_between_ok(sub { $ar->failure(1) }, 2*(1-0.1), 2*(1+0.1));
    rand_between_ok(sub { $ar->success(1) }, 3*(1-0.1), 3*(1+0.1));

    # jittered delay still doesn't violate min_delay and max_delay
    $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
        delay_on_success => 2,
        min_delay => 1.8,
        max_delay => 2.2,
        jitter_factor => 0.5,
    );
    rand_between_ok(sub { $ar->failure(1) }, 1.8, 2.2);

    $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
        delay_on_success => 3,
        min_delay => 2.8,
        max_delay => 3.2,
        jitter_factor => 0.5,
    );

    rand_between_ok(sub { $ar->success(1) }, 2.8, 3.2);
};

subtest "timestamp must not decrease" => sub {
    my $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
    );

    $ar->success(2);
    dies_ok { $ar->success(1) };
};

DONE_TESTING:
done_testing;

# XXX temporary function
sub rand_between_ok(&$$) {
    my ($block, $min, $max, $name) = @_;
    my @res;
    my %res;
    for (1..30) {
        my $res = $block->();
        do {
            ok(0, "Result #$_ is not between $min and $max ($res)");
            return;
        } if $res < $min || $res > $max;
        push @res, $res;
        $res{ $res+0 }++;
    }
    note "Results: ", explain(\@res);
    keys(%res) > 1 or
        ok(0, "Results do not seem to be random, but constant $res[0]");
    ok(1, "Results are random between $min and $max");
}
