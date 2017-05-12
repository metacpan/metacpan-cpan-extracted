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

ok my $parent_pid = App::MultiModule::Test::run_program('-q tqueue -p MultiModuleTest::');

my $OtherExternalModuleIncrement = int rand 10000;
my $OtherModuleIncrement = int rand 10000;
my $YetAnotherExternalModuleIncrement = int rand 10000;
my $config = {
    '.multimodule' => {
        config => {
            MultiModule => {

            },
            OtherExternalModule => {
#                 is_external => 1, this will start as internal
#and we will migrate it to external
                increment_by => $OtherExternalModuleIncrement,
            },
            YetAnotherExternalModule => {
                increment_by => $YetAnotherExternalModuleIncrement, #random number here
                is_external => 1,
            },
            OtherModule => {
                increment_by => $OtherModuleIncrement, #random number here
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
                    },{ match => {
                            match_for => 'YetAnotherExternalModule',
                        },
                        forwards => [
                            {   qname => 'YetAnotherExternalModule_out' }
                        ]
                    }
                ],
            }
        },
    }
};

ok IPC::Transit::send(qname => $test_qname_in, message => $config);

sleep 36;

my $OtherExternalModuleInitialCount = int rand 10000;
ok IPC::Transit::send(qname => 'OtherExternalModule', message => {
    match_for => 'OtherExternalModule',
    ct => $OtherExternalModuleInitialCount
});

my $OtherModuleInitialCount = int rand 10000;
ok IPC::Transit::send(qname => 'OtherModule', message => {
    match_for => 'OtherModule',
    ct => $OtherModuleInitialCount
});
my $YetAnotherExternalModule = int rand 10000;
ok IPC::Transit::send(qname => 'YetAnotherExternalModule', message => {
    match_for => 'YetAnotherExternalModule',
    ct => $YetAnotherExternalModule
});

sleep 16;

#first the internal that will turn into an external
eval {
    ok my $msg = IPC::Transit::receive(qname => 'OtherExternalModule_out', nonblock => 1);
    ok $msg->{ct} == $OtherExternalModuleInitialCount;
    ok $msg->{my_ct} == $OtherExternalModuleInitialCount + $OtherExternalModuleIncrement;
    ok $msg->{module_pid} == $parent_pid;

    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status('OtherExternalModule');
    ok my $module_pid = $status->{pid};
    ok $module_pid == $msg->{module_pid};
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
};
print STDERR "exception in external: $@\n" if $@;

#then the internal
eval {
    ok my $msg = IPC::Transit::receive(qname => 'OtherModule_out', nonblock => 1);
    ok $msg->{ct} == $OtherModuleInitialCount;
    ok $msg->{my_ct} == $OtherModuleInitialCount + $OtherModuleIncrement;
    ok $msg->{module_pid} == $parent_pid;
    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status('main');
    ok my $module_pid = $status->{pid};
    ok $module_pid == $msg->{module_pid};
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
};
print STDERR "exception in internal: $@\n" if $@;


#then the other external
eval {
    ok my $msg = IPC::Transit::receive(qname => 'YetAnotherExternalModule_out', nonblock => 1);
    ok $msg->{ct} == $YetAnotherExternalModule;
    ok $msg->{my_ct} == $YetAnotherExternalModule + $YetAnotherExternalModuleIncrement;
    ok $msg->{module_pid} != $parent_pid;
    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status('YetAnotherExternalModule');
    ok my $module_pid = $status->{pid};
    ok $module_pid == $msg->{module_pid};
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
};
print STDERR "exception in other external: $@\n" if $@;

#now do the migration

#use the same config, just add is_external to OtherExternalModule
$config->{'.multimodule'}->{config}->{OtherExternalModule}->{is_external} = 1;

ok IPC::Transit::send(qname => $test_qname_in, message => $config);
print STDERR "sending re-config\n";
sleep 6;

{
print STDERR "sending OtherExternalModule\n";
my $OtherExternalModuleInitialCount = int rand 10000;
ok IPC::Transit::send(qname => 'OtherExternalModule', message => {
    match_for => 'OtherExternalModule',
    ct => $OtherExternalModuleInitialCount
});

print STDERR "sending OtherModule\n";
my $OtherModuleInitialCount = int rand 10000;
ok IPC::Transit::send(qname => 'OtherModule', message => {
    match_for => 'OtherModule',
    ct => $OtherModuleInitialCount
});

print STDERR "sending YetAnotherExternalModule\n";
my $YetAnotherExternalModule = int rand 10000;
ok IPC::Transit::send(qname => 'YetAnotherExternalModule', message => {
    match_for => 'YetAnotherExternalModule',
    ct => $YetAnotherExternalModule
});

sleep 36;

#this is the newly external task; it was internal before
eval {
    ok my $msg = IPC::Transit::receive(qname => 'OtherExternalModule_out', nonblock => 1);
    ok $msg->{ct} == $OtherExternalModuleInitialCount;
    ok $msg->{my_ct} == $OtherExternalModuleInitialCount + $OtherExternalModuleIncrement;
    ok $msg->{module_pid} != $parent_pid;

    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status('OtherExternalModule');
    ok my $module_pid = $status->{pid};
    ok $module_pid == $msg->{module_pid};
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
};
print STDERR "exception in external: $@\n" if $@;

#then the internal
eval {
    ok my $msg = IPC::Transit::receive(qname => 'OtherModule_out', nonblock => 1);
    ok $msg->{ct} == $OtherModuleInitialCount;
    ok $msg->{my_ct} == $OtherModuleInitialCount + $OtherModuleIncrement;
    ok $msg->{module_pid} == $parent_pid;
    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status('main');
    ok my $module_pid = $status->{pid};
    ok $module_pid == $msg->{module_pid};
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
};
print STDERR "exception in internal: $@\n" if $@;


#then the other external
eval {
    ok my $msg = IPC::Transit::receive(qname => 'YetAnotherExternalModule_out', nonblock => 1);
    ok $msg->{ct} == $YetAnotherExternalModule;
    ok $msg->{my_ct} == $YetAnotherExternalModule + $YetAnotherExternalModuleIncrement;
    ok $msg->{module_pid} != $parent_pid;
    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status('YetAnotherExternalModule');
    ok my $module_pid = $status->{pid};
    ok $module_pid == $msg->{module_pid};
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
};
print STDERR "exception in other external: $@\n" if $@;

}

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

{   my $ret = waitpid($parent_pid, WNOHANG);
    ok $ret == $parent_pid;
}
ok not kill 15, $parent_pid;

App::MultiModule::Test::finish();

done_testing();
