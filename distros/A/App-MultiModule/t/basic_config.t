#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;
use IPC::Transit;

BEGIN {
    use_ok('App::MultiModule::Test') || print "Bail out!\n";
    use_ok('App::MultiModule::API') || print "Bail out!\n";
}

my $config = {
    '.multimodule' => {
        config => {
            MultiModule => {
                something => 'interesting',
            },
        }
    }
};

App::MultiModule::Test::begin();
my $first_pid = App::MultiModule::Test::run_program('-q tqueue -pMultiModuleTest::');

ok $first_pid;
ok -e "/proc/$first_pid";
ok IPC::Transit::send(qname => 'tqueue', message => $config);
my $api = App::MultiModule::API->new();

sleep 3;
{   my $config = $api->get_task_config('MultiModule');
    ok $config->{something} eq 'interesting';
}



App::MultiModule::Test::term_program();
ok not -e "/proc/$first_pid";



App::MultiModule::Test::finish();
done_testing();

