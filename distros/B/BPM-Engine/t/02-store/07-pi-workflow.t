use strict;
use warnings;
use Test::More;

use t::TestUtils;

my $schema = schema();
my $package = $schema->resultset('Package')->create({});
my $process = $package->add_to_processes({});
my $rs_state = $schema->resultset('ProcessInstanceState');

is($rs_state->count, 0);

my $pi = $process->new_instance();

isa_ok($pi->workflow_instance, 'BPM::Engine::Store::Result::ProcessInstanceState');
is($pi->workflow_instance->state->name, 'open.not_running.ready');
is($pi->state, 'open.not_running.ready');
is($rs_state->count, 1);
#is($schema->resultset('ProcessInstanceState')->search_rs->count, 1);

ok($pi->apply_transition('start'));
is($pi->workflow_instance->state->name, 'open.running');
is($pi->state, 'open.running');
#is($schema->resultset('ProcessInstanceState')->search_rs->count, 2);
is($rs_state->count, 2);

$pi->apply_transition('suspend');
is($pi->workflow_instance->state->name, 'open.not_running.suspended');
#is($schema->resultset('ProcessInstanceState')->search_rs->count, 3);
is($rs_state->count, 3);

$pi->apply_transition('resume');
is($pi->workflow_instance->state->name, 'open.running');

$pi->apply_transition('finish');
is($pi->workflow_instance->state->name, 'closed.completed');
is($rs_state->count, 5);

ok(my $wi = $pi->workflow_instance);
ok($wi = $wi->prev);
is($wi->state->name, 'open.running');
$wi = $wi->next;
is($wi->state->name, 'closed.completed');
$wi->delete;
ok(!$pi->workflow_instance);

$pi->delete;
is($rs_state->count, 0);

$pi = $process->new_instance;
$pi->apply_transition('terminate');
is($pi->workflow_instance->state->name, 'closed.cancelled.terminated');

$pi = $process->new_instance;
$pi->apply_transition('abort');
is($pi->workflow_instance->state->name, 'closed.cancelled.aborted');

done_testing();
