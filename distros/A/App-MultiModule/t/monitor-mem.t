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
                transform => {
                    hi => 'there',
                },
            },
            Router => {  #router config
                routes => [
                    {   match => $OtherExternalModule->{match},
                        forwards => [
                            {   qname => $OtherExternalModule->{out_qname} }
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

my $got_levels = {};
#get it going without burning memory
for (1..6) {
    $OtherExternalModule->send();
    my ($levels, $founds) = App::MultiModule::Test::fetch_alerts(
        'test_alert_queue',
        {   check_type => 'process',
            bucket_metric => 'local.memory.vss_of_box_physical',
        },
        $got_levels,
        220
    );
    $OtherExternalModule->receive(type => 'external');
}

my $leak_amt = 10;
#now burn some memory
for (1..100) {
    $OtherExternalModule->send(extras => { leak_memory => 1024 * 1024 * $leak_amt });
    $leak_amt += 5;
    my ($levels, $founds) = App::MultiModule::Test::fetch_alerts(
        'test_alert_queue',
        {   check_type => 'process',
            bucket_metric => 'local.memory.vss_of_box_physical',
        },
        $got_levels,
        220, 
    );
    {   my $spin = $OtherExternalModule->receive(type => 'external', match => { hi => 'there' });
        ok $spin->{leak_memory};
    }
    last if $got_levels->{severe};
    last if $got_levels->{failsafe};
}
ok $got_levels->{severe};
ok $got_levels->{warn};
ok $got_levels->{ok};

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
