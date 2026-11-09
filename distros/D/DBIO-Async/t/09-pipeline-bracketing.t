use strict;
use warnings;
use Test::More;

use Future;
use Scalar::Util ();
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE end-to-end test for the ADR 0003 pipeline-bracketing contract at THIS
# dist's layer: ->pipeline(\&batch) driven through a mock transport that fills
# the three seam hooks the way a real pipelining client library behaves. No DB,
# no event loop, no DBD -- the mock is the whole backend.
#
# WHAT THIS TEST PROVES (ADR 0003, Decision + Consequences): the connection
# carrying a batch is bracketed enter -> queue -> sync -> exit, and it goes back
# into the pool ONLY after _pipeline_exit -- on EVERY exit path, not just the
# happy one. The reason that matters is not symmetry: per the ADR, a connection
# released while still in pipeline mode "poisons the next user". So each
# scenario below finishes by re-acquiring from a size-1 pool -- which can only
# hand back the very same connection -- and asserting it is out of pipeline
# mode and usable. That is the guarantee callers actually depend on; counting
# hook calls alone would not catch a release-before-exit swap.
#
# It also proves the second half of the ADR's promise, the one that used to be
# only a promise (karr k7): the queries inside the block really do queue onto
# the bracketed connection. Since core now hands the block a pinned
# DBIO::Storage::Async::PipelineContext, that is structural -- this backend
# implements no pipeline-aware query routing at all, it only fills the pinned
# seam it already needs for transactions. Scenario 5 shows the other side:
# going around the context, to the storage itself, still lands on the POOLED
# path and is not batched.
#
# Core (dbio t/test/15_async_orchestration.t) covers the scaffold's call
# sequence against a fake pool. This test adds what only this layer can show:
# the real DBIO::Async::Pool checkout/return interleaved with the seams, the
# batch results arriving through the sync round-trip, and the two failure
# branches (a query in the batch failing, and the sync itself failing).

# --- PipeConn9: connection that tracks its own pipeline mode ---
#
# Pipeline mode is per-connection state, so the mock keeps it ON the connection
# (not on the storage): that is what makes "released while still in pipeline
# mode" observable at all.

{
  package PipeConn9;
  sub new { bless { id => $_[1], in_pipeline => 0, queued => [] }, $_[0] }
  sub id          { $_[0]->{id} }
  sub in_pipeline { $_[0]->{in_pipeline} }
}

# --- LogPool9: the real pool, with checkout/return recorded ---
#
# Subclasses DBIO::Async::Pool so the genuine idle-list / waiter-queue /
# readiness-gating mechanics run; it only appends to the storage's log, which is
# what lets the assertions compare seam order against pool order in ONE
# sequence.

{
  package LogPool9;
  use base 'DBIO::Async::Pool';

  sub acquire {
    my $self = shift;
    return $self->SUPER::acquire->on_done(sub {
      push @{ $self->{storage}{_log} }, 'acquire';
    });
  }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{storage}{_log} }, 'release';
    return $self->SUPER::release($conn);
  }
}

# --- TestStorage9: a backend whose client library really pipelines ---

