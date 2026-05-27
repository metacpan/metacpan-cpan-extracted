use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use POSIX ();
use Time::HiRes qw(time);

use Data::HashMap::Shared::SI;

# Regression: a SIGKILL'd child that was holding the rdlock used to leave
# the rwlock's reader counter permanently elevated, blocking the parent
# from ever acquiring the write lock again.  After the dead-reader
# recovery patch, the parent's first write op should succeed within one
# FUTEX_WAIT timeout (~2 s).
#
# Behavioral test, not a precise ordering test.  We poll the rwlock word
# to confirm children entered the rdlock before SIGKILLing them, but
# don't pin any child in the specific inc-subcount-then-CAS-rwlock
# window — that race is too narrow to hit reliably from userspace.  The
# $stuck guard below handles the benign case where every child died
# between ops (rwlock already back to 0).  What matters is the outcome:
# the parent's wrlock acquires within 5 s, not which exact code path
# fired.

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_dead_rdr') . '.shm' }

{
    my $path = tmpfile();
    my $m = Data::HashMap::Shared::SI->new($path, 100_000);

    # Fork N children that hammer incr_by (lock-free fast path → rdlock).
    my $N_CHILDREN = 16;
    my @pids;
    for (1 .. $N_CHILDREN) {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            my $c = Data::HashMap::Shared::SI->new($path, 100_000);
            while (1) { $c->incr_by("k$$/$_", 1) for 1..1000 }
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    # Wait until children have entered the rdlock at least once.  Without
    # this, a race where SIGKILL fires before any child managed an rdlock
    # leaves the rwlock counter at 0 (no recovery needed → recoveries=0).
    my $deadline = time + 5;
    my $rwlock_word;
    while (time < $deadline) {
        open my $f, '<', $path or last;
        seek $f, 128, 0;
        read $f, my $buf, 4;
        close $f;
        $rwlock_word = unpack 'V', $buf;
        last if $rwlock_word > 0 && $rwlock_word < 0x80000000;
        select(undef, undef, undef, 0.02);
    }
    ok($rwlock_word > 0 && $rwlock_word < 0x80000000,
       "children entered rdlock (rwlock=$rwlock_word)");

    kill 'KILL', @pids;
    waitpid($_, 0) for @pids;

    # Check whether SIGKILL caught any child mid-rdlock.  If yes, recovery
    # MUST fire; if no (every child died between ops), recovery is a no-op
    # and the wrlock acquires immediately.
    open my $f, '<', $path or die "open: $!";
    seek $f, 128, 0;
    read $f, my $buf, 4;
    close $f;
    my $rwl = unpack 'V', $buf;
    my $stuck = $rwl > 0 && $rwl < 0x80000000;

    # Parent's wrlock op must complete within ~3s (one 2s FUTEX_WAIT + slack).
    my $start = time;
    my $ok = eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 10;
        # Insert a new key forces the write-lock path.
        $m->put("after_kill", 42);
        alarm 0;
        1;
    };
    my $elapsed = time - $start;

    ok($ok, "parent's put after dead children returned (elapsed ${\ sprintf '%.2f', $elapsed }s)")
        or diag "stuck after ${elapsed}s: $@";
    cmp_ok($elapsed, '<', 5, "recovery completed in <5s");
    is($m->get("after_kill"), 42, "post-recovery value is correct");

    my $stats = $m->stats;
    if ($stuck) {
        ok($stats->{recoveries} >= 1,
           "stat_recoveries incremented when rwlock was stuck (got $stats->{recoveries})");
    } else {
        diag "children died between rdlocks — no recovery needed";
        pass("no recovery expected (rwlock was 0 after waitpid)");
    }

    unlink $path;
}

done_testing;
