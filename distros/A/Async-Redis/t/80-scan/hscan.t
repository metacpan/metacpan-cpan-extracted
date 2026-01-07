# t/80-scan/hscan.t
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

    # Setup test hash
    run { $redis->del('hscan:hash') };
    for my $i (1..50) {
        run { $redis->hset('hscan:hash', "field:$i", "value$i") };
    }

    subtest 'hscan_iter iterates all fields' => sub {
        my $iter = $redis->hscan_iter('hscan:hash');

        my @all_pairs;
        while (my $batch = run { $iter->next }) {
            push @all_pairs, @$batch;
        }

        # HSCAN returns [field, value, field, value, ...]
        is(scalar @all_pairs, 100, '50 field-value pairs = 100 elements');

        my %hash = @all_pairs;
        is(scalar keys %hash, 50, '50 unique fields');
        is($hash{'field:1'}, 'value1', 'first field correct');
        is($hash{'field:50'}, 'value50', 'last field correct');
    };

    subtest 'hscan_iter with match pattern' => sub {
        my $iter = $redis->hscan_iter('hscan:hash', match => 'field:1*');

        my @all_pairs;
        while (my $batch = run { $iter->next }) {
            push @all_pairs, @$batch;
        }

        my %hash = @all_pairs;
        # Should match field:1, field:10-19
        ok(scalar keys %hash >= 10, 'matched field:1* pattern');
        ok(exists $hash{'field:1'}, 'field:1 matched');
        ok(exists $hash{'field:10'}, 'field:10 matched');
    };

    subtest 'hscan_iter with count hint' => sub {
        my $iter = $redis->hscan_iter('hscan:hash', count => 10);

        my @batches;
        while (my $batch = run { $iter->next }) {
            push @batches, $batch;
        }

        ok(@batches >= 1, 'got batches');

        my @all = map { @$_ } @batches;
        is(scalar @all, 100, 'found all field-value pairs');
    };

    # Cleanup
    run { $redis->del('hscan:hash') };
}

done_testing;
