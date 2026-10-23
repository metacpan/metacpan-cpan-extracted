use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use JSON::PP ();

use App::Actions::Check;

my $fake_docker = File::Spec->rel2abs(
    File::Spec->catfile(dirname(__FILE__), 'bin', 'fake-docker'),
);

# Windows writes CRLF when output is redirected to a file, and several checks
# match against the end of a line.
sub useful_text {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/\r\n/\n/g;
    return $text;
}

sub run_check {
    my (%options) = @_;

    my $state = tempdir(CLEANUP => 1);
    my $log   = File::Spec->catfile($state, 'docker.log');
    local $ENV{FAKE_DOCKER_STATE}   = $state;
    local $ENV{FAKE_DOCKER_LOG}     = $log;
    local $ENV{FAKE_NO_DAEMON}      = $options{no_daemon} ? 1 : 0;
    local $ENV{FAKE_OS_TYPE}        = $options{os_type};
    local $ENV{FAKE_BAD_MOUNT}      = $options{bad_mount} ? 1 : 0;
    local $ENV{FAKE_MOUNT_FAILURE}  = $options{mount_failure} ? 1 : 0;
    local $ENV{FAKE_ENTRY_COUNT}    = $options{entry_count};

    my $check = App::Actions::Check->new(
        docker_bin => defined $options{docker_bin} ? $options{docker_bin} : $fake_docker,
        directory  => $options{directory},
        (%{ $options{args} || {} }),
    );

    my ($stdout, $stderr, $exit) = capture { $check->run };

    my $log_text = '';
    if (-f $log) {
        open my $handle, '<', $log or die $!;
        local $/;
        $log_text = <$handle>;
        close $handle;
        $log_text = '' unless defined $log_text;
    }

    return {
        stdout => useful_text($stdout),
        stderr => useful_text($stderr),
        exit   => $exit,
        log    => useful_text($log_text),
    };
}

sub write_file {
    my ($path, $contents) = @_;

    open my $handle, '>', $path or die $!;
    print {$handle} $contents;
    close $handle;

    return $path;
}

is(App::Actions::Check->new->image, 'alpine:3.20', 'the probe image defaults to a small one');
is(App::Actions::Check->new(image => 'perl:5.38')->image, 'perl:5.38', 'the probe image can be chosen');

my $ready = run_check();
is($ready->{exit}, 0, 'a working environment is ready');
like($ready->{stdout}, qr/^action-run check$/m, 'the report names the command');
like($ready->{stdout}, qr/^ {2}host\s+\S.*perl \d/m, 'the host platform is reported');
like($ready->{stdout}, qr/^ {2}docker\s+\S/m, 'the Docker command is reported');
like($ready->{stdout}, qr/^ {2}client\s+26\.0\.0$/m, 'the client version is reported');
like($ready->{stdout}, qr/^ {2}daemon\s+26\.0\.0, linux containers$/m,
    'the daemon version and container type are reported');
like($ready->{stdout}, qr{^ {2}mount\s+\S.* -> /action-run-check: OK$}m,
    'the temporary directory is mounted and read back');
like($ready->{stdout}, qr/^Result: ready$/m, 'the result is reported');

# A report pasted into an issue says which contract its lines were written
# against, and the version comes before the verdict.
my $version = App::Actions::Check->json_schema_version;
like(
    $ready->{stdout},
    qr/^ {2}schema {4}version \Q$version\E \(action-run schema check\)$/m,
    'the report names the schema it was written against',
);
my $schema_at = index($ready->{stdout}, 'schema    version');
my $verdict_at = index($ready->{stdout}, 'Result: ready');
ok(
    $schema_at >= 0 && $schema_at < $verdict_at,
    'the schema is named, and before the verdict',
);

my $untold = run_check(args => { schema_line => 0 });
unlike($untold->{stdout}, qr/^ {2}schema/m,
    'a caller that prints its own contract can leave the line out');

unlike($ready->{stdout}, qr{/check-project}, 'no project directory is probed unless asked');
unlike($ready->{stdout}, qr/^ {2}remedy/m, 'a ready environment suggests nothing');
is($ready->{stderr}, '', 'nothing is written to standard error');

my $project = tempdir(CLEANUP => 1);
write_file(File::Spec->catfile($project, 'first.txt'), "one\n");
write_file(File::Spec->catfile($project, 'second.txt'), "two\n");
make_path(File::Spec->catdir($project, 'subdirectory'));

my $with_directory = run_check(directory => $project);
is($with_directory->{exit}, 0, 'a project directory is ready');
like($with_directory->{stdout}, qr{-> /check-project: OK \(3 entries\)$}m,
    'the project directory is visible inside the container');

