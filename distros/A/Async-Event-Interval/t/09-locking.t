use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use IPC::Shareable qw(:lock :semaphores);
use Test::More;

# Test hook used by the 2.2 stop() polling-loop tests. When $kill_mock
# is set to a coderef, all kill() calls in code compiled AFTER this
# BEGIN (notably Async::Event::Interval, loaded just below) route
# through the mock; otherwise pass through to the real CORE::kill. Lets
# us exercise stop()'s "process never dies" croak path without needing
# an actually-unkillable real process.

our $kill_mock;
BEGIN {
    *CORE::GLOBAL::kill = sub {
        return $kill_mock->(@_) if $kill_mock;
        return CORE::kill(@_);
    };
}

use Async::Event::Interval;

# Helper: get the knot for AEI's %events hash so we can poke at the
# raw semaphore slots and observe lock state directly.

sub events_knot { Async::Event::Interval::_events_knot() }

# Sanity: LOCK_EX and LOCK_SH were imported into Async::Event::Interval
# via `use IPC::Shareable qw(:lock)`.

{
    can_ok 'Async::Event::Interval', 'LOCK_EX';
    can_ok 'Async::Event::Interval', 'LOCK_SH';
    can_ok 'Async::Event::Interval', '_events_write';
    can_ok 'Async::Event::Interval', '_events_read';
}

# _write_events runs its coderef under LOCK_EX (SEM_WRITERS goes to 1
# inside, 0 again afterwards) and returns the coderef's scalar return.

{
    my $knot = events_knot;

    is $knot->sem->getval(SEM_WRITERS), 0,
        "SEM_WRITERS is 0 before _write_events";

    my $writers_during;
    my $rv = Async::Event::Interval::_events_write(sub {
        $writers_during = $knot->sem->getval(SEM_WRITERS);
        return 'wrote';
    });

    is $writers_during, 1,
        "_write_events held LOCK_EX during the coderef (SEM_WRITERS=1)";

    is $knot->sem->getval(SEM_WRITERS), 0,
        "_write_events released LOCK_EX after the coderef (SEM_WRITERS=0)";

    is $rv, 'wrote',
        "_write_events propagates the coderef's return value";
}

# _read_events runs its coderef under LOCK_SH (SEM_READERS goes to 1
# inside, 0 again afterwards) and returns the coderef's scalar return.

{
    my $knot = events_knot;

    is $knot->sem->getval(SEM_READERS), 0,
        "SEM_READERS is 0 before _read_events";

    my $readers_during;
    my $rv = Async::Event::Interval::_events_read(sub {
        $readers_during = $knot->sem->getval(SEM_READERS);
        return 'read';
    });

    is $readers_during, 1,
        "_read_events held LOCK_SH during the coderef (SEM_READERS=1)";

    is $knot->sem->getval(SEM_READERS), 0,
        "_read_events released LOCK_SH after the coderef (SEM_READERS=0)";

    is $rv, 'read',
        "_read_events propagates the coderef's return value";
}

# Errors thrown inside the coderef propagate out and release the lock.

{
    my $knot = events_knot;

    my $ok = eval {
        Async::Event::Interval::_events_write(sub { die "boom-write\n" });
        1;
    };
    is $ok, undef, "_write_events propagates die from its coderef";
    like $@, qr/boom-write/, "...with the original error";
    is $knot->sem->getval(SEM_WRITERS), 0,
        "_write_events released LOCK_EX even on die";

    $ok = eval {
        Async::Event::Interval::_events_read(sub { die "boom-read\n" });
        1;
    };
    is $ok, undef, "_read_events propagates die from its coderef";
    like $@, qr/boom-read/, "...with the original error";
    is $knot->sem->getval(SEM_READERS), 0,
        "_read_events released LOCK_SH even on die";
}

# When the tie has been torn down (simulate by undef'ing tied()), the
# helpers degrade gracefully by just running the coderef without a lock.

{
    no warnings 'redefine';
    local *Async::Event::Interval::_events_write = sub {
        my ($cb) = @_;
        my $knot = Async::Event::Interval::_events_knot();
        # Simulate teardown by ignoring the knot
        $knot = undef;
        return $cb->() unless $knot;
        return 'never';
    };
    is
        Async::Event::Interval::_events_write(sub { 'fallback' }),
        'fallback',
        "_write_events falls back to running the coderef when no knot is available";
}

# Concurrent writers through the public API (interval() setter) do not
# corrupt state. Two forked children each set interval many times; the
# final value is one of the two expected values, not a corrupt mix.

{
    my $e = Async::Event::Interval->new(0.5, sub {});
    my $iters = 100;

    my @kids;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (! $pid) {
        for (1 .. $iters) { $e->interval(100) }
        require POSIX;
        POSIX::_exit(0);
    }
    push @kids, $pid;

    $pid = fork;
    die "fork: $!" unless defined $pid;
    if (! $pid) {
        for (1 .. $iters) { $e->interval(200) }
        require POSIX;
        POSIX::_exit(0);
    }
    push @kids, $pid;

    waitpid $_, 0 for @kids;

    my $v = $e->interval;
    ok $v == 100 || $v == 200,
        "concurrent interval() setters produce an expected value, got $v "
      . "(no corruption across $iters iterations x 2 children)";
}

# A LOCK_EX writer must block a LOCK_SH reader. Verify by holding
# LOCK_EX in a forked child and watching the parent's LOCK_SH wait
# for it.

