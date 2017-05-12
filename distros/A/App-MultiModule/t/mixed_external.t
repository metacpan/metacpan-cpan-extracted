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

ok my $pid = App::MultiModule::Test::run_program('-q tqueue -p MultiModuleTest::');

my $OtherExternalModule_increment = int rand 10000;
my $OtherModule_increment = int rand 10000;
my $config = {
    '.multimodule' => {
        config => {
            MultiModule => {

            },
            OtherExternalModule => {
                is_external => 1,
                increment_by => $OtherExternalModule_increment,
            },
            OtherModule => {
                increment_by => $OtherModule_increment, #random number here
#                is_external => 1,
            },
            Router => {  #router config
                routes => [
                    {   match => {
                            match_for => 'OtherExternalModule',
                        },
                        forwards => [
                            {   qname => 'OtherExternalModule_out' }
                        ]
                    },{ match => {
                            match_for => 'OtherModule',
                        },
                        forwards => [
                            {   qname => 'OtherModule_out' }
                        ]
                    }
                ],
            }
        },
    }
};

ok IPC::Transit::send(qname => 'tqueue', message => $config);

sleep 6;

my $OtherExternalModule_initial_ct = int rand 10000;
ok IPC::Transit::send(qname => 'OtherExternalModule', message => {
    match_for => 'OtherExternalModule',
    ct => $OtherExternalModule_initial_ct
});

my $OtherModule_initial_ct = int rand 10000;
ok IPC::Transit::send(qname => 'OtherModule', message => {
    match_for => 'OtherModule',
    ct => $OtherModule_initial_ct
});

sleep 6;

#first the external
eval {
    ok my $msg = IPC::Transit::receive(qname => 'OtherExternalModule_out', nonblock => 1);
    ok $msg->{ct} == $OtherExternalModule_initial_ct;
    ok $msg->{my_ct} == $OtherExternalModule_initial_ct + $OtherExternalModule_increment;
    ok $msg->{module_pid} != $pid;

    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status('OtherExternalModule');
    ok my $module_pid = $status->{pid};
    ok $module_pid == $msg->{module_pid};
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
};
print STDERR "exception: $@\n" if $@;

#then the internal
eval {
    ok my $msg = IPC::Transit::receive(qname => 'OtherModule_out', nonblock => 1);
    ok $msg->{ct} == $OtherModule_initial_ct;
    ok $msg->{my_ct} == $OtherModule_initial_ct + $OtherModule_increment;
    ok $msg->{module_pid} == $pid;
    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status('main');
    ok my $module_pid = $status->{pid};
    #print STDERR "\$module_pid = $module_pid \$msg->{module_pid}=$msg->{module_pid}\n";
    ok $module_pid == $msg->{module_pid};
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
};
ok not $@;

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

ok waitpid($pid, WNOHANG) == $pid;
ok not kill 15, $pid;

App::MultiModule::Test::finish();

done_testing();
