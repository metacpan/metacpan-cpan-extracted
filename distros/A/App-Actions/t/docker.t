use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use App::Actions::Docker;

my $dir = tempdir(CLEANUP => 1);

# Windows writes CRLF when output is redirected to a file.
sub useful_text {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/\r\n/\n/g;
    return $text;
}

# A Docker wrapper written in Perl.  It deliberately has no file extension and
# is not executable, which is how such a wrapper looks on Windows.
my $wrapper = File::Spec->catfile($dir, 'fake-docker');
open my $handle, '>', $wrapper or die $!;
print {$handle} <<'PERL';
#!/usr/bin/env perl
use strict;
use warnings;

my $command = $ARGV[0] || '';
if ($command eq '--version') {
    print "Wrapper version 1.0\n";
    exit 0;
}
if ($command eq 'fail') {
    print "failing on purpose\n";
    exit 9;
}
print join('|', @ARGV), "\n";
exit 0;
PERL
close $handle;
# On Unix this removes the execute bit; on Windows there is no execute bit and
# the missing .exe/.bat extension is what makes the file unrunnable.
chmod 0644, $wrapper;

my $docker = App::Actions::Docker->new(bin => $wrapper, quiet => 1);

my ($version, $version_rc) = $docker->capture_silent('--version');
is($version_rc, 0, 'a Perl wrapper is run with the interpreter');
is($version, "Wrapper version 1.0\n", 'the wrapper output is captured');

my ($output, $rc) = $docker->capture_silent('pull', 'alpine:3.20');
is($rc, 0, 'the wrapper receives the Docker arguments');
is($output, "pull|alpine:3.20\n", 'arguments are passed through unchanged');

my (undef, $fail_rc) = $docker->capture_silent('fail');
is($fail_rc, 9, 'a failing wrapper status is reported');

my $silent_rc = $docker->run_silent('fail');
is($silent_rc, 9, 'run_silent reports the wrapper status');

my $run_rc;
my ($stdout, $stderr) = capture {
    $run_rc = $docker->run('pull', 'perl:5.38');
};
is($run_rc, 0, 'run executes the wrapper');
like(useful_text($stdout), qr/^pull\|perl:5\.38$/m, 'run streams the wrapper output');

# The program is a file rather than -e code: Win32 Perl does not quote "-e"
# arguments containing double quotes reliably.
my $native_script = File::Spec->catfile($dir, 'native.pl');
open my $native_handle, '>', $native_script or die $!;
binmode $native_handle;
print {$native_handle} "print \"native\\n\";\n";
close $native_handle;

my $native = App::Actions::Docker->new(bin => $^X, quiet => 1);
my ($native_out, $native_rc) = $native->capture_silent($native_script);
is($native_rc, 0, 'a native executable is used directly');
is($native_out, "native\n", 'a native executable still produces output');

# Paths with spaces must reach the wrapper intact, which is the usual case for
# a Windows checkout or a Docker wrapper kept under "Program Files".
my $spaced_dir = File::Spec->catdir($dir, 'with space');
make_path($spaced_dir);
my $spaced_wrapper = File::Spec->catfile($spaced_dir, 'fake-docker');
copy($wrapper, $spaced_wrapper) or die $!;

my $spaced_docker = App::Actions::Docker->new(bin => $spaced_wrapper, quiet => 1);
my ($spaced_out, $spaced_rc) = $spaced_docker->capture_silent('--version');
is($spaced_rc, 0, 'a wrapper below a path with spaces runs');
is($spaced_out, "Wrapper version 1.0\n", 'its output is captured');

