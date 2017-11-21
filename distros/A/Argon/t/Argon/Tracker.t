use Test2::Bundle::Extended;
use Argon::Constants qw(:priorities :commands);
use Argon::Message;
use Argon::Tracker;

sub msg { Argon::Message->new(cmd => $PING) }

ok my $t = Argon::Tracker->new(capacity => 0, length => 10), 'new';

subtest 'initial state' => sub {
  is $t->capacity, 0, 'capacity';
  is $t->available_capacity, 0, 'available_capacity';
  ok !$t->has_capacity, '!has_capacity';
  is $t->load, 0, 'load';
  ok dies { $t->start(msg) }, 'start dies w/o available_capacity';
  ok dies { $t->finish(msg) }, 'finish dies w/ untracked msg';
};

subtest 'adding capacity' => sub {
  is $t->add_capacity(2), 2, 'add_capacity';
  is $t->capacity, 2, 'capacity';
  is $t->available_capacity, 2, 'available_capacity';
  ok $t->has_capacity, 'has_capacity';

  is $t->add_capacity(2), 4, 'add_capacity';
  is $t->capacity, 4, 'capacity';
  is $t->available_capacity, 4, 'available_capacity';
  ok $t->has_capacity, 'has_capacity';
};

subtest 'removing capacity' => sub {
  is $t->remove_capacity(2), 2, 'remove_capacity';
  is $t->capacity, 2, 'capacity';
  is $t->available_capacity, 2, 'available_capacity';
  ok $t->has_capacity, 'has_capacity';
};

subtest 'tracking' => sub {
  my @msgs = map { msg() } (1..3);
  ok !$t->is_tracked($_), 'is_tracked'
    foreach @msgs;

  is $t->start($msgs[0]), 1, 'start';
  is $t->available_capacity, 1, 'available_capacity';
  ok $t->has_capacity, 'has_capacity';
  ok $t->is_tracked($msgs[0]->id), 'is_tracked';

  is $t->start($msgs[1]), 2, 'start';
  is $t->available_capacity, 0, 'available_capacity';
  ok !$t->has_capacity, '!has_capacity';
  ok $t->is_tracked($msgs[1]->id), 'is_tracked';

  ok dies { $t->start($msgs[2]) }, 'start dies w/o available_capacity';

  ok $t->finish($msgs[0]), 'finish';
  is $t->available_capacity, 1, 'available_capacity';
  ok $t->has_capacity, 'has_capacity';
  ok $t->avg_time > 0, 'avg_time';
  is $t->load, $t->avg_time * 2, 'load';
  ok !$t->is_tracked($msgs[0]->id), '!is_tracked';

  ok $t->finish($msgs[1]), 'finish';
  is $t->available_capacity, 2, 'available_capacity';
  ok $t->has_capacity, 'has_capacity';
  is $t->load, $t->avg_time, 'load';
  ok !$t->is_tracked($msgs[1]->id), '!is_tracked';

  for (1 .. 11) {
    my $msg = msg;
    $t->start($msg);
    $t->finish($msg);
    ok scalar(@{$t->{history}}) <= 10, "history length is maintained ($_)";
  }
};

done_testing;
