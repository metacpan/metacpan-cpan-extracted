use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use Fcntl qw(:flock);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use App::Actions;
use App::Actions::Check;
use App::Actions::Docker;
use App::Actions::Process;

# One small workflow run end to end against a real daemon rather than the fake
# one the rest of the suite uses, which is where the bind mounts, the container
# lifecycle and the cleanup differ most from it.  Like the other live tests it
# is behind LIVE_TESTING, so the ordinary suite needs no daemon:
#
#     LIVE_TESTING=1 prove -l t/real-docker.t
#
my $enabled = defined $ENV{LIVE_TESTING} && length $ENV{LIVE_TESTING}
    && $ENV{LIVE_TESTING} ne '0';
plan skip_all => 'set LIVE_TESTING=1 to run a workflow against a real Docker daemon'
    unless $enabled;

my $docker = defined $ENV{DOCKER} && length $ENV{DOCKER} ? $ENV{DOCKER} : 'docker';
my $image  = defined $ENV{LIVE_TESTING_IMAGE} && length $ENV{LIVE_TESTING_IMAGE}
    ? $ENV{LIVE_TESTING_IMAGE}
    : 'alpine:3.20';

# A live run records the images it kept; keep that record out of the test
# host's real image cache.
local $ENV{ACTION_RUN_CACHE_FILE}
    = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
local $ENV{ACTION_RUN_LOG_DIR}
    = File::Spec->catdir(tempdir(CLEANUP => 1), 'logs');

# Windows writes CRLF when output is redirected to a file, and a few of the
# matches below anchor on the end of a line.
sub useful_text {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/\r\n/\n/g;
    return $text;
}

# Use the same wrapper detection as action-run, so a Perl or script wrapper
# passed through DOCKER works here too.
my $daemon = App::Actions::Docker->new(bin => $docker, quiet => 1);
my ($os_type, $info_rc) = $daemon->capture_silent(
    'info', '--format', '{{.OSType}}',
);

ok($info_rc == 0, 'the Docker daemon is reachable')
    or BAIL_OUT("'$docker info' failed; is Docker running and reachable?");

(my $os = $os_type) =~ s/\s+\z//;
is($os, 'linux', 'the Docker daemon runs Linux containers')
    or BAIL_OUT(
        "the Docker daemon reports OSType '$os', not 'linux'.  Use a Windows "
        . "runner with Docker Desktop or WSL2 Linux containers, or point "
        . 'DOCKER_HOST at a Linux daemon',
    );

# The live tests in this suite can overlap - a harness may run files at once,
# and the copy with spaces in its path runs every file again - and while one
# is running its containers are visible to all the others.  One lock in a
# fixed place keeps this run's containers from being taken for another's leak,
# and another's from being taken for this run's.
my $lock_path = File::Spec->catfile(File::Spec->tmpdir, 'app-actions-real-docker.lock');
open my $live_lock, '>>', $lock_path
    or die "Unable to open '$lock_path': $!";
flock($live_lock, LOCK_EX)
    or die "Unable to lock '$lock_path': $!";

# What was already running, so that the check at the end reports this test's
# leaks rather than a container left by an interrupted run of somebody else's.
my $before = _action_run_containers($daemon);
diag 'action-run containers already present before this test: ' . join ' ', @$before
    if @$before;

my $project = tempdir(CLEANUP => 1);
make_path(File::Spec->catdir($project, '.github', 'workflows'));
my $workflow_file = File::Spec->catfile(
    $project, '.github', 'workflows', 'real-docker.yml',
);

open my $handle, '>', $workflow_file or die $!;
print {$handle} <<"YAML";
name: Real Docker
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: $image
    steps:
      - name: Set values
        id: values
        shell: sh
        run: |
          echo "FROM_STEP=hello" >> "\$GITHUB_ENV"
          echo "answer=42" >> "\$GITHUB_OUTPUT"
      - name: Check the environment
        if: env.FROM_STEP == 'hello'
        shell: sh
        run: echo environment-ok
      - name: Check the output
        if: steps.values.outputs.answer == '42'
        shell: sh
        run: echo output-ok
