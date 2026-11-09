use strict;
use warnings;
use Test::More;

use Future;
use Future::IO;
use Scalar::Util 'refaddr';
use DBIO::SQLMaker;          # the mocks' sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;

# OFFLINE test for karr k33 (from dbio-postgresql k94, core k236): statements
# on one pinned connection are serialised.
#
# WHY IT MATTERS. A connection runs one statement at a time; the base's own
# cycle -- _submit_query leaves the statement on the connection,
# _collect_result($conn) reads "the" result -- has room for exactly one. Two
# statements issued on a transaction context without awaiting the first put the
# second on the wire while the first still runs: DBD::Pg clears the first's
# statement handle ("DBI st handle cleared whilst still active"), the first
# never resolves, and since core k236 COMMIT waits for it -- forever. The ev
# transport queues statements per connection; this transport now does too, in
# _query_async_pinned: the next statement is dispatched only once the one before
# it has settled.
#
# WHAT IS REAL. The whole transport -- _query_async_pinned and its queue,
# _await_query_result, _mark_dead_on_fail, the Future::IO watcher seam on a
# real pipe, the real DBIO::Async::Pool with core's release and retirement --
# and core's real txn_do_async with its k236 wait for every statement. Section
# 0 pins that the mocks own the DB-specific seams and nothing else.
#
# THE MOCK SERVER keeps ONE statement slot per connection, as a DBD does, and
# refuses a second statement while the slot is taken. That refusal is the
# loud stand-in for what DBD::Pg does quietly (clobber the first and hang): it
# turns the bug into a failure this test can see without hanging. A statement
# naming BAD fails with a statement error the session survives; one naming
# KILL kills the session (socket -1, as libpq gives it up). The connection's
# socket number going negative is what the classifier (Classify24) reads.

# --- RecPool24: the real pool, with every release recorded ------------------

{
  package RecPool24;
  use base 'DBIO::Async::Pool';

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

# --- Queue24: the DB-specific seams over a pipe ------------------------------

{
  package Queue24;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;
  use Scalar::Util ();

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1]{r} }

  # What a transaction context's CRUD needs from its owning storage (as in
  # t/14, t/22): this mock is its own owner, and proves ownership as core does.
  sub _owner_storage { $_[0] }
  sub _assert_async_context_owner {
    my ($self, $ctx) = @_;
    die "async context does not belong to this storage generation\n"
      unless Scalar::Util::refaddr($self->_context_owner_token)
          == Scalar::Util::refaddr($ctx->_context_owner_token);
    return $ctx;
  }
  sub _select_args { my ($self, @args) = @_; return ('select', @args) }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return { id => ++$self->{_next_id}, r => $r, w => $w, socket => 7 };
  }

  sub _shutdown_pool_connection {
    my ($self, $conn) = @_;
    push @{ $self->{shutdown} }, $conn->{id};
    close $conn->{r};
    close $conn->{w};
  }

  sub pool {
    my $self = shift;
    return $self->{pool} ||= RecPool24->new(
      storage  => $self,
      conninfo => $self->{_conninfo},
      size     => $self->{_pool_size},
      on_error => sub { push @{ $self->{pool_errors} }, $_[0] },
    );
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    my $label = main::label($sql);
    push @{ $self->{wire} }, $label;
    push @{ $self->{log} }, "submit:$label";
    die "no connection to the server\n" if $conn->{socket} < 0;
    die "another statement is still in flight on this connection "
      . "($conn->{in_flight})\n"
      if defined $conn->{in_flight};
    $conn->{in_flight} = $label;
    syswrite $conn->{w}, 'R' unless $label eq 'hold';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    my $label = delete $conn->{in_flight};
    if ($label =~ /KILL/) {
      $conn->{socket} = -1;
      return Future->fail("server closed the connection unexpectedly\n");
    }
    return Future->fail("syntax error at or near BAD\n") if $label =~ /BAD/;
    return Future->done([ 'row-for', $label ]);
  }
}

# --- Classify24: the same driver, answering _conn_error_is_fatal -------------

{
  package Classify24;
  our @ISA = ('Queue24');

  sub _conn_error_is_fatal { $_[1]{socket} < 0 }
}

