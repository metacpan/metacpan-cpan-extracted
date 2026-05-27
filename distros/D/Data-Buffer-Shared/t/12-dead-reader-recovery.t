use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use POSIX ();
use Time::HiRes qw(time);

use Data::Buffer::Shared::I64;

# Regression: a SIGKILL'd child holding lock_rd used to leave the rwlock's
# reader counter permanently elevated, blocking the parent from ever
# acquiring the write lock again.  After the dead-reader recovery patch,
# the parent's first wrlock op should succeed within one FUTEX_WAIT
# timeout (~2 s).

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'buf_dead_rdr') . '.shm' }

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

    # Wait for children to have called lock_rd (rwlock_word > 0).
    my $deadline = time + 5;
    my $rwlock_word;
    while (time < $deadline) {
        open my $f, '<', $path or last;
        seek $f, 68, 0;  # rwlock at offset 68 (cache line 1 begins at 64, +4 for seq)
        read $f, my $buf, 4;
        close $f;
        $rwlock_word = unpack 'V', $buf;
        last if $rwlock_word > 0 && $rwlock_word < 0x80000000;
        select(undef, undef, undef, 0.02);
    }
    ok($rwlock_word > 0 && $rwlock_word < 0x80000000,
       "children held rdlock (rwlock=$rwlock_word)");

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

# Scenario 2: dead PARKED writer leaves phantom writers_waiting > 0 with
# rwlock == 0.  Without the val=0 recovery fix, new readers yield forever
# to the phantom writer.  After the fix, the reader's first timeout drains
# the phantom contribution and lock_rd succeeds.
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

    # Wait for child to park (writers_waiting > 0).
    my $deadline = time + 5;
    my $writers_waiting;
    while (time < $deadline) {
        open my $f, '<', $path or last;
        seek $f, 80, 0;  # rwlock_writers_waiting at offset 80
        read $f, my $buf, 4;
        close $f;
        $writers_waiting = unpack 'V', $buf;
        last if $writers_waiting && $writers_waiting > 0;
        select(undef, undef, undef, 0.02);
    }
    ok(($writers_waiting // 0) > 0, "child parked as writer (writers_waiting=$writers_waiting)");

    kill 'KILL', $child;
    waitpid $child, 0;

    # Release the lock; phantom writers_waiting remains from dead child.
    $b->unlock_wr;

    # Re-read writers_waiting to confirm it's still phantom (>0) before recovery.
    open my $f, '<', $path or die;
    seek $f, 80, 0;
    read $f, my $buf, 4;
    close $f;
    my $phantom = unpack 'V', $buf;
    diag "phantom writers_waiting after kill: $phantom";

    # Now a new reader doing lock_rd should NOT yield forever — within
    # one FUTEX_WAIT timeout, recovery drains the phantom and lock_rd
    # acquires.
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
    cmp_ok($elapsed, '<', 5, "phantom writers_waiting drained in <5s");

    $b->unlink;
}

done_testing;
