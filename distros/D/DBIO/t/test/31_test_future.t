use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Future ();
use DBIO::Test::Future ();

subtest 'new is pending and get never blocks' => sub {
  my $future = DBIO::Test::Future->new;

  ok !$future->is_ready,  'new Future is pending';
  ok !$future->is_failed, 'pending Future is not failed';
  lives_ok { DBIO::Future->validate($future) }
    'pending test Future satisfies the public minimal validator';
  throws_ok { $future->get } qr/pending/i,
    'get on pending Future refuses instead of polling';
};

# Claim (karr k222): new called on an instance makes a fresh pending Future of
# the instance's class -- the Future.pm idiom core's listen machinery uses to
# hand out Futures of the transport's own kind. A subclass must survive it.
subtest 'new on an instance makes a pending Future of the same class' => sub {
  my $settled = DBIO::Test::Future->done('old');
  my $fresh   = $settled->new;
  isa_ok $fresh, 'DBIO::Test::Future', 'instance new';
  ok !$fresh->is_ready, 'it is pending, whatever state its prototype is in';
  isnt $fresh, $settled, 'and a new object';

  @K222::SubFuture::ISA = ('DBIO::Test::Future');
  is ref(K222::SubFuture->new->new), 'K222::SubFuture',
    'a subclass instance makes a Future of that subclass';
};

subtest 'class and object done/fail forms' => sub {
  my $ready = DBIO::Test::Future->done(qw/one two/);
  is_deeply [ $ready->get ], [qw/one two/],
    'class done preserves all values';

  my $pending = DBIO::Test::Future->new;
  is $pending->done('value'), $pending,
    'object done returns the settled object';
  is $pending->get, 'value', 'object done stores the value';

  my $failed = DBIO::Test::Future->fail('class failure');
  ok $failed->is_ready && $failed->is_failed,
    'class fail creates a ready failed Future';
  throws_ok { $failed->get } qr/class failure/,
    'failed get propagates the class-form error';

  my $object_failed = DBIO::Test::Future->new;
  is $object_failed->fail('object failure'), $object_failed,
    'object fail returns the settled object';
  throws_ok { $object_failed->get } qr/object failure/,
    'failed get propagates the object-form error';
};

subtest 'double settlement is rejected' => sub {
  for my $first (qw/done fail/) {
    for my $second (qw/done fail/) {
      my $future = DBIO::Test::Future->new;
      $future->$first("first $first");
      throws_ok { $future->$second("second $second") } qr/already|settled/i,
        "$first followed by $second is rejected";
    }
  }
};

subtest 'pending continuations run FIFO exactly once' => sub {
  my $source = DBIO::Test::Future->new;
  my @seen;
  my $first  = $source->then(sub { push @seen, 'first';  'A' });
  my $second = $source->then(sub { push @seen, 'second'; 'B' });

  ok !$first->is_ready && !$second->is_ready,
    'derived Futures remain pending with their source';
  $source->done('source');
  is_deeply \@seen, [qw/first second/], 'callbacks run FIFO once';
  is $first->get,  'A', 'first result is preserved';
  is $second->get, 'B', 'second result is preserved';
};

subtest 'then uses scalar callback context and flattens pending futures' => sub {
  my $callback_context;
  my $scalar = DBIO::Test::Future->done->then(sub {
    $callback_context = wantarray;
    return (10, 20);
  });
  ok defined($callback_context) && !$callback_context,
    'success callback runs in scalar context';
  is $scalar->get, 20, 'scalar callback result is used';

  my $inner = DBIO::Test::Future->new;
  my $derived = DBIO::Test::Future->done->then(sub { $inner });
  ok !$derived->is_ready, 'returned pending Future keeps chain pending';
  $inner->done('later');
  is $derived->get, 'later', 'pending Future result is flattened';
};

subtest 'then routes parent failure through only the failure callback' => sub {
  my @called;
  my $recovered = DBIO::Test::Future->fail('parent')->then(
    sub { push @called, 'success'; 'wrong' },
    sub { push @called, "failure:$_[0]"; 'recovered' },
  );
  is $recovered->get, 'recovered', 'failure callback may recover';
  is_deeply \@called, ['failure:parent'], 'success callback was skipped';

  my $propagated = DBIO::Test::Future->fail('unchanged')->then(sub { 'wrong' });
  throws_ok { $propagated->get } qr/unchanged/,
    'missing failure callback propagates the parent error';

  my $paired_failure_called = 0;
  my $success_throw = DBIO::Test::Future->done->then(
    sub { die "success callback exploded\n" },
    sub { $paired_failure_called++; 'wrong recovery' },
  );
  throws_ok { $success_throw->get } qr/success callback exploded/,
    'success callback exception fails the derived Future';
  is $paired_failure_called, 0,
    'paired failure callback does not catch success callback exceptions';

  my $failure_throw = DBIO::Test::Future->fail('source')->then(
    sub { 'wrong' },
    sub { die "failure callback exploded\n" },
  );
  throws_ok { $failure_throw->get } qr/failure callback exploded/,
    'failure callback exception fails the derived Future';
};

subtest 'catch preserves success and recovers failure' => sub {
  my $success = DBIO::Test::Future->done(qw/a b/)->catch(sub { 'wrong' });
  is_deeply [ $success->get ], [qw/a b/],
    'catch preserves successful values';

  my $pending = DBIO::Test::Future->new;
  my $caught = $pending->catch(sub { "caught $_[0]" });
  ok !$caught->is_ready, 'catch follows pending source';
  $pending->fail('late');
  is $caught->get, 'caught late', 'catch receives and recovers the error';
};

subtest 'needs_all waits preserves input order and fails' => sub {
  my $left  = DBIO::Test::Future->new;
  my $right = DBIO::Test::Future->new;
  my $all   = DBIO::Test::Future->needs_all($left, $right);

  $right->done('right');
  ok !$all->is_ready, 'aggregate still waits for left input';
  $left->done(qw/left one/);
  is_deeply [ $all->get ], [qw/left one right/],
    'aggregate concatenates values in input order';

  my $failed = DBIO::Test::Future->needs_all(
    DBIO::Test::Future->done('ok'),
    DBIO::Test::Future->fail('aggregate failure'),
  );
  throws_ok { $failed->get } qr/aggregate failure/,
    'aggregate preserves input failure';
  is_deeply [ DBIO::Test::Future->needs_all->get ], [],
    'zero-input aggregate is immediately successful';
};

subtest 'unsupported CPAN-only surface stays absent' => sub {
  my $future = DBIO::Test::Future->new;
  ok !$future->can($_), "$_ is intentionally absent"
    for qw/on_ready on_fail failure is_done await cancel retain/;
  ok !DBIO::Test::Future->isa('DBIO::Future::Immediate'),
    'test Future is independent from Immediate';
};

done_testing;
