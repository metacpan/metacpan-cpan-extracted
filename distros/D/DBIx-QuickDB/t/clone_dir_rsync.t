use strict;
use warnings;

use Test2::V0;
use POSIX();
use File::Temp qw/tempdir/;
use File::Path qw/make_path/;
use Cwd qw/abs_path/;

# clone_dir used to die with a raw wait status and never retry. Exit 23 is what
# two concurrent rsyncs into one destination produce.
#
# Util.pm resolves rsync via can_run() at BEGIN, so a fake one can only be
# substituted on $PATH in a child that has not yet loaded the module.

plan skip_all => "Requires a POSIX shell for the fake rsync" if $^O eq 'MSWin32';

# By contents, not by name: a bare -d 'lib' also matches t/lib from cwd t/.
my ($libdir) = map { abs_path($_) } grep { -f "$_/DBIx/QuickDB/Util.pm" } qw{lib ../lib};
plan skip_all => "Cannot locate the distribution's lib/ directory" unless $libdir && -d $libdir;

my $tmp = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
my $bin = "$tmp/bin";
make_path($bin);
make_path("$tmp/src");
make_path("$tmp/dest");

open(my $srcfh, '>', "$tmp/src/afile") or die "Could not write source file: $!";
print $srcfh "content\n";
close($srcfh);

# A fake rsync that records each invocation and exits with $FAKE_RSYNC_EXIT.
# When FAKE_RSYNC_OK_AFTER is set it succeeds once that many calls have been
# made, which models a genuinely transient failure that a retry recovers from.
open(my $fh, '>', "$bin/rsync") or die "Could not write fake rsync: $!";
# Each call's stderr names its own call number, so an assertion about the die
# message cannot be satisfied by the retry warning's copy of it.
print $fh <<'SH';
#!/bin/sh
echo "call" >> "$FAKE_RSYNC_LOG"
calls=$(wc -l < "$FAKE_RSYNC_LOG" | tr -d ' \t')
echo "fake rsync: simulated failure on call $calls" >&2
if [ -n "$FAKE_RSYNC_OK_AFTER" ] && [ "$calls" -ge "$FAKE_RSYNC_OK_AFTER" ]; then
    exit 0
fi
exit "$FAKE_RSYNC_EXIT"
SH
close($fh);
chmod(0755, "$bin/rsync") or die "Could not chmod fake rsync: $!";

# A noexec TMPDIR forbids running the stub, and the mode bits still say
# executable, so only trying it tells us. Skip rather than report the resulting
# "Permission denied" as though the retry logic were broken.
{
    local $ENV{FAKE_RSYNC_LOG}  = "$tmp/probe-log";
    local $ENV{FAKE_RSYNC_EXIT} = 0;

    my $pid = fork();
    die "Could not fork: $!" unless defined $pid;

    unless ($pid) {
        # Quiet: the probe may fail, and its noise would land in the TAP stream.
        open(STDOUT, '>', '/dev/null');
        open(STDERR, '>', '/dev/null');
        no warnings 'exec';

        # BLOCK form so this never reaches /bin/sh: perl routes a single-argument
        # exec through the shell when the string holds a metacharacter, which
        # $bin does whenever TMPDIR has a space, and the file would then skip
        # itself for a reason that is false.
        exec {"$bin/rsync"} "$bin/rsync";
        POSIX::_exit(127);
    }

    waitpid($pid, 0);

    plan skip_all => "Cannot execute a script from the temp dir (noexec TMPDIR?)" if $?;
}

# Run a child perl with stderr merged into stdout. No shell: list-form exec
# means a path containing a quote cannot mis-parse the command, which backticks
# did even with every interpolation quoted.
sub run_perl {
    my (@args) = @_;

    my $pid = open(my $fh, '-|');
    die "Could not fork: $!" unless defined $pid;

    unless ($pid) {
        open(STDERR, '>&', \*STDOUT);
        exec($^X, @args);
        die "Could not exec $^X: $!";
    }

    my $out = do { local $/; <$fh> };
    close($fh);

    return defined($out) ? $out : '';
}

