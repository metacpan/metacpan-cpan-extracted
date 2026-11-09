use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util ();

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::Async::TransactionContext;
use DBIO::Storage::Async::PipelineContext;
use DBIO::Storage::DBI;

# ADR 0045: $rs->with_context($ctx) (plus the mirrors on Row and
# ResultSetColumn) binds a resultset to the pinned async context handed to a
# txn_do_async / pipeline coderef, so ResultSet/Row/RSC *_async run on the
# PINNED connection instead of a sibling pool connection outside the
# transaction/pipeline. This drives the four acceptance consequences through a
# fully-synchronous fake transport (the same harness shape as
# t/test/15_async_orchestration.t) -- no event loop, no real database.

# --- A fake pool: one connection, wrapped in a Future -----------------------
{
  package Test::SyncPool;
  sub new { bless { released => [] }, shift }
  sub acquire     { DBIO::Test::Future->done('CONN') }
  sub acquire_txn { DBIO::Test::Future->done('CONN') }
  sub release     { push @{ $_[0]->{released} }, $_[1]; 1 }
  sub shutdown    { 1 }
}

# --- The fake transport backend --------------------------------------------
# A concrete DBIO::Storage::Async overriding only the seam hooks. Every query
# is captured with whether it was pinned and onto which connection; the rows it
# "returns" are settable per call via {next_rows}, so RS inflation runs on real
# rows exactly like the pooled path.
{
  package Test::CtxBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured}  = [];
    $self->{next_rows} = [];
    return $self;
  }
  sub future_class    { 'DBIO::Test::Future' }
  sub sql_maker_class { 'DBIO::SQLMaker' }
  sub _sql_maker_args { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }
  sub pool { $_[0]->{pool} ||= Test::SyncPool->new }

  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, pinned => 0 };
    return $self->future_class->done(@{ $self->{next_rows} });
  }
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, pinned => 1, conn => $conn };
    return $self->future_class->done(@{ $self->{next_rows} });
  }
  sub _pipeline_enter { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_ENTER' }; 1 }
  sub _pipeline_exit  { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_EXIT'  }; 1 }
  sub _pipeline_sync  { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_SYNC'  }; $_[0]->future_class->done }
}

# An external object that satisfies the historical select_async shape check but
# carries no Core ownership proof.
{
  package Test::TokenlessContext;
  sub new { bless {}, shift }
  sub select_async { DBIO::Test::Future->done }
}

DBIO::Storage::DBI->register_async_mode( with_ctx_backend => 'Test::CtxBackend' );

# Wire a mock schema so $schema->resultset(...)->_async_storage resolves to the
# registered orchestration backend, exactly as connect(..., { async => ... })
# would. Returns ($schema, $backend).
sub wired_schema {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->_async_mode('with_ctx_backend');
  delete $schema->storage->{_async_storage_obj};
  my $backend = $schema->storage->_async_storage;
  return ($schema, $backend);
}

sub captured_matching {
  my ($backend, $re) = @_;
  return grep { ($_->{sql} || '') =~ $re } @{ $backend->{captured} };
}

my @ARTISTS = ( [ 1, 'Miles Davis', 13, undef ], [ 2, 'John Coltrane', 13, undef ] );

# ---------------------------------------------------------------------------
# Consequence 1: NO context bound == today's behaviour, on the pool.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ @ARTISTS ];

  my @rows = $schema->resultset('Artist')
                    ->search(undef, { order_by => 'me.artistid' })
                    ->all_async->get;
  is scalar @rows, 2, 'unbound all_async resolves the rows';
  isa_ok $rows[0], 'DBIO::Test::Schema::Artist', 'unbound all_async inflates';

  my ($sel) = captured_matching($backend, qr/FROM "artist"/);
  ok $sel, 'unbound all_async issued the select';
  is $sel->{pinned}, 0, 'unbound all_async ran on a POOLED connection (unchanged)';
}

# ---------------------------------------------------------------------------
# Consequence 2 (transactions): with_context routes onto the pinned txn conn.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ @ARTISTS ];

  my $rows;
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    isa_ok $ctx, 'DBIO::Storage::Async::TransactionContext', 'coderef gets the txn ctx';
    return $schema->resultset('Artist')
                  ->search(undef, { order_by => 'me.artistid' })
                  ->with_context($ctx)
                  ->all_async
                  ->then(sub { $rows = [ @_ ]; return 'done' });
  });

  is scalar $f->get, 'done', 'txn commits with the coderef result';
  is scalar @$rows, 2, 'bound all_async resolves the rows inside the txn';
  isa_ok $rows->[0], 'DBIO::Test::Schema::Artist', 'bound all_async still inflates';

  my ($sel) = captured_matching($backend, qr/FROM "artist"/);
  ok $sel->{pinned}, 'bound all_async ran on the PINNED connection, not the pool';
  is $sel->{conn}, 'CONN', 'and specifically on the txn connection';
  ok !( grep { !$_->{pinned} } @{ $backend->{captured} } ),
    'every query in the txn (BEGIN/SELECT/COMMIT) was pinned -- nothing hit the pool';
}

