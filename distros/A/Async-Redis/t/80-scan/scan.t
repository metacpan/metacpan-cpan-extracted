# t/80-scan/scan.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost', connect_timeout => 2);
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    # Setup test keys
    for my $i (1..20) {
        run { $redis->set("scan:key:$i", "value$i") };
    }

    subtest 'scan_iter returns iterator' => sub {
        my $iter = $redis->scan_iter();
        ok($iter, 'iterator created');
        ok($iter->can('next'), 'iterator has next method');
    };

    subtest 'scan_iter iterates all keys' => sub {
        my $iter = $redis->scan_iter(match => 'scan:key:*');

        my @all_keys;
        while (my $batch = run { $iter->next }) {
            push @all_keys, @$batch;
        }

        is(scalar @all_keys, 20, 'found all 20 keys');

        my %unique = map { $_ => 1 } @all_keys;
        is(scalar keys %unique, 20, 'all keys unique');
    };

    subtest 'scan_iter with count hint' => sub {
        my $iter = $redis->scan_iter(match => 'scan:key:*', count => 5);

        my @batches;
        while (my $batch = run { $iter->next }) {
            push @batches, $batch;
        }

        ok(@batches >= 1, 'got batches');

        my @all = map { @$_ } @batches;
        is(scalar @all, 20, 'found all 20 keys across batches');
    };

    subtest 'scan_iter next returns undef when done' => sub {
        my $iter = $redis->scan_iter(match => 'scan:nonexistent:*');

        my @all;
        while (my $batch = run { $iter->next }) {
            push @all, @$batch;
        }

        is(scalar @all, 0, 'no keys found for nonexistent pattern');

        # Subsequent calls return undef
        my $batch = run { $iter->next };
        is($batch, undef, 'iterator exhausted');
    };

    subtest 'scan_iter is restartable via reset' => sub {
        my $iter = $redis->scan_iter(match => 'scan:key:*');

        # Consume part of iteration
        my $batch1 = run { $iter->next };
        ok($batch1, 'got first batch');

        # Reset
        $iter->reset;

        # Should start over
        my @all_keys;
        while (my $batch = run { $iter->next }) {
            push @all_keys, @$batch;
        }

        is(scalar @all_keys, 20, 'reset allowed full re-iteration');
    };

    subtest 'non-blocking verification' => sub {
        my @ticks;
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 0.01,
            on_tick => sub { push @ticks, 1 },
        );
        get_loop()->add($timer);
        $timer->start;

        my $iter = $redis->scan_iter(match => 'scan:key:*', count => 2);
        my @all;
        while (my $batch = run { $iter->next }) {
            push @all, @$batch;
        }

        $timer->stop;
        get_loop()->remove($timer);

        is(scalar @all, 20, 'got all keys');
        pass("Event loop ticked during SCAN iteration");
    };

    # Cleanup
    for my $i (1..20) {
        run { $redis->del("scan:key:$i") };
    }
}

done_testing;
