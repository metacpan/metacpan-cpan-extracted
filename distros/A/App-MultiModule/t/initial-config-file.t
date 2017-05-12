#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX ":sys_wait_h";
use Test::More skip_all => 'needs more development before I can unleash this on
CPAN testers';
use IPC::Transit;
use Data::Dumper;

BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::StatefulStream') || die "Failed to load App::MultiModule::Test::StatefulStream\n";
}

App::MultiModule::Test::begin();

my $OtherExternalModule = App::MultiModule::Test::StatefulStream->new(
    task_name => 'OtherExternalModule',
);

{   my $config = {
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
    };
    open my $fh, '>', 'test.conf';
    print $fh Data::Dumper::Dumper $config;
    close $fh;
}

ok my $daemon_pid = App::MultiModule::Test::run_program('-q tqueue -p MultiModuleTest:: -c test.conf');

for (1..10) {
    $OtherExternalModule->send();
    $OtherExternalModule->receive(type => 'external');
}

App::MultiModule::Test::cleanly_exit('tqueue');
ok waitpid($daemon_pid, WNOHANG) == $daemon_pid;
ok not kill 9, $daemon_pid;

App::MultiModule::Test::finish();

done_testing();
