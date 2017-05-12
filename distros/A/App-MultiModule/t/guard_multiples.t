#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('App::MultiModule::Test') || print "Bail out!\n";
    use_ok('App::MultiModule::API') || print "Bail out!\n";
}

App::MultiModule::Test::begin();
my $first_pid = App::MultiModule::Test::run_program('-p this,that -d 10 -q tqueue');

ok $first_pid;
ok -e "/proc/$first_pid";

my $second_pid;
eval {
    $second_pid = App::MultiModule::Test::run_program('-d 10 -q tqueue');
};
ok $@;
ok $@ =~ /App::MultiModule::Test::run_program: failed: failed/;
ok not $second_pid;

sleep 2;


App::MultiModule::Test::term_program();
ok not -e "/proc/$first_pid";

my $api = App::MultiModule::API->new();
$api->save_task_state('test', { some => 'stuff' });

my $state = $api->get_task_state('test');
print Dumper $state;

App::MultiModule::Test::finish();
done_testing();