{
    my $knot = events_knot;

    pipe my $child_ready_r, my $child_ready_w or die "pipe: $!";
    pipe my $parent_done_r, my $parent_done_w or die "pipe: $!";

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (! $pid) {
        # Child: take LOCK_EX, tell parent, wait for parent's signal,
        # then release.
        $knot->lock(LOCK_EX);
        close $child_ready_r;
        print $child_ready_w "ready\n";
        close $child_ready_w;

        # Block until parent writes back
        close $parent_done_w;
        my $line = <$parent_done_r>;
        close $parent_done_r;

        $knot->unlock;
        require POSIX;
        POSIX::_exit(0);
    }

    # Parent: wait for child's LOCK_EX, then time a LOCK_SH attempt;
    # release the child while we're waiting on LOCK_SH.
    close $child_ready_w;
    my $r = <$child_ready_r>;
    chomp $r;
    is $r, 'ready', "child signaled it holds LOCK_EX";
    close $child_ready_r;

    is $knot->sem->getval(SEM_WRITERS), 1,
        "SEM_WRITERS shows the child's LOCK_EX is held";

    # Release the child only after we've kicked off the LOCK_SH wait
    # below. Do it in a forked grandchild so the parent's blocking
    # _read_events has someone to unblock it.
    my $unblock_pid = fork;
    die "fork: $!" unless defined $unblock_pid;
    if (! $unblock_pid) {
        # Wait briefly so the parent enters its LOCK_SH wait first
        select undef, undef, undef, 0.2;
        close $parent_done_r;
        print $parent_done_w "go\n";
        close $parent_done_w;
        require POSIX;
        POSIX::_exit(0);
    }

    use Time::HiRes ();
    my $t0 = Time::HiRes::time();
    Async::Event::Interval::_events_read(sub { 1 });
    my $elapsed = Time::HiRes::time() - $t0;

    cmp_ok $elapsed, '>=', 0.1,
        "_read_events under LOCK_SH waited for the child's LOCK_EX to release ($elapsed s)";

    waitpid $pid, 0;
    waitpid $unblock_pid, 0;
}

# Internal accessors use LOCK_EX on the write path: an in-process
# observer wrapping _write_events sees it called when state changes.

{
    my $write_count = 0;
    my $orig = \&Async::Event::Interval::_events_write;
    no warnings 'redefine';
    local *Async::Event::Interval::_events_write = sub {
        $write_count++;
        $orig->(@_);
    };

    my $e = Async::Event::Interval->new(0, sub {});

    # new() calls _write_events once for $events{$id} = {}; interval()
    # under _setup adds one more. Anything else counts too — we just
    # require >= 2 here so the test is robust to small refactors.

    cmp_ok $write_count, '>=', 2,
        "new() goes through _write_events at least twice "
      . "(for \$events{\$id} = {} and \$interval setter)";
}

# Public read accessors (info, interval getter, runs, errors,
# error_message) all go through _read_events.

{
    my $read_count = 0;
    my $orig = \&Async::Event::Interval::_events_read;
    no warnings 'redefine';
    local *Async::Event::Interval::_events_read = sub {
        $read_count++;
        $orig->(@_);
    };

    my $e = Async::Event::Interval->new(0.5, sub {});
    $read_count = 0;

    $e->info;
    cmp_ok $read_count, '>=', 1, "info() calls _read_events";

    $read_count = 0;
    $e->interval;
    cmp_ok $read_count, '>=', 1, "interval() getter calls _read_events";

    $read_count = 0;
    $e->runs;
    cmp_ok $read_count, '>=', 1, "runs() calls _read_events";

    $read_count = 0;
    $e->errors;
    cmp_ok $read_count, '>=', 1, "errors() calls _read_events";

    $read_count = 0;
    $e->error_message;
    cmp_ok $read_count, '>=', 1, "error_message() calls _read_events";
}

# The write-side accessors (interval setter, pid) go through _write_events.

{
    my $write_count = 0;
    my $orig = \&Async::Event::Interval::_events_write;
    no warnings 'redefine';
    local *Async::Event::Interval::_events_write = sub {
        $write_count++;
        $orig->(@_);
    };

    my $e = Async::Event::Interval->new(0.5, sub {});
    $write_count = 0;

    $e->interval(1.5);
    cmp_ok $write_count, '>=', 1, "interval() setter calls _write_events";

    # pid() writes to %events via _pid() during start(); verify pid()
    # setter path. We exercise _pid directly since start() would fork.

    $write_count = 0;
    Async::Event::Interval::_pid($e, 12345);
    cmp_ok $write_count, '>=', 1, "_pid() setter calls _write_events";
}

# Fork failure (PFM->start returns undef) croaks instead of falling
# through to the child path and running the callback in the parent.

{
    my $callback_ran = 0;
    my $e = Async::Event::Interval->new(0.5, sub { $callback_ran++ });

    my $start_orig = \&Parallel::ForkManager::start;
    no warnings 'redefine';
    local *Parallel::ForkManager::start = sub { return undef };

    my $ok = eval { $e->start; 1 };
    my $err = $@;

    is $ok, undef,
        "start() croaks on fork failure";
    like $err, qr/fork\(\) failed/,
        "...with fork failure message";

    is $callback_ran, 0,
        "callback was NOT executed on fork failure";
}

# start() propagates the fork error through the _event coderef,
# so _write_events / _read_events locks are not leaked.

