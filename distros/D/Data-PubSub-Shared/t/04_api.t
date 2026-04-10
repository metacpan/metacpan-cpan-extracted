use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::PubSub::Shared;

# --- Int: drain ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    $ps->publish($_) for 1..10;
    my $sub = $ps->subscribe_all;
    my @got = $sub->drain;
    is scalar @got, 10, 'int drain gets all';
    is_deeply \@got, [1..10], 'int drain preserves order';
    my @empty = $sub->drain;
    is scalar @empty, 0, 'int drain returns empty after exhausted';
}

# --- Int: drain with max ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    $ps->publish($_) for 1..10;
    my $sub = $ps->subscribe_all;
    my @got = $sub->drain(5);
    is scalar @got, 5, 'int drain(5) limits count';
    is_deeply \@got, [1..5], 'int drain(5) correct values';
}

# --- Int: poll_wait_multi ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    $ps->publish($_) for 10..19;
    my $sub = $ps->subscribe_all;
    my @got = $sub->poll_wait_multi(5, 0.1);
    is scalar @got, 5, 'int poll_wait_multi returns up to N';
    is_deeply \@got, [10..14], 'int poll_wait_multi correct values';

    # timeout when empty
    my $sub2 = $ps->subscribe;
    my @empty = $sub2->poll_wait_multi(5, 0.01);
    is scalar @empty, 0, 'int poll_wait_multi returns empty on timeout';
}

# --- Int: publish_notify ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    my $fd = $ps->eventfd;
    $ps->publish_notify(42);
    $ps->eventfd_consume;
    my $sub = $ps->subscribe_all;
    is $sub->poll, 42, 'int publish_notify publishes';
    pass 'int publish_notify notifies';
}

# --- Int: overflow_count ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 4);
    my $sub = $ps->subscribe;
    is $sub->overflow_count, 0, 'int overflow_count starts at 0';
    $ps->publish($_) for 1..10;
    $sub->poll;  # triggers overflow recovery
    ok $sub->overflow_count > 0, 'int overflow_count incremented after overflow';
}

# --- Int: write_pos on sub ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    $ps->publish(1);
    my $sub = $ps->subscribe_all;
    is $sub->write_pos, 1, 'int sub write_pos matches handle';
    $ps->publish(2);
    is $sub->write_pos, 2, 'int sub write_pos updates';
}

# --- Int: publish_multi + poll_multi order parity ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 128);
    my @vals = (100, 200, 300, 400, 500);
    $ps->publish_multi(@vals);
    my $sub = $ps->subscribe_all;
    my @got = $sub->poll_multi(5);
    is_deeply \@got, \@vals, 'int publish_multi + poll_multi order parity';
}

# --- Int: batch publish_multi optimization (single fetch_add) ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 1024);
    is $ps->publish_multi(1..100), 100, 'int publish_multi(100) returns 100';
    my $sub = $ps->subscribe_all;
    my @got = $sub->drain;
    is scalar @got, 100, 'int all 100 batch-published messages readable';
    is $got[0], 1, 'int batch first correct';
    is $got[99], 100, 'int batch last correct';
}

# --- Str: drain ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 64);
    $ps->publish("msg$_") for 1..5;
    my $sub = $ps->subscribe_all;
    my @got = $sub->drain;
    is scalar @got, 5, 'str drain gets all';
    is $got[0], 'msg1', 'str drain first correct';
    is $got[-1], 'msg5', 'str drain last correct';
}

# --- Str: poll_wait_multi ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 64);
    $ps->publish("item$_") for 1..10;
    my $sub = $ps->subscribe_all;
    my @got = $sub->poll_wait_multi(3, 0.1);
    is scalar @got, 3, 'str poll_wait_multi returns up to N';
    is $got[0], 'item1', 'str poll_wait_multi first correct';
}

# --- Str: publish_notify ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 64);
    my $fd = $ps->eventfd;
    $ps->publish_notify("hello");
    $ps->eventfd_consume;
    my $sub = $ps->subscribe_all;
    is $sub->poll, 'hello', 'str publish_notify publishes';
}

# --- Str: overflow_count ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 4, 32);
    my $sub = $ps->subscribe;
    $ps->publish("msg$_") for 1..10;
    $sub->poll;
    ok $sub->overflow_count > 0, 'str overflow_count after overflow';
}

# --- Str: write_pos on sub ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 64);
    $ps->publish("a");
    my $sub = $ps->subscribe_all;
    is $sub->write_pos, 1, 'str sub write_pos';
}

# --- Int: sync + re-open data integrity ---
{
    my $path = tmpnam();
    {
        my $ps = Data::PubSub::Shared::Int->new($path, 64);
        $ps->publish($_) for 1..5;
        $ps->sync;
    }
    {
        my $ps2 = Data::PubSub::Shared::Int->new($path, 64);
        is $ps2->write_pos, 5, 'int sync+reopen preserves write_pos';
        my $sub = $ps2->subscribe_all;
        my @got = $sub->drain;
        is_deeply \@got, [1..5], 'int sync+reopen preserves data';
    }
    unlink $path;
}

# --- Str: sync + re-open ---
{
    my $path = tmpnam();
    {
        my $ps = Data::PubSub::Shared::Str->new($path, 64);
        $ps->publish("data$_") for 1..3;
        $ps->sync;
    }
    {
        my $ps2 = Data::PubSub::Shared::Str->new($path, 64);
        is $ps2->write_pos, 3, 'str sync+reopen preserves write_pos';
        my $sub = $ps2->subscribe_all;
        my @got = $sub->drain;
        is_deeply \@got, [qw(data1 data2 data3)], 'str sync+reopen preserves data';
    }
    unlink $path;
}

# --- Int: publish_multi with 0 args ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    is $ps->publish_multi(), 0, 'int publish_multi() with no args returns 0';
    is $ps->write_pos, 0, 'int publish_multi() with no args does not advance write_pos';
}

# --- Int: poll_wait_multi with count=0 ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    $ps->publish(1);
    my $sub = $ps->subscribe_all;
    my @got = $sub->poll_wait_multi(0, 0.01);
    is scalar @got, 0, 'int poll_wait_multi(0) returns empty';
}

# --- Str: poll_wait_multi with count=0 ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 64);
    $ps->publish("x");
    my $sub = $ps->subscribe_all;
    my @got = $sub->poll_wait_multi(0, 0.01);
    is scalar @got, 0, 'str poll_wait_multi(0) returns empty';
}

# --- Str: reset_oldest ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 32);
    $ps->publish("msg$_") for 1..10;
    my $sub = $ps->subscribe;
    is $sub->lag, 0, 'str sub starts with no lag';
    $sub->reset_oldest;
    ok $sub->lag > 0, 'str reset_oldest gives lag';
    my $first = $sub->poll;
    like $first, qr/^msg/, 'str reset_oldest reads oldest available';
}

# --- Str: cursor get/set ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 32);
    $ps->publish("a");
    $ps->publish("b");
    my $sub = $ps->subscribe_all;
    my $c = $sub->cursor;
    is $c, 0, 'str cursor starts at 0 for subscribe_all';
    $sub->cursor(1);
    is $sub->cursor, 1, 'str cursor setter works';
    is $sub->poll, 'b', 'str poll after cursor set reads correct msg';
}

# --- Str: publish_multi with 0 args ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 64);
    is $ps->publish_multi(), 0, 'str publish_multi() with no args returns 0';
}

done_testing;