{
  package TestStorage9;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;

  sub sql_maker_class           { 'DBIO::SQLMaker' }
  sub _transform_sql            { $_[1] }
  sub _post_insert_sql          { '' }
  sub _normalize_conninfo       { $_[1] }
  sub _conn_ready               { 1 }
  sub _shutdown_pool_connection { push @{ $_[0]{_log} }, 'shutdown' }
  sub _txn_context_class        { 'DBIO::Async::TransactionContext' }
  sub _txn_conn_accessor        { 'txn_conn' }

  # The owning sync storage seam this backend delegates to. This mock is a
  # single ownership domain (its own owner), supplying:
  #  * k196 / ADR 0045 §4: the FAITHFUL ownership check core's DBIO::Storage::DBI
  #    runs -- a context of this backend generation is accepted, a foreign one
  #    refused. The batch context's CRUD asserts ownership (_assert_context_active
  #    -> _owner_storage -> _assert_async_context_owner) before it queues; without
  #    these seams it dies "async context ownership cannot be proven".
  #  * k193: the batched select routes through core's _run_crud_pinned('select'),
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

  sub _create_pool_connection { PipeConn9->new(++$_[0]->{_next_id}) }

  # Same wiring as the skeleton's pool(), only with the logging pool class
  # (the skeleton hardcodes DBIO::Async::Pool) and without the AccessBroker
  # branch, which this test does not exercise.
  sub pool {
    my $self = shift;
    return $self->{pool} ||= LogPool9->new(
      storage  => $self,
      conninfo => $self->{_conninfo},
      size     => $self->{_pool_size},
      on_error => sub { die "pool error: $_[0]" }
    );
  }

  # --- the three ADR 0003 seam hooks ---
  #
  # Each one asserts its own precondition by dying: entering twice, or syncing
  # / exiting on a connection that is not in pipeline mode, is exactly the
  # unbalanced-bracket bug the ADR says must be impossible for a caller to
  # produce. A regression in the scaffold shows up as a die here, not as a
  # quietly wrong log.

  sub _pipeline_enter {
    my ($self, $conn) = @_;
    die 'pipeline already open on conn ' . $conn->id . "\n" if $conn->{in_pipeline};
    $conn->{in_pipeline}  = 1;
    $self->{_entered_conn} = $conn;    # kept past exit, for the assertions
    push @{ $self->{_log} }, 'enter';
  }

  # The sync round-trip is what delivers the batched results: every queued
  # query resolves here, not when it was issued. That is the round-trip economy
  # ADR 0003 exists for, and it is why release must not happen before it.
  sub _pipeline_sync {
    my ($self, $conn) = @_;
    die "sync outside pipeline mode\n" unless $conn->{in_pipeline};
    push @{ $self->{_log} }, 'sync';

    return Future->fail($self->{_sync_error}) if $self->{_sync_error};

    while (my $q = shift @{ $conn->{queued} }) {
      next if $q->{future}->is_ready;    # aggregate already failed/cancelled it
      if ($q->{sql} =~ /\bboom\b/) {
        $q->{future}->fail("batch query failed\n");
      }
      else {
        $q->{future}->done([ $q->{sql} ]);
      }
    }
    return Future->done;
  }

  sub _pipeline_exit {
    my ($self, $conn) = @_;
    die "exit without enter\n" unless $conn->{in_pipeline};
    $conn->{in_pipeline} = 0;
    push @{ $self->{_log} }, 'exit';
  }

  # Transport override, PINNED path: run the statement on the connection the
  # caller hands in. On a connection that is in pipeline mode, a real
  # pipelining client queues the statement instead of round-tripping it -- so
  # that is what the mock does. This is the seam the batch context routes
  # through, and it is the SAME seam a transaction uses; the mock therefore
  # models no pipeline-specific transport code at all, which is the point of
  # the core change (karr k7): the driver has nothing to remember.
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    die "pinned query on a connection that is not in pipeline mode: $sql\n"
      unless $conn->{in_pipeline};
    my $f = Future->new;
    push @{ $conn->{queued} }, { future => $f, sql => $sql };
    push @{ $self->{_log} },     'queue';
    push @{ $self->{_batched} }, { sql => $sql, conn => $conn };
    return $f;
  }

  # Transport override, POOLED path: take a connection of its own, run, release.
  # Nothing about it knows pipelines -- which is exactly why a query that
  # reaches this seam during a batch is NOT batched, no matter that a pipeline
  # happens to be open. Scenario 5 relies on that.
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    return $self->pool->acquire->then(sub {
      my $conn = shift;
      push @{ $self->{_log} },       'unbatched-query';
      push @{ $self->{_unbatched} }, { sql => $sql, conn => $conn };
      $self->pool->release($conn);
      return Future->done([$sql]);
    });
  }
}

sub new_storage {
  my $storage = TestStorage9->new(undef);
  $storage->{_next_id} = 0;
  $storage->{_log}       = [];
  $storage->{_batched}   = [];
  $storage->{_unbatched} = [];
  # pool_size 1: the pipeline holds the pool's ONLY connection, so the next
  # acquire is guaranteed to hand back that same connection -- the "next user"
  # of ADR 0003's poisoning consequence, made concrete.
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  return $storage;
}