my $hidden = run_check(directory => $project, entry_count => 0);
is($hidden->{exit}, 2, 'a project the container cannot see is not ready');
like($hidden->{stdout}, qr/^ {2}problem\s+'.*' -> \/check-project sees 0 entries, the host has 3$/m,
    'the entry counts that disagree are reported');
like($hidden->{stdout}, qr/^ {2}remedy\s+\S/m, 'a directory that is not visible comes with a remedy');
like(
    $hidden->{stdout},
    $^O eq 'MSWin32'
        ? qr/^ {2}remedy\s+share the drive that holds/m
        : qr/^ {2}remedy\s+choose a directory the daemon can see/m,
    'the remedy matches the host platform',
);
like($with_directory->{log}, qr/^run\t--rm\t--network\tnone\t/m,
    'the probe container is short-lived and uses no network');
like($with_directory->{log}, qr{\t-v\t[^\t]+:/check-project:ro\t},
    'the project directory is mounted read-only');

my $with_platform = run_check(
    directory => $project,
    args      => { platform => 'linux/amd64' },
);
like($with_platform->{log}, qr/\t--platform\tlinux\/amd64\t/,
    'the requested Docker platform is passed to the probe');

my $windows = run_check(os_type => 'windows');
is($windows->{exit}, 2, 'a Windows-only daemon is not ready');
like($windows->{stdout}, qr/^ {2}daemon\s+26\.0\.0, windows containers$/m,
    'the container type is reported');
like($windows->{stdout}, qr/problem\s+the daemon runs 'windows' containers; action-run needs Linux containers/,
    'the problem is explained');
like($windows->{stdout}, qr/^ {2}remedy\s+\S/m, 'the container type problem comes with a remedy');
like($windows->{stdout}, qr/^Result: not ready \(1 problem\)$/m, 'the result is not ready');
unlike($windows->{stdout}, qr{/action-run-check}, 'no mount probe runs without Linux containers');

my $down = run_check(no_daemon => 1);
is($down->{exit}, 2, 'an unreachable daemon is not ready');
like($down->{stdout}, qr/^ {2}client\s+26\.0\.0$/m, 'the client is still reported');
like($down->{stdout}, qr/problem\s+the daemon is not reachable/, 'the daemon problem is explained');
like($down->{stdout}, qr/^ {2}remedy\s+\S/m, 'the daemon problem comes with a remedy');
like($down->{stdout}, qr/^Result: not ready \(1 problem\)$/m, 'the result is not ready');

my $missing = run_check(
    docker_bin => File::Spec->catfile(tempdir(CLEANUP => 1), 'no-such-docker'),
);
is($missing->{exit}, 2, 'a missing Docker command is not ready');
like($missing->{stdout}, qr/problem\s+the Docker command '.*' could not be run/,
    'the missing command is explained');
like($missing->{stdout}, qr/^ {2}remedy\s+.*--docker/m,
    'the missing command suggests --docker');

my $bad_mount = run_check(bad_mount => 1);
is($bad_mount->{exit}, 2, 'an unreadable mount is not ready');
like($bad_mount->{stdout},
    qr/problem\s+the container could not read the mounted temporary directory/,
    'the mount problem is explained');
like($bad_mount->{stdout}, qr/^ {2}remedy\s+\S/m, 'the mount problem comes with a remedy');

my $failed_probe = run_check(mount_failure => 1);
is($failed_probe->{exit}, 2, 'a failing probe container is not ready');
like($failed_probe->{stdout}, qr/problem\s+the probe container failed \(exit 1\)/,
    'the probe failure is explained');
like($failed_probe->{stdout}, qr/^ {2}remedy\s+run "docker pull alpine:3\.20" by hand/m,
    'the probe failure suggests pulling the image by hand');
like($failed_probe->{stdout}, qr/^ {2}remedy\s+.*--platform linux\/amd64/m,
    'the probe failure suggests --platform for emulated images');