# ---------------------------------------------------------------------------
# Consequence 2 (transactions): a bound ResultSet retained past a terminal
# transaction must refuse rather than finding the pooled async backend.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  my ($bound, $saved_ctx);
  my $gate = DBIO::Test::Future->new;

  my $txn = $backend->txn_do_async(sub {
    ($saved_ctx) = @_;
    $bound = $schema->resultset('Artist')
                    ->search(undef, { order_by => 'me.artistid' })
                    ->with_context($saved_ctx);
    return $gate;
  });

  ok $saved_ctx->_context_active,
    'transaction context is active while its callback Future is pending';
  ok !$txn->is_ready,
    'transaction waits while the bound ResultSet is retained';

  $gate->done('finished');
  is scalar $txn->get, 'finished', 'retained ResultSet transaction commits';
  ok !$saved_ctx->_context_active,
    'transaction context is terminal before the retained ResultSet is reused';

  my $captured_before = scalar @{ $backend->{captured} };
  my $error;
  {
    local $@;
    eval { $bound->all_async };
    $error = $@;
  }
  like $error, qr/no longer active/,
    'ResultSet carrying a completed transaction context refuses';
  unlike $error, qr/a pipeline context is valid only/i,
    'completed transaction context is not diagnosed as pipeline-only';
  is scalar @{ $backend->{captured} }, $captured_before,
    'expired transaction context does not fall back to pool dispatch';
}

# ---------------------------------------------------------------------------
# Consequence 2 (propagation): the context survives search_rs clones, in
# either binding order, and the extra WHERE still reaches the SQL.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ [ 2, 'John Coltrane', 13, undef ] ];

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    # bind first, then search
    return $schema->resultset('Artist')
                  ->with_context($ctx)
                  ->search({ 'me.artistid' => 2 })
                  ->all_async;
  })->get;

  my ($sel) = captured_matching($backend, qr/FROM "artist"/);
  ok $sel->{pinned}, 'context propagated across a search_rs clone (bind-then-search)';
  like $sel->{sql}, qr/WHERE .*artistid/, 'the chained WHERE still reached the SQL';

  # search first, then bind
  my ($schema2, $backend2) = wired_schema();
  $backend2->{next_rows} = [ [ 2, 'John Coltrane', 13, undef ] ];
  $backend2->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema2->resultset('Artist')
                   ->search({ 'me.artistid' => 2 })
                   ->with_context($ctx)
                   ->all_async;
  })->get;
  my ($sel2) = captured_matching($backend2, qr/FROM "artist"/);
  ok $sel2->{pinned}, 'context bound after a search still pins (search-then-bind)';
}

# ---------------------------------------------------------------------------
# Consequence 2 (derived rows inherit): the exact chain from the ticket --
# with_context -> first_async -> then(update_async) -- writes back pinned.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ [ 1, 'Miles Davis', 13, undef ] ];

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema->resultset('Artist')
                  ->with_context($ctx)
                  ->first_async
                  ->then(sub {
                    my ($row) = @_;
                    isa_ok $row, 'DBIO::Test::Schema::Artist', 'first_async gave a Row';
                    $backend->{next_rows} = [ 1 ];   # UPDATE affects 1 row
                    return $row->update_async({ name => 'Miles Dewey Davis' });
                  });
  })->get;

  my ($upd) = captured_matching($backend, qr/^UPDATE "artist"/);
  ok $upd, 'the row derived from first_async issued an UPDATE';
  ok $upd->{pinned}, 'the derived row inherited the context and updated PINNED';
  is $upd->{conn}, 'CONN', 'the derived-row UPDATE ran on the txn connection';
  ok !( grep { !$_->{pinned} } @{ $backend->{captured} } ),
    'select AND write-back both stayed on the pinned connection';
}

