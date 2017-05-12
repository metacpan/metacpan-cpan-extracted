use strict;
use warnings;
use Test::More;
use Test::Moose;
use Test::Exception;
use t::TestUtils;

my $schema = schema();
my ($e, $process) = process_wrap();
my $activity = $process->add_to_activities({})->discard_changes;
my $pi = $process->new_instance();

is($schema->resultset('ActivityInstanceState')->search_rs->count, 0);

my $aic = $activity->new_instance({ process_instance_id => $pi->id });
ok($aic->workflow_instance_id);
is($schema->resultset('ActivityInstanceState')->search_rs->count, 1);
is($pi->activity_instances->count, 1);

#-- get ai

my $ai = $pi->activity_instances->first;
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');

does_ok($ai, 'BPM::Engine::Store::ResultBase::ActivityInstance');
does_ok($ai, 'BPM::Engine::Store::ResultRole::WithAttributes');
does_ok($ai, 'BPM::Engine::Store::ResultRole::WithWorkflow');

has_attribute_ok($ai, 'workflow');
has_attribute_ok($ai, 'error');
can_ok($ai, qw/get_workflow apply_transition clone state/);

isa_ok($ai->workflow, 'Class::Workflow');
isa_ok($ai->workflow_instance, 'BPM::Engine::Store::Result::ActivityInstanceState');
does_ok($ai->workflow_instance, 'Class::Workflow::Instance');

my $wf = $ai->workflow;
my $wi = $ai->workflow_instance;
#state     The state this instance is in. Required.
#prev    The Class::Workflow::Instance object this object was derived from. Optional.
#transition

my $s1 = $wi->state;
#isa_ok($s1,'Class::Workflow::State::Simple');
isa_ok($s1,'BPM::Engine::Class::Workflow::State');
#warn Dumper $s1->name;
my $s2 = $wf->get_state($s1->name);
#warn Dumper $s2->name;
#isa_ok($s2,'Class::Workflow::State::Simple');
isa_ok($s2,'BPM::Engine::Class::Workflow::State');

is($ai->workflow_instance->state->name, 'open.not_running.ready', 'State set to open.not_running.not_assigned');
is($ai->state, 'open.not_running.ready');

my $rs = $schema->resultset('ActivityInstanceState')->search_rs;
is($rs->count, 1);

$ai->apply_transition('start');
is($ai->workflow_instance->state->name, 'open.running.not_assigned');
is($rs->count, 2);

$ai->apply_transition('assign');
is($ai->workflow_instance->state->name, 'open.running.assigned');
is($rs->count, 3);

$ai->apply_transition('suspend');
is($ai->workflow_instance->state->name, 'open.not_running.suspended', 'suspended');
is($rs->count, 4);

$ai->apply_transition('resume');
is($ai->workflow_instance->state->name, 'open.running.assigned', 'resumed');

$ai->apply_transition('reassign');
is($ai->workflow_instance->state->name, 'open.running.assigned', 'reassigned');

my $ai2 = $ai->clone;
is($ai2->workflow_instance->state->name, 'open.not_running.ready', 'ready');

$ai2->apply_transition('assign');
is($ai2->workflow_instance->state->name, 'open.running.assigned', 'assigned');

#$ai2->update;
$ai->apply_transition('abort');
is($ai2->workflow_instance->state->name, 'open.running.assigned', 'open.running.assigned');
is($ai->workflow_instance->state->name, 'closed.cancelled.aborted');

$ai2->apply_transition('finish');
is($ai2->workflow_instance->state->name, 'closed.completed');

# clean up
#$pi->delete;
#$process->package->delete;

done_testing();