# A container that has stopped: the daemon answers with its status and the
# last lines it printed, both streams, which is what a run quotes back.
{
    my $fake = File::Spec->rel2abs(
        File::Spec->catfile(dirname(__FILE__), 'bin', 'fake-docker'),
    );

    local $ENV{FAKE_DOCKER_STATE} = tempdir(CLEANUP => 1);
    local $ENV{FAKE_CONTAINER_EXITS}  = 'svc';
    local $ENV{FAKE_CONTAINER_STATUS} = '7';
    local $ENV{FAKE_CONTAINER_LOGS}   = "out\n";
    local $ENV{FAKE_CONTAINER_ERR}    = "err\n";

    my $daemon = App::Actions::Docker->new(bin => $fake, quiet => 1);

    ok(!$daemon->container_running('run-svc-1'), 'a stopped container is not running');
    is($daemon->container_exit_code('run-svc-1'), 7, 'its exit status is read');
    is($daemon->container_log_text('run-svc-1'), "out\nerr\n",
        'its last output is returned with standard error merged in');

    {
        # No output at all is said by leaving the variables out.  A test that
        # sets them to an empty string gets the same thing on Unix, but Windows
        # cannot hold an empty environment variable, so absence is the form
        # that works on both.
        local $ENV{FAKE_CONTAINER_LOGS};
        local $ENV{FAKE_CONTAINER_ERR};

        is($daemon->container_log_text('run-svc-1'), '',
            'a stopped container that printed nothing yields no quotation');
    }

    ok($daemon->container_running('run-job-1'), 'a running container is running');
    is($daemon->container_exit_code('run-job-1'), 0, 'a running container has status 0');
    is($daemon->container_status('run-job-1'), 'running', 'a running container reports its state');
    is($daemon->container_restart_count('run-job-1'), 0,
        'a container that has stayed up has not been restarted');
    is($daemon->container_log_text('run-job-1'), '',
        'a running container has no log of its own to quote');

    is($daemon->container_status('run-svc-1'), 'exited',
        'a stopped container reports the state it stopped in');

    # A restart policy keeps a container going, and the count is what says so:
    # the daemon reports it as running between attempts.
    {
        local $ENV{FAKE_CONTAINER_RESTARTS} = 'run-loop-1';
        local $ENV{FAKE_RESTART_COUNT}      = '4';

        is($daemon->container_status('run-loop-1'), 'running',
            'a restarting container is running between attempts');
        is($daemon->container_restart_count('run-loop-1'), 4,
            'the restart count is read');
    }

    # A container caught between attempts is reported as restarting rather
    # than as running.
    {
        local $ENV{FAKE_CONTAINER_RESTARTS} = 'run-loop-2';
        local $ENV{FAKE_CONTAINER_STATE}    = 'restarting';

        is($daemon->container_status('run-loop-2'), 'restarting',
            'a container between attempts reports that it is restarting');
        is($daemon->container_restart_count('run-loop-2'), 1,
            'a restart count defaults to one attempt');
    }

    # A start the daemon refuses keeps what it said: the message is the only
    # account of the failure, so it is returned with the status rather than
    # discarded the way a quiet run discards it.
    {
        local $ENV{FAKE_START_FAILURE} = 'run-job-1';
        local $ENV{FAKE_START_ERROR}   = "docker: Error response from daemon: No such image: scratch:latest\n";

        my ($said, $status) = $daemon->container_start_captured(
            '--name', 'run-job-1', 'scratch:latest',
        );
        is($status, 125, 'a refused start reports the daemon status');
        is($said, "docker: Error response from daemon: No such image: scratch:latest\n",
            'the daemon message is returned, not written to the streams');
    }

    # A container that has already been removed answers nothing, and that is
    # not the same as exiting 0.
    {
        local $ENV{FAKE_INSPECT_FAILURE} = 1;
        ok(!defined $daemon->container_exit_code('run-svc-1'),
            'a status the daemon cannot read is undef rather than a guess');
        ok(!defined $daemon->container_status('run-svc-1'),
            'a state the daemon cannot read is undef rather than a guess');
        ok(!defined $daemon->container_restart_count('run-svc-1'),
            'a restart count the daemon cannot read is undef rather than 0');
    }
}

my $missing = App::Actions::Docker->new(bin => File::Spec->catfile($dir, 'absent'), quiet => 1);
my (undef, $missing_rc) = $missing->capture_silent('--version');
isnt($missing_rc, 0, 'a missing Docker command is reported');

# When one secret contains another the longer one must be redacted first, or
# the rest of it is printed ("abc" then "abcdef" left "***def").
{
    my $docker = App::Actions::Docker->new(
        dry_run => 1, quiet => 1,
        secrets => { SHORT => 'abc', LONG => 'abcdef' },
    );
    is($docker->redact('token=abcdef and abc'), 'token=*** and ***',
        'overlapping secrets are redacted completely');
}

done_testing;