# ---------------------------------------------------------------------------
# Consequence 2 (create_async): a row made by create_async on a bound RS
# inserts on the pinned connection.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();

  my $row;
  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $backend->{next_rows} = [ [ 42, 'Cecil Taylor', 13, undef ] ];   # RETURNING *
    return $schema->resultset('Artist')
                  ->with_context($ctx)
                  ->create_async({ name => 'Cecil Taylor' })
                  ->then(sub { $row = $_[0] });
  })->get;

  isa_ok $row, 'DBIO::Test::Schema::Artist', 'create_async resolved a Row';
  is $row->artistid, 42, 'autoinc folded back from the pinned insert';
  my ($ins) = captured_matching($backend, qr/^INSERT INTO "artist"/);
  ok $ins->{pinned}, 'create_async inserted on the PINNED connection';
  is $ins->{conn}, 'CONN', 'on the txn connection';
}

# ---------------------------------------------------------------------------
# Consequence 2 (ResultSetColumn): get_column on a bound RS inherits it.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ [ 1 ], [ 2 ] ];

  my @ids;
  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema->resultset('Artist')
                  ->with_context($ctx)
                  ->get_column('artistid')
                  ->all_async
                  ->then(sub { @ids = @_ });
  })->get;

  is_deeply [ @ids ], [ 1, 2 ], 'bound RSC all_async resolved the column values';
  my ($sel) = captured_matching($backend, qr/FROM "artist"/);
  ok $sel->{pinned}, 'bound get_column(...)->all_async ran on the PINNED connection';
  is $sel->{conn}, 'CONN', 'on the txn connection';
}

# ---------------------------------------------------------------------------
# Consequence 3: a pipeline context is valid ONLY during the synchronous batch
# run. A bound RS used AFTER the batch must fail LOUDLY, never fall back to the
# pool.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ @ARTISTS ];

  my $seen_batch;
  $backend->pipeline(sub {
    my ($batch) = @_;
    $seen_batch = $batch;
    isa_ok $batch, 'DBIO::Storage::Async::PipelineContext', 'batch coderef gets a pipeline ctx';
    ok $batch->_context_active, 'the pipeline context is active DURING the batch';
    # RS async DURING the batch is pinned/batched
    return $schema->resultset('Artist')->with_context($batch)->all_async;
  })->get;

  ok !$seen_batch->_context_active,
    'the pipeline context is invalidated once the batch coderef returns';

  my ($sel) = captured_matching($backend, qr/FROM "artist"/);
  ok $sel->{pinned}, 'the in-batch all_async was pinned onto the bracketed connection';

  throws_ok {
    $schema->resultset('Artist')->with_context($seen_batch)->all_async
  } qr/no longer active/,
    'a bound RS used AFTER the batch throws loudly (does not silently hit the pool)';

  # A row/column bound to the same dead context refuses just as loudly.
  my $rs = $schema->resultset('Artist');
  throws_ok { $rs->with_context($seen_batch)->get_column('artistid')->all_async }
    qr/no longer active/, 'a bound ResultSetColumn refuses on a dead pipeline context too';
}

