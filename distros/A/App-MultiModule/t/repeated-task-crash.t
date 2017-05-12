#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX ":sys_wait_h";
use Test::More;
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

sleep 35;

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
    sleep 12; #give time for Router to route
    my $crash_message = Storable::dclone $OtherExternalModule->{match};
    $crash_message->{crash_me} = 1;
    IPC::Transit::send(
        qname => $OtherExternalModule->{task_name},
        message => $crash_message
    );
};

#crash it and validate it's back several times
for (1..10) {
    my $rand = int rand 4;
    print STDERR "\$rand=$rand\n";
    ok $crash->() if $rand == 0;
    print STDERR '$OtherExternalModule->send();' . "\n";
    $OtherExternalModule->send();
    ok $crash->() if $rand == 1;
    print STDERR '$OtherModule->send();' .  "\n";
    $OtherModule->send();
    ok $crash->() if $rand == 2;
    print STDERR '$OtherExternalModule->receive(type => external);' .  "\n";
    $OtherExternalModule->receive(type => 'external');
    ok $crash->() if $rand == 3;
    print STDERR '$OtherModule->receive(type => internal);' .  "\n";
    $OtherModule->receive(type => 'internal');
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
