use Test2::Bundle::Extended;
use Argon::Queue;
use Argon::Message;
use Argon::Constants qw(:priorities :commands);
use Data::Dumper;

sub msg { Argon::Message->new(cmd => $ACK, pri => $_[0]) };
my $msg1 = Argon::Message->new(cmd => $ACK, pri => $NORMAL);
my $msg2 = Argon::Message->new(cmd => $ACK, pri => $HIGH);
my $msg3 = Argon::Message->new(cmd => $ACK, pri => $LOW);
my $msg4 = Argon::Message->new(cmd => $ACK, pri => $NORMAL);

subtest 'basics' => sub {
  ok my $q = Argon::Queue->new(max => 4), 'new';
  $q->{balanced} = time + 100; # force to future value prevent rebalancing during testing

  is $q->count, 0, 'count';
  ok $q->is_empty, 'is_empty';
  ok !$q->is_full, '!is_full';

  is $q->put($msg1), 1, 'put';
  is $q->put($msg2), 2, 'put';
  is $q->put($msg3), 3, 'put';
  is $q->put($msg4), 4, 'put';
  is $q->count, 4, 'count';
  ok !$q->is_empty, '!is_empty';
  ok $q->is_full, 'is_full';
  ok dies { $q->put(msg($NORMAL)) }, 'put dies when is_full';
  ok dies { $q->put('foo') }, 'put dies on invalid parameter';

  is $q->get, $msg2, 'get';
  is $q->count, 3, 'count';
  is $q->get, $msg1, 'get';
  is $q->count, 2, 'count';
  is $q->get, $msg4, 'get';
  is $q->count, 1, 'count';
  is $q->get, $msg3, 'get';
  is $q->count, 0, 'count';
  is $q->get, U(), 'get returns undef when is_empty';
  is $q->count, 0, 'count';
  ok $q->is_empty, 'is_empty';
  ok !$q->is_full, '!is_full';
};

subtest 'promotion' => sub {
  my $q = Argon::Queue->new(max => 4);
  is $q->promote, 0, 'promote: no messages';

  $q->put($msg3);
  is scalar(@{$q->{msgs}[$LOW]}),    1, 'correct count in $LOW';
  is scalar(@{$q->{msgs}[$NORMAL]}), 0, 'correct count in $NORMAL';

  $q->{tracker}{avg_time} = 10;
  $q->{tracker}{started}{$msg3->id} = time - 15;
  $q->{balanced} = time - 15;

  is $q->promote, 1, 'promote: success';
  is scalar(@{$q->{msgs}[$LOW]}),    0, 'correct count in $LOW';
  is scalar(@{$q->{msgs}[$NORMAL]}), 1, 'correct count in $NORMAL';

  is $q->promote, 0, 'promote: too recent';
};

done_testing;
