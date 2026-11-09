use strict;
use warnings;
use Test::More;

use Future;
use Scalar::Util ();
use DBIO::Exception::Server ();
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;

# OFFLINE end-to-end test for txn_do_async at THIS dist's layer (karr k15
# point 4). The pipeline counterpart, t/09, has existed since ADR 0003; the
# transaction one did not, even though transactions are the older contract
# (ADR 0002) and the one every driver uses.
#
# WHAT IS REAL. Everything below the coderef: the real DBIO::Async::Storage
# with no transport seam substituted, the real DBIO::Async::Pool with its
# genuine idle list and capacity rules, the real Future::IO watcher seam (each
# statement is dispatched on a pipe and awaited through Future::IO->poll, as in
# t/12), and core's real txn_do_async orchestration. The mock supplies only the
# DB-specific seams -- what "send this to the wire" and "read the answer" mean.
# Core's own t/test/15_async_orchestration.t drives the same scaffold against a
# fake pool; what only this layer can show is the interleaving of a real pool
# checkout with the BEGIN/COMMIT bracket, which is where the release rule lives.
#
# WHAT IT PROVES, and why each half matters:
#
#  * BEGIN, the block's statements and COMMIT/ROLLBACK all run through
#    _query_async_pinned on the ONE connection acquire_txn handed out. A
#    statement that slipped onto a pooled connection instead would run outside
#    the transaction it believes it is in -- committed independently, invisible
#    to the ROLLBACK. The mock therefore records the connection per statement
#    and every scenario asserts they are the same one.
#
#  * The connection goes back to the pool EXACTLY ONCE, on every exit path.
#    Not "at least once": releasing twice pushes the same connection onto the
#    idle list twice, after which the pool hands one physical connection to two
#    concurrent callers and their statements interleave. Not "at most once":
#    a path that forgets to release leaks a connection out of a fixed-size pool
#    until it deadlocks. Both are silent, so both are asserted directly --
#    ->available is the observable that tells them apart, and the pool here is
#    size 1 so the next acquire can only be that same connection.
#
#  * And it is released only AFTER the transaction closed, never mid-bracket.

# --- TxnConn14: connection with a real pipe as its wire --------------------
#
# The transaction state is kept ON the connection, exactly as pipeline mode is
# in t/09 and for the same reason: "handed to the next user still inside a
# transaction" is only observable if the state belongs to the connection.

{
  package TxnConn14;
  sub new {
    my ($class, $id) = @_;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return bless { id => $id, r => $r, w => $w, in_txn => 0 }, $class;
  }
  sub id     { $_[0]->{id} }
  sub in_txn { $_[0]->{in_txn} }
}

# --- LogPool14: the real pool, with checkout/return recorded ---------------

{
  package LogPool14;
  use base 'DBIO::Async::Pool';

  sub acquire {
    my $self = shift;
    return $self->SUPER::acquire->on_done(sub {
      push @{ $self->{storage}{log} }, 'acquire';
    });
  }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{storage}{log} }, 'release';
    return $self->SUPER::release($conn);
  }
}

# --- TxnStorage14 ----------------------------------------------------------

