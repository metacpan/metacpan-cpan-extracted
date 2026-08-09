use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use QDB::Installs qw/run_per_install/;    # before Test2::V0: it loads Test2::IPC
use Test2::V0;
use File::Temp qw/tempdir/;
use Capture::Tiny qw/capture/;
use POSIX();

# What the parent says about an isolated install child that died without
# leaving TAP behind.

my $MODE_ENV = 'QDB_DIAG_FIXTURE_MODE';

# Fixture role: run_per_install re-executes this file, so it is its own
# fixture. The env picks the failure shape.
if (my $mode = $ENV{$MODE_ENV}) {
    # Dies in the install child only, before any of the machinery has run.
    POSIX::_exit(255)
        if $mode eq 'abort_before_install' && $ENV{QDB_INSTALL_EXTERNAL_FLAVOR};

    # Spawner only: an unrunnable command makes system() itself fail. More than
    # one element so it never consults the shell, whose status is not a failure.
    if ($mode eq 'launch_failure' && !$ENV{QDB_INSTALL_EXTERNAL_FLAVOR}) {
        no warnings 'redefine';
        *QDB::Installs::_external_child_command = sub { ("$Bin/no-such-perl-$$", '-e', '1') };
    }

    # Two installs move run_per_install to the captured path. No database needed.
    if ($mode eq 'two_installs' && !$ENV{QDB_INSTALL_EXTERNAL_FLAVOR}) {
        no warnings 'redefine';
        *QDB::Installs::qdb_installs = sub {
            return ({name => 'one', bin_dir => undef}, {name => 'two', bin_dir => undef});
        };
    }

    run_per_install(
        SQLite => sub {
            POSIX::_exit(255) if $mode eq 'abort_before_result';

            ok(1, "first assertion");

            POSIX::_exit(255)    if $mode eq 'abort_after_result';
            POSIX::_exit(42)     if $mode eq 'odd_exit_code';
            kill('KILL', $$)     if $mode eq 'signal_death';
            die "boom in body\n" if $mode eq 'die_in_body';
        }
    );

    done_testing;
    exit 0;
}

skip_all "DBD::SQLite is required to run an SQLite install child"
    unless eval { require DBD::SQLite; 1 };

my $tmp = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);

my $run_id = 0;

sub slurp {
    my ($file) = @_;
    open(my $fh, '<', $file) or return '';
    local $/;
    return scalar <$fh>;
}

# Re-run this file as its own fixture. QDB_INSTALL_NO_FORK puts Unix on the
# external-process path MSWin32 always takes.
sub run_fixture {
    my (%params) = @_;

    my @inc = map { "-I$_" } grep { defined($_) && length($_) && !ref($_) } @INC;

    local %ENV = (
        %ENV,
        $MODE_ENV             => $params{mode},
        QDB_INSTALL_NO_FORK   => 1,
    );

    if ($params{trace}) { $ENV{QDB_INSTALL_EXTERNAL_TRACE} = $params{trace} }
    else                { delete $ENV{QDB_INSTALL_EXTERNAL_TRACE} }

    # Private temp dir per child: an install parent leaves through POSIX::_exit,
    # which skips Test2::IPC's sweep.
    my $dir = "$tmp/run-" . ++$run_id;
    mkdir($dir) or die "Could not create '$dir': $!";
    $ENV{$_} = $dir for qw/TMPDIR TEMP TMP/;

    my $status;
    my ($stdout, $stderr) = capture { system($^X, @inc, $0); $status = $? };

    return {stdout => $stdout, stderr => $stderr, exit => $status >> 8, tmpdir => $dir};
}

