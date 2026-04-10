use strict;
use warnings;
use Test::More;

use Data::PubSub::Shared;

# --- Int: poll_cb ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    $ps->publish($_) for 1..5;
    my $sub = $ps->subscribe_all;
    my @got;
    my $n = $sub->poll_cb(sub { push @got, $_[0] });
    is $n, 5, 'int poll_cb returns count';
    is_deeply \@got, [1..5], 'int poll_cb delivers all messages in order';

    # poll_cb on empty returns 0
    is $sub->poll_cb(sub { die "should not fire" }), 0, 'int poll_cb on empty returns 0';
}

# --- Str: poll_cb ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 64);
    $ps->publish("msg$_") for 1..3;
    my $sub = $ps->subscribe_all;
    my @got;
    my $n = $sub->poll_cb(sub { push @got, $_[0] });
    is $n, 3, 'str poll_cb returns count';
    is_deeply \@got, [qw(msg1 msg2 msg3)], 'str poll_cb delivers all messages';
}

# --- Str: poll_cb preserves UTF-8 ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 32);
    my $str = "\x{263A}";
    $ps->publish($str);
    my $sub = $ps->subscribe_all;
    my @got;
    $sub->poll_cb(sub { push @got, $_[0] });
    is $got[0], $str, 'str poll_cb preserves UTF-8 content';
    ok utf8::is_utf8($got[0]), 'str poll_cb preserves UTF-8 flag';
}

# --- Int: drain_notify ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    my $fd = $ps->eventfd;
    my $sub = $ps->subscribe;

    $ps->publish(10);
    $ps->publish(20);
    $ps->notify;

    my @got = $sub->drain_notify;
    is_deeply \@got, [10, 20], 'int drain_notify returns messages';
}

# --- Str: drain_notify ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 64);
    my $fd = $ps->eventfd;
    my $sub = $ps->subscribe;

    $ps->publish("hello");
    $ps->notify;

    my @got = $sub->drain_notify;
    is_deeply \@got, ["hello"], 'str drain_notify returns messages';
}

# --- drain_notify with max ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    my $fd = $ps->eventfd;
    my $sub = $ps->subscribe;

    $ps->publish($_) for 1..10;
    $ps->notify;

    my @got = $sub->drain_notify(3);
    is scalar @got, 3, 'int drain_notify(3) limits count';
    is_deeply \@got, [1, 2, 3], 'int drain_notify(3) correct values';
}

# --- Sub: eventfd_set / fileno ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    my $sub = $ps->subscribe;
    is $sub->fileno, -1, 'sub fileno is -1 before eventfd';

    my $fd = $ps->eventfd;
    # New subscriber after eventfd inherits the fd
    my $sub2 = $ps->subscribe;
    is $sub2->fileno, $fd, 'sub created after eventfd inherits fd';

    # Manually set on existing subscriber
    $sub->eventfd_set($fd);
    is $sub->fileno, $fd, 'sub eventfd_set works';
}

# --- Str: eventfd_set / fileno ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 64);
    my $fd = $ps->eventfd;
    my $sub = $ps->subscribe;
    is $sub->fileno, $fd, 'str sub inherits eventfd';
}

# --- Str: publish_multi batch (single mutex hold) ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 64);
    is $ps->publish_multi("a", "bb", "ccc"), 3, 'str publish_multi batch returns 3';
    my $sub = $ps->subscribe_all;
    my @got = $sub->drain;
    is_deeply \@got, [qw(a bb ccc)], 'str publish_multi batch messages correct';
}

# --- Str: publish_multi batch with variable-length messages ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 64, 1024);
    my @msgs = ("x", "y" x 500, "z" x 1024, "", "short");
    is $ps->publish_multi(@msgs), 5, 'str publish_multi variable-length returns 5';
    my $sub = $ps->subscribe_all;
    my @got = $sub->drain;
    is_deeply \@got, \@msgs, 'str publish_multi variable-length correct';
}

# --- Str: publish_multi batch error handling ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 32, 8);
    eval { $ps->publish_multi("ok", "x" x 100) };
    like $@, qr/too long/, 'str publish_multi croaks on oversized msg';
    # First message should have been published before the croak
    is $ps->write_pos, 1, 'str publish_multi published msgs before error';
}

# --- Int: poll_cb with large batch ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 1024);
    $ps->publish_multi(1..100);
    my $sub = $ps->subscribe_all;
    my $count = 0;
    $sub->poll_cb(sub { $count++ });
    is $count, 100, 'int poll_cb handles 100 messages';
}

# --- drain_notify on empty ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    my $fd = $ps->eventfd;
    my $sub = $ps->subscribe;
    my @got = $sub->drain_notify;
    is scalar @got, 0, 'drain_notify on empty returns empty';
}

done_testing;
