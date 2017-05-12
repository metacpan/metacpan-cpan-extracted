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

sub message_is {
    my $test_name = shift;
    my $expected = shift;
    my $deletes = shift;
    my $message = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 22;
        return IPC::Transit::receive(qname => 'test_out');
    };
    alarm 0;
    my $err = $@;
    ok(!$err, "no exception for $test_name");
    if($err) {
        print STDERR "\$get_msg failed: $@\n";
        return undef;
    }
    delete $message->{$_} for @$deletes;
    is_deeply($message, $expected, $test_name);
}

IPC::Transit::send(qname => 'Runner', message => {
    runner_program_prog => './test-program.pl',
    runner_program_args => { 0 => 'one'},
    runner_process_regex => 'perl ./test-program.pl one',
});
sleep 1;
IPC::Transit::send(qname => 'Runner', message => {
    runner_program_prog => './test-program.pl',
    runner_program_args => { 1 => 'two'},
    runner_process_regex => 'perl ./test-program.pl two',
});
sleep 1;
IPC::Transit::send(qname => 'Runner', message => {
    runner_program_prog => './test-program.pl',
    runner_program_args => { 1 => 'two' },
    runner_process_regex => 'perl ./test-program.pl two',
});
message_is(
    'start for test-program.pl one',
    {
        runner_stderr => '',
        runner_program_prog => './test-program.pl',
        runner_prog_run_key => './test-program.pl,one',
        runner_program_args => {
            0 => 'one'
        },
        runner_stdout => '',
        runner_return_type => 'gather',
        runner_process_regex => 'perl ./test-program.pl one',
        runner_message_type => 'start',
        source => 'Runner',
    },
    ['runner_start_time','runner_pid','.ipc_transit_meta']
);
message_is(
    'start for test-program.pl two',
    {
        runner_prog_run_key => './test-program.pl,two',
        runner_program_args => {
            1 => 'two'
        },
        runner_stdout => '',
        runner_return_type => 'gather',
        runner_process_regex => 'perl ./test-program.pl two',
        runner_stderr => '',
        runner_program_prog => './test-program.pl',
        runner_message_type => 'start',
        source => 'Runner',
    },
    ['runner_start_time','runner_pid','.ipc_transit_meta']
);
message_is(
    'already running test-program.pl two',
    {
        'runner_program_args' => {
            1 => 'two'
        },
        runner_message_type => 'already running',
        runner_return_type => 'gather',
        runner_process_regex => 'perl ./test-program.pl two',
        runner_stdout => '',
        runner_stderr => '',
        source => 'Runner',
        runner_program_prog => './test-program.pl'
    },
    ['runner_start_time','runner_pid','.ipc_transit_meta']
);
message_is(
    'finish test-program.pl one',
    {
        runner_stdout => 'one : ct = 1 : sleep = 1 : delta = 0
one : ct = 2 : sleep = 2 : delta = 1
one : ct = 3 : sleep = 3 : delta = 3
one : ct = 4 : sleep = 4 : delta = 6
one : ct = 5 : sleep = 5 : delta = 10
',
        runner_return_type => 'gather',
        runner_exit_code => 0,
        runner_process_regex => 'perl ./test-program.pl one',
        runner_stderr => '',
        runner_prog_run_key => './test-program.pl,one',
        runner_message_type => 'finish',
        runner_program_prog => './test-program.pl',
        source => 'Runner',
        runner_program_args => {
            0 => 'one'
        },
    },
    ['runner_start_time','runner_pid','runner_run_time','.ipc_transit_meta']
);
message_is(
    'finish test-program.pl two',
    {
        runner_program_prog => './test-program.pl',
        runner_program_args => {
            1 => 'two'
        },
        runner_prog_run_key => './test-program.pl,two',
        runner_message_type => 'finish',
        runner_return_type => 'gather',
        runner_exit_code => 0,
        runner_stdout => 'two : ct = 1 : sleep = 1 : delta = 0
two : ct = 2 : sleep = 2 : delta = 1
two : ct = 3 : sleep = 3 : delta = 3
two : ct = 4 : sleep = 4 : delta = 6
two : ct = 5 : sleep = 5 : delta = 10
',
        runner_stderr => '',
        runner_process_regex => 'perl ./test-program.pl two',
        source => 'Runner',
    },
    ['runner_start_time','runner_pid','runner_run_time','.ipc_transit_meta']
);
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