{
  package TxnStorage14;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1]{r} }

  # The owning sync storage seam this backend delegates to. This mock is a
  # single ownership domain (its own owner), supplying:
  #  * k196 / ADR 0045 §4: the FAITHFUL ownership check core's DBIO::Storage::DBI
  #    runs -- a context of this backend generation is accepted, a foreign one
  #    refused. The transaction context's CRUD asserts ownership
  #    (_assert_context_active -> _owner_storage -> _assert_async_context_owner)
  #    before it runs on the pinned connection; without these seams it dies
  #    "async context ownership cannot be proven".
  #  * k193: the in-txn select routes through core's _run_crud_pinned('select'),
  #    which prepares its args through the owner's _select_args (op name first).
  sub _owner_storage { $_[0] }
  sub _assert_async_context_owner {
    my ($self, $ctx) = @_;
    die "async context ownership cannot be proven\n"
      unless Scalar::Util::blessed($ctx) && $ctx->can('_context_owner_token');
    my $ours   = $self->_context_owner_token;
    my $theirs = $ctx->_context_owner_token;
    die "async context does not belong to this storage generation\n"
      unless $ours && $theirs
          && Scalar::Util::refaddr($ours) == Scalar::Util::refaddr($theirs);
    return $ctx;
  }
  sub _select_args {
    my ($self, @args) = @_;
    return ('select', @args);
  }

  sub _create_pool_connection   { TxnConn14->new(++$_[0]->{_next_id}) }
  sub _shutdown_pool_connection { close $_[1]{r}; close $_[1]{w} }

  # Same wiring as the skeleton's own pool(), only with the logging pool class
  # (the skeleton hardcodes DBIO::Async::Pool) -- as t/09 does.
  sub pool {
    my $self = shift;
    return $self->{pool} ||= LogPool14->new(
      storage  => $self,
      conninfo => $self->{_conninfo},
      size     => $self->{_pool_size},
      on_error => sub { die "pool error: $_[0]" },
    );
  }

  # The DB-specific half, and the only thing this mock owns. Records what went
  # to the wire and on which connection, tracks the transaction state the way a
  # server would, and makes the fd readable so the real Future::IO seam has
  # something to resolve on.
  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;

    push @{ $self->{wire} }, { sql => $sql, conn => $conn->id };
    push @{ $self->{log} },
      $sql =~ /^(?:BEGIN|COMMIT|ROLLBACK)$/ ? $sql : 'stmt';

    # COMMIT and ROLLBACK end the transaction whether the server accepts them
    # or not -- that is what an engine does with them, and modelling it the
    # other way would invent a "released mid-transaction" failure that no real
    # backend produces. BEGIN, by contrast, only starts one if it succeeded.
    $conn->{in_txn} = 0 if $sql eq 'COMMIT' or $sql eq 'ROLLBACK';

    # a string is a failure on the way (the transport), a
    # DBIO::Exception::Server one the server answered with (ADR 0062)
    if (my $e = $self->{fail_sql} && $self->{fail_sql}{$sql}) {
      die ref $e ? $e : "$e\n";
    }

    $conn->{in_txn} = 1 if $sql eq 'BEGIN';
    syswrite $conn->{w}, 'R';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $b, 1;
    return Future->done([ 'row', $self->{wire}[-1]{sql} ]);
  }
}

sub new_storage {
  my $storage = TxnStorage14->new(undef);
  $storage->{_next_id} = 0;
  $storage->{log}      = [];
  $storage->{wire}     = [];
  # pool_size 1: the transaction holds the pool's ONLY connection, so the next
  # acquire is guaranteed to be that same connection -- which is what makes
  # "released clean" and "released twice" observable at all.
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  return $storage;
}

sub sqls   { [ map { $_->{sql} } @{ $_[0]->{wire} } ] }
sub conns  { my %s = map { $_->{conn} => 1 } @{ $_[0]->{wire} }; return [ sort keys %s ] }
sub counted { my ($log, $ev) = @_; return scalar grep { $_ eq $ev } @$log }

# Drive the event loop until the Future settles, without dying on a failure.
# Every assertion below is about a COMPLETED transaction, and on this transport
# nothing completes until something awaits it: txn_do_async returns while BEGIN
# is still out on the wire.
sub settle { my $f = shift; eval { $f->get }; return $f }