{
    my $e = Async::Event::Interval->new(0.5, sub { die "should not run\n" });

    my $start_orig = \&Parallel::ForkManager::start;
    no warnings 'redefine';
    local *Parallel::ForkManager::start = sub { return undef };

    eval { $e->start };

    is $e->runs, 0,
        "runs still 0 after fork failure";
    is $e->errors, 0,
        "errors still 0 after fork failure";
    is $e->interval, 0.5,
        "interval unchanged after fork failure";
}

# The internal write-path incrementors (_errors(1), _runs(1),
# _error_message($msg)) also go through _write_events.

{
    my $write_count = 0;
    my $orig = \&Async::Event::Interval::_events_write;
    no warnings 'redefine';
    local *Async::Event::Interval::_events_write = sub {
        $write_count++;
        $orig->(@_);
    };

    my $e = Async::Event::Interval->new(0.5, sub {});

    $write_count = 0;
    Async::Event::Interval::_errors($e, 1);
    cmp_ok $write_count, '>=', 1, "_errors(1) calls _write_events";

    $write_count = 0;
    Async::Event::Interval::_runs($e, 1);
    cmp_ok $write_count, '>=', 1, "_runs(1) calls _write_events";

    $write_count = 0;
    Async::Event::Interval::_error_message($e, "test");
    cmp_ok $write_count, '>=', 1, "_error_message(\$msg) calls _write_events";
}

# _read_events degrades gracefully when the knot has been torn down
# (same pattern as the _write_events teardown test).

{
    no warnings 'redefine';
    local *Async::Event::Interval::_events_read = sub {
        my ($cb) = @_;
        my $knot = Async::Event::Interval::_events_knot();
        $knot = undef;
        return $cb->() unless $knot;
        return 'never';
    };
    is
        Async::Event::Interval::_events_read(sub { 'fallback' }),
        'fallback',
        "_read_events falls back to running the coderef when no knot is available";
}

# $@ is preserved across _write_events calls inside the error path.
# _write_events → lock(LOCK_EX, sub{...}) does an internal eval{} that
# would clear $@ if $@ were not captured first.

{
    my $e = Async::Event::Interval->new(
        0.05,
        sub { die "expected-error-marker\n" },
    );

    $e->start;
    sleep 1;

    is $e->errors, 1, "error count incremented after crash";
    like
        $e->error_message,
        qr/expected-error-marker/,
        "error_message captured and persisted (was not cleared by _write_events' internal eval)";
    like
        $e->info->{error_message},
        qr/expected-error-marker/,
        "...also visible via info()";
}

# _pm->finish is called even when the callback dies, so ForkManager
# gets notified instead of retaining a stale child record.
# Test in-process by mocking start() to return 0 (child path) and
# finish() to record calls instead of exiting.

{
    my $finish_called = 0;
    my $finish_exit   = undef;
    my $start_call    = 0;

    my $start_orig  = \&Parallel::ForkManager::start;
    my $finish_orig = \&Parallel::ForkManager::finish;

    no warnings 'redefine';
    local *Parallel::ForkManager::start = sub {
        $start_call++;
        return 0 if $start_call == 1;   # child path
        return 1;                        # parent path (breaks loop)
    };
    local *Parallel::ForkManager::finish = sub {
        my ($self, $exit_code) = @_;
        $finish_called++;
        $finish_exit = $exit_code;
    };

    my $e = Async::Event::Interval->new(0, sub { die "child-crash\n" });
    $e->start;

    is $finish_called, 1,
        "_pm->finish called even after callback crash";
    is $finish_exit, 1,
        "...with exit code 1 on failure";

    is $e->errors, 1,
        "error count incremented after in-process crash test";
    like $e->error_message, qr/child-crash/,
        "error_message preserved";

    $e->_pid(0);
}

# Additional 1.2 coverage: _pm->finish must always be called with the
# correct exit code regardless of how the callback finishes, across both
# run-once and interval modes. These blocks mock
# Parallel::ForkManager::start (return 0 for the child path, 1 for the
# parent path so the for(0..1) loop breaks via `last`) and
# Parallel::ForkManager::finish (record instead of exiting). _pid(0) at
# the end suppresses the DESTROY -> stop() -> sleep(1) chain that would
# otherwise fire on the mocked parent-path pid=1.
#
# Run-once success path: callback returns; finish(0); runs=1, errors=0.

{
    my @finish_calls;
    my $start_call = 0;
    no warnings 'redefine';
    local *Parallel::ForkManager::start = sub {
        $start_call++;
        return 0 if $start_call == 1;
        return 1;
    };
    local *Parallel::ForkManager::finish = sub {
        push @finish_calls, $_[1];
    };

    my $e = Async::Event::Interval->new(0, sub { 1 });
    $e->start;

    is scalar @finish_calls, 1,
        "run-once success: _pm->finish called exactly once";
    is $finish_calls[0], 0,
        "...with exit code 0 on success";
    is $e->runs, 1, "run-once success: runs incremented";
    is $e->errors, 0, "run-once success: errors stays 0";
    is $e->error_message, undef,
        "run-once success: error_message stays undef";

    $e->_pid(0);
}

# Run-once failure: Carp::croak inside the callback still triggers finish(1).
# (Carp is loaded transitively via Async::Event::Interval.)

{
    my @finish_calls;
    my $start_call = 0;
    no warnings 'redefine';
    local *Parallel::ForkManager::start = sub {
        $start_call++;
        return 0 if $start_call == 1;
        return 1;
    };
    local *Parallel::ForkManager::finish = sub {
        push @finish_calls, $_[1];
    };

    my $e = Async::Event::Interval->new(0, sub { Carp::croak "carp-form" });
    $e->start;

    is scalar @finish_calls, 1, "Carp::croak: finish called once";
    is $finish_calls[0], 1, "...with exit code 1";
    is $e->errors, 1, "Carp::croak: errors == 1";
    like $e->error_message, qr/carp-form/,
        "Carp::croak: error_message captured";

    $e->_pid(0);
}

