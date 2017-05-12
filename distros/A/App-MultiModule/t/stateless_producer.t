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
my $test_qname_out_alt = 'tqueue_out_alt';
my $test_qname_out_secondary = 'tqueue_out_secondary';
my $test_qname_out_tertiary = 'tqueue_out_tertiary';
my $module_qname = 'OtherExternalModule';
my $module_qname_alt = 'OtherModule';
my $module_qname_secondary = 'YetAnotherExternalModule';

ok my $pid = App::MultiModule::Test::run_program('-q tqueue -p MultiModuleTest::');


my $increment = int rand 10000;
my $increment_alt = int rand 10000;
my $increment_secondary = int rand 10000;
my $config = {
    '.multimodule' => {
        config => {  #consider putting this under '.multimodule' namespace
            StatelessProducer => {
                whatever => 'thing',
            },
            MultiModule => {

            },
            OtherExternalModule => {
                is_external => 1,
                increment_by => $increment,
            },
            YetAnotherExternalModule => {
                increment_by => $increment_secondary, #random number here
                is_external => 1,
            },
            OtherModule => {
                increment_by => $increment_alt, #random number here
            },
            Router => {  #router config
                routes => [
                    {   match => {
                            some => 'message',
                        },
                        forwards => [
                            {   qname => $test_qname_out }
                        ]
                    },{ match => {
                            source => 'Incrementer',
                        },
                        forwards => [
                            {   qname => $test_qname_out_tertiary }
                        ]
                    },{ match => {
                            source => 'StatelessProducer',
                        },
                        forwards => [
                            {   qname => 'Incrementer' }
                        ]
                    },{ match => {
                            another => 'different message',
                        },
                        forwards => [
                            {   qname => $test_qname_out_alt }
                        ]
                    },{ match => {
                            secondary => 'message',
                        },
                        forwards => [
                            {   qname => $test_qname_out_secondary }
                        ]
                    }
                ],
            }
        },
    }
};

ok IPC::Transit::send(qname => $test_qname_in, message => $config);

sleep 16;

my $initial_ct = int rand 10000;
ok IPC::Transit::send(qname => $module_qname, message => {
    some => 'message',
    ct => $initial_ct
});

my $initial_ct_alt = int rand 10000;
ok IPC::Transit::send(qname => $module_qname_alt, message => {
    another => 'different message',
    ct => $initial_ct_alt
});
my $initial_ct_secondary = int rand 10000;
ok IPC::Transit::send(qname => $module_qname_secondary, message => {
    secondary => 'message',
    ct => $initial_ct_secondary
});

sleep 36;

#first the external
eval {
    ok my $msg = IPC::Transit::receive(qname => $test_qname_out, nonblock => 1);
    ok $msg->{ct} == $initial_ct;
    ok $msg->{my_ct} == $initial_ct + $increment;
    ok $msg->{module_pid} != $pid;

    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status($module_qname);
    ok my $module_pid = $status->{pid};
    ok $module_pid == $msg->{module_pid};
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
};
print STDERR "exception in external: $@\n" if $@;

#then the internal
eval {
    ok my $msg = IPC::Transit::receive(qname => $test_qname_out_alt, nonblock => 1);
    ok $msg->{ct} == $initial_ct_alt;
    ok $msg->{my_ct} == $initial_ct_alt + $increment_alt;
    #print STDERR "test: (multimodule PID $pid): " . Data::Dumper::Dumper $msg;
    ok $msg->{module_pid} == $pid;
    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status($module_qname_alt);
    ok my $module_pid = $status->{pid};
    ok $module_pid == $msg->{module_pid};
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
};
print STDERR "exception in internal: $@\n" if $@;


#then the other external
eval {
    ok my $msg = IPC::Transit::receive(qname => $test_qname_out_secondary, nonblock => 1);
    ok $msg->{ct} == $initial_ct_secondary;
    ok $msg->{my_ct} == $initial_ct_secondary + $increment_secondary;
    ok $msg->{module_pid} != $pid;
    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status($module_qname_secondary);
    ok my $module_pid = $status->{pid};
    ok $module_pid == $msg->{module_pid};
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
};
print STDERR "exception in other external: $@\n" if $@;

#ask it to go away nicely
ok IPC::Transit::send(qname => $test_qname_in, message => {
    '.multimodule' => {
        control => [
            {   type => 'cleanly_exit',
                exit_externals => 1,
            }
        ],
    }
});

sleep 18;

{   my $ret = waitpid($pid, WNOHANG);
    ok $ret == $pid;
}
ok not kill 15, $pid;

while(my $msg = IPC::Transit::receive(qname => $test_qname_out_tertiary, nonblock => 1)) {
    ok $msg->{i} == $msg->{emit_ct} + 1;
    ok $msg->{source} eq 'Incrementer';
    ok $msg->{previous_source} eq 'StatelessProducer';
}
App::MultiModule::Test::finish();

done_testing();
