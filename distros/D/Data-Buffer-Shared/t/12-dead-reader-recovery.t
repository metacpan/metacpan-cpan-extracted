use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use POSIX ();
use Time::HiRes qw(time);

use Data::Buffer::Shared::I64;

# Regression: a SIGKILL'd child holding lock_rd used to leave the reader
# counter permanently elevated, blocking the parent from ever acquiring the
# write lock again.  In the reader-slots-only rwlock a reader's contribution is
# its slot's `rdepth`; a draining writer clears a dead reader's slot inline, so
# the parent's first wrlock op succeeds promptly.

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'buf_dead_rdr') . '.shm' }

# Count reader slots with a nonzero rdepth by reading the shared header +
# reader-slot table directly.  Header layout: reader_slots_off is a uint64 at
# byte 40; each BufReaderSlot is 16 bytes { pid, rdepth, _rsv1, _rsv2 }.
sub live_rdepth_slots {
    my ($path) = @_;
    open my $f, '<', $path or return 0;
    binmode $f;
    seek $f, 40, 0;
    read $f, my $off_buf, 8;
    my $slots_off = unpack 'Q<', $off_buf;
    return 0 unless $slots_off;
    my $n = 0;
    for my $i (0 .. 1023) {
        seek $f, $slots_off + $i * 16, 0;
        read $f, my $slot, 8 or last;
        my ($pid, $rdepth) = unpack 'V V', $slot;
        $n++ if $pid && $rdepth;
    }
    close $f;
    return $n;
}

# Scenario 1: dead reader holding lock_rd → writer recovers via timeout drain.
{
    my $path = tmpfile();
    my $b = Data::Buffer::Shared::I64->new($path, 16);
    $b->set(0, 100);

    my @pids;
    for (1 .. 4) {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            my $c = Data::Buffer::Shared::I64->new($path, 16);
            $c->lock_rd;
            while (1) { POSIX::sleep(60) }
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }

    # Wait for children to have called lock_rd (their reader slots show rdepth>0).
    my $deadline = time + 5;
    my $held = 0;
    while (time < $deadline) {
        $held = live_rdepth_slots($path);
        last if $held > 0;
        select(undef, undef, undef, 0.02);
    }
    ok($held > 0, "children held rdlock (slots with rdepth>0: $held)");

    kill 'KILL', @pids;
    waitpid($_, 0) for @pids;

    # Parent's wrlock-path op must complete within ~3 s.
    my $start = time;
    my $ok = eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 10;
        $b->fill(42);  # write-locked
        alarm 0;
        1;
    };
    my $elapsed = time - $start;
    ok($ok, sprintf('parent fill returned (elapsed %.2fs)', $elapsed))
        or diag "stuck after ${elapsed}s: $@";
    cmp_ok($elapsed, '<', 5, "recovery completed in <5s");
    is($b->get(0), 42, "post-recovery value correct");

    my $s = $b->stats;
    ok($s->{recoveries} >= 1, "stat_recoveries incremented (got $s->{recoveries})");

    $b->unlink;
}

# Scenario 2: a dead PARKED writer leaves the parked-waiter hint (rwait)
# over-counted.  In the reader-slots-only rwlock readers gate only on wlock, so
# once the parent releases the write lock a new reader acquires immediately
# regardless of the phantom rwait -- an over-counted rwait can only cause a
# spurious wake, never a lost wakeup or a stuck reader.
{
    my $path = tmpfile();
    my $b = Data::Buffer::Shared::I64->new($path, 16);

    # Hold the write lock in the parent so the child's wrlock parks.
    $b->lock_wr;

    my $child = fork // die "fork: $!";
    if (!$child) {
        my $c = Data::Buffer::Shared::I64->new($path, 16);
        $c->lock_wr;  # will park indefinitely
        POSIX::_exit(0);
    }

    # Wait for child to park (rwait > 0 at offset 72).
    my $deadline = time + 5;
    my $rwait;
    while (time < $deadline) {
        open my $f, '<', $path or last;
        seek $f, 72, 0;  # rwait at offset 72
        read $f, my $buf, 4;
        close $f;
        $rwait = unpack 'V', $buf;
        last if $rwait && $rwait > 0;
        select(undef, undef, undef, 0.02);
    }
    ok(($rwait // 0) > 0, "child parked as writer (rwait=$rwait)");

    kill 'KILL', $child;
    waitpid $child, 0;

    # Release the lock; phantom rwait remains from the dead child.
    $b->unlock_wr;

    # Re-read rwait to confirm it's still phantom (>0) before recovery.
    open my $f, '<', $path or die;
    seek $f, 72, 0;
    read $f, my $buf, 4;
    close $f;
    my $phantom = unpack 'V', $buf;
    diag "phantom rwait after kill: $phantom";

    # A new reader doing lock_rd gates only on wlock (now 0), so it acquires
    # immediately regardless of the phantom rwait.
    my $start = time;
    my $ok = eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 10;
        $b->lock_rd;
        $b->unlock_rd;
        alarm 0;
        1;
    };
    my $elapsed = time - $start;
    ok($ok, sprintf('reader lock_rd returned after dead-writer (elapsed %.2fs)', $elapsed))
        or diag "stuck after ${elapsed}s: $@";
    cmp_ok($elapsed, '<', 5, "reader acquires despite phantom rwait in <5s");

    $b->unlink;
}

done_testing;