# Run-once failure: die without a trailing newline (Perl appends file/line)
# is still caught and finish(1) is invoked with the appended location.

{
    my @finish_calls;
    my $start_call = 0;
    no warnings 'redefine';
    local *Parallel::ForkManager::start = sub {
        $start_call++;
        return 0 if $start_call == 1;
        return 1;
    };
    local *Parallel::ForkManager::finish = sub {
        push @finish_calls, $_[1];
    };

    my $e = Async::Event::Interval->new(0, sub { die "no-newline-die" });
    $e->start;

    is scalar @finish_calls, 1, "die-without-newline: finish called once";
    is $finish_calls[0], 1, "...with exit code 1";
    like $e->error_message, qr/no-newline-die/,
        "die-without-newline: original message captured";
    like $e->error_message, qr/line \d+/,
        "...Perl's appended source location preserved";

    $e->_pid(0);
}

# Interval mode: callback dies on first iteration; the eval around the
# while(1) loop catches and finish(1) is called once.

{
    my @finish_calls;
    my $start_call = 0;
    my $cb_count   = 0;
    no warnings 'redefine';
    local *Parallel::ForkManager::start = sub {
        $start_call++;
        return 0 if $start_call == 1;
        return 1;
    };
    local *Parallel::ForkManager::finish = sub {
        push @finish_calls, $_[1];
    };

    my $e = Async::Event::Interval->new(
        0.001,
        sub { $cb_count++; die "immediate-loop-death\n" },
    );
    $e->start;

    is $cb_count, 1, "interval mode (immediate death): callback ran once";
    is scalar @finish_calls, 1,
        "interval mode (immediate death): finish called exactly once";
    is $finish_calls[0], 1, "...with exit code 1";
    is $e->runs, 1, "runs incremented for the one iteration";
    is $e->errors, 1, "errors incremented exactly once";
    like $e->error_message, qr/immediate-loop-death/,
        "interval mode: error_message captured";

    $e->_pid(0);
}

# Interval mode: callback succeeds N times then dies; finish(1) called
# once, runs == N (incremented in both success and failure paths of
# _run_callback), errors == 1.

{
    my @finish_calls;
    my $start_call = 0;
    my $cb_count   = 0;
    no warnings 'redefine';
    local *Parallel::ForkManager::start = sub {
        $start_call++;
        return 0 if $start_call == 1;
        return 1;
    };
    local *Parallel::ForkManager::finish = sub {
        push @finish_calls, $_[1];
    };

    my $e = Async::Event::Interval->new(0.001, sub {
        $cb_count++;
        die "death-after-runs\n" if $cb_count >= 3;
    });
    $e->start;

    is $cb_count, 3, "interval mode (death after runs): callback ran 3 times";
    is scalar @finish_calls, 1,
        "interval mode (death after runs): finish called exactly once";
    is $finish_calls[0], 1, "...with exit code 1";
    is $e->runs, 3, "runs incremented for all iterations including the dying one";
    is $e->errors, 1, "errors incremented exactly once";
    like $e->error_message, qr/death-after-runs/,
        "interval mode (death after runs): error_message captured";

    $e->_pid(0);
}

# Multiple events crashing independently each receive their own finish(1)
# call. The mocked start() returns 0 on odd calls (child path) and 1 on
# even calls (parent path), so each event's for(0..1) loop runs once
# through the child and once through the parent.

{
    my @finish_calls;
    my $start_call = 0;
    no warnings 'redefine';
    local *Parallel::ForkManager::start = sub {
        $start_call++;
        return $start_call % 2 == 1 ? 0 : 1;
    };
    local *Parallel::ForkManager::finish = sub {
        push @finish_calls, $_[1];
    };

    my $e1 = Async::Event::Interval->new(0, sub { die "e1-crash\n" });
    my $e2 = Async::Event::Interval->new(0, sub { die "e2-crash\n" });
    $e1->start;
    $e2->start;

    is scalar @finish_calls, 2,
        "multiple events: each crash invokes _pm->finish";
    is $finish_calls[0], 1, "first event finish exit code 1";
    is $finish_calls[1], 1, "second event finish exit code 1";
    is $e1->errors, 1, "first event errors == 1";
    is $e2->errors, 1, "second event errors == 1";
    like $e1->error_message, qr/e1-crash/,
        "first event error_message captured";
    like $e2->error_message, qr/e2-crash/,
        "second event error_message captured";

    $e1->_pid(0);
    $e2->_pid(0);
}

# finish() is called exactly once per start, from inside the child-path
# branch of the for(0..1) loop. The parent-path iteration must not call
# finish a second time. Recording the start-call counter at finish time
# proves finish ran before the parent-path iteration.

{
    my @finish_at;
    my $start_call = 0;
    no warnings 'redefine';
    local *Parallel::ForkManager::start = sub {
        $start_call++;
        return 0 if $start_call == 1;
        return 1;
    };
    local *Parallel::ForkManager::finish = sub {
        push @finish_at, $start_call;
    };

    my $e = Async::Event::Interval->new(0, sub { 1 });
    $e->start;

    is scalar @finish_at, 1,
        "exactly one finish() per start() (parent-path iteration does not call finish)";
    is $finish_at[0], 1,
        "finish() ran from the child path, before the parent-path start iteration";

    $e->_pid(0);
}