# The check every scenario ends with. Not a tidy-up: each line is one of the
# two failure modes named in the header.
sub released_exactly_once {
  my ($storage, $label) = @_;
  my $log = $storage->{log};

  is counted($log, 'release'), 1,
    "$label: the pinned connection went back to the pool exactly once";
  is $storage->pool->available, 1,
    "$label: and the idle list holds it once -- not twice (double release "
    . 'hands one connection to two callers), not never (a leaked slot)';

  my $next = $storage->pool->acquire->get;
  is $next->id, 1,
    "$label: the size-1 pool hands the very same connection to the next user";
  ok !$next->in_txn,
    "$label: and it is no longer inside a transaction";
  $storage->pool->release($next);
}

# ---------------------------------------------------------------------------
# 1. The commit path, end to end.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();

  my ($ctx, $ctx_conn);
  my $f = $storage->txn_do_async(sub {
    ($ctx) = @_;
    $ctx_conn = $ctx->txn_conn;
    return $ctx->select_async('artist', ['*'], { id => 1 })
      ->then(sub { return Future->done('inner-result') });
  });

  is scalar(settle($f)->get), 'inner-result',
    'txn_do_async resolves with what the block resolved';

  isa_ok $ctx, 'DBIO::Async::TransactionContext',
    'the context handed to the coderef';
  is $storage->_txn_context_class, 'DBIO::Async::TransactionContext',
    '... the one _txn_context_class names (karr k13: no adapter has to say so)';

  is_deeply $storage->{log},
    [ 'acquire', 'BEGIN', 'stmt', 'COMMIT', 'release' ],
    'the bracket is: acquire, BEGIN, the block\'s statements, COMMIT, release';

  like sqls($storage)->[1], qr/^SELECT .*FROM artist/,
    'the block\'s CRUD really became SQL on the wire (not a mocked-away call)';

  is_deeply conns($storage), [ $ctx_conn->id ],
    'BEGIN, the statement and COMMIT all ran on the ONE connection acquire_txn '
    . 'handed out -- nothing slipped onto a pooled sibling outside the txn';

  released_exactly_once($storage, 'commit');
}

# ---------------------------------------------------------------------------
# 2. The block's Future fails -> ROLLBACK, and the failure reaches the caller
#    unchanged. The commonest real path (a constraint violation), and the one
#    where a missed release would strand the pool for good.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();

  my $f = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->select_async('artist', ['*'], { id => 1 })
      ->then(sub { return Future->fail("constraint violated\n") });
  });

  ok settle($f)->is_failed, 'txn_do_async fails when the block\'s Future fails';
  is scalar($f->failure), "constraint violated\n",
    'and the block\'s own error reaches the caller unchanged';

  is_deeply $storage->{log},
    [ 'acquire', 'BEGIN', 'stmt', 'ROLLBACK', 'release' ],
    'a failing block is rolled back, then released';

  released_exactly_once($storage, 'failing block');
}

# ---------------------------------------------------------------------------
# 3. The block DIES synchronously, before it ever returns a Future. Separate
#    branch in the orchestration, and the one a caller reaches by writing a bug
#    rather than by hitting the database.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();

  my $f = $storage->txn_do_async(sub { die "block blew up\n" });

  ok settle($f)->is_failed, 'txn_do_async fails when the block dies';
  like scalar($f->failure), qr/block blew up/,
    'the die propagates out of txn_do_async';

  is_deeply $storage->{log},
    [ 'acquire', 'BEGIN', 'ROLLBACK', 'release' ],
    'a dying block is rolled back with no statement of its own having run';

  released_exactly_once($storage, 'dying block');
}

# ---------------------------------------------------------------------------
# 4. BEGIN itself fails. The connection was acquired but never entered a
#    transaction, so there is nothing to roll back -- and precisely because
#    there is no ROLLBACK to hang the release off, this is the path where a
#    forgotten release is easiest to write and hardest to notice.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  $storage->{fail_sql} = { BEGIN => 'server said no' };

  my $f = $storage->txn_do_async(sub { die 'the block must never run' });

  ok settle($f)->is_failed, 'txn_do_async fails when BEGIN fails';
  like scalar($f->failure), qr/BEGIN failed: server said no/,
    'the failure names the stage, so a caller can tell it from a block error';

  is_deeply $storage->{log}, [ 'acquire', 'BEGIN', 'release' ],
    'no ROLLBACK is attempted for a transaction that never began';
  is_deeply sqls($storage), ['BEGIN'],
    'and the block never ran -- nothing but the rejected BEGIN reached the wire';

  released_exactly_once($storage, 'failing BEGIN');
}