sub new_storage {
  my ($class) = @_;
  my $storage = ($class // 'Queue24')->new(undef);
  $storage->{_next_id} = 0;
  $storage->{$_} = [] for qw(wire log shutdown pool_errors);
  # pool_size 1: what the next acquire gets tells a retired connection from
  # one put back.
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  return $storage;
}

# The table a statement names, or the statement itself (BEGIN, COMMIT, ...):
# what the log records.
sub label { my ($sql) = @_; return $sql =~ /\bFROM (\w+)/ ? $1 : $sql }

# Drive the loop until the Future settles, without dying on a failure.
sub settle { my $f = shift; eval { $f->get }; return $f }

# A statement on the context, with its settling logged -- from a callback on
# the caller's own Future, so the log shows when the CALLER saw the result
# relative to the next dispatch.
sub stmt {
  my ($storage, $ctx, $table) = @_;
  my $f = $ctx->select_async($table, ['*'], {});
  $f->on_ready(sub { push @{ $storage->{log} }, "settled:$table" });
  return $f;
}

# The same on a bare pinned connection.
sub pinned {
  my ($storage, $conn, $table) = @_;
  my $f = $storage->_query_async_pinned($conn, "SELECT * FROM $table", []);
  $f->on_ready(sub { push @{ $storage->{log} }, "settled:$table" });
  return $f;
}

sub rows_of { my $f = shift; return "never issued" unless $f; return $f->is_done ? [ $f->get ] : $f->failure }

# ---------------------------------------------------------------------------
# 0. The guard that gives every other assertion its meaning: the mock
#    overrides none of the transport's query path, and the pool nothing but
#    the recording release.
# ---------------------------------------------------------------------------

for my $method (qw(_query_async _query_async_pinned _await_query_result
                   _await_readable _mark_dead_on_fail _mark_if_fatal)) {
  is refaddr(Classify24->can($method)), refaddr(DBIO::Async::Storage->can($method)),
    "the mock does NOT override $method -- the transport itself runs";
}
for my $method (qw(_mark_connection_dead _retire_in_use_connection acquire)) {
  is refaddr(RecPool24->can($method)), refaddr(DBIO::Storage::PoolBase->can($method)),
    "RecPool24 does NOT override $method -- core's pool decides";
}

# ---------------------------------------------------------------------------
# 1. The k94 case: statements issued on a transaction context without awaiting
#    each other. Asserts that both resolve with their own rows, that the
#    second reaches the wire only after the first has settled (and after the
#    first's caller saw it), that a statement issued from the first's callback
#    goes behind the one already waiting -- issue order -- and that COMMIT goes
#    out after all of them and the transaction resolves. Without the queue the
#    second statement lands on the connection while the first still holds it.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();

  my ($ctx_conn, $first, $second, $third);
  my $f = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx_conn = $ctx->txn_conn;
    $first  = stmt($storage, $ctx, 'first');
    my $chained = $first->then(sub { $third = stmt($storage, $ctx, 'third') });
    $second = stmt($storage, $ctx, 'second');
    return Future->needs_all($chained, $second)->then(sub { Future->done('both') });
  });

  settle($f);
  ok $f->is_done, 'parallel: the transaction resolves -- it does not hang or fail';
  is $f->is_done ? scalar $f->get : scalar $f->failure, 'both',
    'parallel: ... with what the block resolved';

  is_deeply rows_of($first),  [ [ 'row-for', 'first' ] ],
    'parallel: the first statement resolves with its own rows';
  is_deeply rows_of($second), [ [ 'row-for', 'second' ] ],
    'parallel: the second, issued before the first settled, with its own';
  is_deeply rows_of($third),  [ [ 'row-for', 'third' ] ],
    'parallel: the third, issued from the first\'s callback, with its own';

  is_deeply $storage->{log}, [
    'submit:BEGIN',
    'submit:first',  'settled:first',
    'submit:second', 'settled:second',
    'submit:third',  'settled:third',
    'submit:COMMIT',
  ], 'parallel: one statement at a time, in issue order: each reaches the '
   . 'wire only after the one before it settled and its caller saw that, and '
   . 'COMMIT after all of them';

  is_deeply $storage->pool->{release_log}, [1],
    'parallel: the connection was handed back once';
  is_deeply $storage->{shutdown}, [], 'parallel: ... and not retired';
  ok !exists $ctx_conn->{_dbio_async_queue},
    'parallel: the idle connection carries no queue state back to the pool';
}

