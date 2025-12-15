use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

my $dozo = File::Spec->rel2abs('script/dozo');

# Use empty temp dir to avoid reading any .dozorc (HOME, git top, cwd)
my $empty_home = tempdir(CLEANUP => 1);
$ENV{HOME} = $empty_home;
chdir $empty_home or die "Cannot chdir to $empty_home: $!";

# Docker-dependent tests
SKIP: {
    my $docker_available = system('docker info >/dev/null 2>&1') == 0;
    skip 'Docker not available', 4 unless $docker_available;

    subtest 'run simple command' => sub {
        my $out = `$dozo -I alpine:latest -B echo hello 2>&1`;
        like($out, qr/hello/, 'can run echo command in container');
    };

    subtest 'command with options' => sub {
        my $out = `$dozo -I alpine:latest -B ls -la / 2>&1`;
        like($out, qr/root/, 'ls -la works (command options passed correctly)');
    };

    subtest 'environment variable' => sub {
        my $out = `$dozo -I alpine:latest -B -E TEST_VAR=hello sh -c 'echo \$TEST_VAR' 2>&1`;
        like($out, qr/hello/, 'environment variable is passed');
    };

    subtest 'unmount option' => sub {
        my $out = `$dozo -I alpine:latest -B -U pwd 2>&1`;
        like($out, qr{^/$}m, '-U unmount option works (working dir is /)');
    };
}

done_testing;
