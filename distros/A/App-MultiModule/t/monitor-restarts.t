#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX ":sys_wait_h";
use Test::More skip_all => 'needs more development before I can unleash this on
CPAN testers';
use IPC::Transit;
use Data::Dumper;
use Storable;

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

#make sure everything is flowing normally
$OtherExternalModule->send();
$OtherModule->send();
$OtherModule->receive(type => 'internal');
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'external');
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'external');
$OtherExternalModule->receive(type => 'external');

$OtherModule->send();
$OtherModule->send();
$OtherModule->receive(type => 'internal');
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'external');
$OtherModule->send();
$OtherModule->receive(type => 'internal');
$OtherModule->receive(type => 'internal');

my $crash = sub {
    my $crash_message = Storable::dclone $OtherExternalModule->{match};
    $crash_message->{crash_me} = 1;
    IPC::Transit::send(
        qname => $OtherExternalModule->{task_name},
        message => $crash_message
    );
};

#the idea is to just keep crashing this poor guy until we get the alert
my $got_levels = {};
for (1..100) {
    $crash->();
    my ($levels, $founds) = App::MultiModule::Test::fetch_alerts(
        'test_alert_queue',
        {   check_type => 'admin',
            bucket_metric => 'local.admin.start.external',
        },
        $got_levels,
        220,
    );
    print STDERR Data::Dumper::Dumper $got_levels;
    last if $got_levels->{warn};
    last if $got_levels->{severe};
}


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
