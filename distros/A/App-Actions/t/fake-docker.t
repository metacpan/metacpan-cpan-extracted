use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use FindBin;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib "$FindBin::Bin/lib";

use App::Actions::FakeDocker qw(split_volume mounts to_host);
use App::Actions::Process;

is_deeply(
    [ split_volume('/tmp/project:/github/workspace') ],
    [ '/tmp/project', '/github/workspace' ],
    'a Unix volume specification is split at the colon',
);

is_deeply(
    [ split_volume('C:\\Users\\me\\project:/github/workspace') ],
    [ 'C:\\Users\\me\\project', '/github/workspace' ],
    'a Windows drive letter is not mistaken for the separator',
);

is_deeply(
    [ split_volume('C:/Users/me/project:/github/workspace') ],
    [ 'C:/Users/me/project', '/github/workspace' ],
    'a Windows path with forward slashes is split correctly',
);

is_deeply(
    [ split_volume('/tmp/project:/github/workspace:ro') ],
    [ '/tmp/project', '/github/workspace' ],
    'a read-only mode is dropped',
);

is_deeply(
    [ split_volume('C:\\project:/github/workspace:rw') ],
    [ 'C:\\project', '/github/workspace' ],
    'a Windows host path with a mode is split correctly',
);

is_deeply(
    [ split_volume('data:/var/lib/postgresql/data') ],
    [ 'data', '/var/lib/postgresql/data' ],
    'named volumes are supported',
);

is_deeply([ split_volume('C:\\project') ], [], 'a bare Windows path is not a volume');
is_deeply([ split_volume('/tmp/project') ], [], 'a bare Unix path is not a volume');
is_deeply([ split_volume('') ], [], 'an empty specification is ignored');
is_deeply([ split_volume(undef) ], [], 'an undefined specification is ignored');

my $mounts = mounts([
    'run', '-d',
    '-v', 'C:\\project:/github/workspace',
    '-v', 'data:/var/lib',
    '--volume', '/tmp/runner:/github/actions-runner',
    'alpine:3.20',
]);

is_deeply(
    $mounts,
    {
        '/github/workspace'       => 'C:\\project',
        '/var/lib'                => 'data',
        '/github/actions-runner'  => '/tmp/runner',
    },
    'mounts are collected from a Docker command line',
);

is(
    to_host('/github/workspace/scripts/step-1.sh', $mounts),
    File::Spec->catfile('C:\\project', 'scripts', 'step-1.sh'),
    'container paths are mapped to the host using its own separator',
);

is(
    to_host('/github/actions-runner/env/step-1.env', $mounts),
    File::Spec->catfile('/tmp/runner', 'env', 'step-1.env'),
    'nested container paths are mapped',
);

is(to_host('/elsewhere/step-1.sh', $mounts), undef, 'unmounted paths are not mapped');
is(to_host(undef, $mounts), undef, 'an undefined container path is not mapped');

my $nested = mounts([ '-v', '/a:/github', '-v', '/a/b:/github/workspace' ]);
is(
    to_host('/github/workspace/step.sh', $nested),
    File::Spec->catfile('/a/b', 'step.sh'),
    'the longest matching mount wins',
);

# The fake shell has to see the bytes a real shell would see.  In text mode a
# CR would be translated away, so a CRLF script written by mistake would run
# here while failing on a Linux runner.
my $fake_docker = File::Spec->catfile($FindBin::Bin, 'bin', 'fake-docker');

sub run_step_script {
    my ($contents) = @_;

    my $root    = tempdir(CLEANUP => 1);
    my $scripts = File::Spec->catdir($root, 'runner', 'scripts');
    my $state   = File::Spec->catdir($root, 'state');
    make_path($scripts, $state);

    my $host_script = File::Spec->catfile($scripts, 'step-1.sh');
    open my $handle, '>', $host_script or die $!;
    binmode $handle;
    print {$handle} $contents;
    close $handle;

    # The container's run arguments, as written by "docker run --name".
    my $container = File::Spec->catfile($state, 'container-checkjob');
    open my $state_handle, '>', $container or die $!;
    binmode $state_handle;
    my $mount = File::Spec->catdir($root, 'runner') . ':/github/actions-runner';
    print {$state_handle} join("\t", '-v', $mount);
    close $state_handle;

    my $status;
    my ($stdout, $stderr) = capture {
        local $ENV{FAKE_DOCKER_STATE} = $state;
        $status = App::Actions::Process::stream([
            $^X, $fake_docker, 'exec', 'checkjob', 'sh', '-c',
            'sh /github/actions-runner/scripts/step-1.sh',
        ]);
    };

    return ($stdout, $stderr, $status);
}

my ($lf_out, $lf_err, $lf_status) = run_step_script("#!/bin/sh\n# FAKE_EXIT: 3\n");
is($lf_status, 3, 'an LF script is read and emulated');
like(
    $lf_out,
    qr{executing /github/actions-runner/scripts/step-1\.sh},
    'the script being executed is reported',
);
is($lf_err, '', 'an LF script produces no diagnostics');

my ($crlf_out, $crlf_err, $crlf_status)
    = run_step_script("#!/bin/sh\r\n# FAKE_EXIT: 3\r\n");
is($crlf_status, 127, 'a CRLF script fails the way a shell does');
unlike($crlf_out, qr{FAKE_EXIT}, 'the CRLF script is not emulated');
like($crlf_err, qr/CRLF line endings/, 'the failure names the line endings');
like($crlf_err, qr{\$'\\r'}, 'the failure quotes the CR the shell would see');

# A lone CR at the end of the file is another CR line ending, and a shell
# fails on it too.
my (undef, $bare_err, $bare_status) = run_step_script("#!/bin/sh\r# FAKE_EXIT: 3\r");
is($bare_status, 127, 'CR line endings fail as well');
like($bare_err, qr/CR line endings/, 'CR line endings are named as such');

# A CR inside a line is part of an argument, not a line ending, and a shell
# accepts it, so the fake shell must not invent a failure for it.
my (undef, $inner_err, $inner_status)
    = run_step_script("#!/bin/sh\necho a\rb\n# FAKE_EXIT: 3\n");
is($inner_status, 3, 'a CR inside a line does not fail');
is($inner_err, '', 'a CR inside a line produces no diagnostics');

done_testing;
