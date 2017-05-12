#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX ":sys_wait_h";
use Test::More;
use IPC::Transit;
use Data::Dumper;

use App::MultiModule::API;

BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
}

App::MultiModule::Test::begin();

ok my $daemon_pid = App::MultiModule::Test::run_program('-q tqueue -p MultiModuleTest::');

my $config = {
    '.multimodule' => {
        config => {
            MultiModule => {
            },
            Example1 => {
                outstr => 'howdy'
            },
            Router => {  #router config
            }
        },
    }
};

ok IPC::Transit::send(qname => 'tqueue', message => $config);

sleep 20;

#ask it to go away nicely
ok IPC::Transit::send(qname => 'tqueue', message => {
    '.multimodule' => {
        control => [
            {   type => 'cleanly_exit',
                exit_externals => 1,
            }
        ],
    }
});

sleep 6;
ok waitpid($daemon_pid, WNOHANG) == $daemon_pid;
ok not kill 9, $daemon_pid;


App::MultiModule::Test::finish();

done_testing();

__END__
In this test, we will implement the flow found in lossless-task-migration.t
with static_forwards instead of regular routing rules.