# ---------------------------------------------------------------------------
# 5. COMMIT fails. The block succeeded, so the caller must still be told the
#    transaction did not land -- and the connection must still come back.
#    A COMMIT the server refused ends the transaction: core sends a ROLLBACK
#    on the pinned connection before it is released, so the server keeps
#    nothing open, and the Future fails with the server's object (core karr
#    k372). A COMMIT that failed on the way (a string here) is left as it was.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  $storage->{fail_sql} = { COMMIT => DBIO::Exception::Server->new(
    message => 'deferred constraint failed', sqlstate => '23503') };

  my $f = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->select_async('artist', ['*'], { id => 1 });
  });

  ok settle($f)->is_failed, 'txn_do_async fails when COMMIT fails';
  like scalar($f->failure), qr/COMMIT failed: deferred constraint failed/,
    'a failed COMMIT is reported as such, never as success';

  is_deeply $storage->{log},
    [ 'acquire', 'BEGIN', 'stmt', 'COMMIT', 'ROLLBACK', 'release' ],
    'the COMMIT was attempted, a ROLLBACK follows it, and the connection is released';

  ok Scalar::Util::blessed($f->failure) && $f->failure->isa('DBIO::Exception::Server'),
    'the Future fails with the server\'s object';

  released_exactly_once($storage, 'failing COMMIT');
}

{
  # the same COMMIT failing on the way, not refused by the server: no
  # ROLLBACK is sent after it (core karr k372)
  my $storage = new_storage();
  $storage->{fail_sql} = { COMMIT => 'connection lost' };

  my $f = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->select_async('artist', ['*'], { id => 1 });
  });

  ok settle($f)->is_failed, 'txn_do_async fails when COMMIT fails on the way';
  is_deeply $storage->{log},
    [ 'acquire', 'BEGIN', 'stmt', 'COMMIT', 'release' ],
    'a COMMIT that failed on the way gets no ROLLBACK after it';

  released_exactly_once($storage, 'COMMIT failing on the way');
}

# ---------------------------------------------------------------------------
# 6. A block that returns a plain value rather than a Future. Core commits
#    immediately in that case; it is a documented branch of the orchestration
#    and, on this transport, the one where the whole transaction completes
#    without a single downstream Future to hold the chain alive.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();

  my $f = $storage->txn_do_async(sub { return 'plain value' });

  is scalar(settle($f)->get), 'plain value',
    'a block returning a plain value still resolves through txn_do_async';
  is_deeply $storage->{log},
    [ 'acquire', 'BEGIN', 'COMMIT', 'release' ],
    'and is committed immediately';

  released_exactly_once($storage, 'plain return');
}

# ---------------------------------------------------------------------------
# 7. Two transactions in sequence on a size-1 pool. The release contract is
#    only worth anything if the connection is genuinely reusable afterwards --
#    including its cached Future::IO poll handle, which lives for the
#    connection's whole life and not for one transaction's.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();

  for my $n (1 .. 2) {
    my $f = $storage->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->select_async('artist', ['*'], { id => $n });
    });
    ok settle($f)->is_done, "transaction $n completed";
  }

  is counted($storage->{log}, 'acquire'), 2, 'two transactions, two checkouts';
  is counted($storage->{log}, 'release'), 2, '... and two releases';
  is_deeply conns($storage), [1],
    'both transactions ran on the same, reused connection';
  is scalar @{ $storage->pool->{_connections} }, 1,
    'the pool never had to spawn a second connection';
}

done_testing;
