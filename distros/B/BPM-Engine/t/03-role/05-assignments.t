use strict;
use warnings;
use Test::More;
use t::TestUtils;

{
package WAss;
use Moose;
has 'process' => ( is => 'ro' );
has 'process_instance' => ( is => 'ro' );
with 'BPM::Engine::Role::HandlesAssignments';

sub start_process {}
sub complete_process {}
sub start_activity {}
sub complete_activity {}
sub _execute_transition {}

}


package main;

#- setup

my $schema = schema();
my $package = $schema->resultset('Package')->create_from_xpdl('./t/var/09-data.xpdl');
my $process = $package->processes->first; # $schema->resultset('Process')->search->first;
my $pi = $process->new_instance();

ok(my $wa = WAss->new(process => $process, process_instance => $pi));
ok($wa->process->id);
ok($wa->process_instance->id);

my $activity = $process->start_activity;
my $instance = $activity->new_instance({ process_instance_id => $pi->id });

#my $instance = $pi->activity_instances->first;
isa_ok($instance, 'BPM::Engine::Store::Result::ActivityInstance');
#my $activity = $instance->activity;
isa_ok($activity, 'BPM::Engine::Store::Result::Activity');

#- run tests

is_deeply($pi->attribute('common')->value, ['P2']);

$wa->start_process;
$wa->complete_process;
is_deeply($pi->attribute('common')->value, ['P2']);
$wa->start_activity($activity, $instance);
is_deeply($pi->attribute('common')->value, ['A1']);
$wa->complete_activity($activity, $instance);
is_deeply($pi->attribute('common')->value, ['A2']);
##$wa->_execute_transition;

done_testing();