# ---------------------------------------------------------------------------
# 2. The first of two statements fails with a statement error the session
#    survives. Decided semantics: a failure does not stop the queue -- the
#    second is still dispatched, once the first settled, as it would be had
#    the caller chained it -- and the transaction rolls back with the first's
#    error (core k236). wait_all, so nothing cancels the second.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Classify24');

  my ($first, $second);
  my $f = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $first  = stmt($storage, $ctx, 'BAD');
    $second = stmt($storage, $ctx, 'second');
    return Future->wait_all($first, $second);
  });

  settle($f);
  ok $f->is_failed, 'failure in the middle: the transaction fails';
  like scalar $f->failure, qr/^syntax error at or near BAD/,
    'failure in the middle: ... with the first statement\'s own error';
  is scalar $first->failure, "syntax error at or near BAD\n",
    'failure in the middle: the first statement fails';
  is_deeply rows_of($second), [ [ 'row-for', 'second' ] ],
    'failure in the middle: the second still runs and resolves -- a failed '
    . 'statement does not stop the queue';
  is_deeply $storage->{log}, [
    'submit:BEGIN',
    'submit:BAD',    'settled:BAD',
    'submit:second', 'settled:second',
    'submit:ROLLBACK',
  ], 'failure in the middle: the second was dispatched after the first '
   . 'settled, and ROLLBACK after both';
  is_deeply $storage->{shutdown}, [],
    'failure in the middle: the connection survived and is not retired';
}

# ---------------------------------------------------------------------------
# 2b. The same with needs_all, the common idiom: it cancels the second the
#     moment the first fails. A statement cancelled while it waits for its
#     turn never reaches the wire.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Classify24');

  my ($first, $second);
  my $f = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $first  = stmt($storage, $ctx, 'BAD');
    $second = stmt($storage, $ctx, 'second');
    return Future->needs_all($first, $second);
  });

  settle($f);
  ok $f->is_failed, 'needs_all: the transaction fails';
  like scalar $f->failure, qr/^syntax error at or near BAD/,
    'needs_all: ... with the first statement\'s error, not the cancellation';
  ok $second->is_cancelled, 'needs_all: the second statement was cancelled';
  is_deeply $storage->{wire}, [ 'BEGIN', 'BAD', 'ROLLBACK' ],
    'needs_all: ... and never sent: BEGIN, the failed statement, ROLLBACK';
}

# ---------------------------------------------------------------------------
# 3. The first statement kills the connection, and the driver says so
#    (_conn_error_is_fatal, karr k26). Decided semantics (karr k47, reversing
#    k26's): nothing more is sent on a connection reported dead -- one rule in
#    the queue, as after a cancel in flight. The statements that were waiting
#    behind it are failed without being sent; so is what is issued once the
#    failure is known, from its callbacks, is refused "not sent ... reported
#    dead" and never reaches the seam, so the dead handle is not asked, nor is
#    _conn_error_is_fatal a second time. Core issues no ROLLBACK on such a
#    connection any more (core k274): the transaction fails with the error
#    that killed it. The connection is retired.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Classify24');

  my ($first, $second, $after);
  my $f = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $first  = stmt($storage, $ctx, 'KILL');
    $first->on_fail(sub { $after = stmt($storage, $ctx, 'after') });
    $second = stmt($storage, $ctx, 'second');
    return Future->wait_all($first, $second);
  });

  settle($f);
  ok $f->is_failed, 'dead connection: the transaction fails';
  like scalar $f->failure, qr/server closed the connection unexpectedly/,
    'dead connection: ... with the error that killed the connection';
  ok $second->is_failed, 'dead connection: the waiting statement fails';
  like scalar $second->failure,
    qr/not sent: .*reported dead.*_conn_error_is_fatal/s,
    'dead connection: ... saying it was not sent onto the dead connection';
  like scalar $after->failure, qr/^not sent: .*reported dead/s,
    'dead connection: the statement issued from the failure\'s callback is '
    . 'refused by the queue, not by the dead handle';
  is_deeply $storage->{wire}, [ 'BEGIN', 'KILL' ],
    'dead connection: nothing after the kill reached the wire -- not the '
    . 'waiting statement, not the one issued on the failure, and no ROLLBACK '
    . '(k47, core k274)';
  unlike scalar $f->failure, qr/Rollback failed/,
    'dead connection: ... no ROLLBACK was issued on it, so the transaction '
    . 'fails with the original error and names no rollback';
  is_deeply $storage->{shutdown}, [1],
    'dead connection: the connection was retired';
}

# ---------------------------------------------------------------------------
# 4. A statement cancelled while it waits for its turn is skipped; the ones
#    around it run in order.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $conn = $storage->pool->acquire->get;

  my $fa = pinned($storage, $conn, 'a');
  my $fb = pinned($storage, $conn, 'b');
  my $fc = pinned($storage, $conn, 'c');
  $fb->cancel;
  settle($fc);

  is_deeply rows_of($fa), [ [ 'row-for', 'a' ] ], 'queued cancel: a resolves';
  ok $fb->is_cancelled, 'queued cancel: b stays cancelled';
  is_deeply rows_of($fc), [ [ 'row-for', 'c' ] ], 'queued cancel: c resolves';
  is_deeply $storage->{wire}, [ 'a', 'c' ],
    'queued cancel: b never reached the wire; a and c ran, in order';
  ok !exists $conn->{_dbio_async_queue},
    'queued cancel: the queue state is gone once the connection is idle';
  $storage->pool->release($conn);
  is_deeply $storage->{shutdown}, [], 'queued cancel: nothing is retired';
}

