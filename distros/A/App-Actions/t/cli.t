use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Time::HiRes ();

use JSON::PP ();

my $root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $lib = File::Spec->catdir($root, 'lib');
my $script = File::Spec->catfile($root, 'bin', 'action-run');
my $fake_docker = File::Spec->catfile($root, 't', 'bin', 'fake-docker');

# Object::Configure reads the developer's own configuration files (~/.conf
# and the like), where a UNIVERSAL logger would take the messages these tests
# read off standard error.  An empty directory leaves the defaults in force.
local $ENV{CONFIG_DIR} = tempdir(CLEANUP => 1);

# The images a run keeps are recorded for "action-run cache"; point that
# record at a temporary file so the suite does not touch the real cache.
local $ENV{ACTION_RUN_CACHE_FILE}
    = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
local $ENV{ACTION_RUN_LOG_DIR}
    = File::Spec->catdir(tempdir(CLEANUP => 1), 'logs');

sub make_project {
    my ($yaml) = @_;

    my $project = tempdir(CLEANUP => 1);
    make_path(File::Spec->catdir($project, '.github', 'workflows'));
    my $workflow = File::Spec->catfile($project, '.github', 'workflows', 'test.yml');
    open my $handle, '>', $workflow or die $!;
    print {$handle} $yaml;
    close $handle;

    return ($project, $workflow);
}

# Windows writes CRLF when a program's output is redirected to a file, and
# the tests below match against the end of the line.
sub useful_text {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/\r\n/\n/g;
    return $text;
}

sub run_cli {
    my (@args) = @_;

    my ($stdout, $stderr, $status) = capture {
        system($^X, '-I' . $lib, $script, @args);
    };

    # $? carries the POSIX-compatible status on Windows too.
    return (useful_text($stdout), useful_text($stderr), $status >> 8);
}

# Windows pulls one image at a time whatever is asked for, and the preflight
# reports the number the puller was given rather than the number requested.
sub effective_concurrency {
    my ($asked) = @_;

    return $^O eq 'MSWin32' ? 1 : $asked;
}

my ($version_out, $version_err, $version_exit) = run_cli('--version');
is($version_exit, 0, '--version exits 0');
like($version_out, qr/^action-run 0\.002\.1$/, '--version prints the version');

my ($help_out, $help_err, $help_exit) = run_cli('--help');
is($help_exit, 0, '--help exits 0');
like($help_out, qr/Usage:/, '--help prints usage');
like($help_out, qr/--dry-run/, '--help lists options');
like($help_out, qr/--explain/, '--help lists the container report');
like($help_out, qr/--no-keep-images/, '--help lists the way to drop the image cache');
like($help_out, qr/--parallel/, '--help lists the parallel option');

my $yaml = <<'YAML';
name: CLI test
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        perl: ['5.38', '5.40']
    steps:
      - run: echo hello
YAML

my ($project, $workflow) = make_project($yaml);

my ($list_out, $list_err, $list_exit) = run_cli('--list', $workflow, $project);
is($list_exit, 0, '--list exits 0');
like($list_out, qr/^test\t/m, '--list shows job ids');
like($list_out, qr/test \(perl=5\.38\)/, '--list shows matrix display names');

my ($infer_out, $infer_err, $infer_exit) = run_cli('--list', $workflow);
is($infer_exit, 0, 'project directory can be inferred');
like($infer_out, qr/test \(perl=5\.40\)/, 'inferred project lists jobs');

my ($dry_out, $dry_err, $dry_exit) = run_cli('--dry-run', '--verbose', $workflow, $project);
is($dry_exit, 0, '--dry-run exits 0');
like($dry_out, qr/\[dry-run\]/, '--dry-run prints Docker commands');
like($dry_out, qr/--- script ---/, '--dry-run --verbose prints scripts');

# --explain is the same dry run with the containers as its output, so it must
# not need the Docker command it is given.
my ($explain_out, $explain_err, $explain_exit) = run_cli(
    '--explain', '--docker', File::Spec->catfile($project, 'absent-docker'),
    $workflow, $project,
);
is($explain_exit, 0, '--explain exits 0 without a Docker daemon');
is($explain_err, '', '--explain writes nothing to standard error');
like($explain_out, qr/^==> Job 'test'$/m, '--explain reports the job container');
like($explain_out, qr/^ {4}command {4}-c 'while :; do sleep 3600; done'$/m,
    '--explain reports what the job container would be told to run');
