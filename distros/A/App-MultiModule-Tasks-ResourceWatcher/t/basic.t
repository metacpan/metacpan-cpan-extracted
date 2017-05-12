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

use_ok('App::MultiModule::Tasks::ResourceWatcher');

BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::ResourceWatcher') || die "Failed to load App::MultiModule::Test::ResourceWatcher\n";
}
App::MultiModule::Test::begin();
App::MultiModule::Test::ResourceWatcher::_begin();

my (undef, $errors_log) = tempfile();
my $args = "-q tqueue -p MultiModuleTest:: -o error:$errors_log";
ok my $daemon_pid = App::MultiModule::Test::run_program($args), 'run_program';
my $thing_pid;
END { #just to be damn sure
    kill 9, $daemon_pid;
    unlink $errors_log;
    kill 9, $thing_pid;
};
my $config = {
    '.multimodule' => {
        config => {
            ResourceWatcher => {},
            MultiModule => {
            },
            Router => {  #router config
                routes => [
                    {   match => {
                            source => 'ResourceWatcher'
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

system 'nohup perl long_running_thing_test_thing.pl > /dev/null 2>&1 &';
sleep 1;
$thing_pid = `ps -deaf|grep long_running_thing_test_thing.pl|grep -v grep|grep -v 'tail '|awk '{print \$2}'`;
chomp $thing_pid;
if($thing_pid =~ /\n/s) {
    ok 0, "test program's PID was not detected properly, can not proceed: \$thing_pid=$thing_pid";
    exit 1;
}
ok IPC::Transit::send(qname => 'ResourceWatcher', message => {
    watches => {
        basic_thing => {
            resourceWatcher_PID => $thing_pid,
            no_process => { #used once when we notice a process doen't exist
                transform => {
                    result => 'no process',
                },
            },
            levels => {
                '1' => {
                    floor => {  #all of these have to be at or above the real value
                                #for this to fire
                        process_uptime => 5,  
                    },
                    transform => {  #do this if we meet the criteria
                        result => 'timeout warning',
                    },
                    #and the emit is implicit
                },
                '10' => {
                    floor => {
                        process_uptime => 8,  
                    },
                    transform => {  #do this if we meet the criteria
                        result => 'timeout termination',
                    },
                    actions => {
                        signal => 'TERM',
                    },
                    #and the emit is implicit
                },
                '100' => {
                    floor => {
                        process_uptime => 11,  
                    },
                    transform => {  #do this if we meet the criteria
                        result => 'timeout kill',
                    },
                    actions => {
                        signal => 'KILL',
                    },
                },
            },
        },
    }
}), 'sent dynamic config';


{   my $message = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 2;
        return IPC::Transit::receive(qname => 'test_out');
    };
    alarm 0;
    is($@, "timed out\n", 'verified that nothing was sent too early');
}
my $messages = {};
eval {
    local $SIG{ALRM} = sub { die "timed out\n"; };
    alarm 20;
    while(my $message = IPC::Transit::receive(qname => 'test_out')) {
        my $result = $message->{result} || 'unknown';
        $message->{ct} = $messages->{$result}->{ct} || 0;
        $message->{ct}++;
        $messages->{$result} = Storable::dclone($message);
    }
};
alarm 0;
is $@, "timed out\n", 'collection loop correctly timed out';
ok my $warning = $messages->{'timeout warning'}, 'timeout warning section exists';
is $warning->{resourceWatcher_level}, 1, 'warning on correct level(1)';
is $warning->{watch_name}, 'basic_thing', 'warning has correct watch_name';
ok !$warning->{resourceWatcher_signal_sent}, 'warning correctly did not deliver any signal';
is_deeply($warning->{resourceWatcher}, {
    transform => {
        result => 'timeout warning',
    },
    floor => {
        process_uptime => 5,
    }
}, 'level config for warning properly merged');
ok $warning->{ct} > 2, 'verified at least two warnings hit';

ok !$messages->{unknown}, 'verified that no unknown message results came back';

ok my $term = $messages->{'timeout termination'}, 'timeout termination section exists';
is $term->{resourceWatcher_level}, 10, 'termination on correct level(10)';
is $term->{watch_name}, 'basic_thing', 'termination has correct watch_name';
is $term->{resourceWatcher_signal_sent}, 'TERM', 'termination delivered correct signal(TERM)';
ok $term->{ct} > 2, 'verified at least two terms hit';
is_deeply($term->{resourceWatcher}, {
    actions => {
        signal => 'TERM',
    },
    transform => {
        result => 'timeout termination',
    },
    floor => {
        process_uptime => 8,
    }
}, 'level config for term properly merged');

ok my $kill = $messages->{'timeout kill'}, 'timeout kill section exists';
is $kill->{resourceWatcher_level}, 100, 'kill on correct level(100)';
is $kill->{watch_name}, 'basic_thing', 'kill has correct watch_name';
is $kill->{resourceWatcher_signal_sent}, 'KILL', 'kill delivered correct signal(KILL)';
is $kill->{ct}, 1, 'verified exactly 1 kill hit';
is_deeply($kill->{resourceWatcher}, {
    actions => {
        signal => 'KILL',
    },
    transform => {
        result => 'timeout kill',
    },
    floor => {
        process_uptime => 11,
    }
}, 'level config for kill properly merged');

ok my $noproc = $messages->{'no process'}, 'no process section exists';
is $noproc->{watch_name}, 'basic_thing', 'no process has correct watch_name';


#now let's make sure nothing else is being sent
{   my $message = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 2;
        return IPC::Transit::receive(qname => 'test_out');
    };
    alarm 0;
    is($@, "timed out\n", 'verified that nothing was sent after the process was slain');
}

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
App::MultiModule::Test::ResourceWatcher::_finish();



done_testing();
