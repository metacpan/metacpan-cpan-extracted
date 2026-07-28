use strict;
use warnings;
use Test::More;
use Data::TimingWheel::Shared;

# constructor + introspection
{
    my $tw = Data::TimingWheel::Shared->new(undef, 64, 100);
    isa_ok $tw, 'Data::TimingWheel::Shared';
    is $tw->num_slots, 64, 'num_slots';
    is $tw->capacity, 100, 'capacity';
    is $tw->now, 0, 'fresh: now 0';
    is $tw->count, 0, 'fresh: no timers';
    is_deeply [$tw->advance(1)], [], 'advancing an empty wheel fires nothing';
    is $tw->now, 1, 'advance moves the clock';
}

# a timer fires exactly `delay` ticks after it was scheduled -- including delays
# that exceed one full rotation (exercising the rounds counter)
{
    my $ns = 8;    # small wheel so most delays wrap several times
    my $tw = Data::TimingWheel::Shared->new(undef, $ns, 1000);
    my %expect;    # payload -> the tick it must fire on (== its delay)
    my $p = 1;
    for my $delay (1, 2, 7, 8, 9, 15, 16, 17, 31, 32, 63, 64, 100, 200) {
        $tw->add($delay, $p);
        $expect{$p} = $delay;
        $p++;
    }
    is $tw->count, scalar(keys %expect), 'all timers pending';

    my %got;
    for my $t (1 .. 220) { $got{$_} = $t for $tw->advance(1) }
    my $bad = 0;
    for my $pl (keys %expect) { $bad++ if ($got{$pl} // -1) != $expect{$pl} }
    is $bad, 0, 'every timer fires on exactly its delay tick (incl. multi-rotation)';
    is $tw->count, 0, 'all timers fired';
    is $tw->now, 220, 'clock advanced 220 ticks';
}

# delay < 1 is treated as 1 (fires on the next tick)
{
    my $tw = Data::TimingWheel::Shared->new(undef, 16, 10);
    $tw->add(0, 42);
    is_deeply [$tw->advance(1)], [42], 'delay 0 fires on the next tick';
}

# advance by many ticks returns everything that came due, in tick order
{
    my $tw = Data::TimingWheel::Shared->new(undef, 4, 100);
    $tw->add(1, 10);
    $tw->add(2, 20);
    $tw->add(3, 30);
    $tw->add(5, 50);
    my @due = $tw->advance(4);       # ticks 1..4 -> 10, 20, 30 due (50 not yet)
    is_deeply [sort { $a <=> $b } @due], [10, 20, 30], 'advance(4) fires the first three';
    is $tw->count, 1, 'the 5-tick timer is still pending';
    is_deeply [$tw->advance(1)], [50], 'the last timer fires on tick 5';
}

# schedule alias
{
    my $tw = Data::TimingWheel::Shared->new(undef, 16, 10);
    $tw->schedule(2, 7);
    $tw->advance(1);
    is_deeply [$tw->advance(1)], [7], 'schedule is an alias for add';
}

# cancel
{
    my $tw = Data::TimingWheel::Shared->new(undef, 16, 100);
    my $a = $tw->add(5, 111);
    my $b = $tw->add(5, 222);
    is $tw->count, 2, 'two timers pending';
    is $tw->cancel($a), 1, 'cancel an active timer returns 1';
    is $tw->count, 1, 'count drops after cancel';
    is $tw->cancel($a), 0, 're-cancelling returns 0';
    is $tw->cancel(99999), 0, 'cancelling an invalid id returns 0';
    my @fired;
    push @fired, $tw->advance(1) for 1 .. 5;
    is_deeply \@fired, [222], 'only the surviving timer fires';
}

# a fired timer id is no longer cancellable
{
    my $tw = Data::TimingWheel::Shared->new(undef, 8, 10);
    my $id = $tw->add(1, 5);
    $tw->advance(1);
    is $tw->cancel($id), 0, 'cannot cancel an already-fired timer';
}

# full pool croaks; slots are reusable after firing
{
    my $tw = Data::TimingWheel::Shared->new(undef, 4, 3);
    $tw->add(2, $_) for 1 .. 3;
    ok !eval { $tw->add(2, 99); 1 }, 'scheduling beyond capacity croaks';
    like $@, qr/full/, 'full-pool croak';
    $tw->advance(2);                  # fire all three -> pool empties
    my $id = eval { $tw->add(1, 99) };
    ok defined($id) && !$@, 'a freed slot is reusable after firing';
}

# clear
{
    my $tw = Data::TimingWheel::Shared->new(undef, 16, 100);
    $tw->add(5, 1);
    $tw->add(5, 2);
    $tw->advance(3);
    $tw->clear;
    is $tw->now, 0, 'clear resets the clock';
    is $tw->count, 0, 'clear cancels all timers';
    is_deeply [$tw->advance(10)], [], 'nothing pending after clear';
    # usable after clear
    $tw->add(1, 77);
    is_deeply [$tw->advance(1)], [77], 'usable after clear';
}

# stats
{
    my $tw = Data::TimingWheel::Shared->new(undef, 32, 50);
    $tw->add(10, 1);
    $tw->advance(3);
    my $s = $tw->stats;
    is ref($s), 'HASH', 'stats hashref';
    is $s->{num_slots}, 32, 'stats num_slots';
    is $s->{capacity}, 50, 'stats capacity';
    is $s->{now}, 3, 'stats now';
    is $s->{count}, 1, 'stats count';
    is $s->{cur}, 3, 'stats cur (now mod num_slots)';
    cmp_ok $s->{ops}, '>', 0, 'stats ops';
    ok exists $s->{mmap_size}, 'stats mmap_size';
}

# error paths
ok !eval { Data::TimingWheel::Shared->new(undef, 0, 10); 1 }, 'num_slots 0 rejected';
like $@, qr/num_slots/, 'num_slots croak';
ok !eval { Data::TimingWheel::Shared->new(undef, 16, 0); 1 }, 'capacity 0 rejected';

# file-backed reopen: geometry + pending timers persist
my $path = "/tmp/tw-basic-$$.bin";
unlink $path;
{
    my $w = Data::TimingWheel::Shared->new($path, 64, 100);
    is $w->path, $path, 'file-backed path';
    $w->add(50, 1234);
    $w->advance(10);
    $w->sync;
}
{
    my $r = Data::TimingWheel::Shared->new($path, 1, 1);   # caller args ignored on reopen
    is $r->num_slots, 64, 'reopen: stored num_slots wins';
    is $r->capacity, 100, 'reopen: stored capacity wins';
    is $r->now, 10, 'reopen: clock persisted';
    is $r->count, 1, 'reopen: pending timer persisted';
    my @fired;
    push @fired, $r->advance(1) for 1 .. 40;   # ticks 11..50 -> fires at 50
    is_deeply \@fired, [1234], 'reopen: the pending timer still fires at its tick';
}
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::TimingWheel::Shared->new($path, 64, 100); 1 }, 'corrupt file rejected';
unlink $path;

# memfd round-trip shares the wheel
{
    my $m  = Data::TimingWheel::Shared->new_memfd('tw', 16, 50);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::TimingWheel::Shared->new_from_fd($fd);
    is $m2->num_slots, 16, 'reopened memfd geometry';
    $m->add(3, 55);
    is $m2->count, 1, 'new_from_fd shares the wheel';
    $m2->advance(2);
    is_deeply [$m->advance(1)], [55], 'a timer scheduled via one handle fires via the other';
}

# class-method unlink
my $cu = "/tmp/tw-cu-$$.bin";
unlink $cu;
{ my $w = Data::TimingWheel::Shared->new($cu, 8, 16); $w->sync; }
ok -e $cu, 'backing file exists';
Data::TimingWheel::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# DESTROY
{
    my $i = Data::TimingWheel::Shared->new(undef, 8, 8);
    $i->add(1, 1);
    $i->DESTROY;
    eval { $i->count };
    like $@, qr/destroyed/, 'use after DESTROY croaks';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
