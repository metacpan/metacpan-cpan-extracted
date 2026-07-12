use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Future;
use DBIO::Future::Immediate;

# --- DBIO::Future::Immediate basic API ---

{
  my $f = DBIO::Future::Immediate->done('hello', 'world');
  ok $f->is_ready, 'done future is ready';
  ok !$f->is_failed, 'done future is not failed';
  is_deeply [$f->get], ['hello', 'world'], 'get returns resolved values';
}

{
  my $f = DBIO::Future::Immediate->fail('something broke');
  ok $f->is_ready, 'failed future is ready';
  ok $f->is_failed, 'failed future is_failed';
  throws_ok { $f->get } qr/something broke/, 'get on failed future dies';
}

# --- then chaining ---

{
  my $f = DBIO::Future::Immediate->done(2, 3);
  my $f2 = $f->then(sub { return $_[0] * $_[1] });
  ok $f2->is_ready, 'then result is ready';
  is scalar $f2->get, 6, 'then transforms values';
}

{
  my $f = DBIO::Future::Immediate->done(1);
  my $f2 = $f->then(sub { die "oops" });
  ok $f2->is_failed, 'then that dies produces failed future';
}

{
  my $f = DBIO::Future::Immediate->fail('err');
  my $called = 0;
  my $f2 = $f->then(sub { $called++; return 'nope' });
  ok $f2->is_failed, 'then on failed future stays failed';
  is $called, 0, 'then callback not called on failed future';
}

# --- catch ---

{
  my $f = DBIO::Future::Immediate->fail('db error');
  my $f2 = $f->catch(sub { return "recovered: $_[0]" });
  ok !$f2->is_failed, 'catch recovers from failure';
  is scalar $f2->get, 'recovered: db error', 'catch callback gets error';
}

{
  my $f = DBIO::Future::Immediate->done('ok');
  my $called = 0;
  my $f2 = $f->catch(sub { $called++; return 'nope' });
  ok !$f2->is_failed, 'catch on success stays success';
  is $called, 0, 'catch callback not called on success';
  is scalar $f2->get, 'ok', 'catch passes through success value';
}

# --- needs_all ---

{
  my @futures = map { DBIO::Future::Immediate->done($_) } (1, 2, 3);
  my $all = DBIO::Future::Immediate->needs_all(@futures);
  ok $all->is_ready, 'needs_all is ready';
  is_deeply [$all->get], [1, 2, 3], 'needs_all collects results';
}

{
  my @futures = (
    DBIO::Future::Immediate->done(1),
    DBIO::Future::Immediate->fail('boom'),
    DBIO::Future::Immediate->done(3),
  );
  my $all = DBIO::Future::Immediate->needs_all(@futures);
  ok $all->is_failed, 'needs_all fails if any future fails';
}

# --- and_then (flat map) ---

{
  my $f = DBIO::Future::Immediate->done(5);
  my $f2 = $f->and_then(sub { DBIO::Future::Immediate->done($_[0] * 2) });
  is scalar $f2->get, 10, 'and_then flattens inner future';
}

# --- DBIO::Future validates interface ---

{
  lives_ok { DBIO::Future->validate(DBIO::Future::Immediate->done(1)) }
    'Future::Immediate passes validation';

  my $fake = bless {}, 'Not::A::Future';
  throws_ok { DBIO::Future->validate($fake) }
    qr/does not implement/,
    'validation rejects non-Future objects';
}

# --- Storage future_class ---

{
  my $schema = DBIO::Test->init_schema;
  # mock storage defaults to the 'immediate' async mode (ADR 0030)
  is $schema->storage->future_class, 'DBIO::Future::Immediate',
    'default future_class is DBIO::Future::Immediate';
}

# --- ResultSet async methods ---

{
  my $schema = DBIO::Test->init_schema;
  # mock storage defaults to the 'immediate' async mode (ADR 0030)
  $schema->storage->mock(qr/SELECT.*artist/i => [
    [qw/artistid name/],
    [1, 'Miles Davis'],
    [2, 'John Coltrane'],
  ]);

  my $rs = $schema->resultset('Artist');

  # all_async
  my $f = $rs->all_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'all_async returns Future';
  ok $f->is_ready, 'all_async resolves immediately with test storage';

  # count_async - fake storage returns undef for count, that's fine
  my $cf;
  { local $SIG{__WARN__} = sub {};  # suppress undef warning from fake storage
    $cf = $rs->count_async;
  }
  isa_ok $cf, 'DBIO::Future::Immediate', 'count_async returns Future';
  ok $cf->is_ready, 'count_async resolves immediately';

  # first_async
  $schema->storage->mock(qr/SELECT.*artist/i => [
    [qw/artistid name/],
    [1, 'Miles Davis'],
  ]);
  my $ff = $rs->first_async;
  isa_ok $ff, 'DBIO::Future::Immediate', 'first_async returns Future';
  ok $ff->is_ready, 'first_async resolves immediately';
}

# --- Storage async methods ---

{
  my $schema = DBIO::Test->init_schema;
  # mock storage defaults to the 'immediate' async mode (ADR 0030)

  # txn_do_async
  my $f = $schema->storage->txn_do_async(sub { return 'committed' });
  isa_ok $f, 'DBIO::Future::Immediate', 'txn_do_async returns Future';
  ok $f->is_ready, 'txn_do_async resolves immediately';
  is scalar $f->get, 'committed', 'txn_do_async returns sub result';

  # txn_do_async with failure
  my $ff = $schema->storage->txn_do_async(sub { die "rollback!" });
  ok $ff->is_failed, 'txn_do_async fails on exception';
}

# --- Async base class ---

{
  require DBIO::Storage::Async;
  throws_ok { DBIO::Storage::Async->future_class }
    qr/Subclass must override/,
    'Storage::Async requires future_class override';

  # ADR 0030 §4: pipeline is now a concrete scaffold (lifted into core), not a
  # blanket "not supported" stub. On the bare base it croaks on the first
  # transport seam it touches (future_class / pool) -- there is no transport.
  throws_ok { DBIO::Storage::Async->pipeline(sub {}) }
    qr/Subclass must override/,
    'pipeline scaffold croaks on a transport seam without a backend';

  throws_ok { DBIO::Storage::Async->listen('foo', sub {}) }
    qr/not supported/,
    'listen not supported by default';
}

# --- Pool interface ---

{
  require DBIO::Storage::Pool;
  throws_ok { DBIO::Storage::Pool->acquire }
    qr/Subclass must override/,
    'Pool requires acquire override';
}

done_testing;