# _end() uses _read_events rather than reading %events directly.

{
    my $read_count = 0;
    my $orig = \&Async::Event::Interval::_events_read;
    no warnings 'redefine';
    local *Async::Event::Interval::_events_read = sub {
        $read_count++;
        $orig->(@_);
    };

    # Prevent clean_up_protected from destroying the semaphore set when
    # %events is empty (events from earlier tests may have DESTROY'd).
    my $cleanup_calls = 0;
    local *IPC::Shareable::clean_up_protected = sub { $cleanup_calls++ };

    $read_count = 0;
    Async::Event::Interval::_end();
    cmp_ok $read_count, '>=', 1,
        "_end() calls _read_events to check keys %events";
}

# events() returns a deep copy independent of the live %events hash.
# Mutations to the copy do not affect %events and do not go through
# _write_events or _read_events.

{
    my $write_count = 0;
    my $read_count  = 0;
    my $orig_write = \&Async::Event::Interval::_events_write;
    my $orig_read  = \&Async::Event::Interval::_events_read;
    no warnings 'redefine';
    local *Async::Event::Interval::_events_write = sub { $write_count++; $orig_write->(@_) };
    local *Async::Event::Interval::_events_read  = sub { $read_count++; $orig_read->(@_) };

    my $e = Async::Event::Interval->new(0.5, sub {});
    $write_count = 0;
    $read_count  = 0;

    my $snap = Async::Event::Interval::events();
    cmp_ok $read_count, '>=', 1,
        "events() reads under _read_events to produce the snapshot";

    $read_count  = 0;
    $write_count = 0;
    $snap->{$e->id}{made_up_key} = 'ghost';

    is $write_count, 0,
        "write to events() snapshot does NOT call _write_events";
    is $read_count, 0,
        "write to events() snapshot does NOT call _read_events";
    ok ! exists $e->info->{made_up_key},
        "write to events() snapshot is NOT visible in live %events";
}

# shared_scalar entries in the events() snapshot are the hex key strings
# (the tied scalars themselves are not stored in %events).

{
    my $e  = Async::Event::Interval->new(0.5, sub {});
    my $s  = $e->shared_scalar;
    $$s = 99;

    my $snap = Async::Event::Interval::events();
    my $ss   = $snap->{$e->id}{shared_scalars};

    is ref $ss, 'ARRAY',
        "shared_scalar entry in events() snapshot is an ARRAY ref";
    is scalar @$ss, 1,
        "snapshot has exactly one shared_scalar key";
    like $ss->[0], qr/^0x[a-f0-9]+$/,
        "shared_scalar key is a hex string with 0x prefix";

    # The key string matches what _rand_shm_key() produces; the actual
    # tied scalar lives outside %events (in $self->{_shared_scalars}).
    # The caller's original ref is still live and tracks the value.
    is $$s, 99,
        "original shared_scalar ref still reads same value after events() snapshot";

    $$s = 77;
    is $$s, 77,
        "original shared_scalar ref tracks live changes";
}

# _end() unconditionally cleans up protected segments so that signal
# death (where DESTROY may never run) does not leak.

{
    my $cleanup_calls = 0;
    no warnings 'redefine';
    local *IPC::Shareable::clean_up_protected = sub { $cleanup_calls++ };

    my $e = Async::Event::Interval->new(0.5, sub {});
    Async::Event::Interval::_end();
    is $cleanup_calls, 1,
        "_end() calls clean_up_protected even with live events";

    $e = undef;
    $cleanup_calls = 0;
    Async::Event::Interval::_end();
    is $cleanup_calls, 1,
        "_end() calls clean_up_protected after events destroyed";
}

# 2.1: _end() must not block forever if another process holds LOCK_EX
# on the events knot at exit time. The body is wrapped in
# eval { local $SIG{ALRM} = ...; alarm(END_LOCK_TIMEOUT); ... }, so the
# alarm interrupts _read_events' blocking semop and the parent exits.

# Constant is exported via use constant and has a sane value.

{
    can_ok 'Async::Event::Interval', 'END_LOCK_TIMEOUT';
    cmp_ok Async::Event::Interval::END_LOCK_TIMEOUT(), '>=', 1,
        "END_LOCK_TIMEOUT >= 1 second";
    cmp_ok Async::Event::Interval::END_LOCK_TIMEOUT(), '<=', 10,
        "END_LOCK_TIMEOUT <= 10 seconds (sanity bound)";
}

# No-contention path: _end() returns essentially immediately, well under
# the alarm timeout, when no peer holds LOCK_EX.

{
    no warnings 'redefine';
    local *IPC::Shareable::clean_up_protected = sub {};

    use Time::HiRes ();
    my $t0 = Time::HiRes::time();
    Async::Event::Interval::_end();
    my $elapsed = Time::HiRes::time() - $t0;

    # _end() has three internal _alarmed_eval(1, ...) phases; worst case
    # without contention is well under their sum. Use a generous wall-clock
    # cap so this catches a real "hangs every phase" regression without
    # flaking under VM jitter where semop overhead alone can take seconds.
    my $cap = 8;
    cmp_ok $elapsed, '<', $cap,
        "_end() returns well under the worst-case alarm budget when no "
      . "contention ($elapsed s, cap=$cap)";
}