# The remedies name the platform's own tools, so both sets are checked from
# every host rather than only from the one they apply to.
my $windows_os = { os => 'MSWin32' };
{
    my $on_windows = run_check(no_daemon => 1, args => $windows_os);
    like($on_windows->{stdout}, qr/^ {2}host\s+Windows \(MSWin32\)/m,
        'the host line follows the platform the report is for');
    like($on_windows->{stdout}, qr/^ {2}remedy\s+start Docker Desktop/m,
        'a Windows host is told to start Docker Desktop');
    like($on_windows->{stdout}, qr/^ {2}remedy\s+.*wsl --shutdown/m,
        'a Windows host is told how to restart the WSL 2 backend');

    my $windows_daemon = run_check(os_type => 'windows', args => $windows_os);
    like(
        $windows_daemon->{stdout},
        qr/^ {2}remedy\s+right-click the Docker Desktop tray icon and choose "Switch to Linux containers"$/m,
        'a Windows host is told how to switch to Linux containers',
    );

    my $windows_mount = run_check(bad_mount => 1, args => $windows_os);
    like($windows_mount->{stdout},
        qr/^ {2}remedy\s+share the drive that holds the temporary directory/m,
        'a Windows host is told to share the temporary directory drive');

    my $windows_hidden = run_check(
        directory => $project, entry_count => 0, args => $windows_os,
    );
    like($windows_hidden->{stdout},
        qr/^ {2}remedy\s+share the drive that holds '.*' in Docker Desktop > Settings > Resources > File sharing$/m,
        'a Windows host is told which drive to share, by name');

    my $windows_missing = run_check(
        docker_bin => File::Spec->catfile(tempdir(CLEANUP => 1), 'no-such-docker'),
        args       => $windows_os,
    );
    like($windows_missing->{stdout}, qr/^ {2}remedy\s+install Docker Desktop/m,
        'a Windows host is told to install Docker Desktop');
}

{
    my $on_unix = run_check(no_daemon => 1, args => { os => 'linux' });
    like($on_unix->{stdout}, qr/^ {2}remedy\s+start the Docker daemon/m,
        'a Unix host is told how to start the daemon');
    like($on_unix->{stdout}, qr/^ {2}remedy\s+.*DOCKER_HOST/m,
        'a Unix host is told about DOCKER_HOST');
}

my $not_a_directory = File::Spec->catfile(tempdir(CLEANUP => 1), 'file.txt');
write_file($not_a_directory, "contents\n");
my $bad_directory = run_check(directory => $not_a_directory);
is($bad_directory->{exit}, 2, 'a file is not a directory to mount');
like($bad_directory->{stdout}, qr/problem\s+'.*' is not a directory/,
    'the directory problem is explained');
like($bad_directory->{stdout}, qr/^ {2}remedy\s+pass a directory that exists/m,
    'a file is explained with a remedy');

my $quiet_result = run_check(args => { summary => 0 });
is($quiet_result->{exit}, 0, 'a caller can suppress the result line');
unlike($quiet_result->{stdout}, qr/^Result:/m, 'the caller is left to report the verdict');
like($quiet_result->{stdout}, qr/^action-run check$/m, 'the heading is still printed');

my $untitled = run_check(args => { title => '' });
is($untitled->{exit}, 0, 'a caller can suppress the heading');
unlike($untitled->{stdout}, qr/^action-run check$/m, 'the heading is left to the caller');
like($untitled->{stdout}, qr/^ {2}host\s+\S/m, 'the report body is still printed');
like($untitled->{stdout}, qr/^Result: ready$/m, 'the result is still printed');

{
    my $quiet_ready = run_check(args => { quiet => 1 });
    is($quiet_ready->{exit}, 0, 'a quiet check still passes');
    is($quiet_ready->{stdout}, '', 'a quiet check says nothing when all is well');
}

{
    my $quiet_broken = run_check(no_daemon => 1, args => { quiet => 1 });
    is($quiet_broken->{exit}, 2, 'a quiet check still fails');
    like($quiet_broken->{stdout}, qr/^action-run check$/m,
        'a quiet check prints the report when something is wrong');
    like($quiet_broken->{stdout}, qr/^ {2}remedy\s+\S/m, 'the report keeps its remedies');
}

# --json exists so that a CI job can assert on the environment instead of
# matching English prose.
my $json_ready = run_check(directory => $project, args => { json => 1 });
is($json_ready->{exit}, 0, 'a JSON report keeps the exit status');
unlike($json_ready->{stdout}, qr/^action-run check$/m,
    'the JSON report replaces the text one');

like($json_ready->{stdout}, qr/"ready":true/, 'ready is the JSON boolean true');

my $ready_data = eval { JSON::PP->new->decode($json_ready->{stdout}) };
ok($ready_data, 'the JSON report decodes') or diag "$@";
ok($ready_data->{ready}, 'ready is true');
is($ready_data->{problems}, 0, 'no problems are counted');
is($ready_data->{host}{os}, $^O, 'the host platform is reported');
like($ready_data->{host}{perl}, qr/^\d+\.\d+/, 'the perl version is reported');
is($ready_data->{docker}{bin}, $fake_docker, 'the Docker command is reported');
is($ready_data->{docker}{client}, '26.0.0', 'the client version is reported');
is($ready_data->{docker}{daemon}, '26.0.0', 'the daemon version is reported');
is($ready_data->{docker}{containers}, 'linux', 'the container type is reported');
is($ready_data->{image}, 'alpine:3.20', 'the image is reported');
is(scalar @{ $ready_data->{mounts} }, 2, 'both mounts are listed');
is($ready_data->{mounts}[0]{container}, '/action-run-check',
    'the temporary directory mount is named');
