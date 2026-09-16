use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

use Data::HashMap::Shared::II;

# Two pieces of lock bookkeeping are advisory -- a wrong value costs speed, not
# correctness -- and both live in the file, so a process that died at the wrong
# moment slows every writer from then on, across restarts.  Only one of them can
# be healed.
#
#   occ     one bit per reader slot, set at claim and cleared only on a clean
#           release.  A reader that _exits leaves it set, and every write lock
#           scans it.  A writer retires such a bit by testing whether the slot's
#           pid is still alive, which is evidence, so this one is safe to heal.
#   rwait   counts parked waiters.  A waiter SIGKILLed while parked never
#           decrements it, and every later unlock then pays a futex syscall for
#           nobody.  This one is not healed, deliberately: the only signal the
#           unlocker has is "the wake woke nobody", and a live waiter between
#           its rwait++ and the kernel's compare looks exactly the same.  It may
#           only ever over-count -- see shm_rwlock_wrunlock.

my $dir = tempdir(CLEANUP => 1);

sub hdr32 {                       # read a uint32 header field
    my ($path, $off) = @_;
    open my $fh, '<:raw', $path or die $!;
    seek $fh, $off, 0 or die $!;
    read $fh, my $b, 4 or die $!;
    close $fh;
    return unpack 'L', $b;
}
use constant { SLOTS => 1024, SLOT_SIZE => 16 };
sub slots_off {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die $!;
    read $fh, my $h, 160 or die $!;
    return unpack 'Q<', substr($h, 80, 8);
}
sub poke_slot {                   # write a slot's pid/rdepth and set its bit
    my ($path, $idx, $pid, $rdepth) = @_;
    my $so = slots_off($path);
    open my $fh, '+<:raw', $path or die $!;
    seek $fh, $so + $idx * SLOT_SIZE, 0 or die $!;
    print $fh pack 'LL', $pid, $rdepth;
    my $bit = $so + SLOTS * SLOT_SIZE + int($idx / 8);
    seek $fh, $bit, 0 or die $!;
    read $fh, my $b, 1 or die $!;
    seek $fh, $bit, 0 or die $!;
    print $fh pack 'C', unpack('C', $b) | (1 << ($idx % 8));
    close $fh or die $!;
}
sub occ_bits {                    # slots marked occupied in the bitmap
    my ($path) = @_;
    open my $fh, '<:raw', $path or die $!;
    my $h; read $fh, $h, 160 or die $!;
    my $slots_off = unpack 'Q<', substr($h, 80, 8);
    seek $fh, $slots_off + 1024 * 16, 0 or die $!;
    read $fh, my $occ, 128 or die $!;
    close $fh;
    return unpack '%32b*', $occ;
}

# ---- rwait: a count left behind by a killed waiter is left alone ----------
{
    my $path = "$dir/rwait.shm";
    my $m = Data::HashMap::Shared::II->new($path, 1000);
    $m->put(1, 1);
    is hdr32($path, 132), 0, 'rwait is zero with nobody waiting';

    open my $fh, '+<:raw', $path or die $!;      # 5 waiters that no longer exist
    seek $fh, 132, 0 or die $!;
    print $fh pack 'L', 5;
    close $fh or die $!;
    is hdr32($path, 132), 5, '  ... a killed waiter leaves the count behind';

    $m->put(2, 2);
    is hdr32($path, 132), 5, 'the count is left alone: waking nobody is not evidence it is stale';
    is $m->get(2), 2, '  ... and the write went through regardless';
}

# ---- occupancy: bits left by readers that exited uncleanly are retired ----
{
    my $path = "$dir/occ.shm";
    my $m = Data::HashMap::Shared::II->new($path, 10_000);
    $m->put($_, $_) for 1 .. 50;
    my $base = occ_bits($path);

    my @pids;
    for (1 .. 40) {                   # keys() takes the read lock, so each claims a slot
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            my $c = Data::HashMap::Shared::II->new($path, 10_000);
            my @k = $c->keys;
            POSIX::_exit(0);          # no DESTROY: the bit stays set
        }
        push @pids, $pid;
        waitpid $pid, 0;
    }
    my $leaked = occ_bits($path);
    cmp_ok $leaked, '>', $base, 'readers that exit uncleanly leave their bits set'
        or diag "base=$base leaked=$leaked";

    # a fresh handle sweeps on its first write lock
    my $w = Data::HashMap::Shared::II->new($path, 10_000);
    $w->put(99, 99);
    my $swept = occ_bits($path);
    cmp_ok $swept, '<', $leaked, 'a write lock retires the bits of slots nobody owns';
    is $w->get(99), 99, '  ... having done the write it was there for';
    my @all = $m->keys;
    is scalar(@all), 51, '  ... and the map is intact';

    # our own live slots must survive the sweep
    my @k = $m->keys;
    cmp_ok occ_bits($path), '>', 0, 'a live reader keeps its own bit';
}

# ---- the shape a reader killed inside its read lock leaves -----------------
# The fixture above only ever produces slots that were released cleanly before
# the process exited.  A reader killed mid-read-lock is different: a draining
# writer zeroes its pid but leaves rdepth and the bit, and a sweep that tests
# rdepth before the pid skips exactly those, for ever.  Plant that state
# directly -- racing a kill against the read lock reaches it only sometimes.
{
    my $path = "$dir/drained.shm";
    my $m = Data::HashMap::Shared::II->new($path, 10_000);
    $m->put(1, 1);
    my $base = occ_bits($path);

    poke_slot($path, $_, 0, 1) for 100 .. 199;    # pid 0, rdepth left behind
    cmp_ok occ_bits($path), '>', $base, 'a drained dead reader leaves its bit set';

    my $w = Data::HashMap::Shared::II->new($path, 10_000);   # sweeps on first write
    $w->put(2, 2);
    # base, plus at most the sweeping handle's own freshly claimed slot
    cmp_ok occ_bits($path), '<=', $base + 1,
        'the sweep retires it: rdepth speaks only for a slot with an owner';
    is $w->get(2), 2, '  ... having done the write it was there for';
    is $m->get(1), 1, '  ... and the map is intact';
}

done_testing;
