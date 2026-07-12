use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util 'blessed';

use DBIO::Test;
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::Async::TransactionContext;

# ADR 0030 §4: the loop-agnostic Model-B orchestration is CONCRETE in core
# DBIO::Storage::Async (connect-info normalisation, _run_crud + pooled/pinned
# runners, INSERT returned-columns mapping, txn_do_async + the generic
# TransactionContext, the pipeline scaffold). A transport backend overrides
# only the seam hooks. This test drives that orchestration through a fake,
# fully-synchronous transport -- no event loop, no real database.

# --- A synchronous, contract-compliant Future ------------------------------
# The orchestration sequences work through the backend's future_class and
# relies on real DBIO::Future chaining semantics: ->then flattens a returned
# Future and (its 2-arg form) routes a failure to the on_fail branch without
# catching a failure raised inside on_done. CPAN Future provides this; this
# in-file shim provides the same, synchronously, with no dependency.
{
  package Test::SyncFuture;

  sub done { my $c = shift; bless { failed => 0, result => [@_] }, ref($c) || $c }
  sub fail { my ($c, $e) = @_; bless { failed => 1, error => $e, result => [] }, ref($c) || $c }

  sub is_ready  { 1 }
  sub is_failed { $_[0]->{failed} ? 1 : 0 }

  sub get {
    my $self = shift;
    die $self->{error} if $self->{failed};
    return wantarray ? @{ $self->{result} } : $self->{result}[0];
  }

  sub then {
    my ($self, $on_done, $on_fail) = @_;
    if ($self->{failed}) {
      return $self unless $on_fail;
      return _dispatch($on_fail, $self->{error});
    }
    return _dispatch($on_done, @{ $self->{result} });
  }

  sub catch {
    my ($self, $on_fail) = @_;
    return $self unless $self->{failed};
    return _dispatch($on_fail, $self->{error});
  }

  # Run a continuation and normalise its return: a raised exception becomes a
  # failed Future, a single returned Future is passed through (flattened),
  # anything else is wrapped in an immediately-resolved Future.
  sub _dispatch {
    my ($cb, @args) = @_;
    my @r = eval { $cb->(@args) };
    return __PACKAGE__->fail($@) if $@;
    return $r[0]
      if @r == 1 && Scalar::Util::blessed($r[0]) && $r[0]->isa(__PACKAGE__);
    return __PACKAGE__->done(@r);
  }
}

# --- A fake pool ------------------------------------------------------------
# acquire / acquire_txn hand out a single fake connection wrapped in a Future;
# release/shutdown just record. Enough for the orchestration to bracket a txn
# and a pipeline.
{
  package Test::SyncPool;

  sub new { bless { released => [], available => 1 }, shift }
  sub acquire     { Test::SyncFuture->done('CONN') }
  sub acquire_txn { Test::SyncFuture->done('CONN') }
  sub release     { push @{ $_[0]->{released} }, $_[1]; 1 }
  sub available   { $_[0]->{available} }
  sub shutdown    { $_[0]->{available} = 0 }
}

