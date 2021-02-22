#!perl

use strict;
use warnings;

use Test::More 0.98;
use List::Util qw< min max sum >;

use Algorithm::Backoff::RetryTimeouts;

my $rt;
my $time  = 0;
my $sqrt2 = sqrt(2);

subtest "Base defaults" => sub {
    $rt = Algorithm::Backoff::RetryTimeouts->new(
        # for the unit tests
        _start_timestamp      => 0,
        jitter_factor         => 0,
        timeout_jitter_factor => 0,
    );

    $time = 0;
    is($rt->timeout, 25, 'Initial timeout: 25');

    # 1: one second attempt
    test_attempt(
        attempt_time   => 1,
        expected_delay => $sqrt2 - 1,  # sqrt(2)^1 - 1
    );

    # 2: instant failure
    test_attempt(
        attempt_time   => 0,
        expected_delay => 2,  # sqrt(2)^2
    );

    # 3: full timeout
    test_attempt(
        attempt_time   => $rt->timeout,
        expected_delay => 0,
    );

    # 4: one second attempt
    test_attempt(
        attempt_time   => 1,
        expected_delay => 3,  # sqrt(2)^4 - 1
    );

    # 5: full timeout (with min_adjust_timeout trigger)
    test_attempt(
        expected_delay   => 0,
        expected_timeout => 5,
    );

    # 6: full timeout (with remaining time max delay check)
    test_attempt(
        expected_delay   => 2.323,  # 50% of the remaining time
        expected_timeout => 5,
    );

    # 7: final attempt
    test_attempt(
        expected_delay   => -1,
        expected_timeout => 5
    );
};

subtest "attr: adjust_timeout_factor" => sub {
    $rt = Algorithm::Backoff::RetryTimeouts->new(
        adjust_timeout_factor => 0.25,

        # for the unit tests
        _start_timestamp      => 0,
        jitter_factor         => 0,
        timeout_jitter_factor => 0,
    );

    $time = 0;
    is($rt->timeout, 12.5, 'Initial timeout: 12.5');

    # 1: one second attempt
    test_attempt(
        attempt_time   => 1,
        expected_delay => $sqrt2 - 1,  # sqrt(2)^1 - 1
    );

    # 2: instant failure
    test_attempt(
        attempt_time   => 0,
        expected_delay => 2,  # sqrt(2)^2
    );

    # 3: full timeout
    test_attempt(
        expected_delay => 0,
    );

    # 4: one second attempt
    test_attempt(
        attempt_time   => 1,
        expected_delay => 3,  # sqrt(2)^4 - 1
    );

    # 5: full timeout
    test_attempt(
        expected_delay => 0,
    );

    # 6: full timeout (with min_adjust_timeout trigger)
    note "Prev Timeout: ".round($rt->timeout);
    test_attempt(
        expected_delay   => 2.199,  # sqrt(2)^6 = 8 - 5.801 (prev timeout)
        expected_timeout => 5,
    );

    # 7: full timeout
    test_attempt(
        expected_delay   => 6.314,  # sqrt(2)^7 - 5
        expected_timeout => 5,
    );

    # 8: final attempt
    test_attempt(
        expected_delay   => -1,
        expected_timeout => 5,
    );
};

subtest "attr: min_adjust_timeout" => sub {
    $rt = Algorithm::Backoff::RetryTimeouts->new(
        adjust_timeout_factor => 0.75,  # just to make this faster
        min_adjust_timeout    => 0,

        # for the unit tests
        _start_timestamp      => 0,
        jitter_factor         => 0,
        timeout_jitter_factor => 0,
    );

    $time = 0;
    is($rt->timeout, 37.5, 'Initial timeout: 37.5');

    # 1: full timeout
    test_attempt(
        expected_delay => 0,
    );

    # 2: full timeout
    test_attempt(
        expected_delay => 0,
    );

    # NOTE: The rest of these are so close to the edge of max_actual_duration that they
    # consistently hit the remaining time max delay check.

    # 3-7: full timeouts
    test_attempt(
        expected_delay => 0.195,
    );
    test_attempt(
        expected_delay => 0.037,
    );
    test_attempt(
        expected_delay => 0.007,
    );
    test_attempt(
        expected_delay => 0.001,
    );
    test_attempt(
        expected_delay => 0,
    );

    # 8: final attempt
    test_attempt(
        expected_delay   => -1,
        expected_timeout => 0.001,
    );
};

subtest "Jitter factors" => sub {
    $rt = Algorithm::Backoff::RetryTimeouts->new(
        max_attempts          => 0,
        consider_actual_delay => 0,
        _start_timestamp      => 0,

        jitter_factor         => 0.1,
        timeout_jitter_factor => 0.1,
    );

    # Calculate an average of 1000 hits
    my @timeouts;
    push @timeouts, $rt->timeout for 1 .. 1000;

    my @delays;
    for (1 .. 1000) {
        $rt->{_attempts} = 0;
        $rt->failure(1);
        push @delays, $rt->delay;
    }

    my $min_timeout  = min    @timeouts;
    my $max_timeout  = max    @timeouts;
    my $avg_timeout  = sum    @timeouts;
    $avg_timeout    /= scalar @timeouts;

    my $min_delay    = min    @delays;
    my $max_delay    = max    @delays;
    my $avg_delay    = sum    @delays;
    $avg_delay      /= scalar @delays;

    cmp_ok($avg_timeout, '>=', 24.5, 'Avg timeout within norms (>=)');
    cmp_ok($avg_timeout, '<=', 25.5, 'Avg timeout within norms (<=)');
    cmp_ok($min_timeout, '<=', 23  , 'Min timeout within norms (<=)');
    cmp_ok($max_timeout, '>=', 27  , 'Max timeout within norms (>=)');

    cmp_ok($avg_delay,   '>=', 1.3, 'Avg delay within norms (>=)');
    cmp_ok($avg_delay,   '<=', 1.5, 'Avg delay within norms (<=)');
    cmp_ok($min_delay,   '<=', 1.3, 'Min delay within norms (<=)');
    cmp_ok($max_delay,   '>=', 1.5, 'Max delay within norms (>=)');

    note "AVG: Timeout: $avg_timeout; Delay: $avg_delay";
    note "MIN: Timeout: $min_timeout; Delay: $min_delay";
    note "MAX: Timeout: $max_timeout; Delay: $max_delay";
};

done_testing;

sub test_attempt {
    my (%args) = @_;

    # Progress the timestamp
    $time += $rt->delay;
    $time += $args{attempt_time} // $rt->timeout;

    # Fail or succeed
    my $method = $args{method} // 'failure';

    my ($delay, $timeout) = $rt->$method($time);
    my $attempts = $rt->{_attempts};

    # Figure out the expected values
    my $expected_delay   = round($args{expected_delay});
    my $expected_timeout = round(
        $args{expected_timeout} // (
            ($rt->{max_actual_duration} - $time - $rt->delay) * $rt->{adjust_timeout_factor}
        )
    );

    # Run the unit tests
    note "Time: ".round($time).", Attempt \#$attempts: $method";
    is(
        round($delay),
        $expected_delay,
        "Expected delay: $expected_delay",
    );
    is(
        round($timeout),
        $expected_timeout,
        "Expected timeout: $expected_timeout",
    );
    is($delay,   $rt->delay,   'Delay   method matches return') unless $delay == -1;
    is($timeout, $rt->timeout, 'Timeout method matches return');
}

sub round { sprintf("%.3f", shift) + 0; }
