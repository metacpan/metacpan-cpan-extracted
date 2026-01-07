# t/50-pubsub/unsubscribe.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;
use Future;

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    subtest 'subscription tracks channels for replay' => sub {
        my $subscriber = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $subscriber->connect };

        my $sub = run { $subscriber->subscribe('chan:a', 'chan:b') };
        run { $subscriber->psubscribe('pattern:*') };

        my @replay = $sub->get_replay_commands;

        is(scalar @replay, 2, 'two replay commands');

        my ($sub_cmd) = grep { $_->[0] eq 'SUBSCRIBE' } @replay;
        my ($psub_cmd) = grep { $_->[0] eq 'PSUBSCRIBE' } @replay;

        ok($sub_cmd, 'has SUBSCRIBE command');
        ok($psub_cmd, 'has PSUBSCRIBE command');
        is([sort @{$sub_cmd}[1..$#$sub_cmd]], ['chan:a', 'chan:b'], 'SUBSCRIBE channels');
        is($psub_cmd, ['PSUBSCRIBE', 'pattern:*'], 'PSUBSCRIBE pattern');

        $subscriber->disconnect;
    };

    subtest 'channel count includes all types' => sub {
        my $subscriber = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $subscriber->connect };

        my $sub = run { $subscriber->subscribe('regular:chan') };
        is($sub->channel_count, 1, 'one channel');

        run { $subscriber->psubscribe('pat:*') };
        is($sub->channel_count, 2, 'two after pattern added');

        $subscriber->disconnect;
    };

    $redis->disconnect;
}

done_testing;