# --- The fake transport backend --------------------------------------------
# A concrete DBIO::Storage::Async that overrides ONLY the seam hooks, all
# resolving immediately. Every query the orchestration emits is captured, and
# the rows the transport "returns" are settable per call via {next_rows}.
{
  package Test::SyncBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured}  = [];
    $self->{next_rows} = [];
    return $self;
  }

  # seam: Future implementation
  sub future_class { 'Test::SyncFuture' }

  # seam: SQL maker
  sub sql_maker_class { 'DBIO::SQLMaker' }
  sub _sql_maker_args { (quote_char => '"', name_sep => '.') }

  # seam: SQL shaping (identity transform, PG-style RETURNING)
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }

  # seam: pool
  sub pool { $_[0]->{pool} ||= Test::SyncPool->new }

  # seam: query transport -- capture and resolve immediately
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

  # seam: pipeline bracketing
  sub _pipeline_enter { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_ENTER' }; 1 }
  sub _pipeline_exit  { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_EXIT'  }; 1 }
  sub _pipeline_sync  { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_SYNC'  }; $_[0]->future_class->done }

  # test helper
  sub _last_sql { $_[0]->{captured}[-1]{sql} }
}

sub new_backend {
  my $schema = DBIO::Test->init_schema;
  # keep the schema alive for the caller (backend weakens its ref)
  my $backend = Test::SyncBackend->new($schema);
  return ($backend, $schema);
}

# ---------------------------------------------------------------------------
# connect_info normalization
# ---------------------------------------------------------------------------
{
  my ($backend) = new_backend();

  my $ci = [ { host => 'localhost', dbname => 'test', pool_size => 3 }, { RaiseError => 1 } ];
  is_deeply $backend->connect_info($ci), $ci,
    'connect_info returns the stored raw connect info';

  is $backend->{_pool_size}, 3, 'pool_size extracted from conninfo';
  is_deeply $backend->{_conninfo}, { host => 'localhost', dbname => 'test' },
    'conninfo copied with pool_size stripped';
  is_deeply $backend->{_opts}, { RaiseError => 1 }, 'opts copied through';
  is_deeply $ci->[0], { host => 'localhost', dbname => 'test', pool_size => 3 },
    'caller conninfo untouched (normalization works on a copy)';

  # default pool size + default opts
  my ($b2) = new_backend();
  $b2->connect_info([ { host => 'h' } ]);
  is $b2->{_pool_size}, 5, 'pool_size defaults to 5';
  is_deeply $b2->{_opts}, {}, 'opts default to empty hash';

  # _normalize_conninfo is an identity seam by default
  my $raw = [ { host => 'h' }, {} ];
  is $backend->_normalize_conninfo($raw), $raw,
    '_normalize_conninfo defaults to identity pass-through';
}

# ---------------------------------------------------------------------------
# _run_crud: select / select_single (via the pooled runner)
# ---------------------------------------------------------------------------
{
  my ($backend) = new_backend();

  $backend->{next_rows} = [ [ 1, 'Miles Davis' ], [ 2, 'John Coltrane' ] ];
  my $f = $backend->select_async('artist', [ 'artistid', 'name' ], { name => { -like => '%' } });
  isa_ok $f, 'Test::SyncFuture', 'select_async returns a Future';
  is_deeply [ $f->get ], [ [ 1, 'Miles Davis' ], [ 2, 'John Coltrane' ] ],
    'select_async resolves with the raw result rows';
  like $backend->_last_sql, qr/^SELECT .*FROM "artist"/,
    'select_async emitted real maker SQL for the artist table';

  # select_single resolves with only the first row
  $backend->{next_rows} = [ [ 1, 'Miles Davis' ], [ 2, 'John Coltrane' ] ];
  my $sf = $backend->select_single_async('artist', [ 'artistid', 'name' ], {});
  is_deeply scalar $sf->get, [ 1, 'Miles Davis' ],
    'select_single_async resolves with only the first row';

  # select_single on no rows resolves with undef
  $backend->{next_rows} = [];
  my $ef = $backend->select_single_async('artist', [ 'artistid' ], {});
  is scalar $ef->get, undef, 'select_single_async resolves undef when no rows';
}

# ---------------------------------------------------------------------------
# _run_crud: update / delete
# ---------------------------------------------------------------------------
{
  my ($backend) = new_backend();

  $backend->{next_rows} = [];
  my $uf = $backend->update_async('artist', { name => 'X' }, { artistid => 1 });
  isa_ok $uf, 'Test::SyncFuture', 'update_async returns a Future';
  ok $uf->is_ready, 'update_async resolves';
  like $backend->_last_sql, qr/^UPDATE "artist" SET/, 'update_async emitted UPDATE SQL';
  is_deeply $backend->{captured}[-1]{bind}, [ 'X', 1 ], 'update bind values captured';

  my $df = $backend->delete_async('artist', { artistid => 1 });
  ok $df->is_ready, 'delete_async resolves';
  like $backend->_last_sql, qr/^DELETE FROM "artist"/, 'delete_async emitted DELETE SQL';
}

# ---------------------------------------------------------------------------
# _run_crud: insert -- source->name unwrap, _post_insert_sql, returned-columns
#   (decision b: sm->insert directly + seams; decision c: both mapping seams)
# ---------------------------------------------------------------------------
{
  my ($backend, $schema) = new_backend();
  my $source = $schema->source('Artist');    # ->name = 'artist', ->columns ordered

  # HASH row: the transport returns a column=>value hashref, used as-is over
  # the supplied insert data.
  $backend->{next_rows} = [ { artistid => 10, name => 'Miles Davis', rank => 13 } ];
  my $hf = $backend->insert_async($source, { name => 'Miles Davis' });
  isa_ok $hf, 'Test::SyncFuture', 'insert_async returns a Future';
  is_deeply scalar $hf->get,
    { artistid => 10, name => 'Miles Davis', rank => 13 },
    'insert_async maps a HASH RETURNING row onto the insert data';

  my $insert_sql = $backend->{captured}[-1]{sql};
  like $insert_sql, qr/^INSERT INTO "artist"/, 'insert unwrapped the blessed source to its ->name';
  like $insert_sql, qr/ RETURNING \*$/, '_post_insert_sql appended RETURNING to the INSERT';

  # ARRAY row: positional RETURNING * zipped against the source's declared
  # column order (artistid, name, rank, charfield).
  $backend->{next_rows} = [ [ 7, 'John Coltrane', 8, undef ] ];
  my $af = $backend->insert_async($source, { name => 'John Coltrane' });
  is_deeply scalar $af->get,
    { artistid => 7, name => 'John Coltrane', rank => 8, charfield => undef },
    'insert_async zips a positional ARRAY RETURNING row via _returning_columns';

  # Positional row whose arity does not match the column list is left as the
  # supplied insert data (no partial/garbled mapping).
  $backend->{next_rows} = [ [ 7, 'x' ] ];    # 2 values, 4 columns
  my $mf = $backend->insert_async($source, { name => 'mismatch' });
  is_deeply scalar $mf->get, { name => 'mismatch' },
    'a mismatched positional row leaves the insert data unmapped';

  # No returned row at all -> just the supplied insert data.
  $backend->{next_rows} = [];
  my $nf = $backend->insert_async($source, { name => 'norow' });
  is_deeply scalar $nf->get, { name => 'norow' },
    'insert_async with no RETURNING row resolves the supplied insert data';
}

# ---------------------------------------------------------------------------
# _returning_columns default = the source's declared column order
# ---------------------------------------------------------------------------
{
  my ($backend, $schema) = new_backend();
  my $source = $schema->source('Artist');
  is_deeply [ $backend->_returning_columns($source) ],
    [ $source->columns ],
    '_returning_columns defaults to the source declared column order';
  is_deeply [ $backend->_returning_columns('bare_string') ], [],
    '_returning_columns is empty for a non-source table name';
}

# ---------------------------------------------------------------------------
# txn_do_async: commit path + pinned CRUD through the generic TransactionContext
# ---------------------------------------------------------------------------
{
  my ($backend) = new_backend();

  # A coderef returning a plain value commits immediately.
  my $cf = $backend->txn_do_async(sub { return 'committed' });
  isa_ok $cf, 'Test::SyncFuture', 'txn_do_async returns a Future';
  is scalar $cf->get, 'committed', 'txn_do_async commit resolves with the coderef result';
  is_deeply [ map { $_->{sql} } @{ $backend->{captured} } ], [ 'BEGIN', 'COMMIT' ],
    'commit path pinned BEGIN then COMMIT on the txn connection';
  ok $backend->{captured}[0]{pinned}, 'BEGIN ran on the pinned connection';
  is $backend->{pool}{released}[0], 'CONN', 'txn connection released after COMMIT';

  # CRUD inside the txn runs on the pinned connection via the generic
  # DBIO::Storage::Async::TransactionContext (decision: default txn ctx class).
  my ($b2) = new_backend();
  $b2->{next_rows} = [ [ 1, 'Miles Davis' ] ];
  my $tf = $b2->txn_do_async(sub {
    my ($ctx) = @_;
    isa_ok $ctx, 'DBIO::Storage::Async::TransactionContext', 'coderef gets the generic txn context';
    ok $ctx->in_txn, 'txn context reports in_txn';
    return $ctx->select_async('artist', [ 'artistid', 'name' ], {});
  });
  is_deeply [ $tf->get ], [ [ 1, 'Miles Davis' ] ],
    'a Future-returning coderef commits and resolves with its result';
  is_deeply [ map { $_->{sql} } @{ $b2->{captured} } ],
    [ 'BEGIN', 'SELECT "artistid", "name" FROM "artist"', 'COMMIT' ],
    'pinned SELECT ran between BEGIN and COMMIT on one connection';
  ok !( grep { !$_->{pinned} } @{ $b2->{captured} } ),
    'every query inside the txn was pinned';
  is scalar( grep { $_->{conn} eq 'CONN' } @{ $b2->{captured} } ), 3,
    'BEGIN, SELECT and COMMIT all ran on the same pinned connection';
}

# ---------------------------------------------------------------------------
# txn_do_async: rollback paths (coderef dies; coderef Future fails)
# ---------------------------------------------------------------------------
{
  my ($backend) = new_backend();

  # Coderef dies before returning a Future -> ROLLBACK, failure propagates.
  my $rf = $backend->txn_do_async(sub { die "boom\n" });
  ok $rf->is_failed, 'txn_do_async rolls back and fails when the coderef dies';
  throws_ok { $rf->get } qr/boom/, 'the coderef error propagates through the Future';
  is_deeply [ map { $_->{sql} } @{ $backend->{captured} } ], [ 'BEGIN', 'ROLLBACK' ],
    'die path issued BEGIN then ROLLBACK';
  is $backend->{pool}{released}[0], 'CONN', 'connection released after ROLLBACK';

  # Coderef returns a failed Future -> ROLLBACK, failure propagates.
  my ($b2) = new_backend();
  my $ff = $b2->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->storage->future_class->fail("query blew up\n");
  });
  ok $ff->is_failed, 'txn_do_async rolls back when the coderef Future fails';
  throws_ok { $ff->get } qr/query blew up/, 'the failed-Future error propagates';
  is_deeply [ map { $_->{sql} } @{ $b2->{captured} } ], [ 'BEGIN', 'ROLLBACK' ],
    'failed-Future path issued BEGIN then ROLLBACK';
}

