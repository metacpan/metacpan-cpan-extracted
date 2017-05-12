use strict;
use warnings;
use Test::More;
use DateTime;
use t::TestUtils;

my $schema = schema();
my $pack = $schema->resultset('Package')->create({});
my $proc = $pack->add_to_processes({});
my $act = $proc->add_to_activities({});
my $pi1 = $proc->new_instance();
my $pi2 = $proc->new_instance();

my $rs = $schema->resultset('ActivityInstance');
for(1..5) {
  my $params = {
    process_instance_id => $_ < 3 ? $pi1->id : $pi2->id,
    activity_id => $act->id,
    #transition_id => 1,
    #prev => 1,
    };
  $params->{deferred} = DateTime->now() if($_ < 3);
  if($_ == 5) {
    $params->{completed} = DateTime->now();
    }
  $rs->create($params);
  }

is($rs->count(), 5);
is($rs->active->count(), 2);
is($rs->active_or_deferred->count(), 4);
is($rs->active_or_completed->count(), 3);
is($rs->deferred->count(), 2);
is($rs->completed->count(), 1);

is($rs->completed->count({ process_instance_id => $pi1->id }), 0);
is($rs->completed({ process_instance_id => $pi1->id })->count, 0);

is($rs->completed->count({ process_instance_id => $pi2->id }), 1);
is($rs->completed({ process_instance_id => $pi2->id })->count, 1);

ok($rs->find(5)->is_completed);
ok($rs->find(3)->is_active);
ok($rs->find(1)->is_deferred);

$rs->find(1)->update({ deferred => \'NULL' });
$rs->find(2)->update({ deferred => undef });
is($rs->deferred->count(), 0);

done_testing;
