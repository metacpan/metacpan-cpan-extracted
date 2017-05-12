#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX ":sys_wait_h";
use Test::More;
use IPC::Transit;
use Data::Dumper;

BEGIN {
    use_ok( 'App::MultiModule' ) || print "Bail out!\n";
    use_ok( 'App::MultiModule::API' ) || print "Bail out!\n";
    use_ok( 'App::MultiModule::Test' ) || print "Bail out!\n";
}

App::MultiModule::Test::begin();

my $test_qname_in = 'tqueue';
my $test_qname_out = 'tqueue_out';
my $test_qname_out_alt = 'tqueue_out_alt';
my $module_qname = 'OtherExternalModule';
my $module_qname_alt = 'OtherModule';

ok my $pid = App::MultiModule::Test::run_program('-q tqueue -p MultiModuleTest::');

my $increment = int rand 10000;
my $increment_alt = int rand 10000;
my $config = {
    '.multimodule' => {
        config => {
            MultiModule => {

            },
            OtherExternalModule => {
                is_external => 1,
                increment_by => $increment,
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
                            another => 'different message',
                        },
                        forwards => [
                            {   qname => $test_qname_out_alt }
                        ]
                    }
                ],
            }
        },
    }
};

ok IPC::Transit::send(qname => $test_qname_in, message => $config);

sleep 6;

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

sleep 6;

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
print STDERR "exception: $@\n" if $@;

=head1 cut
#then the internal
{   ok my $msg = IPC::Transit::receive(qname => $test_qname_out_alt, nonblock => 1);
    ok $msg->{ct} == $initial_ct_alt;
    ok $msg->{my_ct} == $initial_ct_alt + $increment_alt;
    ok $msg->{module_pid} == $pid;
    ok my $api = App::MultiModule::API->new();
    ok my $status = $api->get_task_status($module_qname_alt);
    ok my $module_pid = $status->{pid};
    #print STDERR "\$module_pid = $module_pid \$msg->{module_pid}=$msg->{module_pid}\n";
    ok $module_pid == $msg->{module_pid};
    ok my $save_ts = $status->{save_ts};
    ok $save_ts - time < 5;
}
=cut

#check the dynamic transform
eval {
    ok IPC::Transit::send(qname => $module_qname, message => {
        '.multimodule' => {
            transform => {
                some => {
                    levels => {
                        down => {
                            some => ['rich'],
                            config => 'structure',
                        }
                    }
                }
            }
        }
    });
    sleep 6;
    ok my $api = App::MultiModule::API->new();
    ok my $state = $api->get_task_state($module_qname);
    ok $state->{some};
    ok $state->{some}->{levels};
    ok $state->{some}->{levels}->{down};
    ok $state->{some}->{levels}->{down}->{config};
    ok $state->{some}->{levels}->{down}->{config} eq 'structure';
    ok $state->{some}->{levels}->{down}->{some};
    ok $state->{some}->{levels}->{down}->{some}->[0];
    ok $state->{some}->{levels}->{down}->{some}->[0] eq 'rich';
};
print STDERR "exception in dynamic transform: $@\n" if $@;



App::MultiModule::Test::cleanly_exit('tqueue');
ok waitpid($pid, WNOHANG) == $pid;
ok not kill 15, $pid;

App::MultiModule::Test::finish();

done_testing();
