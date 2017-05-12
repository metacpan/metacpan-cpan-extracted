#!env perl

use strict;
use warnings FATAL => 'all';
use IPC::Transit;
use Data::Dumper;
use File::Temp qw/tempfile tempdir/;
use POSIX ":sys_wait_h";
use Test::More;
use lib '../lib';

use_ok('App::MultiModule::Tasks::NagiosCmd');
BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::NagiosCmd') || die "Failed to load App::MultiModule::Test::NagiosCmd\n";
}


App::MultiModule::Test::begin();
App::MultiModule::Test::NagiosCmd::_begin();

my (undef, $errors_log) = tempfile();
my $args = "-q tqueue -p MultiModuleTest:: -o error:$errors_log";
ok my $daemon_pid = App::MultiModule::Test::run_program($args), 'run_program';
END { #just to be damn sure
    kill 9, $daemon_pid;
    unlink $errors_log;
    unlink 'nagios.cmd';
    unlink 'nagios_cmd.log';
};

system 'mkfifo nagios.cmd';
my $config = {
    '.multimodule' => {
        config => {
            NagiosCmd => {
                command_file => 'nagios.cmd',
            },
            MultiModule => {
            },
            Router => {  #router config
                routes => [
                    {   match => {
                            source => 'NagiosCmd'
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

sleep 3;
IPC::Transit::send(qname => 'NagiosCmd', message => {
    nagios_service_description => "service_description",
    nagios_host_name => "some_host",
    nagios_check_name => "some_check",
    nagios_return_code => 1,
    nagios_output => "something to warn about"
});
my $cmd = eval {
    local $SIG{ALRM} = sub { die "timed out\n"; };
    alarm 10;
    open my $fh, '<', 'nagios.cmd' or die "failed to open nagios.cmd for reading: $!";
    read $fh, my $text, 10240 or die "failed to read from nagios.cmd: $!";
    close $fh or die "failed to close nagios.cmd: $!";
    return $text;
};
alarm 0;
ok(!$@, 'no exception in the read block');
ok $cmd, 'read block returned something';
ok($cmd =~ /^\[\d+\]\s+PROCESS_SERVICE_CHECK_RESULT;some_host;service_description;1;some_check WARNING - something to warn about$/, 'command passed to Nagios is valid');

ok(-z $errors_log, 'no errors');

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
unlink 'nagios.cmd';
unlink 'nagios_cmd.log';
ok waitpid($daemon_pid, WNOHANG) == $daemon_pid, 'waitpid';
ok !kill(9, $daemon_pid), 'program exited';

App::MultiModule::Test::finish();
App::MultiModule::Test::NagiosCmd::_finish();

done_testing();