YAML
close $handle;

my $actions = App::Actions->new(
    workflow_file => $workflow_file,
    project_dir   => $project,
    docker_bin    => $docker,
    image         => $image,
    verbose       => 1,
);

my ($stdout, $stderr, $exit) = capture { $actions->run };
$stdout = useful_text($stdout);
$stderr = useful_text($stderr);

diag "stdout:\n$stdout" if $exit != 0;
diag "stderr:\n$stderr" if length $stderr;

is($exit, 0, 'the workflow succeeds against real Docker');
like($stdout, qr/Workflow succeeded/, 'the run reports success');
like($stdout, qr/^ {2}test\s+success$/m, 'the job summary reports success');

# Trailing carriage returns in a script would break these two, so they also
# guard the LF line endings written for the container.
unlike($stdout, qr/Check the environment \(skipped\)/,
    'GITHUB_ENV reaches later steps through a real bind mount');
unlike($stdout, qr/Check the output \(skipped\)/,
    'GITHUB_OUTPUT reaches later steps through a real bind mount');

my ($container) = $stdout =~ /--name\s+(\S+)/;
ok(defined $container, 'the job container is named');
if (defined $container) {
    my (undef, $inspect_rc) = $daemon->capture_silent(
        'container', 'inspect', $container,
    );
    isnt($inspect_rc, 0, 'the job container is removed afterwards');
}

my $check = App::Actions::Check->new(
    docker_bin => $docker,
    image      => $image,
    directory  => $project,
);
my $check_exit;
my ($check_out) = capture { $check_exit = $check->run };
$check_out = useful_text($check_out);

is($check_exit, 0, 'the check command reports a ready environment');
like($check_out, qr/^Result: ready$/m, 'check reports ready');
like($check_out, qr{-> /check-project: OK \(\d+ entr}, 'check mounts the project directory');

# The smoke script is what a user runs on Windows against Docker Desktop, so
# it is exercised here against the real daemon too.
my $root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $smoke = File::Spec->catfile($root, 'bin', 'action-run-smoke');

my $smoke_exit;
my ($smoke_out, $smoke_err) = capture {
    $smoke_exit = App::Actions::Process::stream([
        $^X, $smoke, '--docker', $docker, '--image', $image, '--directory', $project,
    ]);
};
$smoke_out = useful_text($smoke_out);

diag "smoke stdout:\n$smoke_out" if $smoke_exit != 0;
diag "smoke stderr:\n" . useful_text($smoke_err) if length $smoke_err;

is($smoke_exit, 0, 'the smoke script passes against the real daemon');
like($smoke_out, qr/^Result: smoke test passed$/m, 'the smoke script reports a pass');
like($smoke_out, qr/^ {2}workflow\s+one job/m, 'the smoke script reports the workflow it runs');

# Nothing this test started should be left running, the smoke run included.
my %already = map { $_ => 1 } @$before;
my @leftovers = grep { !$already{$_} } @{ _action_run_containers($daemon) };
is_deeply(\@leftovers, [], 'no action-run containers are left behind');

# A failure here is only actionable with the containers named, not with the
# bare IDs the assertion prints.
if (@leftovers) {
    my ($detail) = $daemon->capture_silent(
        'ps', '--all', '--format', '{{.ID}} {{.Names}} {{.Image}} {{.Status}}',
        '--filter', 'name=action-run',
    );
    diag "action-run containers still present:\n" . useful_text($detail);
}

done_testing;

# The containers a run starts are named action-run-*, so they can be listed
# and compared with what was there beforehand.  Every state counts: a
# container that stopped instead of being removed is still one the run left
# behind.
sub _action_run_containers {
    my ($daemon) = @_;

    my ($output) = $daemon->capture_silent(
        'ps', '--all', '--quiet', '--filter', 'name=action-run',
    );

    return [ sort grep { length } split /\s+/, useful_text($output) ];
}