# Run clone_dir in a child whose PATH finds the fake rsync first. Returns
# ($stdout_plus_stderr, $call_count).
sub run_clone {
    my (%params) = @_;

    my $log = "$tmp/calls-$params{tag}";
    unlink($log);

    my $script = 'require DBIx::QuickDB::Util; '
        . 'DBIx::QuickDB::Util::clone_dir($ARGV[0], $ARGV[1]); '
        . 'print "CLONE_OK\n";';

    local $ENV{FAKE_RSYNC_EXIT}     = $params{exit};
    local $ENV{FAKE_RSYNC_LOG}      = $log;
    local $ENV{FAKE_RSYNC_OK_AFTER} = $params{ok_after} // '';
    local $ENV{PATH}                = "$bin:$ENV{PATH}";

    my $out = run_perl("-I$libdir", '-e', $script, "$tmp/src", "$tmp/dest");

    my $count = 0;
    if (open(my $lfh, '<', $log)) {
        $count++ while <$lfh>;
        close($lfh);
    }

    return ($out, $count);
}

subtest exit_23_is_retried_and_reported => sub {
    # One run covers count and message: the full 3-attempt path costs a child
    # perl plus backoff sleeps, and this suite is CPU-saturated at -j16.
    my ($out, $count) = run_clone(exit => 23, tag => 'e23');

    is($count, 3, "Exit 23 was retried up to the bounded limit (3 attempts total)");
    unlike($out, qr/CLONE_OK/, "clone_dir died rather than reporting success");

    like($out, qr/exited 23/, "Reports the DECODED exit code, not a raw wait status");
    unlike($out, qr/returned 5888/, "Does not report the raw wait status");
    like($out, qr/\Q$tmp\E\/src/, "Names the source path");
    like($out, qr/\Q$tmp\E\/dest/, "Names the destination path");

    # The FINAL attempt's stderr, which only the die message can carry.
    like($out, qr/simulated failure on call 3/, "The failure message includes the failing attempt's rsync stderr");
};

subtest recovered_retry_is_not_silent => sub {
    # Without the retry this event died loudly; recovering silently would trade
    # a noisy failure for an invisible one.
    my ($out, $count) = run_clone(exit => 23, ok_after => 2, tag => 'recover');

    is($count, 2, "Succeeded on the second attempt");
    like($out, qr/CLONE_OK/, "clone_dir returned normally after recovering");
    like($out, qr/on attempt 1 of 3, retrying/, "Warned that an attempt failed and was retried");
    like($out, qr/exited 23 \(partial transfer\)/, "The warning names the decoded failure");

    # Call 1 specifically: call 2 succeeded and its stderr reaches $out by the
    # success path, so a call-agnostic match would pass without the warning.
    like($out, qr/simulated failure on call 1/, "The warning carries the FAILED attempt's stderr");
};

subtest closed_stderr_still_copies => sub {
    # A caller that closed STDERR makes the save-dup of fd 2 fail, and it could
    # copy fine before capturing existed. Real rsync: this is the capture
    # plumbing, not the retry logic.
    my $dest = "$tmp/dest-closed";

    my $script = 'require DBIx::QuickDB::Util; close(STDERR);'
        . ' my $ok = eval { DBIx::QuickDB::Util::clone_dir($ARGV[0], $ARGV[1]); 1 };'
        . ' my $e = $@; open(STDERR, ">&", \*STDOUT);'
        . ' print $ok ? "COPY_OK\n" : "COPY_DIED: $e\n";';

    my $out = run_perl("-I$libdir", '-e', $script, "$tmp/src", $dest);

    like($out, qr/COPY_OK/, "clone_dir still copies when the caller has closed STDERR");
    ok(-f "$dest/afile", "The file really was copied");
};

subtest non_retryable_exit_fails_immediately => sub {
    # 12 is a protocol error, and 24 ("vanished source files") means the source
    # is gone -- neither is fixed by trying again.
    my ($out, $count) = run_clone(exit => 12, tag => 'e12');
    is($count, 1, "A non-retryable exit code is attempted exactly once");
    like($out, qr/exited 12/, "Still reports the decoded exit code");

    my ($out24, $count24) = run_clone(exit => 24, tag => 'e24');
    is($count24, 1, "Exit 24 is not retried");
    like($out24, qr/exited 24/, "Reports exit 24");
};

subtest success_is_not_retried => sub {
    my ($out, $count) = run_clone(exit => 0, tag => 'ok');

    is($count, 1, "A successful rsync runs exactly once");
    like($out, qr/CLONE_OK/, "clone_dir returned normally");
    like($out, qr/simulated failure/, "Captured stderr is still passed through on success");
};

done_testing;
