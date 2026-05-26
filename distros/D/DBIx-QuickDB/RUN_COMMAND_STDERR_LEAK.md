# `run_command` stderr redirect can fail under captured-stderr parents

## Summary

`DBIx::QuickDB::Driver::run_command`'s child-side STDOUT/STDERR redirect
to `$log_file` does not always take effect when the calling parent
process has its FD 1 / FD 2 set to a pipe (or any non-default file
descriptor) by `dup2(2)` rather than by the perl-level `open` machinery.
The result is that subprocess output (e.g. `createdb`'s
`createdb: error: ... FATAL: the database system is starting up` retry
chatter during PostgreSQL bootstrap) can leak to the parent's captured
stderr instead of going into `$log_file`.

This was discovered while running the `Test2-Harness` (`yath`) test
suite, where `yath` captures each test job's stderr by `dup2`-ing a
pipe onto FD 2 of the test process before `exec`'ing perl. Tests that
spin up a temporary PostgreSQL via `DBIx::QuickDB` then inherit that
FD 2, and the in-process bootstrap retry of `createdb` writes its
client-side error messages to that pipe instead of into the
per-command log file.

## Affected version(s)

- Confirmed: 0.000040 (CPAN release; reproduced under perl 5.42.2,
  Linux 6.19).
- Code path identical in 0.000042 (current `master`); not patched yet.

## Symptoms

Under load (`-j16` / `-j32` parallel test runs), roughly 5–15% of runs
emit one or two stray lines on the parent's stderr that look like one
of:

```
createdb: error: could not connect to database template1: FATAL:  the database system is starting up
2026-05-08 04:54:42.868 GMT [2468976] FATAL:  the database system is starting up
```

The format depends on which side wrote the message:

- `createdb: error: ...` is libpq's client-side error printed by
  the `createdb` binary itself.
- `<timestamp> [pid] FATAL: ...` is a PostgreSQL backend log line,
  emitted only when `log_min_messages` includes the FATAL level
  (default behaviour) — so suppressible by setting
  `log_min_messages='panic'` in the driver `config`. The
  `createdb: error:` form persists regardless of `log_min_messages`
  because it is the client tool's own STDERR write.

The retries themselves are expected: `bootstrap` calls `start` (which
returns once the unix socket file exists, before the postmaster has
finished startup), then loops `createdb` inside `catch_startup` until
it succeeds. The bug is not the retries; it is that the *stderr* of
those retries is supposed to be captured into a per-invocation
`cmd-log-PID-N` file but isn't.

The `Result` of the test run is still `PASSED` — `catch_startup`
correctly swallows the perl-level exception and retries until
`createdb` succeeds. Only the cosmetic stderr noise leaks.

## Reproduction (minimal)

Outside `yath` the bug doesn't reproduce, because a plain perl process
has FD 2 attached to the terminal via the normal startup path, and
perl's `close(STDERR); open(STDERR, '>&', $log)` works as intended in
that case.

To reproduce, the parent process needs FD 2 *replaced by `dup2`* (as
opposed to set up via perl `open`). Mimic this directly:

```perl
# parent.pl
use strict;
use warnings;
use POSIX ();

# 1. Set up a pipe and dup2 the write-end onto FD 2, the way a
#    test harness or daemon would when capturing child stderr.
pipe(my $rh, my $wh) or die;
my $reader = fork // die;
if (!$reader) {
    close($wh);
    while (defined(my $line = <$rh>)) { print "PARENT-CAPTURED: $line" }
    exit 0;
}
close($rh);
POSIX::dup2(fileno($wh), 2) or die "dup2: $!";
close($wh);

# 2. Now do exactly what run_command's child does:
my $log_file = '/tmp/qdb-repro.log';
open(my $log, '>', $log_file) or die;
close(STDOUT);
open(STDOUT, '>&', $log);
close(STDERR);
open(STDERR, '>&', $log);

# 3. Inspect what FD 1/2 actually point at after the redirect:
warn "FD1=", (readlink("/proc/$$/fd/1") // '?'), "\n";
warn "FD2=", (readlink("/proc/$$/fd/2") // '?'), "\n";

# 4. Exec a command that writes to stderr.
exec('sh', '-c', 'echo "child stderr line" >&2');
```

On affected systems / perls the `warn`s and the child stderr line are
captured by the parent reader (`PARENT-CAPTURED: ...`) instead of
landing in `/tmp/qdb-repro.log`, demonstrating that FD 2 is still the
pipe — perl's `close(STDERR); open(STDERR, '>&', $log)` did not
overwrite the underlying kernel file descriptor.

In a `yath` test run the same effect was observed by adding diagnostic
writes inside `run_command` after the redirect block:

