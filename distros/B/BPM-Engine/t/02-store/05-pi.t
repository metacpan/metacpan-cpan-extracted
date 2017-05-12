use strict;
use warnings;
use Test::More;
use t::TestUtils;

my $schema = schema();

$schema->resultset('Package')->create_from_xpdl('./t/var/02-branching.xpdl');

#-- get the first process definition
ok(my $process = $schema->resultset('Process')->search->first);

#- create a new process instance
my $pi = $process->new_instance();
isa_ok($pi, 'BPM::Engine::Store::Result::ProcessInstance');

my $pi_meta = $pi->meta;
ok($pi_meta->does_role('BPM::Engine::Store::ResultBase::ProcessInstance'), '... ProcessInstance->meta does_role Store::ResultBase::ProcessInstance');

ok($pi->instance_name);
ok($pi->workflow_instance->id);

ok($pi->delete);

done_testing();
