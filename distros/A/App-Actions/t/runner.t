use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use File::Basename qw(dirname);
use Time::HiRes ();
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir);

use App::Actions;

my $fake_docker = File::Spec->rel2abs(
    File::Spec->catfile(dirname(__FILE__), 'bin', 'fake-docker'),
);

# A run records the images it kept for "action-run cache"; keep that record in
# a temporary file so the suite never writes to the machine-wide cache.
local $ENV{ACTION_RUN_CACHE_FILE}
    = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');

# A parallel run copies its per-job logs here; keep them out of the real
# user's log directory.
local $ENV{ACTION_RUN_LOG_DIR} = File::Spec->catdir(
    tempdir(CLEANUP => 1), 'logs',
);

# Windows writes CRLF when output is redirected to a file, and several tests
# match against the end of a line.
sub useful_text {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/\r\n/\n/g;
    return $text;
}

# Read a file without any newline translation, the way a Linux container sees
# it.
sub slurp_bytes {
    my ($path) = @_;

    open my $handle, '<', $path or die $!;
    binmode $handle;
    local $/;
    my $bytes = <$handle>;
    close $handle;

    return defined $bytes ? $bytes : '';
}

# A run with keep => 1 prints the temporary directory it retained.
sub kept_temp_dir {
    my ($result) = @_;

    my ($dir) = $result->{stdout} =~ /^ {2}temporary directory (.+)$/m;
    return $dir;
}

sub remove_kept_dir {
    my ($result) = @_;

    my $dir = kept_temp_dir($result);
    remove_tree($dir) if defined $dir && -d $dir;

    return;
}

# Each run writes its own log, so two runs that share a daemon state - the
# cache test below - do not read each other's commands.
my $docker_log_count = 0;

# The helpers' options mix the fake Docker's knobs (fake_*), the files to
# write into the project and the preflight's json flag with the options
# App::Actions takes.  App::Actions
# rejects an option it does not know, so only its own are passed on.
sub actions_options {
    my (%options) = @_;

    return map { $_ => $options{$_} }
        grep { !/\Afake_/ && $_ ne 'json' && $_ ne 'files' } keys %options;
}

# The contents of a file, or '' when there is none.
sub slurp_if_present {
    my ($path) = @_;

    return '' unless -f $path;
    open my $handle, '<', $path or die "cannot read $path: $!";
    local $/;
    my $text = <$handle>;
    close $handle;

    return defined $text ? $text : '';
}

sub run_workflow {
    my ($yaml, %options) = @_;

    my $project = tempdir(CLEANUP => 1);
    make_path(File::Spec->catdir($project, '.github', 'workflows'));
    my $workflow_file = File::Spec->catfile($project, '.github', 'workflows', 'test.yml');

    open my $handle, '>', $workflow_file or die $!;
    print {$handle} $yaml;
    close $handle;

    for my $path (sort keys %{ $options{files} || {} }) {
        my $target = File::Spec->catfile($project, split m{/}, $path);
        make_path(dirname($target));
        open my $file, '>', $target or die $!;
        print {$file} $options{files}{$path};
        close $file;
    }

    # A caller that runs the same workflow twice passes one state directory,
    # which is what a developer's daemon is between two invocations of the
    # command: the images the first run pulled are already there for the second.
    my $state = delete $options{state} || tempdir(CLEANUP => 1);
    my $log   = File::Spec->catfile($state, 'docker-' . ++$docker_log_count . '.log');

    local $ENV{FAKE_DOCKER_STATE} = $state;
    local $ENV{FAKE_DOCKER_LOG}   = $log;
    local $ENV{FAKE_DOCKER_ARGV_LOG} = "$log.argv";
    local $ENV{FAKE_NO_BASH}      = $options{fake_no_bash} ? 1 : 0;
    local $ENV{FAKE_NO_SUDO}      = $options{fake_no_sudo} ? 1 : 0;
    local $ENV{FAKE_NO_NODE}      = $options{fake_no_node} ? 1 : 0;
    local $ENV{FAKE_OS_TYPE}      = $options{fake_os_type};
    local $ENV{FAKE_ENTRY_COUNT}  = $options{fake_entry_count};
    local $ENV{FAKE_PULL_FAILURE} = $options{fake_pull_failure};
    local $ENV{FAKE_PULL_SLEEP}   = $options{fake_pull_sleep};
    local $ENV{FAKE_PULL_TIMING}  = $options{fake_pull_timing} ? 1 : 0;
    local $ENV{FAKE_RUN_NEEDS_IMAGE} = $options{fake_run_needs_image} ? 1 : 0;
    local $ENV{FAKE_CONTAINER_EXITS}  = $options{fake_container_exits};
    local $ENV{FAKE_CONTAINER_RESTARTS}  = $options{fake_container_restarts};
    local $ENV{FAKE_RESTART_COUNT}       = $options{fake_restart_count};
    local $ENV{FAKE_CONTAINER_STATE}     = $options{fake_container_state};
    local $ENV{FAKE_RESTART_AFTER_EXEC}  = $options{fake_restart_after_exec} ? 1 : 0;
    local $ENV{FAKE_CONTAINER_STATUS} = $options{fake_container_status};
    local $ENV{FAKE_CONTAINER_LOGS}   = $options{fake_container_logs};
    local $ENV{FAKE_CONTAINER_ERR}    = $options{fake_container_err};
    local $ENV{FAKE_START_FAILURE}    = $options{fake_start_failure};
    local $ENV{FAKE_START_ERROR}      = $options{fake_start_error};
    local $ENV{FAKE_START_EXIT}       = $options{fake_start_exit};
    local $ENV{FAKE_INSPECT_FAILURE}  = $options{fake_inspect_failure} ? 1 : 0;

    my $actions = App::Actions->new(
        workflow_file => $workflow_file,
        project_dir   => $project,
        docker_bin    => $fake_docker,
        image         => 'ubuntu:latest',
        actions_options(%options),
    );

    my ($stdout, $stderr, $exit) = capture { $actions->run };
    $stdout = useful_text($stdout);
    $stderr = useful_text($stderr);

    my ($log_text, $argv_text) = map { slurp_if_present($_) } ($log, "$log.argv");

    return {
        stdout   => $stdout,
        stderr   => $stderr,
        exit     => $exit,
        log      => $log_text,
        argv_log => $argv_text,
        project  => $project,
        state    => $state,
    };
}

# A preflight run returns its outcome as data rather than reporting it, so a
# CI job can assert on the images instead of reading the pulls.
sub preflight_workflow {
    my ($yaml, %options) = @_;

    my $project = tempdir(CLEANUP => 1);
    make_path(File::Spec->catdir($project, '.github', 'workflows'));
    my $workflow_file = File::Spec->catfile($project, '.github', 'workflows', 'test.yml');

    open my $handle, '>', $workflow_file or die $!;
    print {$handle} $yaml;
    close $handle;

    my $state = tempdir(CLEANUP => 1);
    my $log   = File::Spec->catfile($state, 'docker.log');

    local $ENV{FAKE_DOCKER_STATE} = $state;
    local $ENV{FAKE_DOCKER_LOG}   = $log;
    local $ENV{FAKE_OS_TYPE}      = $options{fake_os_type};
    local $ENV{FAKE_PULL_FAILURE} = $options{fake_pull_failure};

    my $actions = App::Actions->new(
        workflow_file => $workflow_file,
        project_dir   => $project,
        docker_bin    => $fake_docker,
        image         => 'ubuntu:latest',
        actions_options(%options),
    );

    my $result;
    my ($stdout, $stderr) = capture {
        $result = $actions->preflight(json => $options{json});
    };

    my $log_text = '';
    if (-f $log) {
        open my $log_handle, '<', $log or die $!;
        local $/;
        $log_text = <$log_handle>;
        close $log_handle;
        $log_text = '' unless defined $log_text;
    }

    return {
        result  => $result,
        stdout  => useful_text($stdout),
        stderr  => useful_text($stderr),
        log     => $log_text,
        project => $project,
    };
}

my $matrix_yaml = <<'YAML';
name: Matrix
on: push
jobs:
  test:
    name: Perl ${{ matrix.perl }}
    runs-on: ubuntu-latest
    strategy:
      matrix:
        perl: ['5.38', '5.40']
    container:
      image: perl:${{ matrix.perl }}
    steps:
      - uses: actions/checkout@v4
      - name: Set files
        run: |
          FAKE_ENV: FROM_STEP=one
          FAKE_PATH: /opt/fake/bin
      - name: Use files
        run: echo $FROM_STEP
YAML

my $matrix = run_workflow($matrix_yaml);

is($matrix->{exit}, 0, 'matrix workflow succeeds');
like($matrix->{stdout}, qr/Perl 5\.38/, 'first matrix job ran');
like($matrix->{stdout}, qr/Perl 5\.40/, 'second matrix job ran');
like($matrix->{stdout}, qr/Set files/, 'step names are shown');
like($matrix->{log}, qr/^pull\t/m, 'missing images are pulled');
like($matrix->{log}, qr/\t-e\tFROM_STEP=one\t/, 'GITHUB_ENV updates reach later steps');
like($matrix->{log}, qr/\t-e\tPATH=\/opt\/fake\/bin:/, 'GITHUB_PATH updates reach later steps');
like($matrix->{log}, qr/^rm\t-f\t/m, 'containers are removed');
like($matrix->{log}, qr/^network\trm\t/m, 'networks are removed');
unlike($matrix->{log}, qr/^image\trm\t/m,
    'the images the run pulled are kept rather than removed');

# The kept images are a cache, not leftovers: a second run of the same
# workflow against the same daemon downloads nothing at all.
my $cache_state = tempdir(CLEANUP => 1);
my $first_cached  = run_workflow($matrix_yaml, state => $cache_state);
my $second_cached = run_workflow($matrix_yaml, state => $cache_state);

is($first_cached->{exit}, 0, 'the first run of a workflow succeeds');
is($second_cached->{exit}, 0, 'the second run of the same workflow succeeds');
like($first_cached->{log}, qr/^pull\tperl:5\.38$/m,
    'the first run downloads the job image');
unlike($second_cached->{log}, qr/^pull\t/m,
    'the second run downloads nothing, because the image was kept');

# A matrix of independent jobs runs beside each other, so the wall clock shows
# the overlap rather than the sum of the jobs.
my $slow_matrix = <<'YAML';
name: Slow matrix
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        n: [one, two, three]
    steps:
      - run: sleep 1
      - run: echo "job ${{ matrix.n }}"
