use strict;
use warnings;
use Test2::V0;
use Scalar::Util qw(refaddr);
use Future::AsyncAwait;
use Async::Redis;
use Async::Redis::Error::Connection;

plan skip_all => 'REDIS_HOST not set' unless $ENV{REDIS_HOST};

sub new_redis { Async::Redis->new(host => $ENV{REDIS_HOST}, port => $ENV{REDIS_PORT} // 6379) }

subtest 'subscribe/unsubscribe_all/subscribe returns a fresh subscription object' => sub {
    (async sub {
        my $r = new_redis();
        await $r->connect;
        my $sub1 = await $r->subscribe('ch-life-a');

        # Trigger _close by unsubscribing all channels. If no
        # unsubscribe_all method exists, use unsubscribe with the channel name.
        if ($sub1->can('unsubscribe_all')) {
            await $sub1->unsubscribe_all;
        } else {
            await $sub1->unsubscribe('ch-life-a');
        }

        my $sub2 = await $r->subscribe('ch-life-a');
        isnt refaddr($sub2), refaddr($sub1),
            'fresh subscription object after close';
        $sub2->_close;
        $r->disconnect;
    })->()->get;
};

subtest 'next() on a _close-d subscription returns undef' => sub {
    (async sub {
        my $r = new_redis();
        await $r->connect;
        my $sub = await $r->subscribe('ch-close-test');
        $sub->_close;
        my $result = await $sub->next;
        is $result, undef, 'next returns undef after _close';
        $r->disconnect;
    })->()->get;
};

subtest 'next() on a _fail_fatal-ed subscription fails with typed error' => sub {
    (async sub {
        my $r = new_redis();
        await $r->connect;
        my $sub = await $r->subscribe('ch-fatal-test');
        my $err = Async::Redis::Error::Connection->new(
            message => 'test fatal', host => 'x', port => 0,
        );
        $sub->_fail_fatal($err);
        my $ok = eval { await $sub->next; 1 };
        ok !$ok, 'next died';
        isa_ok $@, ['Async::Redis::Error::Connection'],
            'carries typed error';
        $r->disconnect;
    })->()->get;
};

subtest 'identity guard: stale _close does not clear a newer subscription' => sub {
    (async sub {
        my $r = new_redis();
        await $r->connect;

        my $sub1 = await $r->subscribe('ch-id-test');
        $sub1->_close;
        is $r->{_subscription}, undef, 'slot cleared by first close';

        my $sub2 = await $r->subscribe('ch-id-test');
        # Try to _close the stale $sub1 again. Must NOT clear $sub2's slot.
        $sub1->_close;
        is refaddr($r->{_subscription}), refaddr($sub2),
            'identity guard preserved newer subscription';
        $sub2->_close;
        $r->disconnect;
    })->()->get;
};

done_testing;