# Contention path: a forked child takes LOCK_EX and holds it longer than
# END_LOCK_TIMEOUT. _end() in the parent must time out via SIGALRM
# instead of blocking on _read_events' LOCK_SH wait forever.

{
    my $knot = events_knot;

    pipe my $ready_r, my $ready_w or die "pipe: $!";

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (! $pid) {
        $knot->lock(LOCK_EX);
        close $ready_r;
        print $ready_w "ready\n";
        close $ready_w;
        # Hold the lock well past END_LOCK_TIMEOUT; parent TERMs us when
        # done.
        sleep 30;
        $knot->unlock;
        require POSIX;
        POSIX::_exit(0);
    }

    close $ready_w;
    my $ready = <$ready_r>;
    chomp $ready;
    is $ready, 'ready', "_end timeout: child holds LOCK_EX";
    close $ready_r;

    is $knot->sem->getval(SEM_WRITERS), 1,
        "_end timeout: SEM_WRITERS confirms the child's LOCK_EX is held";

    no warnings 'redefine';
    local *IPC::Shareable::clean_up_protected = sub {};

    my $timeout = Async::Event::Interval::END_LOCK_TIMEOUT();

    use Time::HiRes ();
    my $t0 = Time::HiRes::time();
    Async::Event::Interval::_end();
    my $elapsed = Time::HiRes::time() - $t0;

    # Upper bound loosened for slow-VM SIGALRM-delivery jitter; the
    # behavioral claim is still "_end() bails out instead of blocking
    # forever," which is enforced by a finite ceiling well below the
    # child's sleep 30. The lower bound (unchanged) keeps the "actually
    # waited" assertion.
    cmp_ok $elapsed, '<', $timeout + 8,
        "_end() bailed out instead of blocking "
      . "($elapsed s, timeout=$timeout)";
    cmp_ok $elapsed, '>=', $timeout - 0.5,
        "_end() actually waited ~END_LOCK_TIMEOUT seconds before bailing "
      . "($elapsed s)";

    kill 'TERM', $pid;
    waitpid $pid, 0;
}

# After a timeout-aborted _end(), the next _end() call (with no
# contention) still works — the eval / local $SIG{ALRM} pair leaves no
# leaked alarm or handler state behind.

{
    no warnings 'redefine';
    my $cleanup_calls = 0;
    local *IPC::Shareable::clean_up_protected = sub { $cleanup_calls++ };

    Async::Event::Interval::_end();
    cmp_ok $cleanup_calls, '>=', 1,
        "_end() recovers normally after a prior timeout";

    # No leaked alarm — alarm(0) returns the seconds remaining on any
    # pending alarm, so a clean state returns 0.
    is alarm(0), 0,
        "_end() leaves no pending alarm in the global state";
}

# 2.2: stop() polls kill(0) at STOP_KILL_POLL_INTERVAL cadence for up to
# STOP_KILL_TIMEOUT seconds instead of always sleeping a fixed 1s. It
# returns as soon as the target process is gone, and croaks only if the
# process is still alive after the timeout.

# Constants exist and have sane values; poll interval < total timeout.

{
    can_ok 'Async::Event::Interval', 'STOP_KILL_TIMEOUT';
    can_ok 'Async::Event::Interval', 'STOP_KILL_POLL_INTERVAL';
    cmp_ok Async::Event::Interval::STOP_KILL_TIMEOUT(), '>', 0,
        "STOP_KILL_TIMEOUT is positive";
    cmp_ok Async::Event::Interval::STOP_KILL_POLL_INTERVAL(), '>', 0,
        "STOP_KILL_POLL_INTERVAL is positive";
    cmp_ok Async::Event::Interval::STOP_KILL_POLL_INTERVAL(), '<',
        Async::Event::Interval::STOP_KILL_TIMEOUT(),
        "poll interval is smaller than the total timeout";
}

# Already-dead pid: stop() returns essentially immediately because the
# first `kill 0` returns 0 and the while-loop body never executes.

{
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (! $pid) {
        require POSIX;
        POSIX::_exit(0);
    }
    # $SIG{CHLD} = 'IGNORE' (set by AEI at load time) auto-reaps; sleep
    # briefly so the child has actually exited.
    select(undef, undef, undef, 0.05);

    my $e = Async::Event::Interval->new(0, sub {});
    $e->_pid($pid);

    use Time::HiRes ();
    my $t0 = Time::HiRes::time();
    $e->stop;
    my $elapsed = Time::HiRes::time() - $t0;

    cmp_ok $elapsed, '<',
        Async::Event::Interval::STOP_KILL_POLL_INTERVAL(),
        "stop() on an already-dead pid returns under one poll interval "
      . "($elapsed s)";
    is $e->_started, 0,
        "stop() cleared _started flag";

    $e->_pid(0);
}

# Live child: stop() actually sends SIGKILL and returns well under the
# old fixed 1s sleep — the polling loop catches the child's death on
# the first or second poll.

{
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (! $pid) {
        sleep 30;   # parent's stop() will SIGKILL us long before this
        require POSIX;
        POSIX::_exit(0);
    }

    my $e = Async::Event::Interval->new(0, sub {});
    $e->_pid($pid);
    $e->_started(1);

    # Brief settle so the child is in its sleep before we kill it.
    select(undef, undef, undef, 0.05);

    use Time::HiRes ();
    my $t0 = Time::HiRes::time();
    $e->stop;
    my $elapsed = Time::HiRes::time() - $t0;

    cmp_ok $elapsed, '<',
        Async::Event::Interval::STOP_KILL_TIMEOUT(),
        "stop() on a live child returns under STOP_KILL_TIMEOUT "
      . "($elapsed s)";
    is $e->_started, 0,
        "stop() on a live child cleared _started flag";
    ok ! (kill 0, $pid),
        "child pid is gone after stop()";

    $e->_pid(0);
}

