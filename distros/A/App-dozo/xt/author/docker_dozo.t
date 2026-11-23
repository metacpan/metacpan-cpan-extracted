use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

# Run a callback when the object goes out of scope
package Guard { sub new { my ($c, $cb) = @_; bless { cb => $cb }, $c }
                sub DESTROY { $_[0]{cb}->() } }
package main;

my $dozo = File::Spec->rel2abs('script/dozo');
my $repo = File::Spec->rel2abs('.');

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

    subtest 'live container created with a command' => sub {
        my $image = 'alpine:latest';
        my $container = 'dozo-test-create-cmd';
        `$dozo -I $image -N $container -K 2>&1`;

        my $out = `$dozo -I $image -N $container -L -B sh -c 'echo one > /tmp/stack' 2>&1`;
        like($out, qr/create live container/, 'created');
        is(`docker inspect -f '{{.State.Status}}' $container`, "running\n",
           'still running after the command');

        $out = `$dozo -I $image -N $container -L -B cat /tmp/stack 2>/dev/null`;
        is($out, "one\n", 'next command sees the result');

        `$dozo -I $image -N $container -K 2>&1`;
        $out = `echo data | $dozo -I $image -N $container -L -B cat 2>/dev/null`;
        is($out, "data\n", 'piped input reaches the command on creation');

        `$dozo -I $image -N $container -K 2>&1`;
        `$dozo -I $image -N $container -L -B sh -c 'exit 3' 2>/dev/null`;
        is($? >> 8, 3, 'exit status of the command on creation');

        `$dozo -I $image -N $container -K 2>&1`;
    };
    subtest '--with' => sub {
        my $image = 'alpine:latest';
        my $xdg = tempdir(CLEANUP => 1);
        local $ENV{XDG_CONFIG_HOME} = $xdg;
        my $fdir = "$xdg/dozo/features";
        mkdir "$xdg/dozo" or die; mkdir $fdir or die; mkdir "$fdir/home" or die;
        my $put = sub {
            my ($file, $text) = @_;
            open my $fh, '>', $file or die "$file: $!";
            print $fh $text;
        };
        $put->("$fdir/hello", "RUN echo hello > /hello\n");
        $put->("$fdir/home/Dockerfile",
               "COPY --chown=\$DOZO_USER greeting \$DOZO_HOME/greeting\n");
        $put->("$fdir/home/greeting", "hi\n");

        # derived image names (repo:tag) made from $image
        my $derived = sub {
            sort split /\n/,
                `docker image ls --filter label=dozo.base=$image --format '{{.Repository}}:{{.Tag}}'`;
        };
        # remove everything this subtest creates, also when a test fails
        my $cleanup = sub {
            for my $b ($image, 'dozo-test-user:latest') {
                my @ids = split /\n/,
                    `docker image ls -q --filter label=dozo.base=$b`;
                system("docker image rm -f @ids >/dev/null 2>&1") if @ids;
            }
            system('docker image rm -f dozo-test-user:latest >/dev/null 2>&1');
        };
        $cleanup->();
        my $guard = Guard->new($cleanup);

        my $out = `$dozo -I $image -B --with hello,home sh -c 'cat /hello ~/greeting' 2>/dev/null`;
        is($out, "hello\nhi\n", 'features are added');
        my @first = $derived->();
        is(scalar @first, 2, 'one derived image per feature');

        # second time: the images are reused, nothing new is made
        $out = `$dozo -I $image -B --with hello,home true 2>&1`;
        unlike($out, qr/^#\d|Step \d|building/mi, 'second time: nothing is built');
        is_deeply([$derived->()], \@first, 'second time: same images');

        # changing a later feature rebuilds only that stage
        $put->("$fdir/home/greeting", "hey\n");
        $out = `$dozo -I $image -B --with hello,home sh -c 'cat /hello ~/greeting' 2>/dev/null`;
        is($out, "hello\nhey\n", 'changed feature is rebuilt');
        my ($hello_before) = grep /:hello-/, @first;
        my @hello_after = grep /:hello-/, $derived->();
        is_deeply(\@hello_after, [$hello_before], 'earlier stage is reused');

        # a missing feature is an error
        `$dozo -I $image -B --with nosuch true 2>/dev/null`;
        isnt($? >> 8, 0, 'unknown feature fails');

        # NAME/ARG: the feature splits DOZO_ARG with IFS
        $put->("$fdir/split",
               "ARG DOZO_ARG\nRUN IFS=+ && for v in \$DOZO_ARG; do echo \"[\$v]\"; done > /args\n");
        $out = `$dozo -I $image -B --with 'split/a b+c/d' cat /args 2>/dev/null`;
        is($out, "[a b]\n[c/d]\n", 'argument is split by the feature');

        # USER is restored after a feature that switches to root
        $put->("$fdir/asroot", "USER root\nRUN echo x > /x\n");
        my $df = tempdir(CLEANUP => 1);
        $put->("$df/Dockerfile", "FROM $image\nUSER nobody\n");
        system("docker build -q -t dozo-test-user:latest $df >/dev/null 2>&1");
        $out = `$dozo -I dozo-test-user:latest -B --with asroot id -un 2>/dev/null`;
        is($out, "nobody\n", 'USER of the base image is restored');

        # the bundled share/features/locale does nothing on alpine
        my $share = File::Spec->rel2abs('share/features/locale', $repo);
        ok(-f $share, 'share/features/locale is bundled');
        system('cp', $share, "$fdir/locale") == 0 or die;
        # (the build output may be cached by BuildKit: see the result)
        $out = `$dozo -I $image -B --with locale sh -c 'test -e /etc/locale.gen || echo none' 2>/dev/null`;
        is($?, 0, 'bundled locale feature: succeeds on alpine');
        is($out, "none\n", 'bundled locale feature: nothing is done on alpine');
    };

    subtest 'live container of the directory' => sub {
        use Cwd ();
        my $top = Cwd::realpath(tempdir(CLEANUP => 1));
        my $dir = "dozo-test-proj-$$";      # the container name ends with it
        my ($a, $b) = ("$top/a/$dir", "$top/b/$dir");
        system('mkdir', '-p', "$a/sub", $b) == 0 or die;
        system("cd $a && git init -q") == 0 or die;
        my $container = "alpine.$dir";
        my $cleanup = sub {
            system("docker rm -f $container ${container}-b >/dev/null 2>&1");
        };
        $cleanup->();
        my $guard = Guard->new($cleanup);
        my $in = sub { my $d = shift; scalar `cd $d && $dozo @_` };

        $in->($a, "-B -L -I alpine:latest touch /work/made-in-a 2>/dev/null");
        is(`docker inspect --format '{{index .Config.Labels "dozo.mount"}}' $container`,
           "$a\n", 'the container has the mount label');

        my $out = $in->("$a/sub", '-B -L pwd 2>/dev/null');
        is($out, "/work/sub\n", 'no -I: the container of the repository, from a subdirectory');

        my $err = $in->($b, '-B -L -I alpine:latest ls /work 2>&1 >/dev/null');
        isnt($?, 0, 'same name in another directory: error');
        like($err, qr/is for \Q$a\E/, 'same name in another directory: tells which');

        $out = $in->($b, "-B -L -I alpine:latest -N ${container}-b ls /work 2>/dev/null");
        is($out, '', 'another name with -N: the directory of its own');

        $in->("$a/sub", '-K 2>/dev/null');
        is(`docker ps -a -q --filter name=^/$container\$`, '', 'no -I: -K removes the container');
    };

    subtest 'status' => sub {
        my $top = Cwd::realpath(tempdir(CLEANUP => 1));
        my $dir = "$top/dozo-test-status-$$";
        system('mkdir', '-p', $dir) == 0 or die;
        system("cd $dir && git init -q") == 0 or die;
        my $container = "alpine.dozo-test-status-$$";
        my $xdg = tempdir(CLEANUP => 1);
        local $ENV{XDG_CONFIG_HOME} = $xdg;
        my $fdir = "$xdg/dozo/features";
        system('mkdir', '-p', $fdir) == 0 or die;
        my $put = sub {
            open my $fh, '>', $_[0] or die "$_[0]: $!";
            print $fh $_[1];
        };
        $put->("$fdir/stat", "RUN echo $$ > /stat\n");
        my $cleanup = sub {
            system("docker rm -f $container >/dev/null 2>&1");
            my @ids = split /\n/, `docker image ls -q --filter label=dozo.with=stat`;
            system("docker image rm -f @ids >/dev/null 2>&1") if @ids;
        };
        $cleanup->();
        my $guard = Guard->new($cleanup);
        my $in = sub { my $d = shift; scalar `cd $d && $dozo @_` };

        $in->($dir, "-B -L -I alpine:latest --with stat true 2>/dev/null");
        my ($tag) = `docker image ls --filter label=dozo.with=stat --format '{{.Repository}}:{{.Tag}}'`;
        chomp $tag;
        ok($tag, 'the derived image is made');
        my $state = sub {
            join '', `docker ps -a --format '{{.ID}} {{.State}}'`,
                     `docker image ls -a --format '{{.ID}} {{.Tag}}'`;
        };
        my $before = $state->();

        my $out = $in->($dir, '-S --with stat 2>/dev/null');
        is($?, 0, 'exit status');
        like($out, qr/container +\Q$container\E, running \(found by label\)/, 'here: found by label');
        like($out, qr/^\* \Q$container\E +running /m, 'the container row is marked');
        like($out, qr/^\* \Q$tag\E +alpine:latest +stat +current /m, 'the derived image is current');
        my $clean = sub { $_[0] =~ /^to clean up:\n((?:  .*\n?)*)/m ? $1 : '' };
        unlike($clean->($out), qr/\Q$tag\E/, 'not to clean up');

        $put->("$fdir/stat", "RUN echo changed > /stat\n");
        $out = $in->($dir, '-S 2>/dev/null');
        like($out, qr/^  \Q$tag\E +alpine:latest +stat +outdated /m, 'changed feature: outdated');
        unlike($clean->($out), qr/\Q$tag\E/, 'changed feature: used by the container, not to clean up');
        is($state->(), $before, 'nothing is changed by -S');

        $in->($dir, '-K 2>/dev/null');
        $out = $in->($dir, '-S 2>/dev/null');
        like($clean->($out), qr/^  docker image rm \Q$tag\E$/m, 'no container: to clean up');
    };
}

done_testing;
