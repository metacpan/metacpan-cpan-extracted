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

use_ok('App::MultiModule::Tasks::Scheduler');

BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::Scheduler') || die "Failed to load App::MultiModule::Test::Scheduler\n";
}
App::MultiModule::Test::begin();
App::MultiModule::Test::Scheduler::_begin();

my (undef, $errors_log) = tempfile();
my $args = "-q tqueue -p MultiModuleTest:: -o error:$errors_log";
ok my $daemon_pid = App::MultiModule::Test::run_program($args), 'run_program';
END { #just to be damn sure
    kill 9, $daemon_pid;
    unlink $errors_log;
};
my $ts = time;
my $runAt = $ts + 3;
my $config = {
    '.multimodule' => {
        config => {
            Scheduler => {},
            MultiModule => {
            },
            Router => {  #router config
                routes => [
                    {   match => {
                            source => 'Scheduler'
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
        alarm 12;
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

#verify nothing came in
{   my $message = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 2;
        return IPC::Transit::receive(qname => 'test_out');
    };
    alarm 0;
    is($@, "timed out\n", 'verified no message was sent pre-configuration');
}
# configure basic runAt
ok IPC::Transit::send(qname => 'Scheduler', message => {
    dynamic_config => {
        basic_runAt => {
            runAt => $runAt
        }
    },
}), 'sent runAt config';
message_is(
    'basic_runAt',
    {   runAt => $runAt,
        source => 'Scheduler',
        scheduler_scheduled_key => 'basic_runAt',
    }, ['scheduler_create_ts','.ipc_transit_meta','scheduler_send_ts']
);
#verify nothing came in again
{   my $message = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 6;
        return IPC::Transit::receive(qname => 'test_out');
    };
    alarm 0;
    is($@, "timed out\n", 'verified no message was sent post-configuration and post single expected message');
}

sleep 6;
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
App::MultiModule::Test::Scheduler::_finish();

done_testing();