sub index_of {
  my ($log, $event) = @_;
  for my $i (0 .. $#$log) { return $i if $log->[$i] eq $event }
  return -1;
}

# The check every scenario ends with: the batch connection is back in the pool,
# out of pipeline mode, and the next caller gets it in a usable state.
sub conn_returned_clean {
  my ($storage, $label) = @_;
  my $log  = $storage->{_log};
  my $conn = $storage->{_entered_conn};

  # Presence before order: index_of returns -1 for a missing event, so a
  # bracket that never exits at all would satisfy a bare "exit < release"
  # comparison (-1 is less than anything). Assert exit happened first, and
  # only compare positions once both events are really in the log.
  my ($exit_at, $release_at) = (index_of($log, 'exit'), index_of($log, 'release'));
  cmp_ok $exit_at, '>=', 0,
    "$label: _pipeline_exit ran at all";
  cmp_ok $release_at, '>=', 0,
    "$label: the connection was released back to the pool";
  ok $exit_at >= 0 && $release_at >= 0 && $exit_at < $release_at,
    "$label: _pipeline_exit ran BEFORE the connection went back to the pool";
  is $storage->pool->available, 1,
    "$label: the batch connection was returned to the pool";

  my $next = $storage->pool->acquire->get;
  is $next, $conn,
    "$label: the size-1 pool hands the very same connection to the next user";
  ok !$next->in_pipeline,
    "$label: and it is out of pipeline mode -- the next user is not handed a "
    . 'connection still mid-batch';
}

# The check every FAILED batch ends with (core k396): the bracket was closed
# (exit) and the connection then left the pool for good -- retired, closed
# through the transport, never released. The slot is free and the next caller
# gets a fresh connection, out of pipeline mode.
sub conn_retired_clean {
  my ($storage, $label) = @_;
  my $log  = $storage->{_log};
  my $conn = $storage->{_entered_conn};

  my ($exit_at, $shutdown_at) = (index_of($log, 'exit'), index_of($log, 'shutdown'));
  cmp_ok $exit_at, '>=', 0,
    "$label: _pipeline_exit ran at all";
  is index_of($log, 'release'), -1,
    "$label: the connection of a failed batch was not released to the pool";
  ok $exit_at >= 0 && $shutdown_at > $exit_at,
    "$label: _pipeline_exit ran BEFORE the connection was closed";
  is $storage->pool->available, 0,
    "$label: nothing idle is left in the pool";

  my $next = $storage->pool->acquire->get;
  isnt $next, $conn,
    "$label: the size-1 pool hands the next user a fresh connection";
  ok !$next->in_pipeline,
    "$label: and it is out of pipeline mode -- the next user is not handed a "
    . 'connection still mid-batch';
}

# ---------------------------------------------------------------------------
# 1. Success path: enter -> queue -> sync -> exit -> release, one connection,
#    results delivered by the sync.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();

  my $handed;
  my $f = $storage->pipeline(sub {
    my ($s) = @_;
    $handed = $s;
    return Future->needs_all(
      $s->select_async('artist', ['*'], { id => 1 }),
      $s->select_async('track',  ['*'], { id => 2 })
    );
  });

  isa_ok $f, 'Future', 'pipeline returns a Future';
  isa_ok $handed, 'DBIO::Storage::Async::PipelineContext',
    'the block is handed a batch context pinned to the bracketed connection';
  is $handed->pipeline_conn, $storage->{_entered_conn},
    'and it carries the very connection _pipeline_enter was called on';
  ok $f->is_done, 'pipeline resolves once the batch has been synced';

  is_deeply $storage->{_log},
    [ 'acquire', 'enter', 'queue', 'queue', 'sync', 'exit', 'release' ],
    'bracketing sequence: acquire, enter, both queries queued, sync, exit, release';

  is scalar @{ $storage->{_batched} }, 2,
    'both *_async calls inside the block were batched (no per-query round trip)';
  is_deeply [ map { $_->{conn} } @{ $storage->{_batched} } ],
    [ ($storage->{_entered_conn}) x 2 ],
    'the whole batch ran on the ONE connection the pipeline entered '
    . '(pipeline mode is per-connection state)';

  my @rows = $f->get;
  is scalar @rows, 2,
    'the aggregate Future resolves with every batched result';
  like $rows[0][0], qr/FROM artist/,
    'first batched query resolved through the sync round-trip';
  like $rows[1][0], qr/FROM track/,
    'second batched query resolved through the same sync round-trip';

  conn_returned_clean($storage, 'success');
}

