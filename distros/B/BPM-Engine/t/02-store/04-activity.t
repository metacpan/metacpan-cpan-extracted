use strict;
use warnings;
use Test::More;
use t::TestUtils;

my $schema   = schema();
my $package  = $schema->resultset('Package')->create({});
my $process  = $package->add_to_processes({});
my $activity = $process->add_to_activities({})->discard_changes;

my $act_meta = $activity->meta;
isa_ok($act_meta, 'Moose::Meta::Class');
ok($act_meta->does_role('BPM::Engine::Store::ResultBase::Activity'), '... Activity->meta does_role Store::ResultBase::Activity');
ok($act_meta->does_role('Class::Workflow::State'), '... Activity->meta does_role Class::Workflow::State');
ok($act_meta->does_role('Class::Workflow::State::TransitionHash'), '... Activity->meta does_role Class::Workflow::State::TransitionHash');
ok($act_meta->does_role('Class::Workflow::State::AcceptHooks'), '... Activity->meta does_role Class::Workflow::State::AcceptHooks');
ok($act_meta->does_role('Class::Workflow::State::AutoApply'), '... Activity->meta does_role Class::Workflow::State::AutoApply');

my %undefs = map { $_ => undef } qw/
    activity_uid activity_name
    documentation_url icon_url
    event_attr data_fields input_sets output_sets assignments extended_attr
    /;

my %defaults = (
    activity_type => 'Implementation',
    implementation_type => 'No',
    event_type => 'No',
    description => undef,
    start_mode => 'Automatic',
    finish_mode => 'Automatic',
    priority => 0,
    start_quantity => 1,
    completion_quantity => 1,
    join_type => 'NONE',
    join_type_exclusive => 'Data',
    split_type => 'NONE',
    split_type_exclusive => 'Data',
    %undefs,
    );

foreach my $col(keys %defaults) {
    is($activity->$col, $defaults{$col}, "default $col matches");
    }

can_ok($activity, qw/
    process transitions_in prev_activities transitions next_activities transition_refs
    deadlines performers participants tasks instances
    has_transition has_transitions transitions_in_by_ref transitions_by_ref
    /);

my %false = map { $_ => 0 } qw/
    route_type block_type event_type
    split or_split xor_split and_split complex_split
    join or_join xor_join and_join complex_join
    impl_task impl_subflow impl_reference
	/;

my %bools = (%false, map { $_ => 1 } qw/
	start_activity end_activity auto_start auto_finish
	implementation_type impl_no
	/);

foreach my $col(keys %bools) {
    my $meth = "is_$col";
    is($activity->$meth, $bools{$col}, "$meth returns $bools{$col}");
    }

my $task = $activity->add_to_tasks({
    task_uid    => 112,
    task_name   => 'user task',
    description => '',
    task_type   => 'User',
    #task_data   => '',
    });
isa_ok($task, 'BPM::Engine::Store::Result::ActivityTask');
is($task->id, $activity->tasks->first->id);

done_testing;
