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

ok my $daemon_pid = App::MultiModule::Test::run_program('-q tqueue -p MultiModuleTest::');

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

#now failsafe OtherExternalModule
ok $api->failsafe_task('OtherExternalModule');

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
$OtherExternalModule->receive(type => 'external'); #clean any strays

$OtherExternalModule->send();
#failsafed external module is no longer functioning
ok not $OtherExternalModule->receive(type => 'external', no_fail_exceptions => 1);


#unfailsafe OtherExternalModule
ok $api->unfailsafe_task('OtherExternalModule');

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
