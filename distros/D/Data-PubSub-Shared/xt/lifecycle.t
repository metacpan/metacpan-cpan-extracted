use strict;
use warnings;
use Test::More;

use Data::PubSub::Shared;

# ============================================================
# 1. Rapid subscribe/destroy cycles — Int
# ============================================================
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 1024);
    $ps->publish($_) for 1..100;

    for my $round (1..5000) {
        my $sub = $ps->subscribe_all;
        my $v = $sub->poll;
        # $sub goes out of scope — DESTROY fires, owner_rv refcount decremented
    }

    # handle should still be alive and functional
    $ps->publish(999);
    my $sub = $ps->subscribe_all;
    my @got = $sub->drain;
    ok scalar @got > 0, 'int: handle alive after 5000 subscribe/destroy cycles';
    is $got[-1], 999, 'int: last published value correct';
}

# ============================================================
# 2. Rapid subscribe/destroy cycles — Str
# ============================================================
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 1024);
    $ps->publish("msg$_") for 1..100;

    for my $round (1..5000) {
        my $sub = $ps->subscribe_all;
        my $v = $sub->poll;
    }

    $ps->publish("final");
    my $sub = $ps->subscribe_all;
    my @got = $sub->drain;
    ok scalar @got > 0, 'str: handle alive after 5000 subscribe/destroy cycles';
    is $got[-1], 'final', 'str: last published value correct';
}

# ============================================================
# 3. Multiple subscribers alive simultaneously
# ============================================================
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 256);
    $ps->publish($_) for 1..50;

    my @subs;
    for (1..1000) {
        push @subs, $ps->subscribe_all;
    }

    # all 1000 should read the same data
    my $first = join(',', $subs[0]->drain);
    my $last  = join(',', $subs[-1]->drain);
    is $first, $last, '1000 simultaneous subscribers see same data';

    # drop them all at once
    @subs = ();
    pass '1000 subscribers destroyed without crash';

    # handle still works
    $ps->publish(42);
    my $s = $ps->subscribe_all;
    ok defined $s->poll, 'handle functional after mass subscriber destroy';
}

# ============================================================
# 4. Subscriber outlives explicit handle undef
# ============================================================
{
    my $sub;
    {
        my $ps = Data::PubSub::Shared::Int->new(undef, 64);
        $ps->publish(77);
        $sub = $ps->subscribe_all;
        # $ps goes out of scope here, but $sub holds a reference via owner_rv
    }
    # $sub should still work — owner_rv keeps the handle alive
    is $sub->poll, 77, 'subscriber works after handle goes out of scope';
    is $sub->lag, 0, 'subscriber lag correct after handle scope exit';
}

# ============================================================
# 5. Subscriber outlives handle — Str
# ============================================================
{
    my $sub;
    {
        my $ps = Data::PubSub::Shared::Str->new(undef, 64);
        $ps->publish("held");
        $sub = $ps->subscribe_all;
    }
    is $sub->poll, "held", 'str subscriber works after handle out of scope';
}

# ============================================================
# 6. Handle destroy then subscriber destroy — no double-free
# ============================================================
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    $ps->publish(1);
    my $sub = $ps->subscribe_all;

    # explicitly destroy handle first
    undef $ps;

    # subscriber should still work (holds reference)
    is $sub->poll, 1, 'poll works after explicit handle undef';

    # now destroy subscriber
    undef $sub;
    pass 'no crash after handle then subscriber destroy';
}

# ============================================================
# 7. poll_cb with subscriber that gets destroyed during callback
#    (edge case: callback stores subscriber in outer scope,
#     but we just verify normal callback lifecycle)
# ============================================================
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 256);
    $ps->publish($_) for 1..100;

    for (1..500) {
        my $sub = $ps->subscribe_all;
        my $count = 0;
        $sub->poll_cb(sub { $count++ });
        # $sub destroyed after each iteration
    }
    pass 'poll_cb with rapid subscriber lifecycle x500';
}

# ============================================================
# 8. drain_notify lifecycle — subscriber with eventfd
# ============================================================
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 256);
    my $fd = $ps->eventfd;

    for (1..1000) {
        my $sub = $ps->subscribe;
        $sub->eventfd_set($fd);
        $ps->publish(1);
        $ps->notify;
        my @got = $sub->drain_notify;
        # $sub destroyed each iteration, fd should not be closed
        # (subscriber does not own the fd)
    }

    # fd should still be valid
    $ps->publish(2);
    $ps->notify;
    $ps->eventfd_consume;
    pass 'eventfd survives 1000 subscriber cycles';
}

done_testing;