# ---------------------------------------------------------------------------
# Consequence 4: an operation not expressible as a single pinned statement
# must REFUSE (named) rather than silently run the synchronous fallback, which
# would execute outside the pinned transaction.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();

  # create with a has_many multi-create -> Row::insert_async's related-object
  # punt. On a bound context that punt must refuse, not run sync outside the txn.
  throws_ok {
    $backend->txn_do_async(sub {
      my ($ctx) = @_;
      return $schema->resultset('Artist')->with_context($ctx)->create_async({
        name => 'Ornette Coleman',
        cds  => [ { title => 'The Shape of Jazz to Come', year => 1959 } ],
      });
    })->get;
  } qr/cannot run on a bound async context/,
    'a related-object multi-create refuses on a bound context (consequence 4)';

  # And the very same create WITHOUT a bound context still degrades to the sync
  # path and succeeds -- consequence 4 only fires under a context.
  my ($schema2, $backend2) = wired_schema();
  # sync multi-create runs through the underlying sync mock storage
  $schema2->storage->set_auto_increment('artist', 77);
  my $unbound = $schema2->resultset('Artist')->create_async({
    name => 'Ornette Coleman',
    cds  => [ { title => 'The Shape of Jazz to Come', year => 1959 } ],
  });
  ok $unbound->is_ready, 'the same multi-create WITHOUT a context still runs (sync degrade)';
  my $orow = $unbound->get;
  isa_ok $orow, 'DBIO::Test::Schema::Artist', 'unbound multi-create resolved a Row';
}

# ---------------------------------------------------------------------------
# Generation ownership: class/shape equality does not let a context from one
# storage instance bind to ORM objects from another. Keep B live so the refusal
# cannot be explained by the active-context guard.
# ---------------------------------------------------------------------------
{
  my ($schema_a, $backend_a) = wired_schema();
  my ($schema_b, $backend_b) = wired_schema();
  my ($ctx_b, $gate_b);
  $gate_b = DBIO::Test::Future->new;
  my $txn_b = $backend_b->txn_do_async(sub {
    ($ctx_b) = @_;
    return $gate_b;
  });

  ok $ctx_b->_context_active,
    'foreign transaction context remains active while its callback is pending';

  my $rs_a  = $schema_a->resultset('Artist');
  my $row_a = $rs_a->new_result({ artistid => 1, name => 'A' });
  my $rsc_a = $rs_a->get_column('artistid');
  for my $case (
    [ ResultSet       => $rs_a  ],
    [ Row             => $row_a ],
    [ ResultSetColumn => $rsc_a ],
  ) {
    my ($kind, $object) = @$case;
    throws_ok { $object->with_context($ctx_b) }
      qr/does not belong to this storage generation/,
      "foreign context is rejected before binding to $kind";
  }

  is scalar @{ $backend_a->{captured} }, 0,
    'storage A ran no query while foreign binding was refused';
  is scalar @{ $backend_b->{captured} }, 1,
    'storage B contains only its BEGIN while foreign binding was refused';

  # Bypass every with_context entry point. Each dispatcher must independently
  # reject the foreign slot rather than sending A's SQL over B's connection.
  my $manual_rs = $rs_a->search_rs;
  $manual_rs->{_async_context} = $ctx_b;
  throws_ok { $manual_rs->all_async }
    qr/does not belong to this storage generation/,
    'ResultSet dispatch revalidates a manually injected foreign context';

  my $manual_row = bless { %$row_a }, ref $row_a;
  $manual_row->{_async_context} = $ctx_b;
  throws_ok { $manual_row->update_async({ name => 'Foreign update' }) }
    qr/does not belong to this storage generation/,
    'Row dispatch revalidates a manually injected foreign context';

  my $manual_rsc = bless { %$rsc_a }, ref $rsc_a;
  $manual_rsc->{_async_context} = $ctx_b;
  throws_ok { $manual_rsc->all_async }
    qr/does not belong to this storage generation/,
    'ResultSetColumn dispatch revalidates a manually injected foreign context';

  is scalar @{ $backend_a->{captured} }, 0,
    'manual foreign slots dispatch no query through storage A';
  is scalar @{ $backend_b->{captured} }, 1,
    'manual foreign slots leave storage B with only its BEGIN';

  $gate_b->fail('foreign-context cleanup');
  ok $txn_b->is_failed, 'foreign-context witness transaction was cleaned up';
}

