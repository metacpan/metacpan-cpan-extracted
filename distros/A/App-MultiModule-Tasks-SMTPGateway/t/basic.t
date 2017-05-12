#!env perl

use strict;
use warnings FATAL => 'all';
use IPC::Transit;
use File::Slurp;
use File::Temp qw/tempfile tempdir/;
use Data::Dumper;
use POSIX ":sys_wait_h";
use Test::More;
use Test::Mock::Net::Server::Mail;
use lib '../lib';

use_ok('App::MultiModule::Tasks::SMTPGateway');

BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::SMTPGateway') || die "Failed to load App::MultiModule::Test::SMTPGateway\n";
}
App::MultiModule::Test::begin();
App::MultiModule::Test::SMTPGateway::_begin();

my (undef, $errors_log) = tempfile();
my $args = "-q tqueue -p MultiModuleTest:: -o error:$errors_log";
ok my $daemon_pid = App::MultiModule::Test::run_program($args), 'run_program';
my $fake_smtp_server = Test::Mock::Net::Server::Mail->new;
$fake_smtp_server->start_ok;
ok ((my $smtp_server_port = $fake_smtp_server->port), 'mock smtp server running on port');
ok ((my $smtp_server_pid = $fake_smtp_server->pid), 'mock smtp server running');
END {
    kill 9, $daemon_pid;
    kill 9, $smtp_server_pid;
    unlink $errors_log;
};

my $config = {
    '.multimodule' => {
        config => {
            SMTPGateway => {
            },
            MultiModule => {
            },
            Router => {  #router config
                routes => [
                    {   match => {
                            source => 'SMTPGateway'
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

ok IPC::Transit::send(qname => 'SMTPGateway', message => {
    smtp_to => 'whoever@realms.org',
    smtp_from => 'someone_else@realms.org',
    smtp_subject => 'whatever',
    smtp_body => 'also whatever',
    smtp_transport => [
        'SMTP', {
            host => '127.0.0.1',
            port => $smtp_server_port, 
        }
    ],
}), 'sent basic SMTP send';


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
ok -z $errors_log, 'no errors';
if(not -z $errors_log) {
    my $errors = read_file($errors_log);
    print STDERR "$errors\n";
}
ok waitpid($daemon_pid, WNOHANG) == $daemon_pid, 'waitpid';
ok !kill(9, $daemon_pid), 'program exited';

App::MultiModule::Test::finish();
App::MultiModule::Test::SMTPGateway::_finish();

done_testing();
