# t/10-connection/reconnect.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;
use Time::HiRes qw(time sleep);

# Helper: await a Future and return its result (throws on failure)

subtest 'constructor accepts reconnect parameters' => sub {
    my $redis = Async::Redis->new(
        host                => 'localhost',
        reconnect           => 1,
        reconnect_delay     => 0.1,
        reconnect_delay_max => 30,
        reconnect_jitter    => 0.25,
    );

    ok($redis->{reconnect}, 'reconnect enabled');
    is($redis->{reconnect_delay}, 0.1, 'reconnect_delay');
    is($redis->{reconnect_delay_max}, 30, 'reconnect_delay_max');
    is($redis->{reconnect_jitter}, 0.25, 'reconnect_jitter');
};

subtest 'default reconnect values' => sub {
    my $redis = Async::Redis->new(host => 'localhost');

    ok(!$redis->{reconnect}, 'reconnect disabled by default');
    is($redis->{reconnect_delay}, 0.1, 'default reconnect_delay');
    is($redis->{reconnect_delay_max}, 60, 'default reconnect_delay_max');
    is($redis->{reconnect_jitter}, 0.25, 'default reconnect_jitter');
};

subtest 'callbacks accepted' => sub {
    my @events;

    my $redis = Async::Redis->new(
        host          => 'localhost',
        on_connect    => sub { push @events, ['connect', @_] },
        on_disconnect => sub { push @events, ['disconnect', @_] },
        on_error      => sub { push @events, ['error', @_] },
    );

    ok(ref $redis->{on_connect} eq 'CODE', 'on_connect stored');
    ok(ref $redis->{on_disconnect} eq 'CODE', 'on_disconnect stored');
    ok(ref $redis->{on_error} eq 'CODE', 'on_error stored');
};

subtest 'exponential backoff calculation' => sub {
    my $redis = Async::Redis->new(
        host                => 'localhost',
        reconnect_delay     => 0.1,
        reconnect_delay_max => 10,
        reconnect_jitter    => 0,  # disable jitter for predictable testing
    );

    # Test internal backoff calculation
    is($redis->_calculate_backoff(1), 0.1, 'attempt 1: 0.1s');
    is($redis->_calculate_backoff(2), 0.2, 'attempt 2: 0.2s');
    is($redis->_calculate_backoff(3), 0.4, 'attempt 3: 0.4s');
    is($redis->_calculate_backoff(4), 0.8, 'attempt 4: 0.8s');
    is($redis->_calculate_backoff(10), 10, 'attempt 10: capped at max');
    is($redis->_calculate_backoff(20), 10, 'attempt 20: still capped');
};

subtest 'jitter applied to backoff' => sub {
    my $redis = Async::Redis->new(
        host                => 'localhost',
        reconnect_delay     => 1,
        reconnect_delay_max => 60,
        reconnect_jitter    => 0.25,
    );

    # With 25% jitter, delay 1.0 should be in range [0.75, 1.25]
    my @delays;
    for my $i (1..20) {
        push @delays, $redis->_calculate_backoff(1);
    }

    my $min = (sort { $a <=> $b } @delays)[0];
    my $max = (sort { $b <=> $a } @delays)[0];

    ok($min >= 0.75, "min delay $min >= 0.75");
    ok($max <= 1.25, "max delay $max <= 1.25");
    ok($max > $min, "jitter produced variation");
};

# Tests requiring Redis
SKIP: {
    my $test_redis = eval {
        my $r = Async::Redis->new(
            host            => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 3 unless $test_redis;
    $test_redis->disconnect;

    subtest 'on_connect callback fires' => sub {
        my @events;

        my $redis = Async::Redis->new(
            host       => $ENV{REDIS_HOST} // 'localhost',
            on_connect => sub {
                my ($r) = @_;
                push @events, 'connected';
            },
        );

        run { $redis->connect };

        is(\@events, ['connected'], 'on_connect fired');
        $redis->disconnect;
    };

    subtest 'on_disconnect callback fires' => sub {
        my @events;

        my $redis = Async::Redis->new(
            host          => $ENV{REDIS_HOST} // 'localhost',
            on_disconnect => sub {
                my ($r, $reason) = @_;
                push @events, ['disconnected', $reason];
            },
        );

        run { $redis->connect };
        $redis->disconnect;

        is(scalar @events, 1, 'on_disconnect fired once');
        is($events[0][0], 'disconnected', 'event type');
    };

    subtest 'reconnect after disconnect' => sub {
        my @events;

        my $redis = Async::Redis->new(
            host          => $ENV{REDIS_HOST} // 'localhost',
            reconnect     => 1,
            on_connect    => sub { push @events, 'connect' },
            on_disconnect => sub { push @events, 'disconnect' },
        );

        run { $redis->connect };
        is(\@events, ['connect'], 'initial connect');

        # Force disconnect by closing socket
        close $redis->{socket};
        $redis->{connected} = 0;

        # Next command should trigger reconnect
        my $result = run { $redis->ping };
        is($result, 'PONG', 'command succeeded after reconnect');

        # Should have connected twice (initial + reconnect)
        is(scalar(grep { $_ eq 'connect' } @events), 2, 'connected twice');

        $redis->disconnect;
    };
}

done_testing;