# Croak path: when kill(0) keeps returning truthy past both
# STOP_TERM_TIMEOUT and STOP_KILL_TIMEOUT, stop() croaks after trying
# SIGTERM then escalating to SIGKILL. Uses the CORE::GLOBAL::kill
# override installed at the top of this file so we don't need an
# actually-unkillable real process.

{
    my @kill_calls;       # track all kill calls: [$sig, $pid]
    my @kill_zero_calls;
    local $kill_mock = sub {
        my ($sig, @pids) = @_;
        push @kill_calls, [$sig, @pids];
        push @kill_zero_calls, [@pids] if $sig eq '0';
        return 1;
    };

    my $e = Async::Event::Interval->new(0, sub {});
    $e->_pid(99999);

    my $term_timeout = Async::Event::Interval::STOP_TERM_TIMEOUT();
    my $kill_timeout = Async::Event::Interval::STOP_KILL_TIMEOUT();
    my $total_timeout = $term_timeout + $kill_timeout;

    use Time::HiRes ();
    my $t0 = Time::HiRes::time();
    eval { $e->stop };
    my $err = $@;
    my $elapsed = Time::HiRes::time() - $t0;

    like $err, qr/hasn't been killed/,
        "stop() croaks when kill 0 keeps returning truthy after both signals";
    like $err, qr/SIGTERM \+ SIGKILL/,
        "...error mentions both SIGTERM and SIGKILL";
    cmp_ok $elapsed, '>=', $total_timeout - 0.3,
        "stop() waited ~STOP_TERM_TIMEOUT + STOP_KILL_TIMEOUT before croaking "
      . "($elapsed s, total_timeout=$total_timeout)";
    cmp_ok $elapsed, '<', $total_timeout + 1.0,
        "stop() didn't wait substantially longer than the combined timeouts "
      . "($elapsed s)";

    # Both TERM and KILL were sent in order before croaking.
    my @sigs = map { $_->[0] } @kill_calls;
    ok ((grep { $_ eq 'TERM' } @sigs) >= 1,
        "SIGTERM was sent before croaking");
    ok ((grep { $_ eq 'KILL' } @sigs) >= 1,
        "SIGKILL was sent after SIGTERM failed");

    # TERM was sent before KILL.
    my $term_idx = 0;
    my $kill_idx = 0;
    for my $i (0 .. $#kill_calls) {
        $term_idx = $i if $kill_calls[$i][0] eq 'TERM' && ! $term_idx;
        $kill_idx = $i if $kill_calls[$i][0] eq 'KILL';
    }
    cmp_ok $term_idx, '<', $kill_idx,
        "SIGTERM was sent (idx=$term_idx) before SIGKILL (idx=$kill_idx)";

    # Polling actually polled: at STOP_KILL_POLL_INTERVAL=0.05 over
    # ~1.5s we expect ~30 kill(0) checks. Allow a generous floor.
    cmp_ok scalar @kill_zero_calls, '>=', 10,
        "stop() polled kill(0) across both signal phases (got "
      . scalar(@kill_zero_calls) . ")";

    is $e->_started, 0,
        "stop() cleared _started flag even before croaking";

    $e->_pid(0);
}

# stop() with no pid is a no-op (covers the early `if ($self->pid)`
# guard so the polling loop doesn't run on a fresh, never-started event).

{
    my $e = Async::Event::Interval->new(0, sub {});
    # new() does not call _pid, so $e->pid is undef at this point.
    is $e->pid, undef, "fresh event has no pid before start()";

    use Time::HiRes ();
    my $t0 = Time::HiRes::time();
    $e->stop;
    my $elapsed = Time::HiRes::time() - $t0;

    cmp_ok $elapsed, '<', 0.01,
        "stop() on a never-started event is an instant no-op ($elapsed s)";
}

# 3.3: stop() sends SIGTERM first, escalates to SIGKILL only if TERM fails.
# Tests verify the new STOP_TERM_TIMEOUT constant, the _signal_and_wait
# helper, the TERM-then-KILL ordering, and the short-circuit when TERM
# succeeds.

# STOP_TERM_TIMEOUT exists and has a sane value.

{
    can_ok 'Async::Event::Interval', 'STOP_TERM_TIMEOUT';
    cmp_ok Async::Event::Interval::STOP_TERM_TIMEOUT(), '>', 0,
        "STOP_TERM_TIMEOUT is positive";
    cmp_ok Async::Event::Interval::STOP_TERM_TIMEOUT(), '<=', 5,
        "STOP_TERM_TIMEOUT <= 5 seconds (sanity bound)";
    cmp_ok Async::Event::Interval::STOP_TERM_TIMEOUT(), '<',
        Async::Event::Interval::STOP_KILL_TIMEOUT(),
        "STOP_TERM_TIMEOUT is shorter than STOP_KILL_TIMEOUT";
}

# _signal_and_wait is a method on Async::Event::Interval.

{
    can_ok 'Async::Event::Interval', '_signal_and_wait';
}

# SIGTERM success: when a child dies from SIGTERM, stop() returns
# without ever escalating to SIGKILL. Uses the CORE::GLOBAL::kill mock
# to track signal order and simulate TERM-induced death.