# ---------------------------------------------------------------------------
# 2. A query inside the batch fails. The batch's aggregate Future fails, but
#    the bracket must still close: exit, then the connection is retired (core k396). This is the path a
#    real caller hits most often (bad SQL, constraint violation), and the one
#    where leaving the connection in pipeline mode would silently break the
#    NEXT, unrelated query.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();

  my $f = $storage->pipeline(sub {
    my ($s) = @_;
    return Future->needs_all(
      $s->select_async('artist', ['*'], { id => 1 }),
      $s->select_async('boom',   ['*'], { id => 2 })
    );
  });

  ok $f->is_failed, 'pipeline fails when a query inside the batch fails';
  like scalar $f->failure, qr/batch query failed/,
    'the in-batch query error propagates out of pipeline()';

  is_deeply $storage->{_log},
    [ 'acquire', 'enter', 'queue', 'queue', 'sync', 'exit', 'shutdown' ],
    'a failing batch is bracketed and synced like a good one, then its connection is retired';

  conn_retired_clean($storage, 'failing query');
}

# ---------------------------------------------------------------------------
# 3. The batch builder throws before the batch is ever synced. ADR 0003's
#    fail-safe branch: exit pipeline mode and retire WITHOUT syncing, so a die
#    in the caller's coderef cannot strand a connection in pipeline mode.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();

  my $f = $storage->pipeline(sub {
    my ($s) = @_;
    $s->select_async('artist', ['*'], { id => 1 });    # already queued...
    die "batch builder blew up\n";                     # ...then the builder dies
  });

  ok $f->is_failed, 'pipeline fails when the batch coderef dies';
  like scalar $f->failure, qr/batch builder blew up/,
    'the die from the batch coderef propagates out of pipeline()';

  is_deeply $storage->{_log},
    [ 'acquire', 'enter', 'queue', 'exit', 'shutdown' ],
    'a dying batch coderef skips the sync but still exits pipeline mode first, then retires the connection';
  is index_of($storage->{_log}, 'sync'), -1,
    'no sync is attempted for a batch that was never finished building';

  conn_retired_clean($storage, 'dying coderef');
}

# ---------------------------------------------------------------------------
# 4. The sync round-trip itself fails (the server aborts the batch). Third and
#    last exit path of the bracket -- the one where the connection is most
#    likely to be left dirty, because the failure happens inside the very step
#    that was supposed to complete the batch.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  $storage->{_sync_error} = "sync round-trip failed\n";

  my $f = $storage->pipeline(sub {
    my ($s) = @_;
    return Future->needs_all($s->select_async('artist', ['*'], { id => 1 }));
  });

  ok $f->is_failed, 'pipeline fails when the sync itself fails';
  like scalar $f->failure, qr/sync round-trip failed/,
    'the sync error propagates out of pipeline()';

  is_deeply $storage->{_log},
    [ 'acquire', 'enter', 'queue', 'sync', 'exit', 'shutdown' ],
    'a failed sync still exits pipeline mode before the connection is retired';

  conn_retired_clean($storage, 'failing sync');
}

# ---------------------------------------------------------------------------
# 5. Why the block is handed a context at all (karr k7). A call made on the
#    STORAGE inside the block goes through the ordinary pooled seam -- it is
#    not batched, and with the pool's only connection held by the pipeline it
#    cannot even start until the bracket releases. That is precisely the
#    failure ADR 0003 used to describe as impossible while nothing prevented
#    it; it is now the documented difference between the context and the
#    storage, and this scenario is what would catch a scaffold that quietly
#    went back to handing the storage in.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();

  my $outside;
  my $f = $storage->pipeline(sub {
    my ($batch) = @_;
    # deliberately NOT $batch: the storage, closed over from outside
    $outside = $storage->select_async('artist', ['*'], { id => 1 });
    return Future->needs_all($batch->select_async('track', ['*'], { id => 2 }));
  });

  ok $f->is_done, 'the batch itself completes';

  is scalar @{ $storage->{_batched} }, 1,
    'only the call made on the batch context was batched';
  like $storage->{_batched}[0]{sql}, qr/FROM track/,
    'and it is the context one';

  is scalar @{ $storage->{_unbatched} }, 1,
    'the call made on the storage took the pooled path instead';
  like $storage->{_unbatched}[0]{sql}, qr/FROM artist/,
    'and it is the storage one';

  cmp_ok index_of($storage->{_log}, 'exit'), '<',
    index_of($storage->{_log}, 'unbatched-query'),
    'at pool_size 1 it could not run until the pipeline released -- i.e. '
    . 'strictly AFTER _pipeline_exit, exactly the round-trip win it misses';

  ok $outside->is_done, 'it does still run, which is why the bug was silent';
}

done_testing;
