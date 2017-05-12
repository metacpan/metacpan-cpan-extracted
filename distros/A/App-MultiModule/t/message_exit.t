#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX ":sys_wait_h";
use Test::More;
use IPC::Transit;
use App::MultiModule::API;
use Data::Dumper;

BEGIN {
    use_ok( 'App::MultiModule' ) || print "Bail out!\n";
    use_ok( 'App::MultiModule::Test' ) || print "Bail out!\n";
}

App::MultiModule::Test::begin();

my $test_qname_in = 'tqueue';
my $test_qname_out = 'tqueue_out';
my $module_qname = 'OtherModule';

ok my $pid = App::MultiModule::Test::run_program('-q tqueue -p MultiModuleTest::');

my $increment = int rand 10000;
my $config = {
    '.multimodule' => {
        config => {  #consider putting this under '.multimodule' namespace
            MultiModule => {

            },
            OtherModule => {
                increment_by => $increment, #random number here
            },
            Router => {  #router config
                routes => [
                    {   match => {
                            some => 'message',
                        },
                        forwards => [
                            {   qname => $test_qname_out }
                        ]
                    }
               ],
            }
        },
    }
};

ok IPC::Transit::send(qname => $test_qname_in, message => $config);

sleep 2;

my $initial_ct = int rand 10000;
ok IPC::Transit::send(qname => $module_qname, message => {
    some => 'message',
    ct => $initial_ct
});

sleep 4;

eval {
    ok my $msg = IPC::Transit::receive(qname => $test_qname_out, nonblock => 1);
    ok $msg->{ct} == $initial_ct;
    ok $msg->{my_ct} == $initial_ct + $increment;
    ok $msg->{module_pid} == $pid;

    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status('main');
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
};
print STDERR "exception: $@\n" if $@;

sleep 3;

#ask it to go away nicely
ok IPC::Transit::send(qname => $test_qname_in, message => {
    '.multimodule' => {
        control => [
            {   type => 'cleanly_exit' }
        ],
    }
});

sleep 4;

ok waitpid($pid, WNOHANG) == $pid;
ok not kill 15, $pid;

App::MultiModule::Test::finish();

done_testing();
