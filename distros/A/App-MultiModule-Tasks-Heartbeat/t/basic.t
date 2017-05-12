#!env perl

use strict;
use warnings FATAL => 'all';
use IPC::Transit;
use File::Slurp;
use Storable;
use File::Temp qw/tempfile tempdir/;
use Data::Dumper;
use POSIX ":sys_wait_h";
use Test::More;
use lib '../lib';

use_ok('App::MultiModule::Tasks::Heartbeat');

BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::Heartbeat') || die "Failed to load App::MultiModule::Test::Heartbeat\n";
}
App::MultiModule::Test::begin();
App::MultiModule::Test::Heartbeat::_begin();

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
            Heartbeat => {
                hb_groups => {
                    'hb group 1' => {
                        match => {
                            is_std_heartbeat_check => 1,
                        },
                        hb_instance => ' specials/$message->{inform_instance}',
                        changing_fields => ['status','stdout'],
                        emit_ts_span => 2,
                        transform => {
                            foo => 'bar',
                        }
                    }
                }
            },
            Router => {
                routes => [
                    {   match => {
                            source => 'Heartbeat'
                        },
                        forwards => [
                            {   qname => 'test_out' }
                        ],
                    }
                ],
            },
            MultiModule => {},
        },
    }
};
ok IPC::Transit::send(qname => 'tqueue', message => $config), 'sent config';
sleep 2;

{   #make sure it's not sending anything
    my $message = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 5;
        return IPC::Transit::receive(qname => 'test_out');
    };
    alarm 0;
    ok((not $message), 'verified no emits before first message');
}
IPC::Transit::send(qname => 'Heartbeat', message => {
    inform_instance => 'servers.whatever.check_runner',
    status => 'OK',
    stdout => 'returned OK',
    is_std_heartbeat_check => 1,
});
sleep 3;
{   #should have our first messages
    my $message;
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 5;
        while($message = IPC::Transit::receive(qname => 'test_out')) {
            #yup
        }
    };
    alarm 0;
    ok($message, 'properly received first message');
    is($message->{hb_instance}, 'servers.whatever.check_runner', 'hb_instance is correctly "servers.whatever.check_runner"');
    is($message->{foo}, 'bar', 'foo is correctly set to "bar"');
    ok($message->{hearbeat_last_change_ts_span}, 'correctly received non-zero "hearbeat_last_change_ts_span"');
    ok(($message->{hearbeat_last_change_ts_span} and ($message->{hearbeat_last_change_ts_span} > 1)), '"hearbeat_last_change_ts_span" is correctly greater than 1');
    ok(($message->{hearbeat_last_change_ts_span} and ($message->{hearbeat_last_change_ts_span} < 10)), '"hearbeat_last_change_ts_span" is correctly less than 10');
}

#send the same thing, which should not reset the timer
IPC::Transit::send(qname => 'Heartbeat', message => {
    inform_instance => 'servers.whatever.check_runner',
    status => 'OK',
    stdout => 'returned OK',
    is_std_heartbeat_check => 1,
});

{   #these messages should not have a reset timer
    my $message;
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 5;
        while($message = IPC::Transit::receive(qname => 'test_out')) {
            #yup
        }
    };
    alarm 0;
    ok($message, 'properly received first message');
    is($message->{hb_instance}, 'servers.whatever.check_runner', 'hb_instance is correctly "servers.whatever.check_runner"');
    is($message->{foo}, 'bar', 'foo is correctly set to "bar"');
    ok($message->{hearbeat_last_change_ts_span}, 'correctly received non-zero "hearbeat_last_change_ts_span"');
    ok(($message->{hearbeat_last_change_ts_span} and ($message->{hearbeat_last_change_ts_span} > 6)), '"hearbeat_last_change_ts_span" is correctly greater than 6');
    ok(($message->{hearbeat_last_change_ts_span} and ($message->{hearbeat_last_change_ts_span} < 20)), '"hearbeat_last_change_ts_span" is correctly less than 20');
}
#send the different thing, which should reset the timer
IPC::Transit::send(qname => 'Heartbeat', message => {
    inform_instance => 'servers.whatever.check_runner',
    status => 'CRIT',
    stdout => 'returned CRIT',
    is_std_heartbeat_check => 1,
});

{   #these messages should have a reset timer
    my $message;
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 5;
        while($message = IPC::Transit::receive(qname => 'test_out')) {
            #yup
        }
    };
    alarm 0;
    ok($message, 'properly received first message');
    is($message->{hb_instance}, 'servers.whatever.check_runner', 'hb_instance is correctly "servers.whatever.check_runner"');
    is($message->{foo}, 'bar', 'foo is correctly set to "bar"');
    ok($message->{hearbeat_last_change_ts_span}, 'correctly received non-zero "hearbeat_last_change_ts_span"');
    ok(($message->{hearbeat_last_change_ts_span} and ($message->{hearbeat_last_change_ts_span} > 1)), '"hearbeat_last_change_ts_span" is correctly greater than 1');
    ok(($message->{hearbeat_last_change_ts_span} and ($message->{hearbeat_last_change_ts_span} < 10)), '"hearbeat_last_change_ts_span" is correctly less than 10');
}

sleep 2;
ok -z $errors_log, 'verified errors_log is empty';
#finished, exit the daemon
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
App::MultiModule::Test::Heartbeat::_finish();



done_testing();
