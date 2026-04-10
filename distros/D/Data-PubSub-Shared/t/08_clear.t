use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::PubSub::Shared;

# --- Int: clear ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    $ps->publish($_) for 1..10;
    is $ps->write_pos, 10, 'int write_pos before clear';

    $ps->clear;
    is $ps->write_pos, 0, 'int write_pos reset after clear';

    # Publish after clear works
    $ps->publish(42);
    is $ps->write_pos, 1, 'int publish works after clear';
    my $sub = $ps->subscribe_all;
    is $sub->poll, 42, 'int poll after clear returns new value';
}

# --- Int: clear with existing subscriber ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    $ps->publish($_) for 1..5;
    my $sub = $ps->subscribe_all;
    is $sub->poll, 1, 'int poll before clear';

    $ps->clear;

    # Subscriber's cursor is now ahead of write_pos (0)
    # poll should return undef (nothing new)
    is $sub->poll, undef, 'int poll returns undef after clear';

    # Subscriber can reset and see new messages
    $ps->publish(99);
    $sub->reset_oldest;
    is $sub->poll, 99, 'int subscriber reset_oldest after clear works';
}

# --- Str: clear ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 64);
    $ps->publish("msg$_") for 1..5;
    is $ps->write_pos, 5, 'str write_pos before clear';

    $ps->clear;
    is $ps->write_pos, 0, 'str write_pos reset after clear';

    $ps->publish("after_clear");
    my $sub = $ps->subscribe_all;
    is $sub->poll, 'after_clear', 'str poll after clear returns new value';
}

# --- Str: clear resets arena ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 16, 32);
    # Fill arena with data
    $ps->publish("x" x 30) for 1..16;

    $ps->clear;

    # After clear, arena should be reset — can publish again
    $ps->publish("fresh");
    my $sub = $ps->subscribe_all;
    is $sub->poll, 'fresh', 'str arena works after clear';
}

# --- Int: clear with file-backed, re-open ---
{
    my $path = tmpnam();
    {
        my $ps = Data::PubSub::Shared::Int->new($path, 64);
        $ps->publish($_) for 1..10;
        $ps->clear;
        $ps->publish(42);
        $ps->sync;
    }
    {
        my $ps2 = Data::PubSub::Shared::Int->new($path, 64);
        is $ps2->write_pos, 1, 'int clear+sync persists via file';
        my $sub = $ps2->subscribe_all;
        is $sub->poll, 42, 'int clear+sync+reopen data correct';
    }
    unlink $path;
}

# --- Stats reset after clear ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    $ps->publish($_) for 1..10;
    my $s1 = $ps->stats;
    ok $s1->{publish_ok} > 0, 'stats publish_ok > 0 before clear';

    $ps->clear;
    my $s2 = $ps->stats;
    is $s2->{publish_ok}, 0, 'stats publish_ok reset after clear';
    is $s2->{write_pos}, 0, 'stats write_pos reset after clear';
}

done_testing;
