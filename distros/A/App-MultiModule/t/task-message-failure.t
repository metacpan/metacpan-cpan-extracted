#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX ":sys_wait_h";
use Test::More skip_all => 'needs more development before I can unleash this on CPAN testers';
use IPC::Transit;
use Data::Dumper;

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
                extra_stuff => {
                    extra => 'stuff',
                }
            },
            OtherExternalModule => {
                is_external => 1,
                increment_by => $OtherExternalModule->{increment},
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
#Everything run smoothly for a while
for (1..6) {
    $OtherExternalModule->send();
    my ($levels, $founds) = App::MultiModule::Test::fetch_alerts(
        'test_alert_queue',
        {   check_type => 'queue',
            bucket_metric => 'local.queue.bytes_of_max',
        },
        $got_levels,
        220
    );
    $OtherExternalModule->receive(type => 'external');
}

#Now start causing exceptions
for (1..200) {
    $OtherExternalModule->send();
    my ($levels, $founds) = App::MultiModule::Test::fetch_alerts(
        'test_alert_queue',
        {   check_type => 'admin',
            bucket_metric => 'local.admin.task_message_failure',
        },
        $got_levels,
        220
    );
    ok $OtherExternalModule->receive(type => 'external');
    last if $got_levels->{severe};
    ok IPC::Transit::send(qname => 'OtherExternalModule', message => {
        uncaught_exception => 'boom'
    });
    print STDERR Data::Dumper::Dumper $got_levels;
}
ok $got_levels->{severe};

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

sleep 16;
ok waitpid($daemon_pid, WNOHANG) == $daemon_pid;
ok not kill 9, $daemon_pid;


App::MultiModule::Test::finish();

done_testing();
