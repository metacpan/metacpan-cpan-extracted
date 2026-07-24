use strict;
use warnings;
use Test::More;
use Data::HierTimingWheel::Shared;

# constructor + introspection
{
    my $tw = Data::HierTimingWheel::Shared->new(undef, 16, 3, 100);
    isa_ok $tw, 'Data::HierTimingWheel::Shared';
    is $tw->num_slots, 16, 'num_slots';
    is $tw->num_levels, 3, 'num_levels';
    is $tw->max_delay, 16 ** 3 - 1, 'max_delay == S**L - 1';
    is $tw->capacity, 100, 'capacity';
    is $tw->now, 0, 'fresh: now 0';
    is $tw->count, 0, 'fresh: no timers';
    is_deeply [$tw->advance(1)], [], 'advancing an empty wheel fires nothing';
    is $tw->now, 1, 'advance moves the clock';
}

# THE ORACLE: a timer fires exactly `delay` ticks after scheduling, across delays
# that span every level and force cascades.  Tiny wheel (S=4, L=3, max 63) so the
# 63-delay timer drops through all three levels.
{
    my $S = 4;
    my $tw = Data::HierTimingWheel::Shared->new(undef, $S, 3, 1000);
    my %expect;   # payload -> the tick it must fire on (== its delay)
    my $p = 1;
    for my $delay (1, 2, 3, 4, 5, 7, 8, 15, 16, 17, 31, 32, 48, 63) {
        $tw->add($delay, $p);
        $expect{$p} = $delay;
        $p++;
    }
    is $tw->count, scalar(keys %expect), 'all timers pending';

    my %got;
    for my $t (1 .. 70) { $got{$_} = $t for $tw->advance(1) }
    my $bad = 0;
    for my $pl (keys %expect) { $bad++ if ($got{$pl} // -1) != $expect{$pl} }
    is $bad, 0, 'every timer fires on exactly its delay tick (S=4, L=3, all levels + cascades)';
    is $tw->count, 0, 'all timers fired';
    is $tw->now, 70, 'clock advanced 70 ticks';
}

# a second oracle at a wider geometry (S=8, L=3, max 511), delays landing in
# level 2 and cascading down through levels 1 and 0
{
    my $tw = Data::HierTimingWheel::Shared->new(undef, 8, 3, 1000);
    my %expect;
    my $p = 1;
    for my $delay (1, 8, 9, 63, 64, 65, 100, 200, 511) { $tw->add($delay, $p); $expect{$p} = $delay; $p++ }
    my %got;
    for my $t (1 .. 511) { $got{$_} = $t for $tw->advance(1) }
    my $bad = 0;
    for my $pl (keys %expect) { $bad++ if ($got{$pl} // -1) != $expect{$pl} }
    is $bad, 0, 'exact timing for delays up to 511 across 3 levels';
}

# delay < 1 is treated as 1
{
    my $tw = Data::HierTimingWheel::Shared->new(undef, 8, 2, 10);
    $tw->add(0, 42);
    is_deeply [$tw->advance(1)], [42], 'delay 0 fires on the next tick';
}

# advance by many ticks returns everything due, in tick order
{
    my $tw = Data::HierTimingWheel::Shared->new(undef, 4, 3, 100);
    $tw->add(1, 10);
    $tw->add(2, 20);
    $tw->add(3, 30);
    $tw->add(20, 200);
    my @due = $tw->advance(3);
    is_deeply [sort { $a <=> $b } @due], [10, 20, 30], 'advance(3) fires the first three';
    is $tw->count, 1, 'the 20-tick timer is still pending (in a higher level)';
    my @later;
    push @later, $tw->advance(1) for 1 .. 17;   # reach tick 20
    is_deeply \@later, [200], 'the far timer fires at exactly tick 20 after cascading down';
}

# schedule alias
{
    my $tw = Data::HierTimingWheel::Shared->new(undef, 16, 2, 10);
    $tw->schedule(2, 7);
    $tw->advance(1);
    is_deeply [$tw->advance(1)], [7], 'schedule is an alias for add';
}

# cancel (including a timer parked in a higher level)
{
    my $tw = Data::HierTimingWheel::Shared->new(undef, 4, 3, 100);
    my $a = $tw->add(40, 111);   # lands in a high level
    my $b = $tw->add(40, 222);
    is $tw->count, 2, 'two timers pending';
    is $tw->cancel($a), 1, 'cancel a high-level timer returns 1';
    is $tw->count, 1, 'count drops after cancel';
    is $tw->cancel($a), 0, 're-cancelling returns 0';
    is $tw->cancel(99999), 0, 'cancelling an invalid id returns 0';
    my @fired;
    push @fired, $tw->advance(1) for 1 .. 40;
    is_deeply \@fired, [222], 'only the surviving timer fires, at its tick';
}

# a fired timer id is no longer cancellable
{
    my $tw = Data::HierTimingWheel::Shared->new(undef, 8, 2, 10);
    my $id = $tw->add(1, 5);
    $tw->advance(1);
    is $tw->cancel($id), 0, 'cannot cancel an already-fired timer';
}

# full pool + delay-out-of-range croak; slots reusable after firing
{
    my $tw = Data::HierTimingWheel::Shared->new(undef, 4, 2, 3);   # max delay 4**2 - 1 = 15
    $tw->add(2, $_) for 1 .. 3;
    ok !eval { $tw->add(2, 99); 1 }, 'scheduling beyond capacity croaks';
    like $@, qr/full/, 'full-pool croak';
    $tw->advance(2);                  # fire all three -> pool empties
    my $id = eval { $tw->add(1, 99) };
    ok defined($id) && !$@, 'a freed slot is reusable after firing';
    ok !eval { $tw->add(16, 1); 1 }, 'a delay at/beyond S**L croaks';
    like $@, qr/range|delay/, 'out-of-range delay croak';
    ok defined(eval { $tw->add(15, 1) }), 'the maximum delay (S**L - 1) is accepted';
}

# clear
{
    my $tw = Data::HierTimingWheel::Shared->new(undef, 16, 3, 100);
    $tw->add(5, 1);
    $tw->add(500, 2);
    $tw->advance(3);
    $tw->clear;
    is $tw->now, 0, 'clear resets the clock';
    is $tw->count, 0, 'clear cancels all timers';
    is_deeply [$tw->advance(10)], [], 'nothing pending after clear';
    $tw->add(1, 77);
    is_deeply [$tw->advance(1)], [77], 'usable after clear';
}

# stats
{
    my $tw = Data::HierTimingWheel::Shared->new(undef, 32, 4, 50);
    $tw->add(10, 1);
    $tw->advance(3);
    my $s = $tw->stats;
    is ref($s), 'HASH', 'stats hashref';
    is $s->{num_slots}, 32, 'stats num_slots';
    is $s->{num_levels}, 4, 'stats num_levels';
    is $s->{max_delay}, 32 ** 4 - 1, 'stats max_delay';
    is $s->{capacity}, 50, 'stats capacity';
    is $s->{now}, 3, 'stats now';
    is $s->{count}, 1, 'stats count';
    cmp_ok $s->{ops}, '>', 0, 'stats ops';
    ok exists $s->{mmap_size}, 'stats mmap_size';
}

# error paths
ok !eval { Data::HierTimingWheel::Shared->new(undef, 1, 4, 10); 1 }, 'num_slots < 2 rejected';
like $@, qr/num_slots/, 'num_slots croak';
ok !eval { Data::HierTimingWheel::Shared->new(undef, 16, 0, 10); 1 }, 'num_levels 0 rejected';
like $@, qr/num_levels/, 'num_levels croak';
ok !eval { Data::HierTimingWheel::Shared->new(undef, 16, 4, 0); 1 }, 'capacity 0 rejected';
ok !eval { Data::HierTimingWheel::Shared->new(undef, 65536, 8, 10); 1 }, 'S**L overflow rejected';
like $@, qr/overflow|num_slots\^num_levels/, 'overflow croak';

# file-backed reopen: geometry + pending timers persist
my $path = "/tmp/htw-basic-$$.bin";
unlink $path;
{
    my $w = Data::HierTimingWheel::Shared->new($path, 16, 3, 100);
    is $w->path, $path, 'file-backed path';
    $w->add(50, 1234);
    $w->advance(10);
    $w->sync;
}
{
    my $r = Data::HierTimingWheel::Shared->new($path, 2, 1, 1);   # caller args ignored on reopen
    is $r->num_slots, 16, 'reopen: stored num_slots wins';
    is $r->num_levels, 3, 'reopen: stored num_levels wins';
    is $r->now, 10, 'reopen: clock persisted';
    is $r->count, 1, 'reopen: pending timer persisted';
    my @fired;
    push @fired, $r->advance(1) for 1 .. 40;   # ticks 11..50 -> fires at 50
    is_deeply \@fired, [1234], 'reopen: the pending timer still fires at its tick';
}
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::HierTimingWheel::Shared->new($path, 16, 3, 100); 1 }, 'corrupt file rejected';
unlink $path;

# memfd round-trip shares the wheel
{
    my $m  = Data::HierTimingWheel::Shared->new_memfd('htw', 16, 3, 50);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::HierTimingWheel::Shared->new_from_fd($fd);
    is $m2->num_slots, 16, 'reopened memfd geometry';
    $m->add(3, 55);
    is $m2->count, 1, 'new_from_fd shares the wheel';
    $m2->advance(2);
    is_deeply [$m->advance(1)], [55], 'a timer scheduled via one handle fires via the other';
}

# class-method unlink
my $cu = "/tmp/htw-cu-$$.bin";
unlink $cu;
{ my $w = Data::HierTimingWheel::Shared->new($cu, 8, 2, 16); $w->sync; }
ok -e $cu, 'backing file exists';
Data::HierTimingWheel::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# DESTROY
{
    my $i = Data::HierTimingWheel::Shared->new(undef, 8, 2, 8);
    $i->add(1, 1);
    $i->DESTROY;
    eval { $i->count };
    like $@, qr/destroyed/, 'use after DESTROY croaks';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
