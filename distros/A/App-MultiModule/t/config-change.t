#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX ":sys_wait_h";
use Test::More;
use IPC::Transit;
use Data::Dumper;

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
                transform => {
                    config => 'first',
                }
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


$OtherExternalModule->send();
$OtherModule->send();
$OtherModule->receive(type => 'internal');
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'external', match => {config => 'first'});
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'external', match => {config => 'first'});
$OtherExternalModule->receive(type => 'external', match => {config => 'first'});

#change the config
ok IPC::Transit::send(qname => 'tqueue', message => {
    '.multimodule' => {
        config => {
            OtherExternalModule => {
                is_external => 1,
                increment_by => $OtherExternalModule->{increment},
                transform => {
                    config => 'second',
                },
            },
        },
    },
});

#give it a little while to percolate
sleep 4;
#now test it out.
$OtherExternalModule->send();
$OtherModule->send();
$OtherModule->receive(type => 'internal');
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'external', match => {config => 'second'});
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'external', match => {config => 'second'});
$OtherExternalModule->receive(type => 'external', match => {config => 'second'});

#change the config again, and make it internal
ok IPC::Transit::send(qname => 'tqueue', message => {
    '.multimodule' => {
        config => {
            OtherExternalModule => {
                increment_by => $OtherExternalModule->{increment},
                transform => {
                    config => 'third',
                },
            },
        },
    },
});

#give it a little while to percolate
sleep 4;
#now test it out.
$OtherExternalModule->send();
$OtherModule->send();
$OtherModule->receive(type => 'internal');
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'internal', match => {config => 'third'});
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'internal', match => {config => 'third'});
$OtherExternalModule->receive(type => 'internal', match => {config => 'third'});

App::MultiModule::Test::cleanly_exit('tqueue');
ok waitpid($daemon_pid, WNOHANG) == $daemon_pid;
ok not kill 9, $daemon_pid;


App::MultiModule::Test::finish();

done_testing();