subtest passing_child_says_nothing => sub {
    my $trace = "$tmp/trace-pass";
    my $got   = run_fixture(mode => 'pass', trace => $trace);

    is($got->{exit}, 0, "Passing child exits 0");
    like($got->{stdout}, qr/^ok 1 - Subtest: SQLite install: system$/m, "Child's own TAP reached the harness");
    unlike($got->{stderr}, qr/isolated SQLite process/, "No diagnostics for a child that exited cleanly");

    # Two lines exactly: a longer earlier phase must not leave a tail.
    my @recorded = split(/\n/, slurp($trace));
    like($recorded[0], qr/^phase: install body returned$/,       "Trace records the final phase");
    like($recorded[1], qr/^last Test2 context at .+ line \d+$/,  "Trace records the last location");
    is(scalar(@recorded), 2, "And nothing else");
};

subtest death_before_any_result => sub {
    my $trace = "$tmp/trace-early";
    my $got   = run_fixture(mode => 'abort_before_result', trace => $trace);

    is($got->{exit}, 255, "Mirrors the child's exit status");

    # The shape this reporting exists for: the harness gets no result and no plan.
    unlike($got->{stdout}, qr/^(?:not )?ok \d/m, "Child produced no top-level result");
    unlike($got->{stdout}, qr/^1\.\./m,          "Child produced no plan");

    like($got->{stderr}, qr/isolated SQLite process exited 255 \(status 65280\)/, "Reports exit and raw status");

    # No Test2 context was ever released here, so the phase is the only evidence.
    like($got->{stderr}, qr/child got as far as: phase: running the install body/, "Phase names the body");
    unlike($got->{stderr}, qr/has not run yet|body returned/, "Does not claim the body never ran, or finished");
};

subtest death_after_a_result => sub {
    my $trace = "$tmp/trace-late";
    my $got   = run_fixture(mode => 'abort_after_result', trace => $trace);

    is($got->{exit}, 255, "Mirrors the child's exit status");
    like($got->{stderr}, qr/child got as far as: phase: running the install body/, "Reports the phase");
    like(
        $got->{stderr},
        qr/child got as far as: last Test2 context at \Q$0\E line \d+/,
        "Reports where the child last was, in the file that died",
    );
};

subtest any_exit_code_is_reported => sub {
    my $got = run_fixture(mode => 'odd_exit_code', trace => "$tmp/trace-exit");

    is($got->{exit}, 42, "Mirrors whatever code the child used");
    like($got->{stderr}, qr/isolated SQLite process exited 42 /, "Reports it");
};

subtest exception_in_body_is_left_alone => sub {
    my $got = run_fixture(mode => 'die_in_body', trace => "$tmp/trace-die");

    # The subtest reports the exception; diagnostics must not replace that.
    is($got->{exit}, 1, "Failure count, not 255");
    like($got->{stdout}, qr/^not ok 1 - Subtest: SQLite install: system$/m, "Child reported a normal failing result");
    like($got->{stderr}, qr/Caught exception in subtest: boom in body/, "Child reported the exception");
    like($got->{stderr}, qr/isolated SQLite process exited 1 /, "Parent still names the exit status");

    unlike($got->{stderr}, qr/install body returned/, "A body that threw is not reported as finished");
    like($got->{stderr}, qr/phase: install body did not return normally/, "Phase says the body stopped");
};

subtest stale_trace_content_is_not_attributed_to_this_run => sub {
    my $trace = "$tmp/trace-stale";

    open(my $fh, '>', $trace) or die "Could not seed the trace: $!";
    print $fh "phase: LEFTOVER FROM AN EARLIER RUN\n";
    close($fh);

    # The child never opens the trace, so only the parent's emptying can keep
    # the old content out of this report.
    my $got = run_fixture(mode => 'abort_before_install', trace => $trace);

    is($got->{exit}, 255, "Child died before the machinery ran");
    unlike($got->{stderr}, qr/LEFTOVER/, "Stale content is not reported as this run's progress");
    like($got->{stderr}, qr/no progress was recorded by the child/, "Says nothing was recorded instead");
};

subtest a_signalled_child_is_not_called_an_exit => sub {
    skip_all "No POSIX signals on $^O" if $^O eq 'MSWin32';

    my $got = run_fixture(mode => 'signal_death', trace => "$tmp/trace-signal");

    is($got->{exit}, 128 + 9, "Mirrors the signal as a shell-style status");
    like($got->{stderr}, qr/isolated SQLite process was killed by signal 9 /, "Names the signal");
    unlike($got->{stderr}, qr/exited 137/, "Does not report a code the child never exited with");
};

