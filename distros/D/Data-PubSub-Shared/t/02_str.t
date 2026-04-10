use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::PubSub::Shared;

my $path = tmpnam();
END { unlink $path if $path && -e $path }

# Basic create
my $ps = Data::PubSub::Shared::Str->new($path, 64);
ok $ps, 'create str pubsub';
is $ps->capacity, 64, 'capacity';
is $ps->msg_size, 256, 'default msg_size';
is $ps->write_pos, 0, 'initial write_pos';

# Custom msg_size
{
    my $ps2 = Data::PubSub::Shared::Str->new(undef, 32, 512);
    is $ps2->msg_size, 512, 'custom msg_size';
}

# Publish and subscribe
$ps->publish("hello");
$ps->publish("world");
is $ps->write_pos, 2, 'write_pos after 2 publishes';

my $sub = $ps->subscribe_all;
is $sub->poll, 'hello', 'poll returns first message';
is $sub->poll, 'world', 'poll returns second message';
is $sub->poll, undef, 'poll returns undef when caught up';

# Empty string
$ps->publish("");
my $s = $ps->subscribe_all;
# drain to last
while ($s->lag > 1) { $s->poll }
is $s->poll, "", 'empty string preserved';

# UTF-8 preservation
{
    my $utf = Data::PubSub::Shared::Str->new(undef, 32);
    my $str = "\x{263A}";  # unicode smiley
    $utf->publish($str);
    my $sub = $utf->subscribe_all;
    my $got = $sub->poll;
    is $got, $str, 'UTF-8 content preserved';
    ok utf8::is_utf8($got), 'UTF-8 flag preserved';
}

# publish_multi
{
    my $ps2 = Data::PubSub::Shared::Str->new(undef, 32);
    is $ps2->publish_multi("a", "b", "c"), 3, 'publish_multi returns count';
    my $sub = $ps2->subscribe_all;
    my @got = $sub->poll_multi(10);
    is_deeply \@got, [qw(a b c)], 'poll_multi gets all messages';
}

# Message too long
{
    my $ps2 = Data::PubSub::Shared::Str->new(undef, 32, 8);
    eval { $ps2->publish("x" x 100) };
    like $@, qr/too long/, 'publish croaks on oversized message';
}

# Multiple subscribers
{
    my $ps2 = Data::PubSub::Shared::Str->new(undef, 32);
    $ps2->publish("broadcast");
    my $s1 = $ps2->subscribe_all;
    my $s2 = $ps2->subscribe_all;
    is $s1->poll, 'broadcast', 'subscriber 1 gets message';
    is $s2->poll, 'broadcast', 'subscriber 2 gets same message';
}

# Overflow recovery
{
    my $small = Data::PubSub::Shared::Str->new(undef, 4, 32);
    my $sub = $small->subscribe;
    $small->publish("msg$_") for 1..10;
    ok $sub->has_overflow, 'overflow detected';
    my $v = $sub->poll;
    ok defined $v, 'poll recovers from overflow';
    like $v, qr/^msg/, 'recovered value is valid';
}

# Reset
{
    my $ps2 = Data::PubSub::Shared::Str->new(undef, 32);
    $ps2->publish("old");
    my $sub = $ps2->subscribe_all;
    $sub->reset;
    is $sub->lag, 0, 'reset skips to latest';
    $ps2->publish("new");
    is $sub->poll, 'new', 'only see new messages after reset';
}

# poll_wait with timeout
{
    my $ps2 = Data::PubSub::Shared::Str->new(undef, 32);
    my $sub = $ps2->subscribe;
    my $val = $sub->poll_wait(0.01);
    is $val, undef, 'poll_wait times out';
}

# Stats
{
    my $stats = $ps->stats;
    ok $stats->{publish_ok} > 0, 'stats has publish_ok';
    is $stats->{msg_size}, 256, 'stats has msg_size';
}

# memfd
{
    my $mf = Data::PubSub::Shared::Str->new_memfd('test_str', 32);
    ok $mf, 'memfd str pubsub';
    $mf->publish("via_memfd");
    my $fd = $mf->memfd;
    my $mf2 = Data::PubSub::Shared::Str->new_from_fd($fd);
    my $sub = $mf2->subscribe_all;
    is $sub->poll, 'via_memfd', 'memfd str data shared';
}

# eventfd
{
    my $ps2 = Data::PubSub::Shared::Str->new(undef, 32);
    my $fd = $ps2->eventfd;
    ok $fd >= 0, 'eventfd created';
    $ps2->publish("ev");
    $ps2->notify;
    $ps2->eventfd_consume;
    pass 'str eventfd cycle';
}

# Variable-length messages (short messages don't waste arena space)
{
    my $ps2 = Data::PubSub::Shared::Str->new(undef, 64, 1024);
    # Mix of very different lengths
    $ps2->publish("x");
    $ps2->publish("y" x 500);
    $ps2->publish("z" x 1024);
    $ps2->publish("");
    $ps2->publish("short");
    my $sub = $ps2->subscribe_all;
    is $sub->poll, "x", 'variable-length: 1-byte message';
    is $sub->poll, "y" x 500, 'variable-length: 500-byte message';
    is $sub->poll, "z" x 1024, 'variable-length: max-size message';
    is $sub->poll, "", 'variable-length: empty message';
    is $sub->poll, "short", 'variable-length: short message';
}

# Exact msg_size boundary
{
    my $ps2 = Data::PubSub::Shared::Str->new(undef, 16, 64);
    $ps2->publish("a" x 64);
    my $sub = $ps2->subscribe_all;
    is $sub->poll, "a" x 64, 'exact msg_size message works';
    eval { $ps2->publish("b" x 65) };
    like $@, qr/too long/, 'msg_size+1 croaks';
}

# Arena wrapping (many messages cause arena to wrap)
{
    my $ps2 = Data::PubSub::Shared::Str->new(undef, 8, 32);
    my @msgs;
    for my $i (1..20) {
        my $msg = "msg-$i-" . ("x" x ($i % 15));
        $ps2->publish($msg);
        push @msgs, $msg;
    }
    my $sub = $ps2->subscribe_all;
    my @got;
    while (defined(my $v = $sub->poll)) { push @got, $v }
    # Should get the last 8 (capacity) messages
    ok scalar @got <= 8, 'arena wrap: at most capacity messages';
    ok scalar @got >= 1, 'arena wrap: got at least one message';
    is $got[-1], $msgs[-1], 'arena wrap: last message correct';
    my @bad = grep { $_ !~ /^msg-\d+-x*$/ } @got;
    ok !@bad, 'arena wrap: all recovered messages well-formed';
}

# has_overflow false when cursor ahead of write_pos
{
    my $ps2 = Data::PubSub::Shared::Str->new(undef, 32);
    my $sub = $ps2->subscribe;
    $sub->cursor(999);
    ok !$sub->has_overflow, 'has_overflow false when cursor > write_pos';
}

# Stats arena_cap
{
    my $ps2 = Data::PubSub::Shared::Str->new(undef, 32, 128);
    my $stats = $ps2->stats;
    ok $stats->{arena_cap} > 0, 'stats has arena_cap';
}

# Sync and unlink
{
    my $tmp = tmpnam();
    my $ps2 = Data::PubSub::Shared::Str->new($tmp, 32);
    $ps2->sync;
    $ps2->unlink;
    ok !-e $tmp, 'unlink removes file';
}

done_testing;