# ---------------------------------------------------------------------------
# The matching generation remains usable while its transaction is active.
# ---------------------------------------------------------------------------
{
  my ($schema_a, $backend_a) = wired_schema();
  my ($ctx_a, $gate_a);
  $gate_a = DBIO::Test::Future->new;
  my $txn_a = $backend_a->txn_do_async(sub {
    ($ctx_a) = @_;
    return $gate_a;
  });

  my ($bound, $same_future);
  lives_ok {
    $bound = $schema_a->resultset('Artist')->with_context($ctx_a);
    $same_future = $bound->all_async;
  } 'same-generation transaction context is accepted';
  ok $same_future && $same_future->is_ready,
    'same-generation query completed on the fake transport';
  my ($same_select) = captured_matching($backend_a, qr/FROM "artist"/);
  ok $same_select && $same_select->{pinned},
    'same-generation query stayed on the pinned connection';
  is $same_select ? $same_select->{conn} : undef, 'CONN',
    'same-generation query used its transaction connection';

  $gate_a->fail('same-context cleanup');
  ok $txn_a->is_failed, 'same-context witness transaction was cleaned up';
}

# ---------------------------------------------------------------------------
# Shape alone is insufficient: external contexts without Core's ownership
# evidence fail closed even though they implement select_async.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  throws_ok {
    $schema->resultset('Artist')->with_context(Test::TokenlessContext->new)
  } qr/ownership cannot be proven/,
    'external context without Core ownership proof is rejected';
  is scalar @{ $backend->{captured} }, 0,
    'tokenless context is rejected before query dispatch';
}

# ---------------------------------------------------------------------------
# Reapplying the exact raw DBI connect_info rebuilds the lazy async backend.
# A ResultSet bound before that rebuild must not dispatch through its old
# backend generation afterwards.
# ---------------------------------------------------------------------------
{
  my $rebuild_schema = DBIO::Test->init_schema;
  my $rebuild_storage = $rebuild_schema->storage;
  $rebuild_storage->connect_info([
    sub { },
    { async => 'with_ctx_backend' },
  ]);
  my $old_backend = $rebuild_storage->_async_storage;
  my $old_ctx_class = $old_backend->_txn_context_class;
  my $old_ctx = $old_ctx_class->new(
    storage  => $old_backend,
    txn_conn => 'OLD_CONN',
  );
  my $bound_to_old_ctx =
    $rebuild_schema->resultset('Artist')->with_context($old_ctx);

  my $connect_info = $rebuild_storage->connect_info;
  $rebuild_storage->connect_info($connect_info);
  my $new_backend = $rebuild_storage->_async_storage;
  isnt Scalar::Util::refaddr($new_backend), Scalar::Util::refaddr($old_backend),
    'connect_info rebuild creates a new backend generation';

  my $old_query_count = scalar @{ $old_backend->{captured} };
  throws_ok { $bound_to_old_ctx->all_async }
    qr/does not belong to this storage generation/,
    'old context is refused after connect_info rebuild';
  is scalar @{ $old_backend->{captured} }, $old_query_count,
    'stale pre-rebuild context dispatched no query through its old backend';
  is scalar @{ $new_backend->{captured} }, 0,
    'stale pre-rebuild context dispatched no query through the new backend';

  # The detached old backend still has a weak owner backlink. Rotating it after
  # the DBI storage has installed a replacement must not overwrite the owner's
  # replacement-generation token.
  my $new_ctx_class = $new_backend->_txn_context_class;
  my $new_ctx = $new_ctx_class->new(
    storage  => $new_backend,
    txn_conn => 'NEW_CONN',
  );
  my $new_owner_token = $rebuild_storage->_async_context_owner_token;
  $old_backend->disconnect;
  is Scalar::Util::refaddr($rebuild_storage->_async_context_owner_token),
    Scalar::Util::refaddr($new_owner_token),
    'detached old backend rotation does not overwrite the owner token';
  is Scalar::Util::refaddr($rebuild_storage->_async_context_owner_token),
    Scalar::Util::refaddr($new_backend->_context_owner_token),
    'owner token still identifies the replacement backend generation';
  isnt Scalar::Util::refaddr($rebuild_storage->_async_context_owner_token),
    Scalar::Util::refaddr($old_backend->_context_owner_token),
    'detached backend keeps its newly rotated token to itself';

  my $new_ctx_future;
  lives_ok {
    $new_ctx_future = $new_ctx->select_async('artist', [ 'artistid' ], {}, {});
  } 'replacement-backend context remains valid after detached backend rotation';
  ok $new_ctx_future && $new_ctx_future->is_ready,
    'replacement-backend direct query completes';
  my ($new_ctx_select) = captured_matching($new_backend, qr/FROM "artist"/);
  ok $new_ctx_select && $new_ctx_select->{pinned},
    'replacement context dispatches through the replacement backend';
  is $new_ctx_select ? $new_ctx_select->{conn} : undef, 'NEW_CONN',
    'replacement context retains its own pinned connection';
  is scalar @{ $old_backend->{captured} }, $old_query_count,
    'detached backend rotation and replacement-context query leave old capture unchanged';
}

