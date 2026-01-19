# t/60-scripting/pagi-channels.t
# Tests for PAGI::Channels use cases - realistic channel layer scenarios
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis qw(init_loop skip_without_redis run cleanup_keys);
use Test2::V0;
use Async::Redis;
use JSON::PP qw(encode_json decode_json);

my $loop = init_loop();

SKIP: {
    my $redis = skip_without_redis();

    # Define PAGI::Channels-like scripts
    my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
    run { $r->connect };

    # channel_publish: Publish message to all subscribers of a topic
    $r->define_command(channel_publish => {
        keys => 1,
        lua  => <<'LUA',
            local topic_key = KEYS[1]
            local msg = ARGV[1]
            local exclude = ARGV[2] or ""
            local capacity = tonumber(ARGV[3]) or 100
            local ttl = tonumber(ARGV[4]) or 60

            local members = redis.call('SMEMBERS', topic_key)
            local delivered = 0

            for _, channel in ipairs(members) do
                if channel ~= exclude then
                    local queue = 'queue:' .. channel
                    local len = redis.call('LLEN', queue)
                    if len < capacity then
                        redis.call('LPUSH', queue, msg)
                        redis.call('EXPIRE', queue, ttl)
                        delivered = delivered + 1
                    end
                end
            end

            return delivered
LUA
    });

    # channel_poll: Non-blocking poll for messages
    $r->define_command(channel_poll => {
        keys => 1,
        lua  => <<'LUA',
            local queue = KEYS[1]
            return redis.call('RPOP', queue)
LUA
    });

    # channel_subscribe: Add channel to topic
    $r->define_command(channel_subscribe => {
        keys => 1,
        lua  => <<'LUA',
            local topic_key = KEYS[1]
            local channel = ARGV[1]
            local expiry = tonumber(ARGV[2]) or 86400

            redis.call('SADD', topic_key, channel)
            redis.call('EXPIRE', topic_key, expiry)
            return 1
LUA
    });

    # channel_unsubscribe: Remove channel from topic
    $r->define_command(channel_unsubscribe => {
        keys => 1,
        lua  => <<'LUA',
            local topic_key = KEYS[1]
            local channel = ARGV[1]
            return redis.call('SREM', topic_key, channel)
LUA
    });

    # channel_cleanup: Remove channel and all its subscriptions
    $r->define_command(channel_cleanup => {
        keys => 'dynamic',
        lua  => <<'LUA',
            local channel = ARGV[1]
            local queue = 'queue:' .. channel

            -- Delete the queue
            redis.call('DEL', queue)

            -- Remove from all provided topic keys
            local removed = 0
            for i, topic_key in ipairs(KEYS) do
                removed = removed + redis.call('SREM', topic_key, channel)
            end

            return removed
LUA
    });

    subtest 'basic publish/subscribe flow' => sub {
        # Create two "connections"
        my $conn_a = 'conn.1234.a';
        my $conn_b = 'conn.1234.b';
        my $topic = 'topic:chat.room1';

        # Subscribe both to the topic
        run { $r->run_script('channel_subscribe', $topic, $conn_a, 86400) };
        run { $r->run_script('channel_subscribe', $topic, $conn_b, 86400) };

        # Publish a message (from conn_a, excluding self)
        my $msg = encode_json({ type => 'chat.message', text => 'Hello!' });
        my $delivered = run { $r->run_script('channel_publish', $topic, $msg, $conn_a, 100, 60) };

        is($delivered, 1, 'message delivered to 1 recipient (excluded sender)');

        # conn_b should have the message
        my $received = run { $r->run_script('channel_poll', "queue:$conn_b") };
        is(decode_json($received)->{text}, 'Hello!', 'conn_b received the message');

        # conn_a should NOT have the message
        $received = run { $r->run_script('channel_poll', "queue:$conn_a") };
        is($received, undef, 'conn_a did not receive (was excluded)');

        # Cleanup
        run { cleanup_keys($r, 'topic:*', 'queue:*') };
    };

    subtest 'publish to multiple subscribers' => sub {
        my @conns = map { "conn.multi.$_" } 1..5;
        my $topic = 'topic:chat.broadcast';

        # Subscribe all
        for my $conn (@conns) {
            run { $r->run_script('channel_subscribe', $topic, $conn) };
        }

        # Publish without exclusion
        my $msg = encode_json({ type => 'announcement', text => 'Hello all!' });
        my $delivered = run { $r->run_script('channel_publish', $topic, $msg, '', 100, 60) };

        is($delivered, 5, 'message delivered to all 5 subscribers');

        # Each should have the message
        for my $conn (@conns) {
            my $received = run { $r->run_script('channel_poll', "queue:$conn") };
            ok($received, "$conn has message");
        }

        run { cleanup_keys($r, 'topic:*', 'queue:*') };
    };

    subtest 'capacity limit' => sub {
        my $conn = 'conn.capacity.1';
        my $topic = 'topic:limited';

        run { $r->run_script('channel_subscribe', $topic, $conn) };

        # Fill queue to capacity (set capacity=5)
        for my $i (1..5) {
            my $msg = encode_json({ n => $i });
            run { $r->run_script('channel_publish', $topic, $msg, '', 5, 60) };
        }

        # Sixth message should be dropped (at capacity)
        my $msg = encode_json({ n => 6 });
        my $delivered = run { $r->run_script('channel_publish', $topic, $msg, '', 5, 60) };
        is($delivered, 0, 'message dropped when at capacity');

        # Drain one message
        run { $r->run_script('channel_poll', "queue:$conn") };

        # Now publish should work again
        $delivered = run { $r->run_script('channel_publish', $topic, $msg, '', 5, 60) };
        is($delivered, 1, 'message delivered after draining');

        run { cleanup_keys($r, 'topic:*', 'queue:*') };
    };

    subtest 'cleanup removes channel from topics' => sub {
        my $conn = 'conn.cleanup.1';
        my $topic1 = 'topic:cleanup.a';
        my $topic2 = 'topic:cleanup.b';

        # Subscribe to multiple topics
        run { $r->run_script('channel_subscribe', $topic1, $conn) };
        run { $r->run_script('channel_subscribe', $topic2, $conn) };

        # Push a message to the queue
        run { $r->lpush("queue:$conn", 'test') };

        # Cleanup
        my $removed = run { $r->run_script('channel_cleanup', 2, $topic1, $topic2, $conn) };
        is($removed, 2, 'removed from 2 topics');

        # Queue should be gone
        my $len = run { $r->llen("queue:$conn") };
        is($len, 0, 'queue deleted');

        # Should not be in topics
        my $in_t1 = run { $r->sismember($topic1, $conn) };
        my $in_t2 = run { $r->sismember($topic2, $conn) };
        is($in_t1, 0, 'removed from topic1');
        is($in_t2, 0, 'removed from topic2');

        run { cleanup_keys($r, 'topic:*', 'queue:*') };
    };

    subtest 'pipeline publish to multiple topics' => sub {
        my @conns = map { "conn.pipe.$_" } 1..3;
        my @topics = ('topic:pipe.a', 'topic:pipe.b');

        # Subscribe each conn to a topic
        run { $r->run_script('channel_subscribe', $topics[0], $conns[0]) };
        run { $r->run_script('channel_subscribe', $topics[0], $conns[1]) };
        run { $r->run_script('channel_subscribe', $topics[1], $conns[2]) };

        # Pipeline publish to both topics
        my $msg_a = encode_json({ topic => 'a' });
        my $msg_b = encode_json({ topic => 'b' });

        my $pipe = $r->pipeline;
        $pipe->run_script('channel_publish', $topics[0], $msg_a, '', 100, 60);
        $pipe->run_script('channel_publish', $topics[1], $msg_b, '', 100, 60);

        my $results = run { $pipe->execute };
        is($results, [2, 1], 'pipeline publish: 2 to topic_a, 1 to topic_b');

        run { cleanup_keys($r, 'topic:*', 'queue:*') };
    };

    $r->disconnect;
    $redis->disconnect;
}

done_testing;