subtest parent_creates_its_own_trace => sub {
    # No trace parameter: the path MSWin32 takes, where the parent mints it.
    my $got = run_fixture(mode => 'abort_after_result');

    is($got->{exit}, 255, "Mirrors the child's exit status");
    like($got->{stderr}, qr/child got as far as: phase: running the install body/, "Reports the phase");
    like($got->{stderr}, qr/child got as far as: last Test2 context at \Q$0\E line \d+/, "Reports the location");
    unlike($got->{stderr}, qr/no progress was recorded/, "The child really did write the file");
};

subtest trace_file_is_cleaned_up => sub {
    # A failing mode, so breadcrumbs prove the file existed before removal.
    my $got = run_fixture(mode => 'abort_after_result');

    # readdir, not glob: glob word-splits, so a spaced path fakes a leftover.
    opendir(my $dh, $got->{tmpdir}) or die "Could not read '$got->{tmpdir}': $!";
    my @left = grep { m/^DB-QUICK-TRACE-/ } readdir($dh);
    closedir($dh);

    like($got->{stderr}, qr/child got as far as: phase: /, "The parent read the file it made");
    is(\@left, [], "And removed it");
};

subtest multi_install_children_never_share_the_trace => sub {
    my $trace = "$tmp/trace-multi";

    open(my $fh, '>', $trace) or die "Could not seed the trace: $!";
    print $fh "SEEDED, NOT THIS RUN\n";
    close($fh);

    my $got = run_fixture(mode => 'two_installs', trace => $trace);

    is($got->{exit}, 0, "Both installs ran");
    like($got->{stdout}, qr/^ok 1 - install 'one': /m, "On the captured multi-install path");
    is(slurp($trace), "SEEDED, NOT THIS RUN\n", "Which never touches the caller's trace file");
};

subtest first_phase_is_written_up_front => sub {
    # The opening phase must be on disk before anything else runs. Subprocess:
    # the callback the tracer installs can never be removed again.
    my $trace = "$tmp/trace-initial";
    my $dir   = "$tmp/probe";
    my @inc   = map { "-I$_" } grep { defined($_) && length($_) && !ref($_) } @INC;
    mkdir($dir) unless -d $dir;

    # Private temp dir: POSIX::_exit below skips Test2::IPC's cleanup.
    local %ENV = (%ENV, QDB_INSTALL_EXTERNAL_TRACE => $trace, map {($_ => $dir)} qw/TMPDIR TEMP TMP/);
    my $code = 'use QDB::Installs; use POSIX(); QDB::Installs::_trace_child_progress(); POSIX::_exit(0)';

    is(system($^X, @inc, '-e', $code), 0, "The probe ran");
    like(slurp($trace), qr/^phase: child started, body has not run yet$/m, "Opening phase reached disk unclosed");
};

subtest launch_failure_is_reported => sub {
    # MSWin32 retries a failed spawn through cmd.exe, so $? is never -1 there.
    skip_all "system() does not report a spawn failure as -1 on $^O" if $^O eq 'MSWin32';

    my $got = run_fixture(mode => 'launch_failure');

    is($got->{exit}, 255, "A parent that cannot spawn still fails");
    like($got->{stderr}, qr/isolated SQLite process could not be launched: /, "Says the spawn failed");

    # The parent made the file, no child wrote it; silence would read as broken.
    like($got->{stderr}, qr/no progress was recorded by the child/, "Says nothing was recorded");

    opendir(my $dh, $got->{tmpdir}) or die "Could not read '$got->{tmpdir}': $!";
    my @left = grep { m/^DB-QUICK-TRACE-/ } readdir($dh);
    closedir($dh);

    is(\@left, [], "The trace file is removed even when the spawn never happened");
};

done_testing;