unlike($explain_out, qr/^\[dry-run\]/m, '--explain lists containers, not commands');

{
    my (undef, $explain_bad_err, $explain_bad_exit) = run_cli(
        '--explain', 'check', $project,
    );
    is($explain_bad_exit, 2, '--explain with the check command is a usage error');
    like($explain_bad_err, qr/--explain is only used when running a workflow/,
        'the error says which command --explain belongs to');
}

my $state = tempdir(CLEANUP => 1);
local $ENV{FAKE_DOCKER_STATE} = $state;
local $ENV{FAKE_DOCKER_LOG} = File::Spec->catfile($state, 'docker.log');

my ($run_out, $run_err, $run_exit) = run_cli(
    '--parallel=2', '--docker', $fake_docker, $workflow, $project,
);
is($run_exit, 0, 'CLI run with fake Docker succeeds');
like($run_out, qr/Workflow succeeded/, 'CLI prints a summary');
unlike($run_out, qr/^ {2}mount\s/m, 'the environment probe is silent when it passes');

# A matrix run beside itself keeps a log per job and says where to find them.
SKIP: {
    skip 'jobs run one at a time where fork() is not reliable', 1
        if $^O eq 'MSWin32';

    like($run_out, qr/^Job logs kept in (.+)$/m,
        'the CLI says where it kept the parallel job logs');
}

# The images a run pulls are kept by default, so a later run of the same
# workflow starts from them; --no-keep-images is the opt-out.  Each half gets
# its own daemon state and log, so one run's image does not answer the other's
# pull.
{
    my $keep_state = tempdir(CLEANUP => 1);
    my $keep_log   = File::Spec->catfile($keep_state, 'keep.log');

    {
        local $ENV{FAKE_DOCKER_STATE} = $keep_state;
        local $ENV{FAKE_DOCKER_LOG}   = $keep_log;

        my (undef, undef, $exit) = run_cli(
            '--docker', $fake_docker, $workflow, $project,
        );
        is($exit, 0, 'a CLI run with the images kept succeeds');
    }

    open my $kept, '<', $keep_log or die "Unable to read '$keep_log': $!";
    my $kept_log = useful_text(do { local $/; <$kept> });
    close $kept;

    unlike($kept_log, qr/^image\trm\t/m,
        'the images the CLI pulled are still there for the next run');

    my $remove_state = tempdir(CLEANUP => 1);
    my $remove_log   = File::Spec->catfile($remove_state, 'remove.log');

    local $ENV{FAKE_DOCKER_STATE} = $remove_state;
    local $ENV{FAKE_DOCKER_LOG}   = $remove_log;

    my (undef, undef, $remove_exit) = run_cli(
        '--no-keep-images', '--docker', $fake_docker, $workflow, $project,
    );
    is($remove_exit, 0, '--no-keep-images runs the workflow');

    open my $removed, '<', $remove_log or die "Unable to read '$remove_log': $!";
    my $removed_log = useful_text(do { local $/; <$removed> });
    close $removed;

    like($removed_log, qr/^image\trm\t-f\t/m,
        '--no-keep-images removes the images it pulled');
}

# Jobs run beside each other by default, with the number of processors as the
# ceiling; --parallel=off is the way back to one at a time.
{
    my (undef, $bad_err, $bad_exit) = run_cli(
        '--parallel', 'soon', $workflow, $project,
    );
    is($bad_exit, 2, 'a --parallel value that is not a count is a usage error');
    like(
        $bad_err,
        qr/--parallel must be 'off' or a positive integer/,
        'the error says what --parallel takes',
    );

    my ($off_out, $off_err, $off_exit) = run_cli(
        '--parallel=off', '--docker', $fake_docker, $workflow, $project,
    );
    is($off_exit, 0, '--parallel=off runs the workflow');
    is($off_err, '', '--parallel=off reports no error');
    like($off_out, qr/Workflow succeeded/, '--parallel=off reaches the summary');
}

