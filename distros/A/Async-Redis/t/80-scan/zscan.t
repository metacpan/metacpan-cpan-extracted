# t/80-scan/zscan.t
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

    # Setup test sorted set
    run { $redis->del('zscan:zset') };
    for my $i (1..50) {
        run { $redis->zadd('zscan:zset', $i, "member:$i") };
    }

    subtest 'zscan_iter iterates all members with scores' => sub {
        my $iter = $redis->zscan_iter('zscan:zset');

        my @all_pairs;
        while (my $batch = run { $iter->next }) {
            push @all_pairs, @$batch;
        }

        # ZSCAN returns [member, score, member, score, ...]
        is(scalar @all_pairs, 100, '50 member-score pairs = 100 elements');

        # Convert to hash for verification
        my %scores;
        for (my $i = 0; $i < @all_pairs; $i += 2) {
            $scores{$all_pairs[$i]} = $all_pairs[$i + 1];
        }

        is(scalar keys %scores, 50, '50 unique members');
        is($scores{'member:1'}, '1', 'member:1 has score 1');
        is($scores{'member:50'}, '50', 'member:50 has score 50');
    };

    subtest 'zscan_iter with match pattern' => sub {
        my $iter = $redis->zscan_iter('zscan:zset', match => 'member:1*');

        my @all_pairs;
        while (my $batch = run { $iter->next }) {
            push @all_pairs, @$batch;
        }

        my %scores;
        for (my $i = 0; $i < @all_pairs; $i += 2) {
            $scores{$all_pairs[$i]} = $all_pairs[$i + 1];
        }

        # Should match member:1, member:10-19
        ok(scalar keys %scores >= 10, 'matched member:1* pattern');
    };

    # Cleanup
    run { $redis->del('zscan:zset') };
}

done_testing;
