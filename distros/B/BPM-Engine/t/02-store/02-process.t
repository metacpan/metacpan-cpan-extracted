use strict;
use warnings;
use Test::More;
use t::TestUtils;

my $schema = schema();
my ($package, $process) = ();

is($schema->resultset('Process')->count, 0);
is($schema->resultset('Activity')->count, 0);
$package = $schema->resultset('Package')->create({ });
$process = $package->add_to_processes({});
$process->add_to_activities({});

is($schema->resultset('Process')->count, 1);
is($schema->resultset('Activity')->count, 1);
$package->delete;
is($schema->resultset('Process')->count, 0);
is($schema->resultset('Activity')->count, 0);

$package = $schema->resultset('Package')->create({ });
#ok(my $process = $schema->resultset('Process')->search->first);
ok($process = $schema->resultset('Process')->create({
    package_id    => $package->id,
    process_uid   => 'SomeProcess',
    }));

my $p_meta = $process->meta;
ok($p_meta->does_role('BPM::Engine::Store::ResultBase::Process'), '... Process->meta does_role Store::ResultBase::Process');
ok($p_meta->does_role('BPM::Engine::Store::ResultRole::WithAssignments'), '... Process->meta does_role Store::ResultRole::WithAssignments');
ok($p_meta->does_role('BPM::Engine::Store::ResultRole::WithGraph'), '... Process->meta does_role Store::ResultRole::WithGraph');

is($process->process_name('A Process'),'A Process');

my $activity = $process->add_to_activities({
    activity_uid     => 1,
    activity_name    => 'work item1',
    activity_type    => 'Implementation',
    start_mode       => 'Manual',
    });
my $activity2 = $process->add_to_activities({
    #activity_uid     => 2,
    #activity_name    => 'work item2'
    });
my $t = $process->add_to_transitions({
    from_activity_id  => $activity->id,
    to_activity_id    => $activity2->id,
    });
is($schema->resultset('Activity')->count, 2);
is($schema->resultset('Transition')->count, 1);
$process->delete;
is($schema->resultset('Activity')->count, 0);
is($schema->resultset('Transition')->count, 0);

done_testing;