# The output arrives while the jobs run rather than in one block at the end.
# Each job prints before it sleeps, and the line is read from the pipe while
# the job is still working; a buffered implementation would show every line at
# the same moment.
SKIP: {
    skip 'parallel jobs need a reliable fork()', 3 if $^O eq 'MSWin32';

    my $stream_yaml = <<'YAML';
name: Streaming
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        n: [one, two]
    steps:
      - run: |
          echo "starting ${{ matrix.n }}"
          sleep 1
          echo "finishing ${{ matrix.n }}"
YAML

    my ($stream_project, $stream_workflow) = make_project($stream_yaml);
    my $stream_state = tempdir(CLEANUP => 1);
    local $ENV{FAKE_DOCKER_STATE} = $stream_state;
    local $ENV{FAKE_DOCKER_LOG}   = File::Spec->catfile($stream_state, 'stream.log');

    my $start = Time::HiRes::time();

    open my $pipe, '-|', $^X, '-I' . $lib, $script,
        '--parallel=2', '--docker', $fake_docker, $stream_workflow, $stream_project
        or die "Unable to run action-run: $!";

    my ($first_job_line, @lines);
    while (my $line = <$pipe>) {
        $line = useful_text($line);
        chomp $line;
        push @lines, $line;
        $first_job_line = Time::HiRes::time() - $start
            if !defined $first_job_line && $line =~ /^\[test \(n=/;
    }
    close $pipe;

    my $exit  = $? >> 8;
    my $total = Time::HiRes::time() - $start;

    is($exit, 0, 'the streaming run succeeds');
    ok(defined $first_job_line,
        'a job line names the job it came from');

    # Each job sleeps a second after printing, so a block printed at the end
    # would put its first line at the end too.
    ok(
        defined $first_job_line && $total - $first_job_line > 0.4,
        sprintf(
            'the first job line arrived %.2fs before the run finished',
            defined $first_job_line ? $total - $first_job_line : 0,
        ),
    );
}

{
    local $ENV{FAKE_OS_TYPE} = 'windows';
    my ($blocked_out, $blocked_err, $blocked_exit) = run_cli(
        '--docker', $fake_docker, $workflow, $project,
    );
    is($blocked_exit, 2, 'a run stops when the environment is not ready');
    like($blocked_out, qr/^ {2}problem\s+the daemon runs 'windows' containers/m,
        'the probe report explains the problem');
    like($blocked_err, qr/--skip-check/, 'the failure names the way past the probe');
    unlike($blocked_err, qr/ at \S+ line \d+/, 'the failure reads as a sentence');

    my ($skipped_out, $skipped_err, $skipped_exit) = run_cli(
        '--skip-check', '--docker', $fake_docker, $workflow, $project,
    );
    is($skipped_exit, 0, '--skip-check runs the workflow anyway');
    like($skipped_out, qr/Workflow succeeded/, '--skip-check reaches the workflow');
    is($skipped_err, '', '--skip-check reports no error');
}

my ($check_out, $check_err, $check_exit) = run_cli(
    '--docker', $fake_docker, 'check', $project,
);
is($check_exit, 0, 'check exits 0 when the environment is ready');
like($check_out, qr/^action-run check$/m, 'check names itself in the report');
like($check_out, qr/^ {2}daemon\s+.*linux containers$/m, 'check reports the daemon');
like($check_out, qr{-> /check-project: OK \(\d+ entr}, 'check probes the project directory');
like($check_out, qr/^Result: ready$/m, 'check reports ready');

my ($json_out, $json_err, $json_exit) = run_cli(
    '--docker', $fake_docker, 'check', '--json', $project,
);
is($json_exit, 0, 'check --json exits 0 when the environment is ready');
like($json_out, qr/^\{"docker":/, 'check --json prints one JSON object');
unlike($json_out, qr/^action-run check$/m, 'check --json prints no text report');
is($json_err, '', 'check --json writes nothing to standard error');

my ($json_first_out, undef, $json_first_exit) = run_cli(
    '--json', '--docker', $fake_docker, 'check', $project,
);
is($json_first_exit, 0, '--json before the command works too');
like($json_first_out, qr/^\{"docker":/, 'the option order does not matter');

# preflight --json reports what the run would prepare, so that CI can assert
# on the images rather than on the pull output.
my $preflight_yaml = <<'YAML';
name: Preflight
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
      - run: echo hello
YAML

my ($preflight_project, $preflight_workflow) = make_project($preflight_yaml);

my ($preflight_out, $preflight_err, $preflight_exit) = run_cli(
    '--docker', $fake_docker, 'preflight', '--json',
    $preflight_workflow, $preflight_project,
);
is($preflight_exit, 0, 'preflight --json exits 0 when every image is ready');
like($preflight_out, qr/^\{"docker":/, 'preflight --json prints one JSON object');
unlike($preflight_out, qr/^Pulling image/m, 'preflight --json prints no pull progress');
is($preflight_err, '', 'preflight --json writes nothing to standard error');

my $preflight_data = eval { JSON::PP->new->decode($preflight_out) };
ok($preflight_data, 'the preflight JSON decodes') or diag "$@";
ok($preflight_data->{ready}, 'the preflight is ready');
is($preflight_data->{problems}, 0, 'no problems are counted');
is($preflight_data->{image}, 'perl:5.38',
    'the probe image is reported alongside the check report');
is($preflight_data->{pull_concurrency}, effective_concurrency(4),
    'the pull concurrency in force is reported, four by default');
is(scalar @{ $preflight_data->{images} }, 3, 'every needed image is listed');
is($preflight_data->{images}[0]{image}, 'perl:5.38', 'the job image is listed first');
is($preflight_data->{images}[0]{source}, "job 'test'",
    'the job image names the job that needs it');
is($preflight_data->{images}[1]{source}, "service 'db' of job 'test'",
    'the service image names the service and the job');
is($preflight_data->{images}[2]{source},
    "action 'docker://alpine:3.20' in job 'test'",
    'the action image names the action and the job');
ok($preflight_data->{images}[0]{status} eq 'pulled'
    || $preflight_data->{images}[0]{status} eq 'present',
    'an image is reported as pulled or present, never both');

my ($preflight_first_out, undef, $preflight_first_exit) = run_cli(
    '--json', '--docker', $fake_docker, 'preflight',
    $preflight_workflow, $preflight_project,
);
is($preflight_first_exit, 0, '--json before the preflight command works too');
like($preflight_first_out, qr/^\{"docker":/, 'the option order does not matter');

# An image a step decides cannot be named before the run, so the preflight
# says so rather than guessing; CI can assert on the deferral as easily as on
# a pull.
my $deferred_yaml = <<'YAML';
name: Deferred image
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perl:5.38
    steps:
      - id: pick
        run: |
          FAKE_OUTPUT: image=alpine:3.20
      - uses: docker://${{ steps.pick.outputs.image }}
YAML

my ($deferred_project, $deferred_workflow) = make_project($deferred_yaml);

my ($deferred_out, $deferred_err, $deferred_exit) = run_cli(
    '--docker', $fake_docker, 'preflight', '--json',
    $deferred_workflow, $deferred_project,
);
is($deferred_exit, 0, 'a deferred image leaves the preflight ready');
is($deferred_err, '', 'a deferral writes nothing to standard error');

my $deferred = eval { JSON::PP->new->decode($deferred_out) };
ok($deferred, 'the deferred preflight JSON decodes') or diag "$@";
is($deferred->{images}[1]{status}, 'deferred',
    'the image a step decides is reported as deferred');
is($deferred->{images}[1]{image}, undef, 'no name is guessed for it');
is($deferred->{images}[1]{expression}, '${{ steps.pick.outputs.image }}',
    'the expression is reported as it was written');
like($deferred->{images}[1]{error}, qr/unable to resolve/,
    'the reason it cannot be named is reported with it');
ok($deferred->{ready}, 'everything the preflight could check is ready');
is($deferred->{problems}, 0, 'a deferral is not counted as a problem');

# The pull concurrency is a first-class setting: lower it for a slow
# registry from the command line or the environment, and refuse a value that
# is not a positive integer rather than quietly pulling four at a time.
like($help_out, qr/--pull-concurrency/, '--help lists the pull concurrency option');

my ($concurrent_out, undef, $concurrent_exit) = run_cli(
    '--docker', $fake_docker, '--pull-concurrency', '1', 'preflight', '--json',
    $preflight_workflow, $preflight_project,
);
is($concurrent_exit, 0, '--pull-concurrency 1 is accepted');

my $concurrent = eval { JSON::PP->new->decode($concurrent_out) } || {};
ok($concurrent->{ready}, 'the preflight is still ready with one pull at a time');
is($concurrent->{pull_concurrency}, 1,
    'the option reaches the puller, and the document says so');

{
    local $ENV{ACTION_RUN_PULL_CONCURRENCY} = 2;

    my ($env_out, undef, $env_exit) = run_cli(
        '--docker', $fake_docker, '--json', 'preflight',
        $preflight_workflow, $preflight_project,
    );
    is($env_exit, 0, 'ACTION_RUN_PULL_CONCURRENCY is accepted');
    is((eval { JSON::PP->new->decode($env_out) } || {})->{pull_concurrency},
        effective_concurrency(2),
        'the environment value reaches the puller, and the document says so');
}

for my $bad ('0', '-1', 'lots') {
    my (undef, $bad_err, $bad_exit) = run_cli(
        '--docker', $fake_docker, '--pull-concurrency', $bad, 'preflight',
        $preflight_workflow, $preflight_project,
    );
    is($bad_exit, 2, "--pull-concurrency $bad is a usage error");
    like($bad_err, qr/pull concurrency must be a positive integer, not '\Q$bad\E'/,
        "the value $bad is named in the error");
    unlike($bad_err, qr/ at \S+ line \d+/, 'the error reads as a sentence');
}

{
    local $ENV{ACTION_RUN_PULL_CONCURRENCY} = 'zero';

    my (undef, $env_err, $env_exit) = run_cli(
        '--docker', $fake_docker, 'preflight',
        $preflight_workflow, $preflight_project,
    );
    is($env_exit, 2, 'a bad value in the environment is a usage error');
    like($env_err, qr/pull concurrency must be a positive integer, not 'zero'/,
        'the environment value is named');
}

{
    local $ENV{ACTION_RUN_PULL_CONCURRENCY} = 'zero';

    my ($override_out, undef, $override_exit) = run_cli(
        '--docker', $fake_docker, '--pull-concurrency', '2', '--json',
        'preflight', $preflight_workflow, $preflight_project,
    );
    is($override_exit, 0, 'the option wins over a bad value in the environment');
    is((eval { JSON::PP->new->decode($override_out) } || {})->{pull_concurrency},
        effective_concurrency(2),
        'the option is what the document reports when both are set');
}

{
    local $ENV{FAKE_PULL_FAILURE} = 'postgres:15';

    # --pull makes the cached image fail as well, so the test does not depend
    # on which run happened to leave it behind.
    my ($failed_out, $failed_err, $failed_exit) = run_cli(
        '--pull', '--docker', $fake_docker, '--json', 'preflight',
        $preflight_workflow, $preflight_project,
    );
    is($failed_exit, 2, 'preflight --json exits 2 when an image cannot be pulled');
    is($failed_err, '', 'a JSON failure still writes nothing to standard error');

    my $failed = eval { JSON::PP->new->decode($failed_out) };
    ok($failed, 'the failing preflight JSON decodes') or diag "$@";
    ok(!$failed->{ready}, 'the failing preflight is not ready');
    is($failed->{problems}, 1, 'the failed image is counted as a problem');
    is($failed->{images}[1]{status}, 'failed', 'the image that failed is marked');
    like($failed->{images}[1]{error},
        qr/Failed to pull Docker image 'postgres:15'/,
        'the image carries the reason it failed');
    like($failed->{issues}[0]{problem},
        qr/cannot prepare the image 'postgres:15', needed by service 'db' of job 'test'/,
        'the issue names the image, the service and the job');
    ok(scalar @{ $failed->{issues}[0]{remedies} },
        'the issue carries a remedy');

    my ($text_out, $text_err, $text_exit) = run_cli(
        '--pull', '--docker', $fake_docker, 'preflight',
        $preflight_workflow, $preflight_project,
    );
    is($text_exit, 2, 'preflight reports the same failure as text');
    like($text_out, qr/^Pulling image/m, 'text mode still shows the pulls');
    like($text_out, qr/^ {2}image {5}postgres:15 \(service 'db' of job 'test'\): failed$/m,
        'text mode says which image could not be prepared');
    like($text_out, qr/^ {2}image {5}perl:5\.38 \(job 'test'\): pulled$/m,
        'text mode says what happened to each image');
    unlike($text_out, qr/^\{"docker":/, 'text mode prints no JSON');
    like($text_err, qr/cannot prepare the image 'postgres:15'/,
        'text mode explains the failure on standard error');
}

{
    local $ENV{FAKE_OS_TYPE} = 'windows';

    my ($blocked_out, undef, $blocked_exit) = run_cli(
        '--docker', $fake_docker, 'preflight', '--json',
        $preflight_workflow, $preflight_project,
    );
    is($blocked_exit, 2, 'preflight --json exits 2 when the environment is not ready');

    my $blocked = eval { JSON::PP->new->decode($blocked_out) };
    ok($blocked, 'the blocked preflight JSON decodes') or diag "$@";
    ok(!$blocked->{ready}, 'a broken environment is not ready');
    like($blocked->{issues}[0]{problem}, qr/'windows' containers/,
        'the check issue is reported');
    is(scalar @{ $blocked->{images} }, 3, 'the needed images are still listed');
    is($blocked->{images}[0]{status}, 'skipped',
        'nothing is claimed to be prepared for a broken environment');

    my ($skipped_out, undef, $skipped_exit) = run_cli(
        '--skip-check', '--docker', $fake_docker, 'preflight', '--json',
        $preflight_workflow, $preflight_project,
    );
    is($skipped_exit, 0, '--skip-check prepares the images without probing');

    my $skipped = eval { JSON::PP->new->decode($skipped_out) };
    ok($skipped, 'the skipped-probe JSON decodes') or diag "$@";
    ok($skipped->{ready}, 'the images alone are enough to be ready');
    is($skipped->{docker}{daemon}, undef, 'no probe result is claimed');
}

my ($preflight_usage_out, $preflight_usage_err, $preflight_usage_exit) = run_cli('preflight');
is($preflight_usage_exit, 2, 'preflight needs a workflow');
like($preflight_usage_err,
    qr/Usage: action-run \[options\] preflight <workflow\.yml> \[project-directory\]/,
    'the preflight usage is shown');

my ($json_usage_out, $json_usage_err, $json_usage_exit) = run_cli(
    '--json', 'workflow.yml', 'project',
);
is($json_usage_exit, 2, '--json without a command that uses it is a usage error');
like($json_usage_err, qr/only used by the check, preflight, cache and logs commands/,
    'the misuse is explained');

my ($check_usage_out, $check_usage_err, $check_usage_exit) = run_cli('check', 'a', 'b');
is($check_usage_exit, 2, 'check rejects more than one directory');
like($check_usage_err, qr/Usage: action-run \[options\] check \[directory\]/,
    'check explains its usage');

{
    local $ENV{FAKE_NO_DAEMON} = 1;
    my ($down_out, $down_err, $down_exit) = run_cli(
        '--docker', $fake_docker, 'check', $project,
    );
    is($down_exit, 2, 'check exits 2 when the daemon is unreachable');
    like($down_out, qr/^Result: not ready \(1 problem\)$/m, 'check reports the problem');
    like($down_out, qr/^ {2}remedy\s+\S/m, 'check prints a remedy beside the problem');
}

my ($missing_out, $missing_err, $missing_exit) = run_cli('--list', 'no-such-workflow.yml');
is($missing_exit, 2, 'missing workflow exits 2');
like($missing_err, qr/does not exist|not found/, 'missing workflow is reported');

my ($bad_job_out, $bad_job_err, $bad_job_exit) = run_cli(
    '--list', '--job', 'no-such-job', $workflow, $project,
);
is($bad_job_exit, 2, 'unknown job filter exits 2');
like($bad_job_err, qr/No job matched/, 'unknown job filter is reported');

my ($bad_env_out, $bad_env_err, $bad_env_exit) = run_cli(
    '--env', 'NOT_A_PAIR', '--list', $workflow, $project,
);
is($bad_env_exit, 2, 'invalid --env exits 2');
like($bad_env_err, qr/NAME=VALUE/, 'invalid --env is reported');

my ($conflict_out, $conflict_err, $conflict_exit) = run_cli(
    '--pull', '--no-pull', '--list', $workflow, $project,
);
is($conflict_exit, 2, 'conflicting pull options exit 2');
like($conflict_err, qr/cannot be used together/, 'conflicting pull options are reported');

# A variable name is checked to its very end: with ^...$ a name followed by a
# newline was accepted and handed to docker -e as it was.
SKIP: {
    skip 'a newline in an argument does not survive the Windows command line', 3
        if $^O eq 'MSWin32';

    my ($env_out, $env_err, $env_exit) = run_cli('--env', "FOO\n=bar", 'list');
    is($env_exit, 2, 'a variable name ending in a newline exits 2');
    like($env_err, qr/--env expects NAME=VALUE/, 'and says what --env expects');
    is($env_out, '', 'without listing anything');
}

done_testing;
