use strict;
use warnings;
use Test::More;
use Test::Moose;
use DateTime;
use t::TestUtils;

my ($engine, $process) = process_wrap();
my $pi = $engine->create_process_instance($process);

#-- new activity

my $activity = $process->add_to_activities({
    activity_uid     => 1,
    activity_name    => 'work item',
    activity_type    => 'Implementation',
    start_mode => 'Manual'
    });
$activity->discard_changes;

#-- new activity_instance

my $ai = $activity->add_to_instances({ process_instance_id => $pi->id });
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');
$ai->delete;

# the right way to do it
$ai = $activity->new_instance({
    process_instance_id => $pi->id,
    });
#$ai->discard_changes;
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');

is($pi->activity_instances->count, 1, 'AI count matches');

my $ai_meta = $ai->meta;
ok($ai_meta->does_role('BPM::Engine::Store::ResultBase::ActivityInstance'), '... ActivityInstance->meta does_role Store::ResultBase::ActivityInstance');
ok(!$ai_meta->does_role('Class::Workflow::Instance'), '... ActivityInstance->meta does not do role Class::Workflow::Instance');

#-- activity_instance interface

is($ai->process_instance->id, $pi->id);
is($ai->activity->id, $activity->id);
ok(!$ai->tokenset);
ok(!$ai->transition);
ok(!$ai->prev);
ok(!$ai->next->count);
ok(!$ai->next_rs->count);
ok(!$ai->parent);

ok($ai->is_active);
ok(!$ai->completed);
ok(!$ai->is_deferred);

$ai->update({ deferred => DateTime->now }); #->discard_changes;
ok($ai->deferred);
ok($ai->is_deferred);
ok(!$ai->is_active);

$ai->update({ deferred => \'NULL' })->discard_changes;
#$ai->deferred(undef);
ok($ai->is_active);
ok(!$ai->deferred);
ok(!$ai->is_deferred);
ok(!$ai->is_completed);

$ai->update({ deferred => DateTime->now });
ok($ai->is_deferred);
ok(!$ai->is_completed);
ok(!$ai->is_active);

$ai->update({ deferred => \'NULL' })->discard_changes;
ok($ai->completed( DateTime->now() ));
ok($ai->completed);
ok($ai->is_completed);
ok(!$ai->is_active);
ok(!$ai->is_deferred);


isa_ok($ai->workflow_instance, 'BPM::Engine::Store::Result::ActivityInstanceState');
ok(!$ai->split);
isa_ok($ai->attributes, 'DBIx::Class::ResultSet');
#can_ok($ai, qw/join_should_fire/);

#-- workflow role

isa_ok($ai->workflow, 'Class::Workflow');
does_ok($ai->workflow_instance, 'Class::Workflow::Instance');
is($ai->workflow_instance->state->name, 'open.not_running.ready');
is($ai->state, 'open.not_running.ready');

done_testing();