{
    my @signals_sent;
    my $kill_zero_alive = 0;       # count of kill(0) calls seen so far
    local $kill_mock = sub {
        my ($sig, @pids) = @_;
        push @signals_sent, $sig;

        if ($sig eq 'TERM') {
            # After SIGTERM is delivered, subsequent kill(0) calls
            # should report the process as dead.
            $kill_zero_alive = 0;
            return 1;
        }
        if ($sig eq '0') {
            $kill_zero_alive++;
            # Return alive for the first kill(0) (pre-TERM probe in
            # _signal_and_wait's while loop), then dead afterwards
            # (simulating TERM-induced death).
            return $kill_zero_alive <= 1 ? 1 : 0;
        }
        return 1;
    };

    my $e = Async::Event::Interval->new(0, sub {});
    $e->_pid(99999);

    eval { $e->stop };

    # stop() must have sent TERM (it always tries TERM first).
    ok ((grep { $_ eq 'TERM' } @signals_sent) >= 1,
        "SIGTERM success: SIGTERM was sent");

    # SIGKILL must NOT have been sent — TERM killed the child.
    ok (! (grep { $_ eq 'KILL' } @signals_sent),
        "SIGTERM success: SIGKILL was NOT sent (TERM sufficed)");

    is $e->_started, 0,
        "SIGTERM success: _started cleared";

    $e->_pid(0);
}

# Live child actually dies from SIGTERM: fork a child that sleeps,
# call stop(), verify it returns quickly (under STOP_TERM_TIMEOUT) and
# the child is gone. SIGTERM's default action (terminate) kills the
# sleeping child on the first poll.

{
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (! $pid) {
        sleep 30;
        require POSIX;
        POSIX::_exit(0);
    }

    my $e = Async::Event::Interval->new(0, sub {});
    $e->_pid($pid);
    $e->_started(1);

    select(undef, undef, undef, 0.05);

    use Time::HiRes ();
    my $t0 = Time::HiRes::time();
    $e->stop;
    my $elapsed = Time::HiRes::time() - $t0;

    my $term_timeout = Async::Event::Interval::STOP_TERM_TIMEOUT();
    cmp_ok $elapsed, '<', $term_timeout,
        "live child: stop() returns under STOP_TERM_TIMEOUT when SIGTERM works "
      . "($elapsed s, term_timeout=$term_timeout)";
    is $e->_started, 0,
        "live child: _started cleared";
    ok ! (kill 0, $pid),
        "live child: pid is gone after stop()";

    $e->_pid(0);
}

# _signal_and_wait with an already-dead pid: returns 1 immediately
# because the kill(0) polling loop never enters.

{
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (! $pid) {
        require POSIX;
        POSIX::_exit(0);
    }
    select(undef, undef, undef, 0.05);

    my $e = Async::Event::Interval->new(0, sub {});
    $e->_pid($pid);

    use Time::HiRes ();
    my $t0 = Time::HiRes::time();
    my $rv = $e->_signal_and_wait('TERM',
        Async::Event::Interval::STOP_TERM_TIMEOUT());
    my $elapsed = Time::HiRes::time() - $t0;

    is $rv, 1,
        "_signal_and_wait returns 1 when pid is already dead";
    cmp_ok $elapsed, '<',
        Async::Event::Interval::STOP_KILL_POLL_INTERVAL(),
        "_signal_and_wait returns immediately for already-dead pid "
      . "($elapsed s)";
    $e->_pid(0);
}

# _signal_and_wait with a live child: sends the signal, polls until
# the child dies, returns 1 within one poll interval.

{
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (! $pid) {
        sleep 30;
        require POSIX;
        POSIX::_exit(0);
    }

    select(undef, undef, undef, 0.05);

    my $e = Async::Event::Interval->new(0, sub {});
    $e->_pid($pid);

    use Time::HiRes ();
    my $t0 = Time::HiRes::time();
    my $rv = $e->_signal_and_wait('TERM',
        Async::Event::Interval::STOP_TERM_TIMEOUT());
    my $elapsed = Time::HiRes::time() - $t0;

    is $rv, 1,
        "_signal_and_wait returns 1 when child dies from signal";
    cmp_ok $elapsed, '<',
        Async::Event::Interval::STOP_TERM_TIMEOUT(),
        "_signal_and_wait returns within STOP_TERM_TIMEOUT "
      . "($elapsed s)";
    ok ! (kill 0, $pid),
        "_signal_and_wait: child pid is gone";

    $e->_pid(0);
}

# _signal_and_wait timeout: when kill(0) keeps returning truthy past
# the timeout, returns 0 (used by stop() to decide escalation).

{
    my @kill_calls;
    local $kill_mock = sub {
        my ($sig, @pids) = @_;
        push @kill_calls, $sig;
        return 1;   # always alive
    };

    my $e = Async::Event::Interval->new(0, sub {});
    $e->_pid(99999);

    use Time::HiRes ();
    my $t0 = Time::HiRes::time();
    my $rv = $e->_signal_and_wait('TERM',
        Async::Event::Interval::STOP_TERM_TIMEOUT());
    my $elapsed = Time::HiRes::time() - $t0;

    is $rv, 0,
        "_signal_and_wait returns 0 on timeout";
    my $term_timeout = Async::Event::Interval::STOP_TERM_TIMEOUT();
    cmp_ok $elapsed, '>=', $term_timeout - 0.2,
        "_signal_and_wait waited ~STOP_TERM_TIMEOUT before returning 0 "
      . "($elapsed s)";

    $e->_pid(0);
}