# ---------------------------------------------------------------------------
# Disconnecting the owning DBI storage detaches its async backend generation.
# Both a previously bound ResultSet and direct Core-context CRUD must refuse
# before the detached backend sees another query.
# ---------------------------------------------------------------------------
{
  my $schema = DBIO::Test->init_schema;
  my $storage = $schema->storage;
  $storage->connect_info([
    sub { },
    { async => 'with_ctx_backend' },
  ]);
  my $backend = $storage->_async_storage;
  my $ctx_class = $backend->_txn_context_class;
  my $old_ctx = $ctx_class->new(
    storage  => $backend,
    txn_conn => 'OLD_DBI_CONN',
  );
  my $bound = $schema->resultset('Artist')->with_context($old_ctx);
  my $captured_before = scalar @{ $backend->{captured} };

  $storage->disconnect;
  throws_ok { $bound->all_async }
    qr/does not belong to this storage generation/,
    'bound context is stale after owning DBI storage disconnect';
  throws_ok {
    $old_ctx->select_async('artist', [ 'artistid' ], {}, {});
  } qr/does not belong to this storage generation/,
    'direct Core context is stale after owning DBI storage disconnect';
  is scalar @{ $backend->{captured} }, $captured_before,
    'DBI-disconnect stale contexts dispatch no query through detached backend';
}

# ---------------------------------------------------------------------------
# Async connect_info rotates ownership even when its pool has never been
# materialized. An old direct context refuses; a context from the new generation
# remains usable.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  ok !$backend->{pool},
    'direct connect_info witness starts without a materialized async pool';
  my $ctx_class = $backend->_txn_context_class;
  my $old_ctx = $ctx_class->new(
    storage  => $backend,
    txn_conn => 'PRE_CONNECT_INFO_CONN',
  );
  my $old_token = $backend->_context_owner_token;
  my $captured_before = scalar @{ $backend->{captured} };

  $backend->connect_info([ sub { }, {} ]);
  ok !$backend->{pool},
    'direct connect_info rotates without materializing an async pool';
  isnt Scalar::Util::refaddr($backend->_context_owner_token),
    Scalar::Util::refaddr($old_token),
    'direct connect_info rotates the backend generation token without a pool';
  is Scalar::Util::refaddr($schema->storage->_async_context_owner_token),
    Scalar::Util::refaddr($backend->_context_owner_token),
    'direct connect_info mirrors the rotated token to the current owner';
  throws_ok {
    $old_ctx->select_async('artist', [ 'artistid' ], {}, {});
  } qr/does not belong to this storage generation/,
    'pre-connect_info direct context is stale without a prior pool';
  is scalar @{ $backend->{captured} }, $captured_before,
    'pre-connect_info direct context is refused before pinned dispatch';

  my $new_ctx = $ctx_class->new(
    storage  => $backend,
    txn_conn => 'POST_CONNECT_INFO_CONN',
  );
  my $new_future;
  lives_ok {
    $new_future = $new_ctx->select_async('artist', [ 'artistid' ], {}, {});
  } 'post-connect_info context is valid without a materialized pool';
  ok $new_future && $new_future->is_ready,
    'post-connect_info direct query completes';
}

