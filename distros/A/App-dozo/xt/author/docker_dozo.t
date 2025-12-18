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

    subtest 'live container' => sub {
        my $image = 'alpine:latest';
        my $container = 'dozo-test-live';

        # Clean up any existing container
        `$dozo -I $image -N $container -K 2>&1`;

        # Create live container with sleep to keep it running (detached)
        `docker run -d --name $container $image sleep 60 2>&1`;

        # Run command in existing running container
        my $out = `$dozo -I $image -N $container -L -B echo world 2>&1`;
        unlike($out, qr/create live container/, 'uses existing container');
        like($out, qr/world/, 'command runs via exec in running container');

        # Stop container and verify restart
        `docker stop $container 2>&1`;
        $out = `$dozo -I $image -N $container -L -B echo restarted 2>&1`;
        like($out, qr/restarting exited container $container/, 'restarts stopped container');

        # Kill and recreate
        $out = `$dozo -I $image -N $container -KL -B echo recreated 2>&1`;
        like($out, qr/removed|create live container/, 'kills and recreates');
        like($out, qr/recreated/, 'command runs in new container');

        # Clean up
        `$dozo -I $image -N $container -K 2>&1`;
    };

    subtest 'dryrun mode' => sub {
        my $image = 'alpine:latest';
        my $container = 'dozo-test-dryrun';

        # Clean up
        `$dozo -I $image -N $container -K 2>&1`;

        # Dryrun without existing container
        my $out = `$dozo -I $image -N $container -Ln -B echo test 2>&1`;
        like($out, qr/create live container/, 'dryrun shows create message');
        like($out, qr/^docker run\b/m, 'dryrun shows docker run command');
        unlike($out, qr/^test$/m, 'command not actually executed');

        # Create container for next tests
        `$dozo -I $image -N $container -L -B true 2>&1`;

        # Dryrun with existing running container
        $out = `$dozo -I $image -N $container -Ln -B echo test 2>&1`;
        like($out, qr/^docker exec\b/m, 'dryrun shows docker exec command');

        # Stop container and test dryrun
        `docker stop $container 2>&1`;
        $out = `$dozo -I $image -N $container -Ln -B echo test 2>&1`;
        like($out, qr/restarting exited container/, 'dryrun shows restart message');
        like($out, qr/^docker exec\b/m, 'dryrun shows docker exec after start');

        # Clean up
        `$dozo -I $image -N $container -K 2>&1`;
    };
}

done_testing;
