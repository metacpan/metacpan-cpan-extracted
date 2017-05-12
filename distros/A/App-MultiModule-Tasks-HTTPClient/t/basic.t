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

use_ok('App::MultiModule::Tasks::HTTPClient');

BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::HTTPClient') || die "Failed to load App::MultiModule::Test::HTTPClient\n";
}

App::MultiModule::Test::begin();
App::MultiModule::Test::HTTPClient::_begin();

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
            HTTPClient => {
            },
            MultiModule => {
            },
            Router => {  #router config
                routes => [
                    {   match => {
                            source => 'HTTPClient'
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

IPC::Transit::send(qname => 'HTTPClient', message => {
    http_url => 'https://www.realms.org',
    http_timeout => 20
});
sleep 1;
message_is(
    'basic https get for realms.org',
    {
          'http_is_error' => '',
          'http_status_line' => '200 OK',
          'http_is_fresh' => 1,
          'http_timeout' => 20,
          'source' => 'HTTPClient',
          'http_is_server_error' => '',
          'http_url' => 'https://www.realms.org',
          'http_is_success' => 1,
          'http_is_redirect' => '',
          'http_is_info' => '',
          'http_is_client_error' => '',
          'http_code' => 200
    },
    ['http_content','http_fresh_until','.ipc_transit_meta']
);
sleep 5;

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
App::MultiModule::Test::HTTPClient::_finish();

done_testing();
