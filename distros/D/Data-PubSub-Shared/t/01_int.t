use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::PubSub::Shared;

my $path = tmpnam();
END { unlink $path if $path && -e $path }

# Basic create
my $ps = Data::PubSub::Shared::Int->new($path, 64);
ok $ps, 'create int pubsub';
is $ps->capacity, 64, 'capacity rounded to power of 2';
is $ps->write_pos, 0, 'initial write_pos is 0';
ok $ps->path, 'has path';

# Publish
ok $ps->publish(42), 'publish returns true';
is $ps->write_pos, 1, 'write_pos incremented';

# Publish multi
is $ps->publish_multi(1, 2, 3), 3, 'publish_multi returns count';
is $ps->write_pos, 4, 'write_pos after publish_multi';

# Subscribe (from current position)
my $sub = $ps->subscribe;
ok $sub, 'subscribe returns subscriber';
isa_ok $sub, 'Data::PubSub::Shared::Int::Sub';
is $sub->cursor, 4, 'subscriber starts at current write_pos';
is $sub->lag, 0, 'no lag initially';

# Poll empty
is $sub->poll, undef, 'poll returns undef when empty';

# Publish then poll
$ps->publish(100);
is $sub->lag, 1, 'lag is 1 after publish';
is $sub->poll, 100, 'poll returns published value';
is $sub->lag, 0, 'lag back to 0';
is $sub->cursor, 5, 'cursor advanced';

# Subscribe all (from oldest)
$ps->publish(200);
my $sub_all = $ps->subscribe_all;
ok $sub_all->lag > 0, 'subscribe_all has lag';
my @vals;
while (defined(my $v = $sub_all->poll)) { push @vals, $v }
ok scalar @vals >= 1, 'subscribe_all gets historical messages';
is $vals[-1], 200, 'last message is 200';

# Multiple subscribers
$ps->publish(300);
my $s1 = $ps->subscribe_all;
my $s2 = $ps->subscribe_all;
my $v1 = $s1->poll;
my $v2 = $s2->poll;
is $v1, $v2, 'multiple subscribers see same message';

# poll_multi
$ps->publish($_) for 10..19;
my $sub3 = $ps->subscribe_all;
# drain to near end
while ($sub3->lag > 10) { $sub3->poll }
my @batch = $sub3->poll_multi(5);
is scalar @batch, 5, 'poll_multi returns requested count';

# Overflow detection
{
    my $small = Data::PubSub::Shared::Int->new(undef, 4);
    my $sub = $small->subscribe;
    $small->publish($_) for 1..10;
    # subscriber is behind by 10, capacity is 4 -> overflow
    ok $sub->has_overflow, 'has_overflow detects overflow';
    # poll should auto-recover
    my $v = $sub->poll;
    ok defined $v, 'poll returns value after overflow recovery';
}

# Reset
{
    my $sub = $ps->subscribe_all;
    ok $sub->lag > 0, 'has lag before reset';
    $sub->reset;
    is $sub->lag, 0, 'lag is 0 after reset';
}

# Reset oldest
{
    my $sub = $ps->subscribe;
    is $sub->lag, 0, 'starts with no lag';
    $sub->reset_oldest;
    ok $sub->lag > 0, 'has lag after reset_oldest';
}

# Cursor get/set
{
    my $sub = $ps->subscribe;
    my $c = $sub->cursor;
    $sub->cursor($c - 1);
    is $sub->cursor, $c - 1, 'cursor set works';
}

# Stats
{
    my $stats = $ps->stats;
    ok $stats->{publish_ok} > 0, 'stats has publish_ok';
    ok $stats->{capacity} > 0, 'stats has capacity';
    ok exists $stats->{write_pos}, 'stats has write_pos';
}

# Anonymous pubsub
{
    my $anon = Data::PubSub::Shared::Int->new(undef, 32);
    ok $anon, 'anonymous pubsub created';
    is $anon->path, undef, 'anonymous has no path';
    $anon->publish(77);
    my $sub = $anon->subscribe_all;
    is $sub->poll, 77, 'anonymous pubsub works';
}

# memfd
{
    my $mf = Data::PubSub::Shared::Int->new_memfd('test', 32);
    ok $mf, 'memfd pubsub created';
    my $fd = $mf->memfd;
    ok $fd >= 0, 'memfd returns valid fd';
    $mf->publish(55);

    my $mf2 = Data::PubSub::Shared::Int->new_from_fd($fd);
    ok $mf2, 'opened from fd';
    my $sub = $mf2->subscribe_all;
    is $sub->poll, 55, 'memfd pubsub data shared';
}

# eventfd
{
    my $ps2 = Data::PubSub::Shared::Int->new(undef, 32);
    my $fd = $ps2->eventfd;
    ok $fd >= 0, 'eventfd created';
    is $ps2->fileno, $fd, 'fileno returns eventfd';
    $ps2->publish(1);
    $ps2->notify;
    $ps2->eventfd_consume;
    pass 'eventfd notify/consume cycle';
}

# has_overflow false when cursor ahead of write_pos
{
    my $ps2 = Data::PubSub::Shared::Int->new(undef, 32);
    my $sub = $ps2->subscribe;
    $sub->cursor(999);
    ok !$sub->has_overflow, 'has_overflow false when cursor > write_pos';
}

# poll_wait with timeout
{
    my $ps2 = Data::PubSub::Shared::Int->new(undef, 32);
    my $sub = $ps2->subscribe;
    my $val = $sub->poll_wait(0.01);
    is $val, undef, 'poll_wait with short timeout returns undef';
}

# Sync and unlink
{
    my $tmp = tmpnam();
    my $ps2 = Data::PubSub::Shared::Int->new($tmp, 32);
    $ps2->sync;
    pass 'sync works';
    $ps2->unlink;
    ok !-e $tmp, 'unlink removes file';
}

done_testing;
