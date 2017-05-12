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
my $config = {
    '.multimodule' => {
        config => {
            Scheduler => {
                schedule => {
                    recurringThing => {
                        recur => 5,
                        this => 'that',
                        x => ' specials/"whatever"',
                    }
                },
            },
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

message_is(
    'first 5 second recur',
    {   recur => 5,
        source => 'Scheduler',
        scheduler_send_count => 1,
        this => 'that',
        x => 'whatever',
        scheduler_scheduled_key => 'recurringThing',
    }, ['scheduler_create_ts','.ipc_transit_meta','scheduler_send_ts']
);
{   my $message = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 2;
        return IPC::Transit::receive(qname => 'test_out');
    };
    alarm 0;
    is($@, "timed out\n", 'verified second message not sent too early');
}
message_is(
    'second 5 second recur',
    {   recur => 5,
        source => 'Scheduler',
        scheduler_send_count => 2,
        this => 'that',
        x => 'whatever',
        scheduler_scheduled_key => 'recurringThing',
    }, ['scheduler_create_ts','.ipc_transit_meta','scheduler_send_ts']
);
{   my $message = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 2;
        return IPC::Transit::receive(qname => 'test_out');
    };
    alarm 0;
    is($@, "timed out\n", 'verified third message not sent too early');
}
message_is(
    'third 5 second recur',
    {   recur => 5,
        source => 'Scheduler',
        scheduler_send_count => 3,
        this => 'that',
        x => 'whatever',
        scheduler_scheduled_key => 'recurringThing',
    }, ['scheduler_create_ts','.ipc_transit_meta','scheduler_send_ts']
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
App::MultiModule::Test::Scheduler::_finish();



done_testing();
