# t/80-scan/match.t
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

    # Setup test keys with different patterns
    my @keys = (
        'match:user:1', 'match:user:2', 'match:user:10',
        'match:order:1', 'match:order:2',
        'match:product:a', 'match:product:b',
    );
    for my $key (@keys) {
        run { $redis->set($key, 'value') };
    }

    subtest 'SCAN MATCH with wildcard' => sub {
        my $iter = $redis->scan_iter(match => 'match:user:*');

        my @found;
        while (my $batch = run { $iter->next }) {
            push @found, @$batch;
        }

        is(scalar @found, 3, 'found 3 user keys');
        ok((grep { $_ eq 'match:user:1' } @found), 'found user:1');
        ok((grep { $_ eq 'match:user:2' } @found), 'found user:2');
        ok((grep { $_ eq 'match:user:10' } @found), 'found user:10');
    };

    subtest 'SCAN MATCH with different prefix' => sub {
        my $iter = $redis->scan_iter(match => 'match:*:1');

        my @found;
        while (my $batch = run { $iter->next }) {
            push @found, @$batch;
        }

        is(scalar @found, 2, 'found 2 keys ending in :1');
        ok((grep { $_ eq 'match:user:1' } @found), 'found user:1');
        ok((grep { $_ eq 'match:order:1' } @found), 'found order:1');
    };

    subtest 'SCAN MATCH with question mark' => sub {
        my $iter = $redis->scan_iter(match => 'match:product:?');

        my @found;
        while (my $batch = run { $iter->next }) {
            push @found, @$batch;
        }

        is(scalar @found, 2, 'found 2 product keys');
    };

    subtest 'SCAN MATCH with no matches' => sub {
        my $iter = $redis->scan_iter(match => 'match:nonexistent:*');

        my @found;
        while (my $batch = run { $iter->next }) {
            push @found, @$batch;
        }

        is(scalar @found, 0, 'found no keys');
    };

    # Cleanup
    run { $redis->del(@keys) };
}

done_testing;