```perl
# After the existing close/open dance, before exec:
if (open(my $dh, '>>', '/tmp/qdb-fd2-debug.log')) {
    print $dh "PID=$$ CMD=@$cmd\n";
    print $dh "  FD1=", (readlink("/proc/$$/fd/1") // '?'), "\n";
    print $dh "  FD2=", (readlink("/proc/$$/fd/2") // '?'), "\n";
    close($dh);
}
```

The captured log shows entries like:

```
PID=2721067 CMD=/.../bin/initdb -E UTF8 -A trust -D /tmp/.../data
  FD1=pipe:[15413060]
  FD2=pipe:[15413061]
  LOG_FILE=/tmp/.../cmd-log-2721057-0
```

i.e. the redirect "succeeded" at the perl level (no `die`), but FD 1
and FD 2 are still the parent's pipes.

## Root cause

`run_command` (in `lib/DBIx/QuickDB/Driver.pm`) currently does:

```perl
unless ($no_log) {
    open(my $log, '>', $log_file) or die "Could not open log file ($log_file): $!";
    close(STDOUT);
    open(STDOUT, '>&', $log);
    close(STDERR);
    open(STDERR, '>&', $log);
}
```

This relies on perl's `close(STDOUT)` / `close(STDERR)` actually closing
the underlying FDs 1 and 2, so that the subsequent `open(STDOUT, '>&',
$log)` / `open(STDERR, '>&', $log)` `dup` the log handle into those now-
free FD slots.

That assumption holds when STDOUT/STDERR are the perl-managed handles
inherited from process startup. It does **not** hold when the parent
process has used `dup2(2)` (or its perl analogue) to bind a foreign FD
onto FD 1 / FD 2 — in that case perl's `close()` releases its PerlIO
handle but the underlying FD 1 / FD 2 stay open (because they are still
referenced by whatever opened them). The next `open(STDOUT, '>&', $log)`
then duplicates `$log` into the lowest free FD, which is no longer 1
or 2, so STDOUT / STDERR end up pointing at a fresh FD while FD 1 / FD 2
remain the parent's pipes. After `exec`, the new program inherits
FD 1 / FD 2 unchanged, so its stdout/stderr go straight to the parent.

## Proposed fix

Replace the close/open dance with explicit `POSIX::dup2(2)`. `dup2`
atomically closes whatever is currently at the target FD and replaces
it with a copy of the source FD, regardless of perl's PerlIO state:

```perl
use POSIX ();

unless ($no_log) {
    open(my $log, '>', $log_file) or die "Could not open log file ($log_file): $!";
    my $log_fd = fileno($log);
    POSIX::dup2($log_fd, 1) // die "dup2 STDOUT: $!";
    POSIX::dup2($log_fd, 2) // die "dup2 STDERR: $!";
    # The perl-level STDOUT/STDERR handles still point at the old
    # PerlIO layers, but the kernel FDs 1 and 2 (which exec inherits)
    # now point at the log file, which is what matters for the
    # subprocess.
    close($log);
}
```

Notes:

- `POSIX::dup2` returns the new FD on success and `undef` on failure
  (with `$!` set), hence the `// die`.
- After `dup2`, the perl-level `STDOUT` / `STDERR` filehandles still
  refer to whatever PerlIO state they were in. The subprocess only
  cares about the kernel FDs. If callers want the perl handles to also
  point at the log file (e.g. for `print STDERR` between this block and
  `exec`), they need a follow-up `open(STDOUT, '>&', $log)` — but in
  the existing `run_command` flow the very next call is `exec`, so this
  isn't required.
- The same change is needed for the `STDIN` redirect (`open(STDIN, '<',
  $file)`) if it ever has to work with a parent-imposed FD 0; right
  now that path uses `close(STDIN); open(STDIN, '<', $file)` and would
  exhibit the same bug, but no in-tree caller hits it.

## Why not "just configure postgres to not log"

`log_min_messages='panic'` in the driver `config` does suppress the
postgres-server-side `<timestamp> [pid] FATAL: the database system is
starting up` line. It does **not** suppress the client-side
`createdb: error: ...` message, which is written by `createdb` itself
to its own stderr. Fixing `run_command`'s redirect is the only way to
contain that output, and is the right fix anyway because the redirect
is supposed to capture *all* subprocess output, not just postgres-
server log lines.

## Severity

Cosmetic. The retries succeed, tests pass, no data is lost. The
visible noise is one or two lines per affected run, ~5–15% of stress
runs at high parallelism. Worth fixing because:

- It misleads readers of test output into thinking something is wrong.
- The `run_command` API documents that subprocess output is captured
  into a log file and only surfaced on failure; right now that
  contract is silently violated.

## References

- Discovered: 2026-05-07, while wiring `App::Yath2::Log::Postgres`
  tests in `Test2-Harness2`.
- Discussion / context: see `Test2-Harness/t/lib/Test2/Harness2/Test/DBVersions.pm`
  (the `get_quiet_db` helper there suppresses the postgres-side log
  via `log_min_messages='panic'` as a workaround pending this fix).
