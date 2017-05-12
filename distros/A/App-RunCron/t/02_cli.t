use strict;
use warnings;
use utf8;
use Test::Exit;
use Test::More;

use Capture::Tiny qw/capture/;
use File::pushd;
use File::Temp qw/tempdir/;
use App::RunCron::CLI;

subtest 'specify runcron.yml' => sub {
    my $cli = App::RunCron::CLI->new(qw!--config=eg/sample-runcron.yml!, $^X, '-e', 'print "Hello"');
    my $runner = $cli->{runner};
    isa_ok $runner, 'App::RunCron';
    ok $runner->timestamp;
    ok $runner->reporter, 'Stdout';
};

subtest 'implicit loading runcron.yml' => sub {
    my $guard = tempd;
    my $yml = File::Spec->catfile($guard.'', 'runcron.yml');
    open my $fh, '>', $yml or die $!;
    print $fh "timestamp: 1\n";
    close $fh;

    my $cli = App::RunCron::CLI->new(qw/--logfile=hoge/, $^X, '-e', 'print "Hello"');
    my $runner = $cli->{runner};
    isa_ok $runner, 'App::RunCron';
    ok $runner->timestamp;
};


subtest 'implicit loading runcron.yml' => sub {
    my $guard = tempd;
    my $yml = File::Spec->catfile($guard.'', 'runcron.yml');
    open my $fh, '>', $yml or die $!;
    print $fh "timestamp: 1\nErrorError";
    close $fh;

    my $cli;
    {
        my ($stdout, $stderr) = capture {
            $cli = App::RunCron::CLI->new(qw/--logfile=hoge/, $^X, '-e', 'print "Hello"');
        };
        like $stderr, qr/^Bad config: runcron\.yml/;
    };
    my $runner = $cli->{runner};
    isa_ok $runner, 'App::RunCron';
    ok !$runner->timestamp;

    my ($stdout, $stderr);
    exits_zero {
        ($stdout, $stderr) = capture { $cli->run };
    };
    ok !$stdout;
    ok !$stderr;
};

done_testing;
