use strict;
use warnings;
use Test::More;
use t::TestUtils;

{
package WAss;
use Test::More;
use Moose;
has 'process' => ( is => 'ro' );
has 'process_instance' => ( is => 'ro' );
with 'BPM::Engine::Role::HandlesTaskdata';

sub execute_task {
    my ($self, $task, $instance) = @_;

    ok(my $thash = $instance->taskdata);
    is($thash->{meta}->{type},'User');
    ok(exists $thash->{parameters});
    is($thash->{message}->{faultname}, 'error');
    is($thash->{service}->{type},'Service');
    is($thash->{users}->[0]->{type},'HUMAN');
    is($thash->{performers}->[0]->{type},'ROLE');

    return 1;
    }

}

package main;

my $schema = schema();
my $package = $schema->resultset('Package')->create_from_xpdl('./t/var/09-data.xpdl');

my $process = $package->processes->first; # $schema->resultset('Process')->search->first;
my $pi = $process->new_instance();

ok(my $wa = WAss->new(process => $process, process_instance => $pi));
ok($wa->process->id);
ok($wa->process_instance->id);

my $activity = $process->start_activity;
my $instance = $activity->new_instance({ process_instance_id => $pi->id });

# start testing

ok(!$instance->taskdata);

foreach my $task($activity->tasks->all) {
    $wa->execute_task($task, $instance);
    }

#warn Dumper $instance->taskdata;

ok(1);

done_testing();

