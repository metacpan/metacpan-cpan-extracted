#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX ":sys_wait_h";
use Test::More;
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
                transform => {
                    hi => 'there',
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
$OtherExternalModule->receive(type => 'external', match => { hi => 'there' });
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

#OtherExternalModule external -> internal
ok IPC::Transit::send(qname => 'tqueue', message => {
    '.multimodule' => {
        config => {
            OtherExternalModule => {
                increment_by => $OtherExternalModule->{increment},
            },
        },
    },
});

#test it out
$OtherExternalModule->send();
$OtherExternalModule->send();
$OtherExternalModule->receive();
$OtherExternalModule->send();
$OtherExternalModule->receive();
$OtherExternalModule->receive();

#by now, it should have transitioned to internal
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'internal');

#back again
#OtherExternalModule internal -> external
ok IPC::Transit::send(qname => 'tqueue', message => {
    '.multimodule' => {
        config => {
            OtherExternalModule => {
                increment_by => $OtherExternalModule->{increment},
                is_external => 1,
            },
        },
    },
});

#test it out
$OtherExternalModule->send();
$OtherModule->send();
$OtherExternalModule->send();
$OtherExternalModule->receive();
$OtherModule->send();
$OtherExternalModule->send();
$OtherModule->receive(type => 'internal');
$OtherModule->receive(type => 'internal');
$OtherExternalModule->receive();
$OtherExternalModule->receive();

#by now, it should have transitioned back to external
$OtherExternalModule->send();
$OtherExternalModule->receive(type => 'external');

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
