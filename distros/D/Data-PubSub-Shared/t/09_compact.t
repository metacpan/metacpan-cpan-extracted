use strict;
use warnings;
use Test::More;

use Data::PubSub::Shared;

for my $cfg (
    ['Int32', 'Data::PubSub::Shared::Int32', -2_000_000_000, 2_000_000_000],
    ['Int16', 'Data::PubSub::Shared::Int16', -30000, 30000],
) {
    my ($label, $class, $min, $max) = @$cfg;
    my $sub_class = "${class}::Sub";

    # Basic create
    my $ps = $class->new(undef, 64);
    ok $ps, "$label: create";
    is $ps->capacity, 64, "$label: capacity";
    is $ps->write_pos, 0, "$label: initial write_pos";

    # Publish + subscribe
    $ps->publish($min);
    $ps->publish(0);
    $ps->publish($max);
    is $ps->write_pos, 3, "$label: write_pos after 3 publishes";

    my $sub = $ps->subscribe_all;
    isa_ok $sub, $sub_class;
    is $sub->poll, $min, "$label: poll min value";
    is $sub->poll, 0, "$label: poll zero";
    is $sub->poll, $max, "$label: poll max value";
    is $sub->poll, undef, "$label: poll empty";

    # publish_multi
    $ps->publish_multi(1, 2, 3);
    my $sub2 = $ps->subscribe_all;
    my @got = $sub2->poll_multi(10);
    is $got[-3], 1, "$label: publish_multi first";
    is $got[-1], 3, "$label: publish_multi last";

    # drain
    $ps->publish(10);
    $ps->publish(20);
    my $sub3 = $ps->subscribe_all;
    my @all = $sub3->drain;
    ok scalar @all > 0, "$label: drain returns messages";
    is $all[-1], 20, "$label: drain last value";

    # lag + overflow
    {
        my $small = $class->new(undef, 4);
        my $s = $small->subscribe;
        $small->publish($_) for 1..10;
        ok $s->has_overflow, "$label: overflow detected";
        my $v = $s->poll;
        ok defined $v, "$label: poll after overflow";
        ok $s->overflow_count > 0, "$label: overflow_count > 0";
    }

    # poll_cb
    {
        my $ps2 = $class->new(undef, 64);
        $ps2->publish($_) for 1..5;
        my $s = $ps2->subscribe_all;
        my @cb_got;
        my $n = $s->poll_cb(sub { push @cb_got, $_[0] });
        is $n, 5, "$label: poll_cb count";
        is_deeply \@cb_got, [1..5], "$label: poll_cb values";
    }

    # poll_wait with timeout
    {
        my $ps2 = $class->new(undef, 64);
        my $s = $ps2->subscribe;
        is $s->poll_wait(0.01), undef, "$label: poll_wait timeout";
    }

    # poll_wait_multi
    {
        my $ps2 = $class->new(undef, 64);
        $ps2->publish($_) for 10..14;
        my $s = $ps2->subscribe_all;
        my @v = $s->poll_wait_multi(3, 0.1);
        is scalar @v, 3, "$label: poll_wait_multi count";
        is_deeply \@v, [10, 11, 12], "$label: poll_wait_multi values";
    }

    # reset / reset_oldest / cursor
    {
        my $ps2 = $class->new(undef, 64);
        $ps2->publish($_) for 1..10;
        my $s = $ps2->subscribe;
        $s->reset_oldest;
        ok $s->lag > 0, "$label: reset_oldest gives lag";
        $s->reset;
        is $s->lag, 0, "$label: reset clears lag";
        is $s->cursor, $ps2->write_pos, "$label: cursor matches write_pos";
    }

    # stats
    {
        my $st = $ps->stats;
        ok $st->{publish_ok} > 0, "$label: stats publish_ok";
        ok $st->{capacity} > 0, "$label: stats capacity";
    }

    # memfd
    {
        my $mf = $class->new_memfd("test_$label", 32);
        ok $mf, "$label: memfd created";
        $mf->publish(55);
        my $fd = $mf->memfd;
        my $mf2 = $class->new_from_fd($fd);
        my $s = $mf2->subscribe_all;
        is $s->poll, 55, "$label: memfd data shared";
    }

    # clear
    {
        my $ps2 = $class->new(undef, 64);
        $ps2->publish($_) for 1..10;
        $ps2->clear;
        is $ps2->write_pos, 0, "$label: clear resets write_pos";
    }

    # Slot size check (8 bytes for compact vs 16 for Int)
    {
        my $compact = $class->new(undef, 1024);
        my $int64   = Data::PubSub::Shared::Int->new(undef, 1024);
        ok $compact->stats->{mmap_size} < $int64->stats->{mmap_size},
            "$label: smaller mmap than Int64";
    }
}

# Value truncation (C cast semantics)
{
    my $ps16 = Data::PubSub::Shared::Int16->new(undef, 64);
    $ps16->publish(32767);
    $ps16->publish(-32768);
    my $sub = $ps16->subscribe_all;
    is $sub->poll, 32767, 'int16: max positive';
    is $sub->poll, -32768, 'int16: min negative';
}

{
    my $ps32 = Data::PubSub::Shared::Int32->new(undef, 64);
    $ps32->publish(2147483647);
    $ps32->publish(-2147483648);
    my $sub = $ps32->subscribe_all;
    is $sub->poll, 2147483647, 'int32: max positive';
    is $sub->poll, -2147483648, 'int32: min negative';
}

# Mode mismatch: open Int file as Int32, and vice versa
{
    use File::Temp 'tmpnam';

    my $path = tmpnam();
    my $ps = Data::PubSub::Shared::Int->new($path, 64);
    $ps->publish(1);
    $ps->sync;

    eval { Data::PubSub::Shared::Int32->new($path, 64) };
    like $@, qr/invalid|incompatible/, 'int32: opening Int file as Int32 croaks';

    eval { Data::PubSub::Shared::Str->new($path, 64) };
    like $@, qr/invalid|incompatible/, 'str: opening Int file as Str croaks';

    unlink $path;
}

{
    use File::Temp 'tmpnam';

    my $path = tmpnam();
    my $ps = Data::PubSub::Shared::Int32->new($path, 64);
    $ps->publish(1);
    $ps->sync;

    eval { Data::PubSub::Shared::Int->new($path, 64) };
    like $@, qr/invalid|incompatible/, 'int: opening Int32 file as Int croaks';

    eval { Data::PubSub::Shared::Int16->new($path, 64) };
    like $@, qr/invalid|incompatible/, 'int16: opening Int32 file as Int16 croaks';

    unlink $path;
}

done_testing;
