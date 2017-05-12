#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX ":sys_wait_h";
use Test::More skip_all => 'needs more development before I can unleash this on';
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

my $block = [
    {   object => $OtherModule,
        name => 'OtherModule',
        ct => 1234,
    },{ object => $OtherExternalModule,
        name => 'OtherExternalModule',
        ct => 1234,
    },
];
my $do_tests_call_ct = 0;
my $ops = {
    'send' => 0,
    'receive' => 0,
    OtherModule => {
        to_internal => 0,
        to_external => 0,
    },
    OtherExternalModule => {
        to_internal => 0,
        to_external => 0,
    },
};

sub do_tests {
    my $count = shift;
    my $chance_of_change = shift;
    if(int rand 100 < $chance_of_change) {
        #randomly set internal/external config of one of the tasks
        my $task = $block->[int rand 2];
        my $task_name = $task->{name};
        my $task_object = $task->{object};
        my $message = {
            '.multimodule' => {
                config => {
                    $task_name => {
                        increment_by => $task_object->{increment},
                    },
                },
            }
        };
        if(int rand 2) { #internal
            $ops->{$task_name}->{to_internal}++;
        } else { #external
            $ops->{$task_name}->{to_external}++;
            $message->{'.multimodule'}->{config}->{$task_name}->{is_external} = 1;
        }
        IPC::Transit::send(qname => 'tqueue', message => $message);
    }
    $do_tests_call_ct++;
    $ops->{do_tests_call_ct} = $do_tests_call_ct;
    my $operation_ct = 0;
    for (1..$count) {
        my $task = $block->[int rand 2];
        if(not defined $task->{send_ct}) {
            $task->{send_ct} = $task->{ct};
            $task->{receive_ct} = $task->{ct};
            $ops->{total_ct} = $task->{ct};
        }
        if(int rand 2) { #send
            next unless $task->{send_ct};
            $task->{send_ct}--;
            $task->{object}->send();
            $operation_ct++;
            $ops->{'send'}++;
        } else { #receive
            next unless $task->{receive_ct};
            next unless $task->{send_ct} < $task->{receive_ct};
            $task->{receive_ct}--;
            $task->{object}->receive();
            $operation_ct++;
            $ops->{'receive'}++;
        }
    }
    return ($operation_ct, $ops);
}

my $config = {
    '.multimodule' => {
        config => {
            MultiModule => {

            },
            StatelessProducer => {
#                emit_rate => 3,
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

for (1..50) {
    my ($ct, $ops) = do_tests(20, 20);
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
