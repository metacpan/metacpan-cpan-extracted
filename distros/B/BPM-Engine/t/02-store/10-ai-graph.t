use strict;
use warnings;
use Test::More;
use Test::Exception;

use t::TestUtils;

my ($engine, $process) = process_wrap();
my $pi = $engine->create_process_instance($process);
my $activity = $process->add_to_activities({
        activity_uid     => 1,
        activity_name    => 'work item1',
        activity_type    => 'Implementation',
        start_mode       => 'Manual',
        });
my $activity2 = $process->add_to_activities({
        activity_uid     => 2,
        activity_name    => 'work item2',
        activity_type    => 'Implementation',
        start_mode       => 'Manual',
        #join_type => 'OR'
        #split_type => 'NONE',
        });
my $t = $process->add_to_transitions({
        from_activity_id  => $activity->id,
        to_activity_id    => $activity2->id,
        });

# this is what $activity->new_instance does:
my $ai = $activity->add_to_instances({ process_instance_id => $pi->id });
$activity->split_type('OR');
$activity->update();
if($activity->split_type =~ /^(OR|Inclusive)$/ && !$ai->split) {
    $ai->create_related('split', { states => {} });
    }
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');

# fake taking the transition
my $split = $ai->split;
$split->set_transition($t->id, 'taken');
is($split->states->{$t->id}, 'taken', "Transition is 'taken'");

# new child (like after split)
$activity2->update({
    #split_type => 'NONE',
    join_type => 'OR'
    });
ok(!$activity2->split_type);

# get defaults from the db
$activity2->discard_changes;
is($activity2->split_type, 'NONE');

my $child = $activity2->new_instance({
    prev => $ai->id,
    process_instance_id => $pi->id,
    transition_id => $t->id,
    parent_token_id => $ai->id,
    });
$child->update();
isa_ok($child, 'BPM::Engine::Store::Result::ActivityInstance');

ok(!$ai->parent);
is($ai->children->first->id, $child->id);
is($child->parent->id, $ai->id);
is($child->prev->id, $ai->id);
is($ai->next->first->id, $child->id);

is($split->states->{$t->id}, 'taken', "Transition is 'taken'");
$split->should_fire($t);
is($split->states->{$t->id}, 'joined', "Transition is 'joined'");

# reset - this happens when you call $split->set_transition($t->id, 'taken');
my $states = $split->states;
$states->{ $t->id } = 'taken';
$split->states($states);
#$split->update->discard_changes();
is($split->states->{$t->id}, 'taken', "Transition is 'taken'");

ok($child->is_enabled);
$split->discard_changes;
is($split->states->{$t->id}, 'joined', "Transition is 'joined'");

done_testing();