ok($ready_data->{mounts}[0]{ok}, 'the temporary directory mount is ok');
is($ready_data->{mounts}[1]{container}, '/check-project', 'the project mount is named');
is($ready_data->{mounts}[1]{entries}, 3, 'the entries seen in the container are reported');
is($ready_data->{mounts}[1]{expected}, 3, 'the entries on the host are reported');
ok($ready_data->{mounts}[1]{ok}, 'the project mount is ok');
is_deeply($ready_data->{issues}, [], 'a ready environment lists no issues');

my $json_broken = run_check(os_type => 'windows', args => { json => 1 });
is($json_broken->{exit}, 2, 'a JSON report keeps the exit status when not ready');
my $broken_data = eval { JSON::PP->new->decode($json_broken->{stdout}) };
ok($broken_data, 'the failing JSON report decodes') or diag "$@";
ok(!$broken_data->{ready}, 'ready is false');
is($broken_data->{problems}, 1, 'the problem is counted');
is($broken_data->{docker}{containers}, 'windows', 'the container type is still reported');
is($broken_data->{image}, undef, 'a value that was not reached is null');
is_deeply($broken_data->{mounts}, [], 'no mounts are claimed when none ran');
is(scalar @{ $broken_data->{issues} }, 1, 'the issue is listed');
like($broken_data->{issues}[0]{problem}, qr/'windows' containers/,
    'the issue carries the problem');
ok(scalar @{ $broken_data->{issues}[0]{remedies} }, 'the issue carries its remedies');
like($broken_data->{issues}[0]{remedies}[0], qr/\S/, 'the remedy is readable');

my $json_hidden = run_check(
    directory => $project, entry_count => 0, args => { json => 1 },
);
is($json_hidden->{exit}, 2, 'a hidden project fails the JSON report');
my $hidden_data = eval { JSON::PP->new->decode($json_hidden->{stdout}) };
ok($hidden_data, 'the hidden-project report decodes') or diag "$@";
ok(!$hidden_data->{mounts}[1]{ok}, 'the project mount is not ok');
is($hidden_data->{mounts}[1]{entries}, 0, 'the entries seen are reported');
is($hidden_data->{mounts}[1]{expected}, 3, 'the entries expected are reported');

my $json_quiet = run_check(args => { json => 1, quiet => 1 });
is($json_quiet->{exit}, 0, 'a quiet JSON report still exits 0');
ok(eval { JSON::PP->new->decode($json_quiet->{stdout}) },
    'a quiet JSON report is still printed');

my $buffer = '';
open my $output, '>', \$buffer or die $!;
{
    local $ENV{FAKE_DOCKER_STATE} = tempdir(CLEANUP => 1);
    my $check = App::Actions::Check->new(
        docker_bin => $fake_docker,
        output     => $output,
    );
    is($check->run, 0, 'the report can be written to a filehandle');
}
close $output;
like($buffer, qr/^Result: ready$/m, 'the chosen filehandle receives the report');

# The same report is available as data, which the preflight adds its images
# to.  "ready" is a plain 0 or 1 here; JSON encodes it as true or false.
my $summary_check;
{
    local $ENV{FAKE_DOCKER_STATE} = tempdir(CLEANUP => 1);
    $summary_check = App::Actions::Check->new(
        docker_bin => $fake_docker,
        directory  => $project,
        quiet      => 1,
    );
    is($summary_check->run, 0, 'a check that is asked for its summary still passes');
}

my $summary = $summary_check->summary(0);
is($summary->{ready}, 1, 'a ready summary is a plain 1');
is($summary->{problems}, 0, 'no problems are counted');
is($summary->{docker}{containers}, 'linux', 'the container type is in the summary');
is($summary->{image}, 'alpine:3.20', 'the probe image is in the summary');
is(scalar @{ $summary->{mounts} }, 2, 'both mounts are in the summary');
is_deeply($summary->{issues}, [], 'a ready summary lists no issues');

my $failed_summary = $summary_check->summary(2);
is($failed_summary->{ready}, 0, 'a failing summary is a plain 0');

done_testing;
