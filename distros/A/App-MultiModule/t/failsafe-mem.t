#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX ":sys_wait_h";
use Test::More skip_all => 'needs more development before I can unleash this on
CPAN testers';
use IPC::Transit;
use Data::Dumper;

use App::MultiModule::API;

BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::StatefulStream') || die "Failed to load App::MultiModule::Test::StatefulStream\n";
}

App::MultiModule::Test::begin();

ok my $daemon_pid = App::MultiModule::Test::run_program('-q tqueue -p MultiModuleTest:: -o alert:test_alert_queue,this:that');

my $OtherExternalModule = App::MultiModule::Test::StatefulStream->new(
    task_name => 'OtherExternalModule',
    program_pid => $daemon_pid,
);
my $OtherModule = App::MultiModule::Test::StatefulStream->new(
    task_name => 'OtherModule',
    program_pid => $daemon_pid,
);

my $config = {
    '.multimodule' => {
        config => {
            MultiModule => {

            },
            StatelessProducer => {

            },
            OtherExternalModule => {
                is_external => 1,
                increment_by => $OtherExternalModule->{increment},
            },
            OtherModule => {
                increment_by => $OtherModule->{increment},
#                is_external => 1,
            },
            Router => {  #router config
                routes => [
                    {   match => $OtherExternalModule->{match},
                        forwards => [
                            {   qname => $OtherExternalModule->{out_qname} }
                        ]
                    },{ match => $OtherModule->{match},
                        forwards => [
                            {   qname => $OtherModule->{out_qname} }
                        ]
                    },{ match => {
                            source => 'Incrementer',
                        },
                        forwards => [
                            {   qname => 'Incrementer_out' }
                        ],
                    },{ match => {
                            source => 'StatelessProducer',
                        },
                        forwards => [
                            {   qname => 'Incrementer' }
                        ],
                    }
                ],
            }
        },
    }
};

ok IPC::Transit::send(qname => 'tqueue', message => $config);


#everything working well..
$OtherExternalModule->send();
$OtherModule->send();
$OtherModule->receive(type => 'internal');
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'external');
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'external');
$OtherExternalModule->receive(type => 'external');
$OtherExternalModule->send();

$OtherModule->send();
$OtherModule->send();
$OtherModule->send();
$OtherModule->send();
$OtherModule->receive(type => 'internal');
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'external');
$OtherExternalModule->receive(type => 'external');
$OtherModule->send();
$OtherModule->receive(type => 'internal');
$OtherModule->receive(type => 'internal');

ok my $api = App::MultiModule::API->new();
ok not $api->task_is_failsafe('OtherExternalModule');
{   my $status = $api->get_task_status('OtherExternalModule');
    ok $status->{is_running};
}


sleep 2; #nothing stray going on

my $got_levels = {};

my $leak_amt = 10;
#now cause OtherExternalModule to memory failsafe
for (1..100) {
    $OtherExternalModule->send(extras => { leak_memory => 1024 * 1024 * $leak_amt });
    $leak_amt += 5;
    my ($levels, $founds) = App::MultiModule::Test::fetch_alerts(
        'test_alert_queue',
        {   check_type => 'process',
            bucket_metric => 'local.memory.vss_of_box_physical',
        },
        $got_levels,
        220
    );
    $OtherExternalModule->receive(type => 'external', no_fail_exceptions => 1);
    last if $got_levels->{failsafe};
    print STDERR Data::Dumper::Dumper $got_levels;
}
ok $got_levels->{failsafe};
ok $got_levels->{severe};
ok $got_levels->{warn};

sleep 2;
#should be down now.
#make sure the other guy is fine
$OtherModule->send();
$OtherModule->receive(type => 'internal');

ok $api->task_is_failsafe('OtherExternalModule');
{   my $status = $api->get_task_status('OtherExternalModule');
    ok not $status->{is_running};
}

sleep 2;

$OtherExternalModule->send();
#failsafed external module is no longer functioning
ok not $OtherExternalModule->receive(type => 'external', no_fail_exceptions => 1);
ok IPC::Transit::receive(qname => 'OtherExternalModule');

#unfailsafe OtherExternalModule
ok $api->unfailsafe_task('OtherExternalModule');

#sometimes the most recent message gets lost during the failsafe
{   my $stat = IPC::Transit::stat(qname => 'OtherExternalModule', override_local => 1);
    print STDERR Data::Dumper::Dumper $stat;
    system 'qtrans | grep -v "   0 "';
    shift @{$OtherExternalModule->{sent_messages}};
    if($stat and $stat->{qnum} == 0) {
        shift @{$OtherExternalModule->{sent_messages}};
    }
}

$OtherExternalModule->send();
ok $OtherExternalModule->receive(type => 'external');

sleep 2;
#should be back now
ok not $api->task_is_failsafe('OtherExternalModule');
{   my $status = $api->get_task_status('OtherExternalModule');
    ok $status->{is_running};
}
$OtherExternalModule->send();
$OtherExternalModule->send();
$OtherModule->send();
$OtherModule->send();
ok $OtherExternalModule->receive(type => 'external');
ok $OtherExternalModule->receive(type => 'external');
ok $OtherModule->receive(type => 'internal');
ok $OtherModule->receive(type => 'internal');
ok $OtherModule->receive(type => 'internal');
sleep 6;

ok $OtherModule->receive(type => 'internal');
#bye bye now
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