# ---------------------------------------------------------------------------
# 5. The statement IN FLIGHT is cancelled. Its result is still on its way,
#    and the base can neither read it nor cancel it on the server. Decided
#    semantics: nothing more is sent on that connection -- the statements
#    waiting behind it and every later one fail without being sent -- and the
#    connection is reported dead to the pool, so its hand-back retires it
#    instead of passing the unread result to the next borrower.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $conn = $storage->pool->acquire->get;

  my $fa = pinned($storage, $conn, 'a');
  my $fb = pinned($storage, $conn, 'b');
  $fa->cancel;

  ok $fb->is_failed, 'in-flight cancel: the statement waiting behind it fails';
  like scalar $fb->failure, qr/not sent: .*cancelled while in flight/s,
    'in-flight cancel: ... saying why it was not sent';
  my $later = settle(pinned($storage, $conn, 'later'));
  like scalar $later->failure, qr/not sent: .*cancelled while in flight/s,
    'in-flight cancel: a statement issued afterwards is refused as well';
  is_deeply $storage->{wire}, [ 'a' ],
    'in-flight cancel: nothing after the cancelled statement reached the wire';

  $storage->pool->release($conn);
  is_deeply $storage->{shutdown}, [1],
    'in-flight cancel: the hand-back retired the connection';
}

# ---------------------------------------------------------------------------
# 6. The Future of txn_do_async is cancelled while a statement of the block is
#    in flight (karr k45, core k274). Future.pm runs none of the ->then
#    callbacks that end the transaction, so core answers the cancel itself:
#    the connection is retired -- closed once, never put back idle -- and NO
#    ROLLBACK goes out on it, because what is in flight cannot be vouched for.
#    The pool slot is free: the next query runs on a fresh connection.
#
#    Two ways in, measured against core's txn_do_async: the caller cancels the
#    transaction's own Future (it ends cancelled), or cancels the Future the
#    block's coderef returned (the transaction does not stay pending: it FAILS
#    "Transaction cancelled", the original error of the cancel).
# ---------------------------------------------------------------------------

for my $case (
  [ 'outer'   => sub { $_[0]->cancel } ],
  [ 'coderef' => sub { $_[2]->cancel } ],
) {
  my ($name, $cancel) = @$case;
  my $t = "txn cancel ($name)";

  my $storage = new_storage();
  my $pool    = $storage->pool;

  my ($stmt, $own, $f);
  $f = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt = stmt($storage, $ctx, 'hold');
    $own  = Future->new;
    # the statement stays on the wire (the mock answers 'hold' never); the
    # caller gives up a moment later, from the loop
    Future::IO->sleep(0.01)->on_done(sub { $cancel->($f, $stmt, $own) });
    return $own;
  });

  # bounded: a transaction left pending by the cancel fails this test instead
  # of hanging it
  eval {
    Future->wait_any($f, Future::IO->sleep(2)->then(sub { Future->done }))->get;
  };
  ok $f->is_ready, "$t: the transaction Future is settled";
  if ($name eq 'outer') {
    ok $f->is_cancelled, "$t: ... cancelled, as the caller asked";
  }
  else {
    ok $f->is_failed, "$t: ... failed, not left pending nor cancelled";
    like scalar $f->failure, qr/Transaction cancelled/,
      "$t: ... saying the transaction was cancelled";
  }
  is_deeply $storage->{wire}, [ 'BEGIN', 'hold' ],
    "$t: only BEGIN and the statement reached the wire -- no ROLLBACK "
    . 'on the connection that cannot be vouched for';
  is_deeply $storage->{shutdown}, [1],
    "$t: the connection was retired, exactly once";
  is $pool->available, 0,
    "$t: ... and it is not idle in the pool";

  my $g = settle($storage->_query_async('SELECT * FROM next', []));
  is $g->is_done ? $g->get->[1] : undef, 'next',
    "$t: the next query runs -- the pool slot is free";
  is $storage->{wire}[-1], 'next', "$t: ... and reached the wire";
  is_deeply $storage->{shutdown}, [1],
    "$t: ... on a fresh connection, the retired one is not reused";
}

done_testing;
