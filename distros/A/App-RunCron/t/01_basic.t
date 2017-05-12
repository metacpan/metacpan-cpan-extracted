use strict;
use warnings;
use utf8;

use Capture::Tiny qw/capture/;
use File::Temp    qw/tempdir/;
use File::Spec;
use Test::More;
use App::RunCron;

subtest normal => sub {
    my $runner = App::RunCron->new(
        command   => [$^X, '-e', "print 'Hello'"],
    );
    isa_ok $runner, 'App::RunCron';
    my ($stdout, $stderr) = capture { $runner->_run };
    ok !$stdout;
    ok !$stderr;
    is $runner->exit_code, 0;
};

subtest die => sub {
    my $runner = App::RunCron->new(
        command   => [$^X, '-e', "die 'Hello'"],
    );
    my ($stdout, $stderr) = capture { $runner->_run };
    like $stdout, qr/Hello at -e line 1\.\ncommand exited with code:255$/;
    ok !$stderr;
    is $runner->exit_code >> 8, 255;
};

subtest 'reporter stdout' => sub {
    my $runner = App::RunCron->new(
        command   => [$^X, '-e', qq[print "Hello\n"]],
        reporter  => 'Stdout',
        timestamp => 1,
    );
    my ($stdout, $stderr) = capture { $runner->_run };
    like $stdout, qr/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{6}\] Hello\n\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{6}\] command exited with code:0$/;
    ok !$stderr;
    is $runner->exit_code, 0;
};

subtest 'reporter stdout' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $logfile = File::Spec->catfile($dir, 'log.log');

    ok ! -e $logfile;
    my $runner = App::RunCron->new(
        command   => [$^X, '-e', qq[print "Hello\n"]],
        logfile   => $logfile,
    );
    my ($stdout, $stderr) = capture { $runner->_run };
    ok -e $logfile;

    ok !$stdout;
    ok !$stderr;

    my $content = do {
        local $/;
        open my $fh, '<', $logfile or die $!;
        <$fh>
    };
    like $content, qr/Hello\ncommand exited with code:0$/;

    is $runner->exit_code, 0;
};

subtest 'reporter stdout' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $logfile = File::Spec->catfile($dir, 'log.log');

    ok ! -e $logfile;
    my $runner = App::RunCron->new(
        command   => [$^X, '-e', qq[print "Hello\n"]],
        reporter  => [
            'Stdout',
            'File' => {
                file => $logfile,
            },
        ],
    );
    my ($stdout, $stderr) = capture { $runner->_run };
    ok -e $logfile;

    like $stdout, qr/Hello\ncommand exited with code:0$/;
    ok !$stderr;

    my $content = do {
        local $/;
        open my $fh, '<', $logfile or die $!;
        <$fh>
    };
    like $content, qr/Hello\ncommand exited with code:0$/;

    is $runner->exit_code, 0;
};

subtest 'reporter:Stdout common_reporter:File' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $logfile = File::Spec->catfile($dir, 'log.log');

    ok ! -e $logfile;
    my $runner = App::RunCron->new(
        command   => [$^X, '-e', qq[print "Hello\n"]],
        common_reporter => [
            'File' => {
                file => $logfile,
            },
        ],
        reporter  => 'Stdout',
    );
    my ($stdout, $stderr) = capture { $runner->_run };
    ok -e $logfile;

    like $stdout, qr/Hello\ncommand exited with code:0$/;
    ok !$stderr;

    my $content = do {
        local $/;
        open my $fh, '<', $logfile or die $!;
        <$fh>
    };
    like $content, qr/Hello\ncommand exited with code:0$/;

    is $runner->exit_code, 0;
};

subtest 'invalid reporter' => sub {
    my $runner = App::RunCron->new(
        command   => [$^X, '-e', qq[print "Hello\n"]],
        reporter  => sub {
            my $runner = shift;
            isa_ok $runner, 'App::RunCron';
            die 'Oops!'
        },
    );
    my ($stdout, $stderr) = capture { $runner->_run };

    ok !$stdout;
    like $stderr, qr/Oops/;
    like $stderr, qr/Hello\ncommand exited with code:0/;

    is $runner->exit_code, 0;
};

subtest 'announcer' => sub {
    my $runner = App::RunCron->new(
        command   => [$^X, '-e', qq[print "Hello\n"]],
        announcer => sub {
            my $r = shift;
            print STDERR $r->pid;
        },
    );
    my ($stdout, $stderr) = capture { $runner->_run };

    ok !$stdout;
    is $stderr, $$;

    is $runner->exit_code, 0;
};

subtest 'invalid announcer' => sub {
    my $runner = App::RunCron->new(
        command   => [$^X, '-e', qq[print "Hello\n"]],
        announcer => sub {
            die 'Oops';
        },
        reporter => 'Stdout',
    );
    my ($stdout, $stderr) = capture { $runner->_run };

    like $stdout, qr/Hello\ncommand exited with code:0$/;
    like $stderr, qr/Oops/;

    is $runner->exit_code, 0;
};

subtest 'command reporter' => sub {
    subtest 'string' => sub {
        my $runner = App::RunCron->new(
            command   => [$^X, '-e', qq[print "Hello\n"]],
            reporter => [Command => "$^X -e 'print while <>'"],
        );
        my ($stdout, $stderr) = capture { $runner->_run };

        like $stdout, qr/command exited with code:0/;
        is $runner->exit_code, 0;
    };
    subtest 'array' => sub {
        my $runner = App::RunCron->new(
            command   => [$^X, '-e', qq[print "Hello\n"]],
            reporter => [Command => [$^X, '-e', 'print while <>']],
        );
        my ($stdout, $stderr) = capture { $runner->_run };

        like $stdout, qr/command exited with code:0/;
        is $runner->exit_code, 0;
    };
};

subtest 'command announcer' => sub {
    my $runner = App::RunCron->new(
        command   => [$^X, '-e', qq[print "Hello\n"]],
        announcer => [Command => [$^X, '-e', 'warn $_ while <>']],
    );
    my ($stdout, $stderr) = capture { $runner->_run };
    ok !$stdout;
    like $stderr, qr/$$/;
    is $runner->exit_code, 0;
};

done_testing;