# ---------------------------------------------------------------------------
# pipeline scaffold (newly concrete in core)
# ---------------------------------------------------------------------------
{
  my ($backend) = new_backend();

  # Coderef returns a plain value.
  my $pf = $backend->pipeline(sub { return 'batched' });
  is scalar $pf->get, 'batched', 'pipeline resolves with a plain coderef result';
  is_deeply [ map { $_->{sql} } @{ $backend->{captured} } ],
    [ 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT' ],
    'pipeline bracketed the batch: enter, sync, exit';
  is $backend->{pool}{released}[0], 'CONN', 'pipeline connection released';

  # Coderef returns a Future -> passed straight through after sync.
  my ($b2) = new_backend();
  my $pf2 = $b2->pipeline(sub { return Test::SyncFuture->done('fut-batched') });
  is scalar $pf2->get, 'fut-batched', 'pipeline passes a Future-returning coderef through';

  # Coderef dies -> exit + release, failure propagates.
  my ($b3) = new_backend();
  my $pf3 = $b3->pipeline(sub { die "pipe boom\n" });
  ok $pf3->is_failed, 'pipeline fails when the coderef dies';
  is_deeply [ map { $_->{sql} } @{ $b3->{captured} } ],
    [ 'PIPELINE_ENTER', 'PIPELINE_EXIT' ],
    'a dying pipeline coderef still runs exit (no sync)';
  is $b3->{pool}{released}[0], 'CONN', 'pipeline connection released on failure';
}

# ---------------------------------------------------------------------------
# sync fallbacks + schema integration
# ---------------------------------------------------------------------------
{
  my ($backend, $schema) = new_backend();

  $backend->{next_rows} = [ [ 1, 'Miles Davis' ] ];
  is_deeply [ $backend->select('artist', [ 'artistid', 'name' ], {}) ],
    [ [ 1, 'Miles Davis' ] ],
    'sync select() blocks on the async result via ->get';

  is $backend->schema, $schema, 'schema accessor returns the schema';
  is $backend->in_txn, 0, 'in_txn is false on the storage itself';
  ok !$backend->connected, 'connected is false with no pool built';

  $backend->pool;    # build the pool
  ok $backend->connected, 'connected is true once the pool is available';
  $backend->disconnect;
  ok !$backend->{pool}, 'disconnect tears the pool down';
}

done_testing;
