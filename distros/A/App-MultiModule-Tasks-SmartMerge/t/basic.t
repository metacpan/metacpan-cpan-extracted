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

use_ok('App::MultiModule::Tasks::SmartMerge');

BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::SmartMerge') || die "Failed to load App::MultiModule::Test::SmartMerge\n";
#    use_ok('Message::SmartMerge::Test') || die 'Failed to load Message::SmartMerge::Test';
}

App::MultiModule::Test::begin();
App::MultiModule::Test::SmartMerge::_begin();

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
            SmartMerge => {
                merge_instance => 'a',
            },
            MultiModule => {
            },
            Router => {  #router config
                routes => [
                    {   match => {
                            source => 'SmartMerge'
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

IPC::Transit::send(qname => 'SmartMerge', message => {
    x => 'y', a => 'b'
});

message_is(
    'first validate pass-through',
    {
        x => 'y',
        a => 'b',
        source => 'SmartMerge',
    },
    ['.ipc_transit_meta']
);
IPC::Transit::send(qname => 'SmartMerge', message => {
    add_merge => {
        match => {x => 'y'},
        transform => {this => 'that'},
        merge_id => 'm1',
    }
});
message_is(
    'add a simple merge',
    {
        x => 'y',
        a => 'b',
        this => 'that',
        source => 'SmartMerge',
    },
    ['.ipc_transit_meta']
);


sleep 3;
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
App::MultiModule::Test::SmartMerge::_finish();

done_testing();
