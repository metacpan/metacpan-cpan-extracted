#!env perl

use strict;
use warnings FATAL => 'all';
use IPC::Transit;
use File::Slurp;
use File::Temp qw/tempfile tempdir/;
use Data::Dumper;
use POSIX ":sys_wait_h";
use Test::More;
use lib '../lib';

use_ok('App::MultiModule::Tasks::Runner');

BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::Runner') || die "Failed to load App::MultiModule::Test::Runner\n";
}

App::MultiModule::Test::begin();
App::MultiModule::Test::Runner::_begin();

my (undef, $errors_log) = tempfile();
my $args = "-q tqueue -p MultiModuleTest:: -o error:$errors_log";
ok my $daemon_pid = App::MultiModule::Test::run_program($args), 'run_program';
END { #just to be damn sure
    kill 9, $daemon_pid;
    unlink $errors_log;
};

my $config = {
    '.multimodule' => {
        config => {
            Runner => {
            },
            MultiModule => {
            },
            Router => {  #router config
                routes => [
                    {   match => {
                            source => 'Runner'
                        },
                        forwards => [
                            {   qname => 'test_out' }
                        ],
                    }
                ],
            }
        },
    }
};
ok IPC::Transit::send(qname => 'tqueue', message => $config), 'sent config';

IPC::Transit::send(qname => 'Runner', message => {
    runner_program_prog => './sub-program-test-program.pl',
    runner_program_args => [],
    runner_process_regex => 'perl ./sub-program-test-program.pl',
});


ok my $ret = IPC::Transit::receive(qname => 'test_out');
is $ret->{runner_message_type}, 'start', 'first message correctly has runner_message_type "start"';
ok $ret = IPC::Transit::receive(qname => 'test_out');
is $ret->{runner_message_type}, 'finish', 'second message correctly has runner_message_type "finish"';

ok $ret->{runner_stdout}, 'correctly received stdout';
ok !$ret->{runner_stderr}, 'correctly did not receive stderr';


ok IPC::Transit::send(qname => 'tqueue', message => {
    '.multimodule' => {
        control => [
            {   type => 'cleanly_exit',
                exit_externals => 1,
            }
        ],
    }
}), 'sent program exit request';

sleep 6;
ok waitpid($daemon_pid, WNOHANG) == $daemon_pid, 'waitpid';
ok !kill(9, $daemon_pid), 'program exited';

App::MultiModule::Test::finish();
App::MultiModule::Test::Runner::_finish();

done_testing();