# ---------------------------------------------------------------------------
# Async disconnect also rotates ownership when no pool exists. Exercise both
# direct Core context kinds while they are still active, so only generation
# ownership can explain the refusal.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  ok !$backend->{pool},
    'direct disconnect witness starts without a materialized async pool';
  my $txn_ctx_class = $backend->_txn_context_class;
  my $old_txn_ctx = $txn_ctx_class->new(
    storage  => $backend,
    txn_conn => 'PRE_DISCONNECT_TXN_CONN',
  );
  my $pipeline_ctx_class = $backend->_pipeline_context_class;
  my $old_pipeline_ctx = $pipeline_ctx_class->new(
    storage       => $backend,
    pipeline_conn => 'PRE_DISCONNECT_PIPELINE_CONN',
  );
  ok $old_pipeline_ctx->_context_active,
    'pipeline context is active before no-pool disconnect rotation';
  my $old_token = $backend->_context_owner_token;
  my $captured_before = scalar @{ $backend->{captured} };

  $backend->disconnect;
  ok !$backend->{pool},
    'direct disconnect rotates without creating an async pool';
  isnt Scalar::Util::refaddr($backend->_context_owner_token),
    Scalar::Util::refaddr($old_token),
    'direct disconnect rotates the backend generation token without a pool';
  is Scalar::Util::refaddr($schema->storage->_async_context_owner_token),
    Scalar::Util::refaddr($backend->_context_owner_token),
    'direct disconnect mirrors the rotated token to the current owner';
  throws_ok {
    $old_txn_ctx->select_async('artist', [ 'artistid' ], {}, {});
  } qr/does not belong to this storage generation/,
    'pre-disconnect transaction context is stale without a prior pool';
  throws_ok {
    $old_pipeline_ctx->select_async('artist', [ 'artistid' ], {}, {});
  } qr/does not belong to this storage generation/,
    'pre-disconnect active PipelineContext is stale after rotation';
  is scalar @{ $backend->{captured} }, $captured_before,
    'no-pool disconnect stale contexts are refused before pinned dispatch';

  my $new_ctx = $txn_ctx_class->new(
    storage  => $backend,
    txn_conn => 'POST_DISCONNECT_CONN',
  );
  my $new_future;
  lives_ok {
    $new_future = $new_ctx->select_async('artist', [ 'artistid' ], {}, {});
  } 'post-disconnect context is valid without a materialized pool';
  ok $new_future && $new_future->is_ready,
    'post-disconnect direct query completes';
}

# ---------------------------------------------------------------------------
# A direct disconnect rotates the pool generation even though the backend
# object itself survives. The context must retain its old-generation snapshot.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  my $old_pool = $backend->pool;
  my $ctx_class = $backend->_txn_context_class;
  my $old_ctx = $ctx_class->new(
    storage  => $backend,
    txn_conn => 'OLD_CONN',
  );

  $backend->disconnect;
  my $new_pool = $backend->pool;
  isnt Scalar::Util::refaddr($new_pool), Scalar::Util::refaddr($old_pool),
    'direct backend disconnect creates a new pool generation';

  my $captured_before = scalar @{ $backend->{captured} };
  throws_ok {
    $schema->resultset('Artist')->with_context($old_ctx);
  } qr/does not belong to this storage generation/,
    'context snapshots the old pool generation when backend object survives';
  is scalar @{ $backend->{captured} }, $captured_before,
    'old pool-generation context is rejected before binding dispatch';

  throws_ok {
    $old_ctx->select_async('artist', [ 'artistid' ], {}, {});
  } qr/does not belong to this storage generation/,
    'direct Core context refuses the old pool generation';
  is scalar @{ $backend->{captured} }, $captured_before,
    'stale direct Core context is refused before pinned query dispatch';
}

# ---------------------------------------------------------------------------
# with_context input validation.
# ---------------------------------------------------------------------------
{
  my ($schema) = wired_schema();
  my $rs = $schema->resultset('Artist');
  throws_ok { $rs->with_context(undef) } qr/with_context requires an async context/,
    'with_context(undef) is rejected';
  throws_ok { $rs->with_context('not an object') } qr/with_context requires an async context/,
    'with_context on a non-object is rejected';
  throws_ok { $rs->with_context( bless {}, 'Some::Random::Class' ) }
    qr/with_context requires an async context/,
    'with_context on an object without select_async is rejected';
}

done_testing;