YAML

SKIP: {
    skip 'jobs run one at a time where fork() is not reliable', 8
        if $^O eq 'MSWin32';

    my $started = Time::HiRes::time();
    my $serial = run_workflow($slow_matrix);
    my $serial_seconds = Time::HiRes::time() - $started;

    $started = Time::HiRes::time();
    my $together = run_workflow($slow_matrix, parallel => 3);
    my $parallel_seconds = Time::HiRes::time() - $started;

    is($together->{exit}, 0, 'a matrix run three jobs at a time succeeds');
    ok(
        $parallel_seconds < $serial_seconds - 1,
        sprintf(
            'the jobs overlapped: %.2fs three at a time, %.2fs one at a time',
            $parallel_seconds, $serial_seconds,
        ),
    );
    like(
        $together->{stdout},
        qr/^\[test \(n=one\)\] job one$/m,
        'each line of a job\'s output names the job it came from',
    );

    # The terminal shows interleaved prefixed lines, so each job's own log is
    # kept where it can be read in order afterwards.
    my ($log_dir) = $together->{stdout} =~ /^Job logs kept in (.+)$/m;
    ok(defined $log_dir, 'a parallel run says where it kept the job logs');

    SKIP: {
        skip 'the run did not print a log directory', 4 unless defined $log_dir;

        ok(-d $log_dir, 'the directory the run named exists');

        my @files = sort glob(File::Spec->catfile($log_dir, '*.log'));
        is(scalar @files, 3, 'one log was kept for each job of the matrix');

        my %logs;
        for my $file (@files) {
            open my $handle, '<', $file or die "Unable to read '$file': $!";
            local $/;
            $logs{$file} = do { <$handle> };
            close $handle;
        }

        my ($one) = grep { $logs{$_} =~ /\bjob one\b/ } keys %logs;
        my ($two) = grep { $logs{$_} =~ /\bjob two\b/ } keys %logs;
        ok(defined $one && defined $two,
            'the kept logs name the job each one came from');
        unlike($logs{$one} || '', qr/^\[test /m,
            'a kept log is the job\'s own output, without the prefix');
    }
}

# A sequential run prints one job at a time, so there is nothing to tell apart
# afterwards and no log copies are made.
{
    local $ENV{ACTION_RUN_LOG_DIR} = File::Spec->catdir(
        tempdir(CLEANUP => 1), 'logs',
    );

    my $serial_only = run_workflow($slow_matrix);
    is($serial_only->{exit}, 0, 'a sequential matrix succeeds');
    ok(!-e $ENV{ACTION_RUN_LOG_DIR},
        'a run that is not parallel keeps no log copies');
}

# --quiet suppresses the note, not the logs: they are still there for whoever
# needs to read what the jobs said.
SKIP: {
    skip 'jobs run one at a time where fork() is not reliable', 4
        if $^O eq 'MSWin32';

    local $ENV{ACTION_RUN_LOG_DIR} = File::Spec->catdir(
        tempdir(CLEANUP => 1), 'logs',
    );

    my $silent = run_workflow($slow_matrix, parallel => 2, quiet => 1);
    is($silent->{exit}, 0, 'a quiet parallel run succeeds');
    unlike($silent->{stdout}, qr/Job logs kept in/,
        'a quiet run does not print where the logs are');

    my @directories = glob(File::Spec->catdir($ENV{ACTION_RUN_LOG_DIR}, '*'));
    is(scalar @directories, 1, 'a quiet run still keeps one directory of logs');
    my @files = glob(File::Spec->catfile($directories[0] || '', '*.log'));
    is(scalar @files, 3, 'a quiet run still keeps one log per job');
}

# A run that goes one job at a time has no other jobs to tell apart, so its
# output is left as the job printed it.
unlike($matrix->{stdout}, qr/^\[test /m,
    'a sequential run prints no per-job prefixes');

# One job's failure does not let the rest of the matrix start: what was not
# already running is skipped, as a sequential run with fail-fast skips it.
my $fail_fast_matrix = <<'YAML';
name: Fail fast
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        n: [one, bad, three, four]
    steps:
      - run: |
          if [ "${{ matrix.n }}" = bad ]; then exit 7; fi
          sleep 1
YAML

SKIP: {
    skip 'jobs run one at a time where fork() is not reliable', 4
        if $^O eq 'MSWin32';

    my $failing = run_workflow($fail_fast_matrix, parallel => 2);

    is($failing->{exit}, 1, 'a failed job fails a parallel matrix');

    my ($failed_dir) = $failing->{stdout} =~ /^Job logs kept in (.+)$/m;
    ok(defined $failed_dir && -d $failed_dir,
        'the logs are kept after a job failed');
    like(
        $failing->{stdout},
        qr/^==> Job: test \(n=three\) \(skipped by fail-fast\)$/m,
        'a job that had not started is skipped when the one beside it failed',
    );
    like(
        $failing->{stdout},
        qr/^ {2}test \(n=four\)\s+skipped$/m,
        'the summary records the job fail-fast skipped',
    );
}

# A step is a program, so what it prints comes back in the run.  The fake
# daemon runs step scripts with the host's shell, mapping the paths docker exec
# was given back to the host, so this covers that path without a daemon - the
# same ground t/self_test.t covers through the command a user runs.  A host
# with no POSIX shell emulates the script instead, so there is nothing to quote
# there.
my $echoed = run_workflow(<<'YAML');
name: Echo
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Say something
        run: echo hello-from-a-step
YAML

is($echoed->{exit}, 0, 'a workflow whose step prints succeeds');
like($echoed->{log}, qr/^exec\t/m, 'the step runs in the job container');

SKIP: {
    skip 'the fake daemon cannot execute step scripts on this host', 1
        if $^O eq 'MSWin32';

    like($echoed->{stdout}, qr/^hello-from-a-step$/m,
        'what the step printed is what the run sees');
}

my $failure = run_workflow(<<'YAML');
name: Failure
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Fail
        run: |
          FAKE_EXIT: 7
YAML

is($failure->{exit}, 1, 'failing workflow exits 1');
like($failure->{stderr}, qr/step exited with status 7/, 'step failure is reported');
like($failure->{log}, qr/^rm\t-f\t/m, 'failed runs still clean up containers');

my $skipped = run_workflow(<<'YAML');
name: Windows only
on: push
jobs:
  test:
    runs-on: windows-latest
    steps:
      - run: echo nope
YAML

is($skipped->{exit}, 0, 'workflow with only unsupported jobs exits 0');
like($skipped->{stdout}, qr/skipped: runs-on 'windows-latest' is not Linux/,
    'unsupported runner is explained');

my $dry_run = run_workflow(<<'YAML', dry_run => 1);
name: Dry run
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo hello
YAML

is($dry_run->{exit}, 0, 'dry run succeeds without Docker');
like($dry_run->{stdout}, qr/\[dry-run\]/, 'dry run prints Docker commands');

# An explain run is the same dry run with the containers as its output: it
# needs no daemon at all, which the missing Docker command below proves, and
# says what each container would be told to run.
{
    my $absent = File::Spec->catfile(tempdir(CLEANUP => 1), 'absent-docker');

    my $explained = run_workflow(
        <<'YAML',
name: Explained
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    services:
      helper:
        image: postgres:16
        options: --restart always --entrypoint /bin/sh
    steps:
      - uses: docker://hello-world:latest
        with:
          args: /hello
      - run: echo hi
YAML
        explain    => 1,
        docker_bin => $absent,
    );

    is($explained->{exit}, 0, 'an explain run succeeds without a Docker daemon');
    is($explained->{log}, '', 'an explain run starts nothing');

    like($explained->{stdout}, qr/^==> Service 'helper' of job 'test'$/m,
        'the service container is reported');
    like(
        $explained->{stdout},
        qr/^ {4}container {2}action-run-\S+-svc-test-0-helper$/m,
        'the service container is named',
    );
    like($explained->{stdout}, qr/^ {4}entrypoint \/bin\/sh$/m,
        'the entrypoint the service options ask for is reported');
    like($explained->{stdout}, qr/^ {4}command {4}\(the image's own\)$/m,
        'a service with no command of its own says so, which is what diagnoses it');

    like($explained->{stdout}, qr/^==> Job 'test'$/m, 'the job container is reported');
    like($explained->{stdout}, qr/^ {4}image {6}alpine:3\.20$/m,
        'the job container image is reported');
    like($explained->{stdout}, qr/^ {4}entrypoint \/bin\/sh$/m,
        'the job container entrypoint is reported');
    like(
        $explained->{stdout},
        qr/^ {4}command {4}-c 'while :; do sleep 3600; done'$/m,
        'the job container command is reported',
    );

    like(
        $explained->{stdout},
        qr/^==> Action 'docker:\/\/hello-world:latest' in job 'test'$/m,
        'the action container is reported',
    );
    like($explained->{stdout}, qr/^ {4}command {4}\/hello$/m,
        'the argument the action is given is reported');

    unlike($explained->{stdout}, qr/^\[dry-run\]/m,
        'an explain run lists containers, not Docker commands');
}

my $outputs = run_workflow(<<'YAML');
name: Outputs
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Build
        id: build
        run: |
          FAKE_OUTPUT: result=ok
      - name: Use output
        if: steps.build.outputs.result == 'ok'
        run: echo yes
YAML

is($outputs->{exit}, 0, 'step outputs workflow succeeds');
like($outputs->{log}, qr/step-2\.sh/, 'step using an output ran');
like($outputs->{log}, qr/GITHUB_OUTPUT/, 'GITHUB_OUTPUT is passed to steps');

my $needs = run_workflow(<<'YAML');
name: Needs
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Build
        run: |
          FAKE_EXIT: 1
  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Test
        run: echo test
  always:
    needs: build
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Always
        run: |
          FAKE_SUMMARY: always ran
YAML

is($needs->{exit}, 1, 'failed dependency fails the workflow');
like($needs->{stdout}, qr/Job: test \(skipped\)/, 'dependent job is skipped');
like($needs->{stdout}, qr/Job: always/, 'always() job runs after a failed dependency');
like($needs->{stdout}, qr/always ran/, 'always() step summary is printed');

my $services = run_workflow(<<'YAML');
name: Services
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: secret
        ports:
          - 5432:5432
    steps:
      - run: echo hello
YAML

is($services->{exit}, 0, 'workflow with services succeeds');
like($services->{log}, qr/--network-alias\tpostgres/, 'service is attached to the job network');
like($services->{log}, qr/\t-e\tPOSTGRES_PASSWORD=secret\t/, 'service environment is passed');
like($services->{log}, qr/\t-p\t5432:5432\t/, 'service ports are published');
my @service_removals = ($services->{log} =~ /^rm\t-f\t/gm);
is(scalar @service_removals, 2, 'job and service containers are removed');

# A service container that stops instead of serving is an infrastructure
# failure, and "did not stay running" on its own says nothing about why: the
# status it exited with and what it printed are what tell a bad command from a
# bad image or a port already in use.
my $stopped_service = run_workflow(
    <<'YAML',
name: Stopped service
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    services:
      helper:
        image: postgres:16
    steps:
      - run: echo never
YAML
    fake_container_exits  => '-svc-',
    fake_container_status => 7,
    fake_container_logs   => "starting up\nport 5432 is already in use\n",
    fake_container_err    => "fatal: could not bind\n",
);

is($stopped_service->{exit}, 2, 'a service that stops is an infrastructure failure');
like(
    $stopped_service->{stderr},
    qr/^action-run: Service 'helper' did not stay running \(exit 7\);/m,
    'the failure names the service and the status it exited with',
);
like($stopped_service->{stderr}, qr/^ {2}starting up$/m,
    'the service output is quoted');
like($stopped_service->{stderr}, qr/^ {2}port 5432 is already in use$/m,
    'the last lines are quoted, not the first ones');
like($stopped_service->{stderr}, qr/^ {2}fatal: could not bind$/m,
    'the service standard error is quoted too');
unlike($stopped_service->{stderr}, qr/\s+at\s+\S+ line \d+/,
    'the failure reads as a sentence, not a source location');
unlike($stopped_service->{stdout}, qr/--- Step:/,
    'no step runs when its service has stopped');

# A service that said nothing at all is reported as silent rather than being
# left with an empty quotation.
my $silent_service = run_workflow(
    <<'YAML',
name: Silent service
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    services:
      helper:
        image: postgres:16
    steps:
      - run: echo never
YAML
    fake_container_exits => '-svc-',
    fake_container_logs  => '',
);

is($silent_service->{exit}, 2, 'a silent service is still a failure');
like(
    $silent_service->{stderr},
    qr/did not stay running \(exit 1\); it printed nothing/m,
    'a service that printed nothing says so',
);

# A container the daemon will not describe, because it has already gone, is
# not the same as one that exited 0: the message says the status is unknown
# rather than inventing one.
my $unreadable = run_workflow(
    <<'YAML',
name: Unreadable service
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    services:
      helper:
        image: postgres:16
    steps:
      - run: echo never
YAML
    fake_container_exits => '-svc-',
    fake_container_logs  => "gone before it could be asked\n",
    fake_inspect_failure => 1,
);

is($unreadable->{exit}, 2, 'an unreadable service status is a failure');
like(
    $unreadable->{stderr},
    qr/did not stay running \(its exit status could not be read\); its last output was:/m,
    'a status that cannot be read is reported as unknown, not guessed',
);
like($unreadable->{stderr}, qr/^ {2}gone before it could be asked$/m,
    'the output is still quoted when the status is unknown');

# A service whose restart policy brings it back is not serving, even though
# Docker reports it as running between attempts: asking only whether it is
# running would let the steps talk to a container that keeps dying.
my $restarting_service = run_workflow(
    <<'YAML',
name: Restarting service
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    services:
      helper:
        image: postgres:16
        options: --restart always
    steps:
      - run: echo never
YAML
    fake_container_restarts => '-svc-',
    fake_restart_count      => 3,
    fake_container_logs     => "starting up\nport 5432 is already in use\n",
);

is($restarting_service->{exit}, 2, 'a service that keeps restarting is an infrastructure failure');
like(
    $restarting_service->{stderr},
    qr/^action-run: Service 'helper' is restarting \(restart count 3\);/m,
    'the failure names the service and how often it was restarted',
);
like($restarting_service->{stderr}, qr/^ {2}port 5432 is already in use$/m,
    'the output the restarts repeat is quoted');
unlike($restarting_service->{stdout}, qr/--- Step:/,
    'no step runs against a service that is restarting');
unlike($restarting_service->{log}, qr/^run\t-d\t.*-job-/m,
    'no job container is started for a restarting service');
like($restarting_service->{log}, qr/^rm\t-f\taction-run-\S+-svc-\S+$/m,
    'the restarting service is removed');

# A service caught between attempts is described as restarting rather than as
# one that never stayed up, which is what its restart policy is doing.
my $backing_off = run_workflow(
    <<'YAML',
name: Backing off service
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    services:
      helper:
        image: postgres:16
        options: --restart always
    steps:
      - run: echo never
YAML
    fake_container_restarts => '-svc-',
    fake_restart_count      => 0,
    fake_container_state    => 'restarting',
    fake_container_logs     => "could not connect to the server\n",
);

is($backing_off->{exit}, 2, 'a service backing off is an infrastructure failure');
like(
    $backing_off->{stderr},
    qr/^action-run: Service 'helper' is restarting; its last output was:/m,
    'a service between attempts is described as restarting',
);
like($backing_off->{stderr}, qr/^ {2}could not connect to the server$/m,
    'the output that made it give up is quoted');

# A restart that happens while the job runs is caught too: the service was
# serving when it was started, so only the check after the steps can see it.
my $restarted_later = run_workflow(
    <<'YAML',
name: Restarted during the run
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    services:
      helper:
        image: postgres:16
        options: --restart always
    steps:
      - run: echo the step runs first
YAML
    fake_container_restarts   => '-svc-',
    fake_restart_count        => 2,
    fake_restart_after_exec   => 1,
    fake_container_logs       => "server closed the connection unexpectedly\n",
);

is($restarted_later->{exit}, 2, 'a service that restarts during the run fails it');
like($restarted_later->{stdout}, qr/--- Step: /,
    'the step had already run when the restart was noticed');
like(
    $restarted_later->{stderr},
    qr/^action-run: Service 'helper' is restarting \(restart count 2\);/m,
    'the late restart is reported with its count',
);
like($restarted_later->{stderr}, qr/^ {2}server closed the connection unexpectedly$/m,
    'the late restart quotes what the container printed');

# The job container is held to the same standard.  A container that stops
# before any step has run is an infrastructure failure, and its status and last
# output are what tell a bad image from a bad entrypoint or a missing command.
my $stopped_job = run_workflow(
    <<'YAML',
name: Stopped job container
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    steps:
      - run: echo never
YAML
    fake_container_exits  => '-job-',
    fake_container_status => 7,
    fake_container_logs   => "could not set up the runner\n",
    fake_container_err    => "fatal: no such entrypoint\n",
);

is($stopped_job->{exit}, 2, 'a job container that stops is an infrastructure failure');
like(
    $stopped_job->{stderr},
    qr/^action-run: Job container '\S+' did not stay running \(exit 7\);/m,
    'the failure names the job container and its exit status',
);
like($stopped_job->{stderr}, qr/^ {2}could not set up the runner$/m,
    'the job container output is quoted');
like($stopped_job->{stderr}, qr/^ {2}fatal: no such entrypoint$/m,
    'the job container standard error is quoted too');
unlike($stopped_job->{stderr}, qr/\s+at\s+\S+ line \d+/,
    'the failure reads as a sentence, not a source location');
unlike($stopped_job->{stdout}, qr/--- Step:/,
    'no step runs in a job container that stopped');
like(
    $stopped_job->{log},
    qr/^rm\t-f\taction-run-\S+-job-\S+$/m,
    'the job container that stopped is removed',
);

# A job container that printed nothing is reported as silent rather than left
# with an empty quotation.
my $silent_job = run_workflow(
    <<'YAML',
name: Silent job container
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    steps:
      - run: echo never
YAML
    fake_container_exits => '-job-',
    fake_container_logs  => '',
);

is($silent_job->{exit}, 2, 'a silent job container is still a failure');
like(
    $silent_job->{stderr},
    qr/Job container '\S+' did not stay running \(exit 1\); it printed nothing/m,
    'a job container that printed nothing says so',
);

# A container the daemon refuses to start has no output of its own to quote:
# the daemon's message is the only account of the failure, and it names the
# part of the request it could not use.  Quoting it back with that name is what
# tells a missing image from an entrypoint the image does not have.
my $refused_job = run_workflow(
    <<'YAML',
name: Refused job container
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    steps:
      - run: echo never
YAML
    fake_start_failure => '-job-',
    fake_start_error   => "Unable to find image 'alpine:3.20' locally\n"
        . "docker: Error response from daemon: No such image: alpine:3.20\n",
);

is($refused_job->{exit}, 2,
    'a job container the daemon will not start is an infrastructure failure');
like(
    $refused_job->{stderr},
    qr/^action-run: Job container '\S+' could not be started \(exit 125\); at fault: the image 'alpine:3\.20'; the daemon said:$/m,
    'the failure names the container, the status and the image at fault',
);
like($refused_job->{stderr}, qr/^ {2}Unable to find image 'alpine:3\.20' locally$/m,
    'what the daemon said is quoted');
like(
    $refused_job->{stderr},
    qr/^ {2}docker: Error response from daemon: No such image: alpine:3\.20$/m,
    'every line the daemon said is quoted, not just the first',
);
unlike($refused_job->{stderr}, qr/\s+at\s+\S+ line \d+/,
    'the failure reads as a sentence, not a source location');
unlike($refused_job->{stdout}, qr/--- Step:/,
    'no step runs in a container that would not start');
like(
    $refused_job->{log},
    qr/^rm\t-f\taction-run-\S+-job-\S+$/m,
    'the container the daemon would not start is removed',
);

# The same status with another message is another fault: a runtime that cannot
# exec the entrypoint says so, and the entrypoint is what it names.
my $no_entrypoint = run_workflow(
    <<'YAML',
name: Job image without a shell
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: scratch:latest
    steps:
      - run: echo never
YAML
    fake_start_failure => '-job-',
    fake_start_exit    => 127,
    fake_start_error   => 'docker: Error response from daemon: failed to create task for container: '
        . 'exec: "/bin/sh": stat /bin/sh: no such file or directory: unknown.' . "\n",
);

like(
    $no_entrypoint->{stderr},
    qr/could not be started \(exit 127\); at fault: the entrypoint '\/bin\/sh'; the daemon said:$/m,
    'a missing entrypoint is named, with the status that reported it',
);
like(
    $no_entrypoint->{stderr},
    qr/^ {2}docker: Error response from daemon: .*stat \/bin\/sh: no such file or directory/m,
    'the runtime message that named it is quoted too',
);

# A daemon that said nothing, and one whose message names nothing this run can
# point at, are reported as they are rather than being given a verdict.
my $silent_start = run_workflow(
    <<'YAML',
name: Silent start failure
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    steps:
      - run: echo never
YAML
    fake_start_failure => '-job-',
    fake_start_error   => '',
);

like(
    $silent_start->{stderr},
    qr/Job container '\S+' could not be started \(exit 125\); the daemon said nothing$/m,
    'a start the daemon refused silently says so',
);
unlike($silent_start->{stderr}, qr/at fault:/,
    'no fault is invented when the daemon said nothing');

my $unrecognised_start = run_workflow(
    <<'YAML',
name: Unrecognised start failure
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    steps:
      - run: echo never
YAML
    fake_start_failure => '-job-',
    fake_start_error   => "docker: Error response from daemon: the daemon went away\n",
);

like($unrecognised_start->{stderr},
    qr/could not be started \(exit 125\); the daemon said:$/m,
    'a message that names nothing recognised is quoted without a verdict');
like($unrecognised_start->{stderr},
    qr/^ {2}docker: Error response from daemon: the daemon went away$/m,
    'the daemon output is still quoted');
unlike($unrecognised_start->{stderr}, qr/at fault:/,
    'no part of the request is blamed without the daemon naming it');

my $docker_action = run_workflow(<<'YAML');
name: Docker action
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Action
        id: action
        uses: docker://alpine:3.20
        with:
          args: FAKE_ACTION
      - name: After
        if: steps.action.outputs.result == 'ok'
        run: echo after
YAML

is($docker_action->{exit}, 0, 'docker action workflow succeeds');
like($docker_action->{log}, qr/^run\t--rm\t/m, 'docker action uses a one-shot container');
like($docker_action->{log}, qr/\t-e\tFROM_ACTION=yes\t/, 'docker action environment update is applied');
like($docker_action->{log}, qr/step-2\.sh/, 'step after docker action ran');

# A one-shot container runs a program, so what the action prints and the
# status it exits with are what the run sees.  The fake daemon runs the
# command with the host's shell, mapping the container's mounts back to it,
# which is how this is covered without a daemon; a host with no POSIX shell
# cannot do that, and the live run is the one that covers it there.
my $printing_action = run_workflow(<<'YAML');
name: Docker action output
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Print
        uses: docker://alpine:3.20
        with:
          args: echo hello-from-the-action
      - name: Through the entrypoint
        uses: docker://alpine:3.20
        with:
          entrypoint: /bin/sh
          args: -c "echo through-the-entrypoint"
YAML

is($printing_action->{exit}, 0, 'a docker action that prints succeeds');

SKIP: {
    skip 'the fake daemon cannot run a container command on this host', 2
        if $^O eq 'MSWin32';

    like($printing_action->{stdout}, qr/^hello-from-the-action$/m,
        'what the action printed is in the run');
    like($printing_action->{stdout}, qr/^through-the-entrypoint$/m,
        'the entrypoint the action names is the one that runs');
}

my $failing_action = run_workflow(<<'YAML');
name: Failing action
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Fail
        uses: docker://alpine:3.20
        with:
          args: sh -c "echo about-to-fail; exit 3"
      - name: Never
        run: echo after
YAML

SKIP: {
    skip 'the fake daemon cannot run a container command on this host', 5
        if $^O eq 'MSWin32';

    is($failing_action->{exit}, 1, 'a docker action that exits non-zero fails the run');
    like($failing_action->{stdout}, qr/^about-to-fail$/m,
        'the failing action ran, and its output came back');
    like($failing_action->{stderr}, qr/docker action exited with status 3/,
        'the failure says what the action exited with');
    unlike($failing_action->{stdout}, qr/^after$/m,
        'the step after a failed action does not run');
    like($failing_action->{log}, qr/^rm\t-f\t/m,
        'a failed action still cleans up its container');
}

my $no_bash = run_workflow(<<'YAML', fake_no_bash => 1);
name: No bash
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    steps:
      - run: echo hello
YAML

is($no_bash->{exit}, 0, 'default shell falls back to sh when bash is absent');
like($no_bash->{log}, qr/sh -e '/, 'sh is used when bash is absent');

my $no_sudo = run_workflow(<<'YAML', fake_no_sudo => 1);
name: No sudo
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    steps:
      - run: echo hello
YAML

is($no_sudo->{exit}, 0, 'workflow without sudo succeeds');
like($no_sudo->{log}, qr/\t-e\tPATH=\/github\/actions-runner\/bin:/,
    'sudo shim directory is added to PATH when sudo is absent');

my $user_no_sudo = run_workflow(<<'YAML', fake_no_sudo => 1, user => '1000:1000');
name: User no sudo
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    steps:
      - run: echo hello
YAML

is($user_no_sudo->{exit}, 0, 'workflow with --user succeeds');
unlike($user_no_sudo->{log}, qr/\t-e\tPATH=\/github\/actions-runner\/bin:/,
    'sudo shim is not added when a container user is requested');

my $explicit_bash = run_workflow(<<'YAML', fake_no_bash => 1);
name: Explicit bash
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.20
    steps:
      - run: echo hello
        shell: bash
YAML

is($explicit_bash->{exit}, 1, 'explicit bash fails when bash is absent');
like($explicit_bash->{stderr}, qr/Shell 'bash' is not available/,
    'missing explicit shell is reported');

my $strict = run_workflow(<<'YAML', strict_actions => 1);
name: Strict
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: some/unknown-action@v1
YAML

is($strict->{exit}, 1, 'strict mode fails on an unknown action');
like($strict->{stderr}, qr/skipped: remote JavaScript and composite actions are not supported/,
    'strict mode explains the unsupported action');

my $keep = run_workflow(<<'YAML', keep => 1);
name: Keep
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo hello
YAML

is($keep->{exit}, 0, 'keep workflow succeeds');
like($keep->{stdout}, qr/Kept Docker resources/, 'keep reports the resources it retained');
unlike($keep->{log}, qr/^rm\t-f\t/m, 'keep does not remove containers');
remove_kept_dir($keep);

# bash inside the container rejects scripts whose lines end in CR, so every
# file the container reads must be written with LF even when the host is
# Windows.
my $line_endings = run_workflow(<<'YAML', keep => 1);
name: Line endings
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Script
        run: |
          FAKE_ENV: FROM_STEP=one
YAML

is($line_endings->{exit}, 0, 'line ending workflow succeeds');

my $temp_dir = kept_temp_dir($line_endings);
ok(defined $temp_dir, 'the kept temporary directory is reported');

if (defined $temp_dir) {
    for my $relative (qw(scripts/step-1.sh bin/sudo aptbin/apt aptbin/apt-get event.json)) {
        my $path = File::Spec->catfile($temp_dir, split m{/}, $relative);
        ok(-f $path, "$relative is written");
        unlike(slurp_bytes($path), qr/\r/, "$relative keeps LF line endings");
    }
    remove_kept_dir($line_endings);
}

# Removing the images is the opt-out, which action-run spells
# --no-keep-images: what this run pulled goes once its containers and networks
# are gone.
my $no_cache = run_workflow(<<'YAML', keep_images => 0);
name: No cache
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo hello
YAML

is($no_cache->{exit}, 0, 'a workflow run with the images removed succeeds');
like($no_cache->{log}, qr/^rm\t-f\t/m, 'its containers are still removed');
like($no_cache->{log}, qr/^image\trm\t-f\tubuntu:latest$/m,
    'the image it pulled is removed when it finishes');

# The environment probe starts a container from the run's own image, so a
# daemon that has never seen it pulls it there, before the explicit pull that
# then finds it present.  A run told not to keep its images has to remove that
# one too, or the opt-out quietly leaves the first image behind.
my $probe_pull = run_workflow(
    $matrix_yaml,
    keep_images          => 0,
    fake_run_needs_image => 1,
);
is($probe_pull->{exit}, 0, 'a run whose probe pulls its image succeeds');
like($probe_pull->{log}, qr/^image\trm\t-f\tperl:5\.38$/m,
    'the image the probe pulled is removed with the rest');

my $implicit_success = run_workflow(<<'YAML');
name: Implicit success
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Fail early
        run: |
          FAKE_EXIT: 9
      - name: Plain condition
        if: runner.os == 'Linux'
        run: echo should-not-run
      - name: Status condition
        if: failure()
        run: echo failure-handler
      - name: Always
        if: always()
        run: echo always-runs
YAML

is($implicit_success->{exit}, 1, 'workflow with a failing step exits 1');
like($implicit_success->{stdout}, qr/Plain condition \(skipped\)/,
    'if without a status function implies success()');
unlike($implicit_success->{stdout}, qr/Status condition \(skipped\)/,
    'failure() is not short-circuited by the failing job');
unlike($implicit_success->{stdout}, qr/Always \(skipped\)/,
    'always() runs after a failure');

my $apt_path = run_workflow(<<'YAML');
name: Apt shims
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo hello
YAML

like($apt_path->{log}, qr/\t-e\tPATH=\/github\/actions-runner\/aptbin:/,
    'apt shim directory is added to PATH');
like($apt_path->{log}, qr/\t-e\tDEBIAN_FRONTEND=noninteractive\t/,
    'package installation runs non-interactively');

my $redacted = run_workflow(<<'YAML', dry_run => 1, verbose => 1, secrets => { TOKEN => 'super-secret-value' });
name: Secret
on: push
jobs:
  test:
    name: Auth ${{ secrets.TOKEN }}
    runs-on: ubuntu-latest
    steps:
      - run: echo "${{ secrets.TOKEN }}"
YAML

is($redacted->{exit}, 0, 'secret dry-run succeeds');
like($redacted->{stdout}, qr/\*\*\*/, 'secret values are redacted in dry-run scripts');
unlike($redacted->{stdout}, qr/super-secret-value/, 'secret values do not appear in output');
unlike($redacted->{stderr}, qr/super-secret-value/, 'secret values do not appear in error output');

# A process's arguments can be read by every user of the host, so the job's
# variables reach docker through its environment instead: the container is
# given the secret, and no docker command line carries it.
my $hidden = run_workflow(<<'YAML', secrets => { TOKEN => 'super-secret-value' });
name: Hidden
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    env:
      JOB_TOKEN: ${{ secrets.TOKEN }}
    steps:
      - run: echo checking
        env:
          STEP_TOKEN: ${{ secrets.TOKEN }}
YAML

is($hidden->{exit}, 0, 'a run whose variables carry a secret succeeds');
like($hidden->{log}, qr/\t-e\tSTEP_TOKEN=super-secret-value\t/, 'the step is given the secret');
like($hidden->{log}, qr/^run\t.*\t-e\tJOB_TOKEN=super-secret-value\t/m, 'and so is the job container');
like($hidden->{argv_log}, qr/\t-e\tSTEP_TOKEN\t/, 'the docker command names the variable');
unlike($hidden->{argv_log}, qr/super-secret-value/, 'but no docker command line carries its value');
like($hidden->{argv_log}, qr/\t-e\tGITHUB_WORKSPACE\t/, 'nor the value of any other job variable');

my $composite_action = <<'YAML';
name: Greet
inputs:
  who:
    description: Who to greet
    default: world
outputs:
  greeting:
    value: ${{ steps.say.outputs.message }}
  where:
    value: ${{ steps.report.outputs.where }}
runs:
  using: composite
  steps:
    - id: say
      name: Say hello
      shell: sh
      run: |
        FAKE_OUTPUT: message=hello-${{ inputs.who }}
        FAKE_ENV: FROM_COMPOSITE=yes
    - id: report
      name: Report path
      shell: sh
      run: |
        FAKE_OUTPUT: where=${{ github.action_path }}
        FAKE_PATH: /opt/composite/bin
YAML

my $outer_action = <<'YAML';
name: Outer
inputs:
  who:
    default: outer-default
outputs:
  greeting:
    value: ${{ steps.inner.outputs.greeting }}
  where:
    value: ${{ steps.inner.outputs.where }}
runs:
  using: composite
  steps:
    - id: inner
      uses: ./.github/actions/greet
      with:
        who: ${{ inputs.who }}
YAML

my $composite = run_workflow(<<'YAML', files => {
name: Composite
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Use the action
        id: greet
        uses: ./.github/actions/outer
        with:
          who: Nigel
      - name: Check the output
        if: steps.greet.outputs.greeting == 'hello-Nigel'
        run: echo output-ok
      - name: Check the environment
        if: env.FROM_COMPOSITE == 'yes'
        run: echo env-ok
      - name: Check the action path
        if: contains(steps.greet.outputs.where, '/github/workspace/.github/actions/greet')
        run: echo path-ok
YAML
    '.github/actions/greet/action.yml' => $composite_action,
    '.github/actions/outer/action.yml' => $outer_action,
});

is($composite->{exit}, 0, 'composite action workflow succeeds');
like($composite->{stdout}, qr/^ {4}--- Step: Say hello$/m,
    'nested composite steps are indented');
unlike($composite->{stdout}, qr/Say hello \(skipped\)/,
    'composite steps run');
unlike($composite->{stdout}, qr/Check the output \(skipped\)/,
    'nested composite outputs reach the caller');
unlike($composite->{stdout}, qr/Check the environment \(skipped\)/,
    'GITHUB_ENV changes inside a composite reach later steps');
unlike($composite->{stdout}, qr/Check the action path \(skipped\)/,
    'github.action_path points at the action directory');
like($composite->{log}, qr/\t-e\tFROM_COMPOSITE=yes\t/,
    'composite environment changes are exported to the job');
like($composite->{log}, qr/\t-e\tPATH=\/opt\/composite\/bin:/,
    'GITHUB_PATH changes inside a composite reach later steps');
like($composite->{log}, qr/\t-e\tGITHUB_ACTION_PATH=\/github\/workspace\/\.github\/actions\/greet\t/,
    'composite scripts see GITHUB_ACTION_PATH');

my $js_action = <<'YAML';
name: JavaScript
inputs:
  who:
    default: default-name
runs:
  using: node20
  main: main.js
  pre: pre.js
  post: post.js
YAML

my $javascript = run_workflow(<<'YAML', files => {
name: JavaScript
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Run the action
        id: js
        uses: ./.github/actions/js
        with:
          who: Nigel
      - name: Check the output
        if: steps.js.outputs.answer == '42'
        run: echo output-ok
      - name: Check the environment
        if: env.FROM_JS == 'yes'
        run: echo env-ok
YAML
    '.github/actions/js/action.yml' => $js_action,
    '.github/actions/js/pre.js'  => "// FAKE_ENV: FROM_PRE=yes\n",
    '.github/actions/js/main.js' => "// FAKE_OUTPUT: answer=42\n// FAKE_ENV: FROM_JS=yes\n",
    '.github/actions/js/post.js' => "// FAKE_ENV: FROM_POST=yes\n",
});

is($javascript->{exit}, 0, 'JavaScript action workflow succeeds');
like($javascript->{log}, qr/\tnode\t\/github\/workspace\/\.github\/actions\/js\/pre\.js/,
    'the pre step runs before the main step');
like($javascript->{log}, qr/\tnode\t\/github\/workspace\/\.github\/actions\/js\/main\.js/,
    'the main entry point runs');
like($javascript->{log}, qr/\tnode\t\/github\/workspace\/\.github\/actions\/js\/post\.js/,
    'the post step runs');
like($javascript->{log}, qr/\t-e\tINPUT_WHO=Nigel\t/,
    'action inputs are passed as INPUT_* variables');
like($javascript->{log}, qr/\t-e\tGITHUB_ACTION_PATH=\/github\/workspace\/\.github\/actions\/js\t/,
    'JavaScript actions see GITHUB_ACTION_PATH');
like($javascript->{log}, qr/\t-e\tFROM_PRE=yes\t/, 'the pre step can export variables');
like($javascript->{log}, qr/\t-e\tFROM_JS=yes\t/, 'the main step can export variables');
like($javascript->{log}, qr/\t-e\tGITHUB_ACTION=js\t.*post\.js/s,
    'the post step runs with the job environment');
unlike($javascript->{stdout}, qr/Check the output \(skipped\)/,
    'JavaScript action outputs reach later steps');
unlike($javascript->{stdout}, qr/Check the environment \(skipped\)/,
    'JavaScript action environment changes reach later steps');

my $main_position = index($javascript->{log}, 'actions/js/main.js');
my $post_position = index($javascript->{log}, 'actions/js/post.js');
ok($main_position >= 0, 'the main step is logged');
ok($post_position > $main_position, 'the post step runs after the main step');

my $no_node = run_workflow(<<'YAML', files => {
name: No node
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: ./.github/actions/js
YAML
    '.github/actions/js/action.yml' => $js_action,
    '.github/actions/js/main.js'    => "// FAKE_OUTPUT: answer=42\n",
}, fake_no_node => 1);

is($no_node->{exit}, 1, 'a JavaScript action without node fails');
like($no_node->{stderr}, qr/needs Node\.js/, 'missing node is explained');

my $missing_action = run_workflow(<<'YAML');
name: Missing action
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: ./.github/actions/absent
YAML

is($missing_action->{exit}, 1, 'a missing local action fails');
like($missing_action->{stderr}, qr/Local action .* does not exist/,
    'a missing local action is reported');
unlike($missing_action->{stderr}, qr/cannot prepare the image/,
    'the preflight leaves a missing action to the step that uses it');

my $escaping_action = run_workflow(<<'YAML');
name: Escaping action
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: ../../etc
YAML

is($escaping_action->{exit}, 1, 'a local action outside the project fails');
like($escaping_action->{stderr}, qr/must not escape the project/,
    'a local action outside the project is rejected');

my $broken_action = run_workflow(<<'YAML', files => {
name: Broken action
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: ./.github/actions/broken
YAML
    '.github/actions/broken/action.yml' => "name: Broken\n",
});

is($broken_action->{exit}, 1, 'an action without runs fails');
like($broken_action->{stderr}, qr/has no 'runs' mapping/,
    'broken action metadata is reported');

# The environment is probed before any job starts, using the image the job
# will use, and the probe is silent when it passes.
my $simple = <<'YAML';
name: Plain
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    steps:
      - run: echo hello
YAML

my $probed = run_workflow($simple);
is($probed->{exit}, 0, 'a workflow still runs when the probe passes');
like($probed->{log}, qr/^run\t--rm\t--network\tnone\t/m,
    'the bind mount is probed before the workflow starts');
like($probed->{log}, qr/\t-v\t[^\t]+:\/check-project:ro\t/,
    'the probe mounts the project directory read-only');
unlike($probed->{stdout}, qr/^ {2}mount\s/m, 'a passing probe says nothing');

# A probe container can fail because the daemon cannot pull its image, which
# is the same branch a real daemon takes when the probe image is unavailable.
my $probe_image_missing = run_workflow(
    $simple,
    fake_run_needs_image => 1,
    fake_pull_failure    => 'perl:5.38',
);
is($probe_image_missing->{exit}, 2, 'a probe whose image cannot be pulled stops the run');
like($probe_image_missing->{stdout}, qr/probe container failed \(exit 125\)/,
    'the report names the probe container and its exit status');
like($probe_image_missing->{stdout}, qr/^ {2}remedy\s+\S/m,
    'the failed probe comes with a remedy');
like($probe_image_missing->{stderr}, qr/the environment is not ready/,
    'the run stops for the environment, not for the job');
unlike($probe_image_missing->{log}, qr/^run\t-d\t/m, 'no job container is started');

# Probe image: the job's own image, so a working setup needs no extra pull.
unlike($probed->{log}, qr/^pull\t.*alpine:3\.20/m,
    'the probe does not pull an image the run does not need');
like($probed->{log}, qr/:ro\tperl:5\.38\t/,
    'the probe uses the image the job will use');

my $verbose_probe = run_workflow($simple, verbose => 1);
is($verbose_probe->{exit}, 0, 'a verbose run passes the probe');
like($verbose_probe->{stdout}, qr/^ {2}mount\s+\S.* -> \/check-project: OK/m,
    'a verbose run shows the probe report');

# A broken environment stops the run before a job container is started.
my $not_ready = run_workflow($simple, fake_os_type => 'windows');
is($not_ready->{exit}, 2, 'a broken environment stops the run');
like($not_ready->{stderr}, qr/the environment is not ready/,
    'the run says the environment is at fault');
like($not_ready->{stderr}, qr/--skip-check/, 'the run points at --skip-check');
unlike($not_ready->{stderr}, qr/ at \S+ line \d+/,
    'the failure message is not decorated with a source location');
unlike($not_ready->{log}, qr/^exec\t/m, 'no step runs in a broken environment');

my $hidden_project = run_workflow($simple, fake_entry_count => 0);
is($hidden_project->{exit}, 2, 'a project the container cannot see stops the run');
like($hidden_project->{stderr}, qr/the environment is not ready/,
    'the unshared drive is reported before the job starts');
unlike($hidden_project->{log}, qr/^exec\t/m, 'nothing runs with an unreadable project');

# --skip-check is the escape hatch.
my $unchecked = run_workflow($simple, fake_os_type => 'windows', skip_check => 1);
is($unchecked->{exit}, 0, 'skip_check runs the workflow anyway');
like($unchecked->{stdout}, qr/Workflow succeeded/, 'the workflow runs with skip_check');
unlike($unchecked->{log}, qr/--network\tnone\t/m, 'skip_check skips the probes');
like($unchecked->{log}, qr/^info\t/m, 'skip_check still asks whether Docker is there');

my $skipped_hidden = run_workflow($simple, fake_entry_count => 0, skip_check => 1);
is($skipped_hidden->{exit}, 0, 'skip_check ignores an unreadable project');

# Every image the run needs is prepared before the first job starts, so a
# typo in a service or action image does not surface with containers up.
my $with_images = <<'YAML';
name: Images
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    services:
      db:
        image: postgres:15
    steps:
      - uses: docker://alpine:3.20
        with:
          args: echo hi
      - run: echo hello
YAML

my $prepared = run_workflow($with_images);
is($prepared->{exit}, 0, 'a workflow with services and an action image runs');
like($prepared->{log}, qr/^pull\tpostgres:15$/m, 'the service image is pulled');
like($prepared->{log}, qr/^pull\talpine:3\.20$/m, 'the action image is pulled');

my $service_pull = index($prepared->{log}, "pull\tpostgres:15");
my $action_pull  = index($prepared->{log}, "pull\talpine:3.20");
my $job_start    = index($prepared->{log}, "run\t-d\t");
ok($service_pull >= 0 && $job_start >= 0 && $service_pull < $job_start,
    'the service image is pulled before the job container starts');
ok($action_pull >= 0 && $action_pull < $job_start,
    'the action image is pulled before the job container starts');

# --pull refreshes the images even when they are present, but only once each:
# the preflight prepares everything the run needs, so the check each job makes
# of its own image must not download it a second time.
my $pulled_once = run_workflow($with_images, pull => 1);
is($pulled_once->{exit}, 0, '--pull still runs the workflow');
for my $image (qw(perl:5.38 postgres:15 alpine:3.20)) {
    is(scalar(() = $pulled_once->{log} =~ /^pull\t\Q$image\E$/mg), 1,
        "--pull pulls $image once");
}
is(scalar(() = $pulled_once->{stdout} =~ /^Pulling image \S+\.\.\.$/mg), 3,
    '--pull announces each pull once');
unlike($pulled_once->{log}, qr/^image\trm\t/m,
    'the images --pull refreshed are kept for the next run');

# The same image in two matrix jobs is one download, not two.
my $shared_image_yaml = <<'YAML';
name: Shared image
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        flavour: ['one', 'two']
    container:
      image: perl:5.38
    steps:
      - run: echo ${{ matrix.flavour }}
YAML

my $shared_image = run_workflow($shared_image_yaml, pull => 1);
is($shared_image->{exit}, 0, 'two jobs can share one image');
like($shared_image->{stdout}, qr/one/, 'both matrix jobs ran');
is(scalar(() = $shared_image->{log} =~ /^pull\tperl:5\.38$/mg), 1,
    '--pull pulls a shared matrix image once for the whole run');

# --skip-check skips the preflight, so each job prepares its own image; the
# image is still fetched once, by the job that reaches it first.
my $skip_pull = run_workflow($shared_image_yaml, pull => 1, skip_check => 1);
is($skip_pull->{exit}, 0, '--pull runs with --skip-check');
is(scalar(() = $skip_pull->{log} =~ /^pull\tperl:5\.38$/mg), 1,
    '--pull pulls a shared image once even without the preflight');

my $service_broken = run_workflow($with_images, fake_pull_failure => 'postgres:15');
is($service_broken->{exit}, 2, 'an unpullable service image stops the run');
like(
    $service_broken->{stderr},
    qr/cannot prepare the image 'postgres:15', needed by service 'db' of job 'test'/,
    'the failure names the image and the service that needs it',
);
unlike($service_broken->{stderr}, qr/ at \S+ line \d+/,
    'the image failure reads as a sentence, not a source location');
unlike($service_broken->{log}, qr/^run\t-d\t/m, 'no job container is started');
unlike($service_broken->{log}, qr/^exec\t/m, 'no step runs');

my $strict_pull = run_workflow($with_images, no_pull => 1);
is($strict_pull->{exit}, 2, '--no-pull with a missing image stops the run');
like($strict_pull->{stderr}, qr/is not available locally \(--no-pull\)/,
    'the --no-pull problem is explained before any container starts');
unlike($strict_pull->{stderr}, qr/ at \S+ line \d+/, 'that message reads as a sentence too');
unlike($strict_pull->{log}, qr/^run\t-d\t/m, 'no job container is started by --no-pull');

my $action_broken = run_workflow($with_images, fake_pull_failure => 'alpine:3.20');
is($action_broken->{exit}, 2, 'an unpullable action image stops the run');
like(
    $action_broken->{stderr},
    qr/cannot prepare the image 'alpine:3\.20', needed by action 'docker:\/\/alpine:3\.20'/,
    'the failure names the action that needs it',
);
unlike($action_broken->{log}, qr/^run\t-d\t/m, 'no job container is started');

# Images inside local composite actions are found by reading the action up
# front, rather than when the step that uses it happens to run.
my $image_action = <<'YAML';
name: Run an image
runs:
  using: composite
  steps:
    - name: Say hello
      uses: docker://busybox:1.36
      with:
        args: echo hi
YAML

my $local_images = run_workflow(<<'YAML', files => {
name: Local action image
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    steps:
      - uses: ./.github/actions/run-image
      - run: echo hello
YAML
    '.github/actions/run-image/action.yml' => $image_action,
});

is($local_images->{exit}, 0, 'a composite action with a docker:// step runs');
my $local_pull = index($local_images->{log}, "pull\tbusybox:1.36");
my $local_start = index($local_images->{log}, "run\t-d\t");
ok($local_pull >= 0 && $local_start >= 0 && $local_pull < $local_start,
    'the composite action image is pulled before the job container starts');

# A composite action inside a composite action is followed, and the image it
# names can come from the caller's inputs (or the action's defaults).
my $inner_action = <<'YAML';
name: Inner
inputs:
  image:
    default: busybox:1.35
runs:
  using: composite
  steps:
    - uses: docker://${{ inputs.image }}
      with:
        args: echo inner
YAML

my $wrapper_action = <<'YAML';
name: Wrapper
inputs:
  image:
    default: busybox:1.34
runs:
  using: composite
  steps:
    - uses: ./.github/actions/inner
      with:
        image: ${{ inputs.image }}
YAML

my $nested_images = run_workflow(<<'YAML', files => {
name: Nested action image
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    steps:
      - uses: ./.github/actions/wrapper
        with:
          image: busybox:1.37
      - run: echo hello
YAML
    '.github/actions/inner/action.yml'    => $inner_action,
    '.github/actions/wrapper/action.yml'  => $wrapper_action,
});

is($nested_images->{exit}, 0, 'a nested composite action runs');
my $nested_pull = index($nested_images->{log}, "pull\tbusybox:1.37");
my $nested_start = index($nested_images->{log}, "run\t-d\t");
ok($nested_pull >= 0 && $nested_start >= 0 && $nested_pull < $nested_start,
    'an image named two levels down is pulled before the job starts');
unlike($nested_images->{log}, qr/^pull\tbusybox:1\.3[45]$/m,
    'the input overrides the defaults of both actions');

# A broken image inside a local action fails the same way as a broken service
# image: before the first container, naming the action it came from.
my $local_broken = run_workflow(
    <<'YAML',
name: Local action image
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    steps:
      - uses: ./.github/actions/run-image
      - run: echo hello
YAML
    files => { '.github/actions/run-image/action.yml' => $image_action },
    fake_pull_failure => 'busybox:1.36',
);

is($local_broken->{exit}, 2, 'an unpullable image in a local action stops the run');
like(
    $local_broken->{stderr},
    qr/cannot prepare the image 'busybox:1\.36', needed by action 'docker:\/\/busybox:1\.36' in local action '\.\/\.github\/actions\/run-image' of job 'test'/,
    'the failure names the image, the action, and the job',
);
unlike($local_broken->{log}, qr/^run\t-d\t/m, 'no job container is started');
unlike($local_broken->{log}, qr/^exec\t/m, 'no step runs');

# An action that uses itself must not make the preflight descend forever.
my $self_action = <<'YAML';
name: Self
runs:
  using: composite
  steps:
    - uses: docker://busybox:1.38
    - uses: ./.github/actions/self
YAML

my $loop = run_workflow(<<'YAML', files => {
name: Self action
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    steps:
      - uses: ./.github/actions/self
YAML
    '.github/actions/self/action.yml' => $self_action,
});

my $loop_pulls = () = $loop->{log} =~ /^pull\tbusybox:1\.38$/mg;
is($loop_pulls, 1, 'a self-referencing action is walked once, not forever');

# A dry run pulls nothing for a local action's image either.
my $local_dry = run_workflow(
    <<'YAML',
name: Local action image
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    steps:
      - uses: ./.github/actions/run-image
YAML
    files   => { '.github/actions/run-image/action.yml' => $image_action },
    dry_run => 1,
);

is($local_dry->{exit}, 0, 'a dry run with a local action image succeeds');
unlike($local_dry->{log}, qr/^pull\t/m, 'a dry run pulls no local action image');

# The verbose listing points at the action an image came from.
my $local_verbose = run_workflow(
    <<'YAML',
name: Local action image
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    steps:
      - uses: ./.github/actions/run-image
YAML
    files   => { '.github/actions/run-image/action.yml' => $image_action },
    verbose => 1,
);

is($local_verbose->{exit}, 0, 'a verbose run with a local action image passes');
like(
    $local_verbose->{stdout},
    qr/^ {2}image\s+busybox:1\.36 \(action 'docker:\/\/busybox:1\.36' in local action '\.\/\.github\/actions\/run-image' of job 'test'\)$/m,
    'a verbose run names the composite action an image came from',
);

# The images are pulled at the same time, so a wide matrix does not spend the
# start of the run waiting for one image after another.
my $many_images = <<'YAML';
name: Many images
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    services:
      first:
        image: first:1
      second:
        image: second:1
      third:
        image: third:1
    steps:
      - run: echo hello
YAML

# The timing log of a run, as the times each pull started and finished.
sub pull_times {
    my ($log) = @_;

    my (%start, %finished);
    for my $line (split /\n/, $log) {
        my ($event, $image, $at) = split /\t/, $line;
        next unless defined $at;
        $start{$image}    = $at if $event eq 'pull-start';
        $finished{$image} = $at if $event eq 'pull-end';
    }

    return (\%start, \%finished);
}

# The most pulls that were under way at the same time.
sub max_overlap {
    my ($start, $finished) = @_;

    my @events;
    for my $image (keys %$start) {
        next unless exists $finished->{$image};
        push @events, [ $start->{$image}, 1 ], [ $finished->{$image}, -1 ];
    }

    my ($running, $most) = (0, 0);
    for my $event (sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @events) {
        $running += $event->[1];
        $most = $running if $running > $most;
    }

    return $most;
}

SKIP: {
    skip 'pulls run one at a time where fork() is not used', 10 if $^O eq 'MSWin32';

    my $together = run_workflow(
        $many_images,
        fake_pull_sleep  => 0.4,
        fake_pull_timing => 1,
    );

    is($together->{exit}, 0, 'a workflow with several images runs');

    my ($start, $finished) = pull_times($together->{log});
    my @pulled = sort grep { exists $finished->{$_} } keys %$start;
    is_deeply(
        \@pulled,
        [ 'first:1', 'perl:5.38', 'second:1', 'third:1' ],
        'every image is still pulled, once each',
    );

    ok(max_overlap($start, $finished) > 1,
        'the pulls overlap instead of running one after another');

    # The concurrency can be lowered, which is how a slow registry is read
    # without one download hiding the others.
    my $serial = run_workflow(
        $many_images,
        fake_pull_sleep   => 0.4,
        fake_pull_timing  => 1,
        pull_concurrency  => 1,
    );

    is($serial->{exit}, 0, 'a workflow runs with the pulls made one at a time');
    my ($serial_start, $serial_finished) = pull_times($serial->{log});
    is(max_overlap($serial_start, $serial_finished), 1,
        'pull_concurrency 1 pulls the images one after another');

    my $pair = run_workflow(
        $many_images,
        fake_pull_sleep   => 0.4,
        fake_pull_timing  => 1,
        pull_concurrency  => 2,
    );

    is($pair->{exit}, 0, 'a workflow runs with two pulls at a time');
    my ($pair_start, $pair_finished) = pull_times($pair->{log});
    is(max_overlap($pair_start, $pair_finished), 2,
        'pull_concurrency 2 keeps two pulls in flight, no more');

    # The same knob from the environment, which is what a CI job sets once.
    {
        local $ENV{ACTION_RUN_PULL_CONCURRENCY} = 1;

        my $from_env = run_workflow(
            $many_images,
            fake_pull_sleep  => 0.4,
            fake_pull_timing => 1,
        );

        is($from_env->{exit}, 0, 'a workflow runs with the concurrency from the environment');
        my ($env_start, $env_finished) = pull_times($from_env->{log});
        is(max_overlap($env_start, $env_finished), 1,
            'ACTION_RUN_PULL_CONCURRENCY is honoured');
    }

    # A one-off command line beats a value left in the environment.
    {
        local $ENV{ACTION_RUN_PULL_CONCURRENCY} = 1;

        my $wins = run_workflow(
            $many_images,
            fake_pull_sleep  => 0.4,
            fake_pull_timing => 1,
            pull_concurrency => 3,
        );

        is($wins->{exit}, 0, 'a workflow runs with the option and the environment set');
        my ($win_start, $win_finished) = pull_times($wins->{log});
        ok(max_overlap($win_start, $win_finished) > 1,
            'the option wins over the environment');
    }
}

# A pull that fails is still reported in the order the run needs the images,
# even though the pulls themselves finish in any order.
my $failing_pair = run_workflow(
    $many_images, fake_pull_failure => 'second:1', keep_images => 0,
);
is($failing_pair->{exit}, 2, 'one unpullable image among several stops the run');
like(
    $failing_pair->{stderr},
    qr/cannot prepare the image 'second:1', needed by service 'second' of job 'test'/,
    'the failing image is named, not whichever pull happened to finish first',
);
unlike($failing_pair->{log}, qr/^run\t-d\t/m, 'no job container is started');

# Images that did arrive are removed again when the run was told not to keep
# them, even though it stopped.
like($failing_pair->{log}, qr/^image\trm\t-f\tperl:5\.38$/m,
    'the job image is removed after a failed preflight');
like($failing_pair->{log}, qr/^image\trm\t-f\tthird:1$/m,
    'an image that was pulled is removed too');
unlike($failing_pair->{log}, qr/^image\trm\t-f\tsecond:1$/m,
    'the image that was never pulled is not claimed as pulled');

# An image used by two jobs is prepared once.
my $shared = <<'YAML';
name: Shared
on: push
jobs:
  first:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    steps:
      - run: echo one
  second:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    steps:
      - run: echo two
YAML

my $shared_run = run_workflow($shared);
is($shared_run->{exit}, 0, 'two jobs sharing an image run');
my $pulls = () = $shared_run->{log} =~ /^pull\tperl:5\.38$/mg;
is($pulls, 1, 'a shared image is pulled once');

# --skip-check leaves the images to be pulled when they are first used.
my $skipped_images = run_workflow(
    $with_images, fake_pull_failure => 'postgres:15', skip_check => 1,
);
is($skipped_images->{exit}, 2, 'skip_check fails later, inside the job');
like($skipped_images->{stdout}, qr/==> Job: test/, 'the job starts with skip_check');
like($skipped_images->{stderr}, qr/Failed to pull Docker image 'postgres:15'/,
    'the pull failure surfaces at use time');

# A dry run must not touch the registry.
my $dry = run_workflow($with_images, dry_run => 1);
is($dry->{exit}, 0, 'a dry run with services succeeds');
unlike($dry->{log}, qr/^pull\t/m, 'a dry run pulls nothing');

# The images are named when verbose, which is how a stuck pull is diagnosed.
my $verbose_images = run_workflow($with_images, verbose => 1);
is($verbose_images->{exit}, 0, 'a verbose run with services passes');
like($verbose_images->{stdout}, qr/^ {2}image\s+postgres:15 \(service 'db' of job 'test'\)$/m,
    'a verbose run names each image and why it is needed');

# Images that only an expression can produce are left to the run itself.
my $expression_image = run_workflow(<<'YAML');
name: Expression image
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        db: ['15', '16']
    container:
      image: perl:5.38
    services:
      database:
        image: postgres:${{ matrix.db }}
    steps:
      - run: echo hello
YAML

is($expression_image->{exit}, 0, 'a matrix-driven service image runs');
like($expression_image->{log}, qr/^pull\tpostgres:15$/m, 'the matrix value is resolved');
like($expression_image->{log}, qr/^pull\tpostgres:16$/m, 'each matrix value is resolved');

# A value that cannot be resolved yet is not guessed at.
my $unknown_image = run_workflow(<<'YAML');
name: Unknown image
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    services:
      database:
        image: postgres:${{ github.ref }}
    steps:
      - run: echo hello
YAML

is($unknown_image->{exit}, 0, 'an unresolved expression image is left to the run');

# A job image that uses a value the run resolves for each job is prepared
# under the name the job will use, not as the expression it was written as.
my $use_time_job_image = run_workflow(<<'YAML');
name: Use-time job image
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: busybox:${{ github.ref_name }}
    steps:
      - run: echo hello
YAML

is($use_time_job_image->{exit}, 0, 'a job image built from github.* runs');
like($use_time_job_image->{log}, qr/^pull\tbusybox:main$/m,
    'the job image is prepared under the name the job will use');
unlike($use_time_job_image->{log}, qr/\$\{\{/,
    'no unresolved expression reaches Docker');

# An image only a step can name is reported by the job before it starts and
# prepared by that step, before the step's own container.
my $step_decided = <<'YAML';
name: Step-decided image
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    steps:
      - id: pick
        run: |
          FAKE_OUTPUT: image=busybox:1.37
      - uses: docker://${{ steps.pick.outputs.image }}
        with:
          args: echo hi
YAML

my $step_decided_run = run_workflow($step_decided);
is($step_decided_run->{exit}, 0, 'an image a step decides still runs');
like(
    $step_decided_run->{stdout},
    qr/^ {2}deferred {2}\$\{\{ steps\.pick\.outputs\.image \}\} \(action 'docker:\/\/\$\{\{ steps\.pick\.outputs\.image \}\}' in job 'test'\)$/m,
    'the job says which image only the step can name',
);
like($step_decided_run->{log}, qr/^pull\tbusybox:1\.37$/m,
    'the step resolves the image and pulls it');

# The preflight says an image is deferred rather than pretending it is ready,
# and a deferral is not a problem with the environment.
# A job container starts before any step has run, so a name only a step
# could give is a workflow error reported before the job starts.
my $step_job_image = run_workflow(<<'YAML');
name: Step job image
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: busybox:${{ steps.pick.outputs.image }}
    steps:
      - id: pick
        run: |
          FAKE_OUTPUT: image=1.37
      - run: echo hello
YAML

is($step_job_image->{exit}, 2, 'a job image a step would decide stops the run');
like(
    $step_job_image->{stderr},
    qr/cannot resolve the image 'busybox:\$\{\{ steps\.pick\.outputs\.image \}\}', needed by job 'test'/,
    'the failure names the expression and the job',
);
unlike($step_job_image->{log}, qr/^run\t-d\t/m, 'nothing is started for it');

my $deferred_preflight = preflight_workflow($step_decided, json => 1);
is($deferred_preflight->{result}{exit}, 0, 'a deferred image does not fail the preflight');
my $deferred_summary = $deferred_preflight->{result}{summary};
is($deferred_summary->{images}[1]{status}, 'deferred',
    'the image the preflight cannot name is deferred');
is($deferred_summary->{images}[1]{image}, undef, 'no image name is guessed');
is($deferred_summary->{images}[1]{expression}, '${{ steps.pick.outputs.image }}',
    'the expression is reported as it was written');
like($deferred_summary->{images}[1]{error}, qr/unable to resolve/,
    'the record says why it could not be named');
is($deferred_summary->{problems}, 0, 'a deferral is not counted as a problem');
ok($deferred_summary->{ready}, 'everything the preflight could check is ready');

# A value from another job does not exist until that job has run, so the
# preflight defers it; the job's own check resolves it before its first
# container, and a bad image therefore stops the run before the job starts.
my $needs_image = <<'YAML';
name: Needs image
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    steps:
      - run: echo built
  test:
    runs-on: ubuntu-latest
    needs: build
    container:
      image: perl:5.38
    services:
      helper:
        image: busybox:${{ needs.build.result }}
    steps:
      - run: echo hello
YAML

my $needs_preflight = preflight_workflow($needs_image, json => 1);
is($needs_preflight->{result}{summary}{images}[1]{status}, 'deferred',
    'an image built from another job is deferred by the preflight');

my $needs_run = run_workflow($needs_image);
is($needs_run->{exit}, 0, 'a workflow whose image comes from another job runs');

my @needs_log = split /\n/, $needs_run->{log};
my ($needs_pull, @needs_starts);
for my $index (0 .. $#needs_log) {
    $needs_pull = $index
        if !defined $needs_pull && $needs_log[$index] eq "pull\tbusybox:success";
    # The job containers are the ones named for the job; a service is named
    # for its own kind.
    push @needs_starts, $index
        if $needs_log[$index] =~ /^run\t-d\t.*-job-test-/;
}

is(scalar @needs_starts, 1, 'the job that needed the deferred image started');
ok(
    defined $needs_pull && @needs_starts == 1 && $needs_pull < $needs_starts[0],
    'the deferred image is prepared before the job that needs it starts',
);

my $needs_failure = run_workflow(
    $needs_image, fake_pull_failure => 'busybox:success',
);
is($needs_failure->{exit}, 2,
    'an unusable image named by another job stops the run before the job starts');
like(
    $needs_failure->{stderr},
    qr/cannot prepare the image 'busybox:success', needed by service 'helper' of job 'test'/,
    'the failure names the image, the service and the job',
);
my $needs_started = () = $needs_failure->{log} =~ /^run\t-d\t/mg;
is($needs_started, 1, 'only the job that had already run started a container');

# The probe still runs first: an image problem is reported after the
# environment report, not instead of it.
my $broken_environment = run_workflow(
    $with_images, fake_os_type => 'windows', fake_pull_failure => 'postgres:15',
);
is($broken_environment->{exit}, 2, 'a broken environment is still reported first');
unlike($broken_environment->{log}, qr/^pull\t/m, 'nothing is pulled for a broken environment');

# The preflight can be asked for its outcome as data: the check's report plus
# one record per image, saying what needs it and whether it was prepared.
my $preflight = preflight_workflow($with_images, json => 1);

is($preflight->{result}{exit}, 0, 'a ready preflight exits 0');
my $summary = $preflight->{result}{summary};
ok($summary->{ready}, 'the summary says the run can start');
is($summary->{problems}, 0, 'no problems are counted');
is($summary->{image}, 'perl:5.38', 'the probe image is part of the summary');
is(scalar @{ $summary->{images} }, 3, 'every needed image is listed');
is_deeply(
    [ map { $_->{status} } @{ $summary->{images} } ],
    [ 'pulled', 'pulled', 'pulled' ],
    'each image is reported as pulled',
);
is($summary->{images}[0]{source}, "job 'test'", 'the job image names the job');
is($summary->{images}[1]{source}, "service 'db' of job 'test'",
    'the service image names the service');
is($summary->{images}[2]{source}, "action 'docker://alpine:3.20' in job 'test'",
    'the action image names the action');
is($preflight->{stdout}, '', 'a JSON preflight prints nothing itself');
is($preflight->{stderr}, '', 'a JSON preflight writes no errors');
unlike($preflight->{log}, qr/^run\t-d\t/m, 'the preflight starts no job container');

my $preflight_failure = preflight_workflow(
    $with_images, json => 1, fake_pull_failure => 'postgres:15',
);

is($preflight_failure->{result}{exit}, 2, 'an unpullable image fails the preflight');
my $failed_summary = $preflight_failure->{result}{summary};
ok(!$failed_summary->{ready}, 'the summary says the run cannot start');
is($failed_summary->{problems}, 1, 'the failed image is counted');
is($failed_summary->{images}[1]{status}, 'failed', 'the image that failed is marked');
like($failed_summary->{images}[1]{error},
    qr/Failed to pull Docker image 'postgres:15'/,
    'the image carries the reason it failed');
like($failed_summary->{issues}[0]{problem},
    qr/cannot prepare the image 'postgres:15', needed by service 'db' of job 'test'/,
    'the issue names the image, the service and the job');
ok(scalar @{ $failed_summary->{issues}[0]{remedies} }, 'the issue carries a remedy');
like($preflight_failure->{result}{error},
    qr/cannot prepare the image 'postgres:15'/,
    'the message a run would have stopped with is returned');
unlike($preflight_failure->{log}, qr/^run\t-d\t/m, 'no job container is started');

# A broken environment is reported, and the images it would have needed are
# listed as skipped rather than guessed at.
my $preflight_blocked = preflight_workflow(
    $with_images, json => 1, fake_os_type => 'windows',
);
my $blocked_summary = $preflight_blocked->{result}{summary};
is($preflight_blocked->{result}{exit}, 2, 'a broken environment fails the preflight');
ok(!$blocked_summary->{ready}, 'a broken environment is not ready');
like($blocked_summary->{issues}[0]{problem}, qr/'windows' containers/,
    'the check issue is reported');
is_deeply(
    [ map { $_->{status} } @{ $blocked_summary->{images} } ],
    [ 'skipped', 'skipped', 'skipped' ],
    'nothing is claimed to be prepared',
);
unlike($preflight_blocked->{log}, qr/^pull\t/m, 'nothing is pulled for a broken environment');

# --skip-check prepares the images without claiming a probe result.
my $preflight_skipped = preflight_workflow(
    $with_images, json => 1, fake_os_type => 'windows', skip_check => 1,
);
is($preflight_skipped->{result}{exit}, 0, 'skip_check prepares the images without probing');
ok($preflight_skipped->{result}{summary}{ready}, 'the images alone are enough to be ready');
is($preflight_skipped->{result}{summary}{docker}{daemon}, undef,
    'no probe result is claimed');

# --no-pull is reported per image, before anything is downloaded.
my $preflight_no_pull = preflight_workflow($with_images, json => 1, no_pull => 1);
is($preflight_no_pull->{result}{exit}, 2, '--no-pull fails the preflight');
like(
    $preflight_no_pull->{result}{summary}{images}[0]{error},
    qr/is not available locally \(--no-pull\)/,
    'the record explains why the image is unusable',
);
unlike($preflight_no_pull->{log}, qr/^pull\t/m, 'nothing is pulled with --no-pull');

# Without json the same run reports in the usual way, so the command works
# like a run that stops after preparing its images.
my $preflight_text = preflight_workflow($with_images);
is($preflight_text->{result}{exit}, 0, 'a text preflight exits 0');
like($preflight_text->{stdout}, qr/^Pulling image/m, 'a text preflight shows the pulls');
like(
    $preflight_text->{stdout},
    qr/^ {2}image {5}perl:5\.38 \(job 'test'\): pulled$/m,
    'a text preflight names each image and what happened to it',
);
like(
    $preflight_text->{stdout},
    qr/^ {2}image {5}postgres:15 \(service 'db' of job 'test'\): pulled$/m,
    'the image line names the service that needs it',
);
unlike($preflight_text->{stdout}, qr/^ {2}deferred/m,
    'no deferral is claimed for an image the preflight could name');

# A pasted preflight report says which document version produced it, and it is
# the preflight's version rather than the check's it embeds.
my $preflight_version = App::Actions::Runner->preflight_schema_version;
like(
    $preflight_text->{stdout},
    qr/^ {2}schema {4}version \Q$preflight_version\E \(action-run schema preflight\)$/m,
    'a text preflight names the schema it was written against',
);
unlike($preflight_text->{stdout}, qr/action-run schema check/,
    'the preflight names its own contract, not the check document it embeds');

# Even a verbose preflight, where the check report is printed in full, leaves
# the check's own schema line out.
my $verbose_text = preflight_workflow($with_images, verbose => 1);
like($verbose_text->{stdout}, qr/^ {2}host\s+\S/m,
    'a verbose preflight shows the check report');
like(
    $verbose_text->{stdout},
    qr/^ {2}schema {4}version \Q$preflight_version\E \(action-run schema preflight\)$/m,
    'a verbose preflight still names its own contract',
);
unlike($verbose_text->{stdout}, qr/action-run schema check/,
    'a verbose preflight does not name the check contract as well');

# An image only a step can name is reported by its expression, with the
# reason, since there is no name to print yet.
my $deferred_text = preflight_workflow($step_decided);
my $step_image    = '${{ steps.pick.outputs.image }}';
is($deferred_text->{result}{exit}, 0, 'a deferred image leaves a text preflight ready');
like(
    $deferred_text->{stdout},
    qr/^ {2}image {5}\Q$step_image\E \(action 'docker:\/\/\Q$step_image\E' in job 'test'\): deferred$/m,
    'a deferred image is reported by its expression, not a guessed name',
);
like(
    $deferred_text->{stdout},
    qr/^ {2}deferred {2}unable to resolve '\Q$step_image\E'/m,
    'the reason the image could not be named is printed with it',
);

my $preflight_text_failure = preflight_workflow(
    $with_images, fake_pull_failure => 'postgres:15',
);
is($preflight_text_failure->{result}{exit}, 2, 'a text preflight reports a failure');
like(
    $preflight_text_failure->{stdout},
    qr/^ {2}schema {4}version \Q$preflight_version\E \(action-run schema preflight\)$/m,
    'a failing preflight report names its contract too',
);
like($preflight_text_failure->{result}{error},
    qr/cannot prepare the image 'postgres:15', needed by service 'db' of job 'test'/,
    'the failure names the image and the service');

unlike($preflight_text->{log}, qr/^run\t-d\t/m, 'a text preflight starts no job container');

done_testing;
