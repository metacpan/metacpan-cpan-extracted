use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::Async::TransactionContext;

# ADR 0030 §4: the loop-agnostic Model-B orchestration is CONCRETE in core
# DBIO::Storage::Async (connect-info normalisation, _run_crud + pooled/pinned
# runners, INSERT returned-columns mapping, txn_do_async + the generic
# TransactionContext, the pipeline scaffold). A transport backend overrides
# only the seam hooks. This test drives that orchestration through a fake,
# fully-synchronous transport -- no event loop, no real database. Queries resolve
# immediately unless a test explicitly selects a failure or synchronous throw seam.

# --- A fake pool ------------------------------------------------------------
# acquire / acquire_txn hand out a single fake connection wrapped in a Future;
# release/shutdown just record. Enough for the orchestration to bracket a txn
# and a pipeline.
{
  package Test::SyncPool;

  sub new {
    my ($class, %args) = @_;
    return bless {
      released          => [],
      available         => 1,
      acquire_txn_count => 0,
      %args,
    }, $class;
  }

  sub future_class { $_[0]->{future_class} || 'DBIO::Test::Future' }

  sub acquire {
    my ($self) = @_;
    return $self->future_class->done('CONN');
  }

  sub acquire_txn {
    my ($self) = @_;
    $self->{acquire_txn_count}++;
    return $self->future_class->fail($self->{acquire_error})
      if defined $self->{acquire_error};
    return $self->future_class->done('CONN');
  }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{released} }, $conn;
    $self->{on_release}->($self, $conn) if $self->{on_release};
    return 1;
  }

  sub available { $_[0]->{available} }
  sub shutdown  { $_[0]->{available} = 0 }
}

# --- The fake transport backend --------------------------------------------
# A concrete DBIO::Storage::Async that overrides ONLY the seam hooks, all
# resolving immediately. Every query the orchestration emits is captured, and
# the rows the transport "returns" are settable per call via {next_rows}.
{
  package Test::SyncBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema, %opt) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured} = [];
    $self->{next_rows} = [];
    $self->{fail_on} = $opt{fail_on};
    $self->{throw_on} = $opt{throw_on};
    $self->{acquire_error} = $opt{acquire_error};
    $self->{on_release} = $opt{on_release};
    $self->{txn_context_class} = $opt{txn_context_class};
    $self->{txn_contexts} = [];
    $self->{release_context_states} = [];
    return $self;
  }

  # seam: Future implementation
  sub future_class { 'DBIO::Test::Future' }

  # seam: SQL maker
  sub sql_maker_class { 'DBIO::SQLMaker' }
  sub _sql_maker_args { (quote_char => '"', name_sep => '.') }

  # seam: SQL shaping (identity transform, PG-style RETURNING)
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }

  # seam: pool
  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= Test::SyncPool->new(
      future_class  => $self->future_class,
      acquire_error => $self->{acquire_error},
      on_release    => sub {
        my ($pool, $conn) = @_;
        push @{ $self->{release_context_states} },
          $self->{txn_contexts}[-1]->_context_active
          if @{ $self->{txn_contexts} };
        $self->{on_release}->($pool, $conn) if $self->{on_release};
        return;
      },
    );
  }

  sub _txn_context_class {
    return $_[0]->{txn_context_class} || 'Test::SyncTransactionContext';
  }

  sub _seam_result {
    my ($self, $sql, $bind) = @_;
    die "synchronous seam throw on $sql\n"
      if $self->{throw_on} && $sql =~ $self->{throw_on};
    return $self->future_class->fail("future failure on $sql\n")
      if $self->{fail_on} && $sql =~ $self->{fail_on};
    my @rows = $self->{row_provider}
      ? $self->{row_provider}->($sql, $bind)
      : @{ $self->{next_rows} || [] };
    return $self->future_class->done(@rows);
  }

  # seam: query transport -- capture and resolve immediately
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, pinned => 0 };
    return $self->_seam_result($sql, $bind);
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, pinned => 1, conn => $conn };
    return $self->_seam_result($sql, $bind);
  }

  # seam: pipeline bracketing
  sub _pipeline_enter { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_ENTER' }; 1 }
  sub _pipeline_exit  { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_EXIT'  }; 1 }
  sub _pipeline_sync  { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_SYNC'  }; $_[0]->future_class->done }

  # test helper
  sub _last_sql { $_[0]->{captured}[-1]{sql} }
}

# Retain every context constructed by the real txn_do_async path, including a
# context whose BEGIN fails before the callback can receive it.
{
  package Test::SyncTransactionContext;
  use base 'DBIO::Storage::Async::TransactionContext';

  sub new {
    my ($class, %args) = @_;
    my $ctx = $class->SUPER::new(%args);
    push @{ $args{storage}{txn_contexts} }, $ctx;
    return $ctx;
  }
}

# A custom context class whose constructor is a synchronous post-acquire seam.
{
  package Test::ThrowingTransactionContext;

  sub new { die "transaction context constructor failed\n" }
}

# A deterministic retain observer: no CPAN Future/weak-reference behaviour is
# needed to assert which Future txn_do_async itself asked to retain.
{
  package Test::RetainingFuture;
  use base 'DBIO::Test::Future';

  sub retain {
    my ($self) = @_;
    $self->{retain_count}++;
    return $self;
  }

  sub retain_count { $_[0]->{retain_count} // 0 }
}

{
  package Test::RetainingBackend;
  use parent -norequire, 'Test::SyncBackend';

  sub future_class { 'Test::RetainingFuture' }
}

sub new_backend {
  my (%opt) = @_;
  my $schema = DBIO::Test->init_schema;
  # keep the schema alive for the caller (backend weakens its refs)
  my $backend = Test::SyncBackend->new($schema, %opt);
  my $owner = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
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
  isa_ok $f, 'DBIO::Test::Future', 'select_async returns a Future';
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
# _run_crud: select preparation must preserve rows/offset as SQLMaker's
# separate $limit/$offset positional arguments. The direct cases here pin the
# ordinary SQL shape; the ResultSet-level cases below exercise the owning
# storage's full _select_args preparation and result semantics.
# ---------------------------------------------------------------------------
{
  my ($backend) = new_backend();

  $backend->{next_rows} = [ [ 1, 'Miles Davis' ], [ 2, 'John Coltrane' ], [ 3, 'Sun Ra' ] ];
  my $f = $backend->select_async('artist', [ 'artistid', 'name' ], {}, { rows => 3, offset => 2 });
  ok $f->is_ready, 'select_async with rows/offset attrs resolves';
  like $backend->_last_sql, qr/LIMIT \? OFFSET \?/,
    'select_async forwarded rows/offset from $attrs as SQLMaker LIMIT/OFFSET, not silently dropped';

  # No rows/offset in attrs -> no LIMIT clause at all, matching sync exactly.
  my $nf = $backend->select_async('artist', [ 'artistid', 'name' ], {}, {});
  ok $nf->is_ready, 'select_async with no rows/offset resolves';
  unlike $backend->_last_sql, qr/LIMIT/,
    'select_async emits no LIMIT clause when $attrs carries no rows/offset';

  # software_limit keeps LIMIT out of the SQL so the async orchestration can
  # slice transport rows before ResultSet inflation. Result-level slicing is
  # asserted through the registered backend below.
  my $sf = $backend->select_async('artist', [ 'artistid', 'name' ], {}, { rows => 3, software_limit => 1 });
  ok $sf->is_ready, 'select_async with software_limit resolves';
  unlike $backend->_last_sql, qr/LIMIT/,
    'select_async does not push rows into SQL when software_limit is set, matching sync';

  # select_single gets the same treatment (shares the branch with select).
  my $ssf = $backend->select_single_async('artist', [ 'artistid' ], {}, { rows => 1 });
  ok $ssf->is_ready, 'select_single_async with a rows attr resolves';
  like $backend->_last_sql, qr/LIMIT \?/,
    'select_single_async also forwards rows/offset from $attrs';

  # offset WITHOUT rows: sync's own _select_args normalizes rows to
  # __max_int before pushing @limit_args whenever offset is present alone
  # (`elsif ($attrs->{offset}) { $attrs->{rows} = $sql_maker->__max_int }`),
  # so BOTH end up in the SQL. Pushing only offset (a naive `$attrs->{rows}
  # || (), $attrs->{offset} || ()`) leaves @limit_args with exactly one
  # element, which lands in SQLMaker::select's $limit slot (5th positional
  # arg) -- the offset value is silently bound as a row LIMIT instead of an
  # OFFSET, and no OFFSET is applied at all.
  my $of = $backend->select_async('artist', [ 'artistid' ], {}, { offset => 2 });
  ok $of->is_ready, 'select_async with offset-only attrs resolves';
  like $backend->_last_sql, qr/LIMIT \? OFFSET \?/,
    'select_async normalizes offset-only into LIMIT <max> OFFSET <n>, matching sync -- not offset landing in the LIMIT slot';
}

# ---------------------------------------------------------------------------
# ResultSet-level integration through the registered orchestration backend.
# Unlike the rowmock oracle, every query here exercises _run_crud and the
# owning synchronous storage installed by DBIO::Storage::DBI->_async_storage.
# ---------------------------------------------------------------------------
DBIO::Storage::DBI->register_async_mode( sync_orch_backend => 'Test::SyncBackend' );

sub new_registered_backend {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->_async_mode('sync_orch_backend');
  delete $schema->storage->{_async_storage_obj};
  my $backend = $schema->storage->_async_storage;
  return ($backend, $schema);
}

# ---------------------------------------------------------------------------
# software_limit applies rows/offset to transport rows before ORM inflation.
# ---------------------------------------------------------------------------
{
  my ($backend, $schema) = new_registered_backend();
  isa_ok $backend, 'Test::SyncBackend',
    'the registered mode built the real orchestration backend for this schema';

  $backend->{next_rows} = [
    [ 1, 'Miles Davis',    13, undef ],
    [ 2, 'John Coltrane',  13, undef ],
    [ 3, 'Sun Ra',         13, undef ],
    [ 4, 'Herbie Hancock', 13, undef ],
  ];
  my $rs = $schema->resultset('Artist')->search(undef, {
    rows           => 2,
    offset         => 1,
    software_limit => 1,
    order_by       => 'me.artistid',
  });

  my @artists = $rs->all_async->get;
  is_deeply [ map { $_->artistid } @artists ], [ 2, 3 ],
    'software_limit slices raw rows before inflation';
  unlike $backend->_last_sql, qr/\bLIMIT\b/i,
    'software_limit still suppresses the SQL limit';
}

# ---------------------------------------------------------------------------
# owning _select_args supplies the synchronous rows/offset diagnostics before
# the transport is dispatched.
# ---------------------------------------------------------------------------
{
  my ($backend, $schema) = new_registered_backend();
  my $captured_before = scalar @{ $backend->{captured} };

  throws_ok {
    $backend->select_async('artist', ['artistid'], {}, {
      rows => 0, software_limit => 1,
    });
  } qr/The rows attribute must be a positive integer if present/,
    'software-limit rows validation matches sync';

  throws_ok {
    $backend->select_async('artist', ['artistid'], {}, {
      offset => -1, collapse => 1,
    });
  } qr/A supplied offset attribute must be a non-negative integer/,
    'collapse offset validation matches sync';

  is scalar @{ $backend->{captured} }, $captured_before,
    'invalid select attributes are refused before transport dispatch';
}

# ---------------------------------------------------------------------------
# offset-only ResultSet selects receive the owning SQLMaker's max-int row cap.
# ---------------------------------------------------------------------------
{
  my ($backend, $schema) = new_registered_backend();
  $backend->{next_rows} = [];

  my $offset_rs = $schema->resultset('Artist')->search(undef, {
    offset   => 1,
    order_by => 'me.artistid',
  });
  $offset_rs->all_async->get;

  like $backend->_last_sql, qr/LIMIT \? OFFSET \?/,
    'offset-only select receives the SQLMaker max-int limit';
  is_deeply [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ }
                  @{ $backend->{captured}[-1]{bind} } ],
    [ $schema->storage->sql_maker->__max_int, 1 ],
    'offset-only select binds max-int rows followed by offset';
}

# ---------------------------------------------------------------------------
# owning _select_args performs the canonical complex-prefetch join-pruning
# sequence: prune the inner shape once, then leave the rewritten outer shape.
# ---------------------------------------------------------------------------
{
  my ($backend, $schema) = new_registered_backend();
  my @pruned;
  {
    no warnings 'redefine';
    my $orig = \&DBIO::Storage::QueryRewrite::_prune_unused_joins;
    local *DBIO::Storage::QueryRewrite::_prune_unused_joins = sub {
      my ($self, @args) = @_;
      my ($from, $aliastypes) = $orig->($self, @args);
      push @pruned, (keys %{ $aliastypes || {} }) ? 1 : 0;
      return ($from, $aliastypes);
    };

    $backend->{next_rows} = [];
    $schema->resultset('CD')->search(
      { 'artist.name' => 'x' },
      {
        join     => 'artist',
        prefetch => 'tracks',
        rows     => 2,
        order_by => 'me.cdid',
      },
    )->all_async->get;
  }

  is_deeply \@pruned, [ 1, 0 ],
    'async complex prefetch runs owning-storage join pruning twice in the canonical shape';
}

# ---------------------------------------------------------------------------
# complex prefetch limits parent rows in an inner select without truncating
# the complete child groups returned for those parents.
# ---------------------------------------------------------------------------
{
  my ($backend, $schema) = new_registered_backend();
  my @all_join_rows = (
    [ 1, 'Miles Davis',   13, undef, 10, 1, 'Kind of Blue',       1959, undef, undef ],
    [ 1, 'Miles Davis',   13, undef, 11, 1, 'Bitches Brew',       1970, undef, undef ],
    [ 2, 'John Coltrane', 13, undef, 20, 2, 'A Love Supreme',     1965, undef, undef ],
    [ 3, 'Sun Ra',        13, undef, 30, 3, 'Space Is the Place', 1973, undef, undef ],
  );
  $backend->{row_provider} = sub {
    my ($sql) = @_;
    return $sql =~ /\bLIMIT\b/i
      ? @all_join_rows[0 .. 2]
      : @all_join_rows;
  };

  my $prefetched = $schema->resultset('Artist')->search(undef, {
    prefetch => 'cds',
    rows     => 2,
    order_by => 'me.artistid',
  });
  my @artists = $prefetched->all_async->get;

  is_deeply [ map { $_->artistid } @artists ], [ 1, 2 ],
    'complex prefetch returns two parent rows';
  is_deeply [
    map {
      [ sort { $a <=> $b } map { $_->cdid } $_->cds->all ]
    } @artists
  ], [ [ 10, 11 ], [ 20 ] ],
    'included parents retain every prefetched child';
  like $backend->_last_sql, qr/\bLIMIT\b/i,
    'complex prefetch uses an inner limited select';
}

# ---------------------------------------------------------------------------
# _run_crud: update / delete -- must resolve the affected-row COUNT (a plain
# scalar), not raw row data. The transport (_query_async) is documented to
# resolve "raw result rows", but update/delete have no row data to speak of,
# only a count; a compliant transport's sole resolved value for these ops IS
# that count (Test::SyncBackend's {next_rows} = [1] simulates "1 row
# affected"). DBIO::Row::update_async relies on this to detect "row not
# found" / "updated more than one row" exactly like sync _update_body does --
# see the blessed-source section below for why this matters together with
# the source-unwrap fix.
# ---------------------------------------------------------------------------
{
  my ($backend) = new_backend();

  $backend->{next_rows} = [ 1 ];
  my $uf = $backend->update_async('artist', { name => 'X' }, { artistid => 1 });
  isa_ok $uf, 'DBIO::Test::Future', 'update_async returns a Future';
  ok $uf->is_ready, 'update_async resolves';
  like $backend->_last_sql, qr/^UPDATE "artist" SET/, 'update_async emitted UPDATE SQL';
  is_deeply $backend->{captured}[-1]{bind}, [ 'X', 1 ], 'update bind values captured';
  is scalar $uf->get, 1, 'update_async resolves with the affected-row count, not raw rows';

  my $df = $backend->delete_async('artist', { artistid => 1 });
  ok $df->is_ready, 'delete_async resolves';
  like $backend->_last_sql, qr/^DELETE FROM "artist"/, 'delete_async emitted DELETE SQL';
  is scalar $df->get, 1, 'delete_async resolves with the affected-row count, not raw rows';
}

# ---------------------------------------------------------------------------
# _run_crud: update / delete with a BLESSED ResultSource -- the actual shape
# DBIO::Row::update_async/delete_async pass ($self->result_source, exactly
# like sync Row::update/delete pass to $storage->update/delete). The bare
# string 'artist' used above never exercises this path; SQLMaker's
# update()/delete() need a plain table name, so a blessed source must be
# unwrapped first, exactly like the insert branch already unwraps via
# ->name (see the insert section below).
# ---------------------------------------------------------------------------
{
  my ($backend, $schema) = new_backend();
  my $source = $schema->source('Artist');    # ->name = 'artist'

  $backend->{next_rows} = [ 1 ];
  my $uf = $backend->update_async($source, { name => 'X' }, { artistid => 1 });
  isa_ok $uf, 'DBIO::Test::Future', 'update_async with a blessed source returns a Future';
  ok $uf->is_ready, 'update_async with a blessed source resolves (does not die)';
  like $backend->_last_sql, qr/^UPDATE "artist" SET/,
    'update_async unwrapped the blessed source to its ->name, like insert does';
  is_deeply $backend->{captured}[-1]{bind}, [ 'X', 1 ],
    'update bind values captured correctly with a blessed source';
  is scalar $uf->get, 1,
    'update_async with a blessed source still resolves with the affected-row count';

  my $df = $backend->delete_async($source, { artistid => 1 });
  ok $df->is_ready, 'delete_async with a blessed source resolves (does not die)';
  like $backend->_last_sql, qr/^DELETE FROM "artist"/,
    'delete_async unwrapped the blessed source to its ->name, like insert does';
  is scalar $df->get, 1,
    'delete_async with a blessed source still resolves with the affected-row count';
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
  isa_ok $hf, 'DBIO::Test::Future', 'insert_async returns a Future';
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
  isa_ok $cf, 'DBIO::Test::Future', 'txn_do_async returns a Future';
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
# txn_do_async: terminal contexts are invalidated before their only release.
# Every terminal route after a successful acquire must leave a saved context
# unusable; an acquire failure neither starts SQL nor releases a connection.
# ---------------------------------------------------------------------------
{
  my ($backend, $saved_ctx, $gate);
  ($backend) = new_backend();

  $gate = DBIO::Test::Future->new;
  my $txn = $backend->txn_do_async(sub {
    ($saved_ctx) = @_;
    return $gate;
  });

  ok $saved_ctx->_context_active,
    'context is active while the callback Future is pending';
  ok !$txn->is_ready, 'outer transaction waits for the callback Future';
  is scalar @{ $backend->pool->{released} }, 0,
    'a pending transaction has not released its connection';

  $gate->done('value');
  is scalar $txn->get, 'value', 'transaction preserves the callback result';
  ok !$saved_ctx->_context_active, 'COMMIT invalidates the context';
  ok !$saved_ctx->in_txn, 'COMMIT leaves the context outside a transaction';
  is $backend->{release_context_states}[0], 0,
    'COMMIT invalidates before releasing the connection';
  is scalar @{ $backend->pool->{released} }, 1,
    'successful transaction releases exactly once';

  my $captured_before = scalar @{ $backend->{captured} };
  throws_ok { $saved_ctx->select_async('artist', ['artistid'], {}, {}) }
    qr/no longer active/,
    'direct CRUD rejects a completed transaction context';
  is scalar @{ $backend->{captured} }, $captured_before,
    'expired direct CRUD does not issue another pinned query';

  throws_ok { $saved_ctx->txn_do_async(sub { return 'nested' }) }
    qr/no longer active/,
    'nested transactions reject a completed transaction context';
  is scalar @{ $backend->{captured} }, $captured_before,
    'expired nested transaction does not issue BEGIN on a released connection';
}

{
  my ($backend, $ctx);
  ($backend) = new_backend();

  my $txn = $backend->txn_do_async(sub {
    ($ctx) = @_;
    die "callback threw\n";
  });
  eval { $txn->get };
  like $@, qr/callback threw/, 'callback throw keeps its diagnostic after ROLLBACK';
  ok !$ctx->_context_active, 'callback throw invalidates the context';
  ok !$ctx->in_txn, 'callback throw leaves in_txn false';
  is $backend->{release_context_states}[0], 0,
    'callback throw invalidates before release';
  is scalar @{ $backend->pool->{released} }, 1,
    'callback throw rollback releases exactly once';
  like join('|', map { $_->{sql} } @{ $backend->{captured} }), qr/BEGIN.*ROLLBACK/,
    'callback throw rolls back';
}

{
  my ($backend, $ctx, $gate);
  ($backend) = new_backend();

  $gate = DBIO::Test::Future->new;
  my $txn = $backend->txn_do_async(sub {
    ($ctx) = @_;
    return $gate;
  });
  ok !$txn->is_ready, 'outer transaction waits for a failed callback Future too';
  $gate->fail('callback future failed');
  eval { $txn->get };
  like $@, qr/callback future failed/,
    'failed callback Future keeps its diagnostic after ROLLBACK';
  ok !$ctx->_context_active, 'failed callback Future invalidates the context';
  ok !$ctx->in_txn, 'failed callback Future leaves in_txn false';
  is $backend->{release_context_states}[0], 0,
    'failed callback Future invalidates before release';
  is scalar @{ $backend->pool->{released} }, 1,
    'failed callback Future rollback releases exactly once';
  like join('|', map { $_->{sql} } @{ $backend->{captured} }), qr/BEGIN.*ROLLBACK/,
    'failed callback Future rolls back';
}

# A failed BEGIN or COMMIT keeps its prefix. A failed ROLLBACK does not take
# the place of the callback failure it was cleaning up after: both are
# reported, the callback's first, in the words the synchronous txn_do uses
# (karr k237 -- until then the ROLLBACK's error replaced the callback's, and
# this case asserted that).
for my $case (
  [
    'BEGIN',
    qr/^BEGIN$/,
    sub { return 'unused' },
    qr/BEGIN failed: future failure on BEGIN/,
    'keeps its prefix',
  ],
  [
    'COMMIT',
    qr/^COMMIT$/,
    sub { return 'plain result' },
    qr/COMMIT failed: future failure on COMMIT/,
    'keeps its prefix',
  ],
  [
    'ROLLBACK',
    qr/^ROLLBACK$/,
    sub { return DBIO::Test::Future->fail('callback future failed') },
    qr/Transaction aborted: callback future failed\. Rollback failed: future failure on ROLLBACK/,
    'is added to the callback failure, not put in its place',
  ],
) {
  my ($name, $fail_on, $callback, $diagnostic, $claim) = @$case;
  my ($backend) = new_backend(fail_on => $fail_on);
  my $future = $backend->txn_do_async($callback);

  eval { $future->get };
  like $@, $diagnostic, "$name failure $claim";
  my $ctx = $backend->{txn_contexts}[0];
  ok !$ctx->_context_active, "$name failure invalidates the context";
  ok !$ctx->in_txn, "$name failure leaves in_txn false";
  # A ROLLBACK nobody confirmed retires the connection, never releases it
  # (karr k395).
  my $rolled = $name eq 'ROLLBACK' ? 1 : 0;
  is $backend->{release_context_states}[0], 0,
    "$name failure invalidates before its only release" unless $rolled;
  is scalar @{ $backend->pool->{released} }, ($rolled ? 0 : 1),
    $rolled ? "$name failure does not release the connection"
            : "$name failure releases exactly once after successful acquire";
}

{
  my ($backend) = new_backend(acquire_error => 'acquire failed');
  my $future;
  lives_ok {
    $future = $backend->txn_do_async(sub { return 'never runs' });
  } 'acquire failure returns a Future';
  ok $future->is_failed, 'acquire failure fails that Future';
  eval { $future->get };
  like $@, qr/acquire failed/, 'acquire failure keeps its diagnostic';
  is scalar @{ $backend->pool->{released} }, 0,
    'acquire failure releases no connection';
  is scalar @{ $backend->{captured} }, 0,
    'acquire failure does not issue BEGIN';
}

for my $case (
  [
    'BEGIN',
    qr/^BEGIN$/,
    sub { return 'unused' },
    qr/synchronous seam throw on BEGIN/,
  ],
  [
    'COMMIT',
    qr/^COMMIT$/,
    sub { return 'plain result' },
    qr/synchronous seam throw on COMMIT/,
  ],
  [
    # A ROLLBACK whose dispatch throws failed like one whose Future fails:
    # the throw is added to the callback failure (karr k237).
    'ROLLBACK',
    qr/^ROLLBACK$/,
    sub { return DBIO::Test::Future->fail('callback future failed') },
    qr/Transaction aborted: callback future failed\. Rollback failed: synchronous seam throw on ROLLBACK/,
  ],
) {
  my ($name, $throw_on, $callback, $diagnostic) = @$case;
  my ($backend) = new_backend(throw_on => $throw_on);
  my $future;
  lives_ok {
    $future = $backend->txn_do_async($callback);
  } "$name seam throw is captured after acquire";
  ok $future->is_failed, "$name seam throw returns a failed Future";
  eval { $future->get };
  like $@, $diagnostic, "$name seam diagnostic is preserved";
  my $ctx = $backend->{txn_contexts}[0];
  ok !$ctx->_context_active, "$name seam throw invalidates the context";
  ok !$ctx->in_txn, "$name seam throw leaves in_txn false";
  my $rolled = $name eq 'ROLLBACK' ? 1 : 0;
  is $backend->{release_context_states}[0], 0,
    "$name seam throw invalidates before its only release" unless $rolled;
  is scalar @{ $backend->pool->{released} }, ($rolled ? 0 : 1),
    $rolled ? "$name seam throw does not release the connection"
            : "$name seam throw releases exactly once";
}

# ---------------------------------------------------------------------------
# txn_do_async: post-acquire constructor and release cleanup seams.
# A synchronous constructor fault must be a failed Future with release, and
# release faults are primary only if the terminal transaction itself succeeded.
# ---------------------------------------------------------------------------
{
  my ($backend) = new_backend(
    txn_context_class => 'Test::ThrowingTransactionContext',
  );
  my ($txn, $callback_ran);

  lives_ok {
    $txn = $backend->txn_do_async(sub {
      $callback_ran++;
      return 'never runs';
    });
  } 'context constructor throw is captured after acquire';
  ok $txn->is_failed, 'context constructor throw returns a failed Future';
  eval { $txn->get };
  like $@, qr/transaction context constructor failed/,
    'context constructor throw keeps its diagnostic';
  is $callback_ran, undef, 'context constructor throw skips the callback';
  is scalar @{ $backend->{captured} }, 0,
    'context constructor throw issues no BEGIN';
  is scalar @{ $backend->pool->{released} }, 1,
    'context constructor throw releases exactly once after acquire';
}

{
  my ($backend, $ctx);
  ($backend) = new_backend(
    on_release => sub { die "release threw\n" },
  );
  my $txn;

  lives_ok {
    $txn = $backend->txn_do_async(sub {
      ($ctx) = @_;
      return 'committed value';
    });
  } 'release throw after COMMIT returns a Future';
  ok $txn->is_failed, 'release throw after COMMIT fails the transaction Future';
  eval { $txn->get };
  like $@, qr/release threw/,
    'release throw is the terminal error after an otherwise successful COMMIT';
  ok !$ctx->_context_active, 'successful transaction invalidates before a throwing release';
  ok !$ctx->in_txn, 'successful transaction leaves in_txn false before a throwing release';
  is $backend->{release_context_states}[0], 0,
    'successful transaction is inactive inside a throwing release';
  is scalar @{ $backend->pool->{released} }, 1,
    'throwing release is attempted exactly once after COMMIT';
}

for my $case (
  [
    'callback failure',
    undef,
    sub { return DBIO::Test::Future->fail('callback future failed') },
    qr/callback future failed/,
  ],
  [
    # The transaction failure a release throw stays secondary to is, since
    # karr k237, both errors: the callback's, then the ROLLBACK's.
    'ROLLBACK failure',
    qr/^ROLLBACK$/,
    sub { return DBIO::Test::Future->fail('callback future failed') },
    qr/Transaction aborted: callback future failed\. Rollback failed: future failure on ROLLBACK/,
  ],
) {
  my ($name, $fail_on, $callback, $diagnostic) = @$case;
  my ($backend, $ctx);
  ($backend) = new_backend(
    fail_on    => $fail_on,
    on_release => sub { die "release threw\n" },
  );
  my $txn;

  lives_ok {
    $txn = $backend->txn_do_async(sub {
      ($ctx) = @_;
      return $callback->();
    });
  } "$name plus release throw returns a Future";
  ok $txn->is_failed, "$name plus release throw returns a failed Future";
  eval { $txn->get };
  like $@, $diagnostic,
    "$name remains primary when release also throws";
  unlike $@, qr/release threw/,
    "$name keeps the release throw secondary";
  ok !$ctx->_context_active,
    "$name invalidates before a secondary release throw";
  ok !$ctx->in_txn,
    "$name leaves in_txn false before a secondary release throw";
  my $rolled = $name eq 'ROLLBACK failure' ? 1 : 0;
  is $backend->{release_context_states}[0], 0,
    "$name is inactive inside the throwing release" unless $rolled;
  is scalar @{ $backend->pool->{released} }, ($rolled ? 0 : 1),
    $rolled ? "$name retires instead of releasing"
            : "$name attempts its throwing release exactly once";
}

# ---------------------------------------------------------------------------
# txn_do_async: the Future returned to the caller must retain itself while a
# callback Future is pending, not only retain the pre-finalizer terminal chain.
# ---------------------------------------------------------------------------
{
  my $schema = DBIO::Test->init_schema;
  my $backend = Test::RetainingBackend->new($schema);
  my ($ctx, $gate);
  $gate = Test::RetainingFuture->new;

  my $txn = $backend->txn_do_async(sub {
    ($ctx) = @_;
    return $gate;
  });

  isa_ok $txn, 'Test::RetainingFuture',
    'txn_do_async returns the backend Future class to its caller';
  ok $ctx->_context_active, 'retained transaction context is active while callback is pending';
  ok !$txn->is_ready, 'returned transaction Future waits for the callback Future';
  is $txn->retain_count, 1,
    'returned transaction Future itself is retained while callback is pending';

  $gate->done('first value', 'second value');
  is_deeply [ $txn->get ], [ 'first value', 'second value' ],
    'COMMIT and finalizer preserve both callback Future list values';
  ok !$ctx->_context_active, 'settlement invalidates the retained context';
  is $backend->{release_context_states}[0], 0,
    'settlement invalidates before the retained Future releases';
  is scalar @{ $backend->pool->{released} }, 1,
    'settlement finalizes and releases exactly once';
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
  my $pf2 = $b2->pipeline(sub { return DBIO::Test::Future->done('fut-batched') });
  is scalar $pf2->get, 'fut-batched', 'pipeline passes a Future-returning coderef through';

  # dbio-async ADR 0003: the batch coderef is handed a PIPELINE
  # CONTEXT pinned to the bracketed connection, not the storage. That is what
  # makes "the calls inside the block queue onto the pipelined connection" a
  # structural property instead of an unwritten obligation on every driver's
  # _pipeline_enter: the context's CRUD routes through _query_async_pinned
  # with the bracketed connection, so a query in the batch CANNOT end up on a
  # second pooled connection (where it would run outside the bracket,
  # unbatched -- and at pool_size 1 only after the pipeline released).
  {
    my ($b4) = new_backend();
    my $seen_ctx;
    $b4->{next_rows} = [ [ 1, 'Miles Davis' ] ];

    my $pf4 = $b4->pipeline(sub {
      my ($batch) = @_;
      $seen_ctx = $batch;
      return $batch->select_async('artist', ['*'], { artistid => 1 });
    });

    isa_ok $seen_ctx, 'DBIO::Storage::Async::PipelineContext',
      'the batch coderef is handed a pipeline context';
    is $seen_ctx->pipeline_conn, 'CONN',
      'the context carries the connection the scaffold bracketed';
    ok !$seen_ctx->in_txn, 'a pipeline batch is not a transaction';
    is $seen_ctx->future_class, 'DBIO::Test::Future',
      'the context exposes future_class -- the batch needs it for its aggregate';

    my ($batched) = grep { ($_->{sql} || '') =~ /FROM/ } @{ $b4->{captured} };
    ok $batched->{pinned},
      'an *_async call inside the batch went through the PINNED query seam';
    is $batched->{conn}, 'CONN',
      'and it ran on the bracketed connection, not a freshly acquired one';

    is_deeply [ map { $_->{sql} =~ /FROM/ ? 'QUERY' : $_->{sql} } @{ $b4->{captured} } ],
      [ 'PIPELINE_ENTER', 'QUERY', 'PIPELINE_SYNC', 'PIPELINE_EXIT' ],
      'the batched query was issued inside the bracket, before the sync';

    is_deeply [ $pf4->get ], [ [ 1, 'Miles Davis' ] ],
      'the batch Future resolves with the batched result';

    # A blocking call inside the batch cannot be served: the result arrives at
    # the sync, which runs only after the coderef returns. Refuse with the
    # reason rather than wait for a result that cannot come.
    throws_ok { $seen_ctx->select('artist', ['*'], {}) }
      qr/Blocking ->select is not available inside a pipeline batch/,
      'a blocking CRUD call on the batch context refuses instead of deadlocking';
  }

  # All five blocking forms are refused, from inside the batch where the
  # deadlock would be -- each naming itself and the *_async form to call
  # instead, and none of them reaching the transport (karr k270: only select
  # was asserted, and only after the batch had ended).
  {
    my ($b7) = new_backend();
    my %blocking_args = (
      select        => [ 'artist', ['*'], { artistid => 1 } ],
      select_single => [ 'artist', ['*'], { artistid => 1 } ],
      insert        => [ 'artist', { name => 'Miles Davis' } ],
      update        => [ 'artist', { name => 'X' }, { artistid => 1 } ],
      delete        => [ 'artist', { artistid => 1 } ],
    );
    my (%refusal, %issued);

    my $pf7 = $b7->pipeline(sub {
      my ($batch) = @_;
      for my $op (sort keys %blocking_args) {
        my $before = scalar @{ $b7->{captured} };
        eval { $batch->$op(@{ $blocking_args{$op} }); 1 }
          or $refusal{$op} = "$@";
        $issued{$op} = scalar(@{ $b7->{captured} }) - $before;
      }
      return 'batch survived';
    });

    for my $op (sort keys %blocking_args) {
      like $refusal{$op},
        qr/Blocking ->\Q$op\E is not available inside a pipeline batch.* Call ->\Q$op\E_async and return an aggregate Future/s,
        "blocking $op inside a pipeline batch refuses, naming itself and ${op}_async";
      is $issued{$op}, 0, "... and issues no statement";
    }
    is scalar $pf7->get, 'batch survived',
      'a batch that caught the refusals still completes';
    is_deeply [ map { $_->{sql} } @{ $b7->{captured} } ],
      [ 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT' ],
      'and its bracket holds nothing but the sync';
  }

  # Coderef dies -> exit, retire (never release), failure propagates.
  my ($b3) = new_backend();
  my $pf3 = $b3->pipeline(sub { die "pipe boom\n" });
  ok $pf3->is_failed, 'pipeline fails when the coderef dies';
  is_deeply [ map { $_->{sql} } @{ $b3->{captured} } ],
    [ 'PIPELINE_ENTER', 'PIPELINE_EXIT' ],
    'a dying pipeline coderef still runs exit (no sync)';
  is $b3->{pool}{released}[0], undef,
    'a failed pipeline does not release its connection, it retires it';

  # A backend that overrides NONE of the three seams -- the
  # documented default for "cannot pipeline" -- must not leak a connection.
  # Since karr core k218 it is refused BEFORE the pool is touched, with an
  # error written for the caller (transport + pipeline()), not the bare seam's
  # "Subclass must override _pipeline_enter" (full claims:
  # t/test/37_async_pipeline_unsupported.t).
  {
    package Test::DecliningBackend;
    use base 'DBIO::Storage::Async';
    sub future_class { 'DBIO::Test::Future' }
    sub pool { $_[0]->{pool} ||= Test::SyncPool->new }
  }

  my $schema   = DBIO::Test->init_schema;
  my $decliner = Test::DecliningBackend->new($schema);
  my $ran      = 0;
  my $pf5      = $decliner->pipeline(sub { $ran++; return 'never runs' });

  ok $pf5->is_failed,
    'pipeline() on a backend declining every seam fails the Future (not a bare die)';
  throws_ok { $pf5->get }
    qr/Test::DecliningBackend does not support pipeline\(\) \(no _pipeline_enter\)/,
    'the failure names the transport and pipeline(), not the seam';
  is $ran, 0, 'the batch coderef never ran -- pipeline mode was never entered';
  ok !$decliner->{pool},
    'the pool was never even built, so no connection can leak';

  # A backend that DOES override _pipeline_enter but declines at run time
  # (croaks) must still hand the acquired connection back.
  {
    package Test::RuntimeDecliningBackend;
    use base 'DBIO::Storage::Async';
    sub future_class { 'DBIO::Test::Future' }
    sub pool { $_[0]->{pool} ||= Test::SyncPool->new }
    sub _pipeline_enter { die "pipeline mode refused by server\n" }
  }

  my $rt_decliner = Test::RuntimeDecliningBackend->new($schema);
  $ran = 0;
  my $pf6 = $rt_decliner->pipeline(sub { $ran++; return 'never runs' });
  throws_ok { $pf6->get } qr/pipeline mode refused by server/,
    'a run-time _pipeline_enter failure fails the Future';
  is $ran, 0, 'the batch coderef never ran';
  is $rt_decliner->{pool}{released}[0], 'CONN',
    'the acquired connection was released, not leaked, when _pipeline_enter croaked';
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

# ---------------------------------------------------------------------------
# Every blocking form is its *_async twin, waited for: the same arguments make
# the same statement on the same runner, and what the Future resolves with is
# what the blocking call returns -- or, failed, what it throws. Only select
# (above) and deploy (t/test/19_async_deploy.t) were executed on a core
# backend; the rest ran only in the EV drivers' mock suites (karr k270).
# ---------------------------------------------------------------------------
sub statement { [ @{ $_[0] }{qw(sql bind pinned)} ] }

sub blocking_cases {
  my ($source) = @_;
  return (
    [ select => [ 'artist', [ 'artistid', 'name' ], { name => { -like => 'M%' } } ],
      [ [ 1, 'Miles Davis' ], [ 2, 'Max Roach' ] ],
      [ [ 1, 'Miles Davis' ], [ 2, 'Max Roach' ] ], qr/^SELECT / ],
    [ select_single => [ 'artist', [ 'artistid', 'name' ], { artistid => 1 } ],
      [ [ 1, 'Miles Davis' ], [ 2, 'Max Roach' ] ],
      [ [ 1, 'Miles Davis' ] ], qr/^SELECT / ],
    [ insert => [ $source, { name => 'Miles Davis' } ],
      [ { artistid => 10, name => 'Miles Davis', rank => 13 } ],
      [ { artistid => 10, name => 'Miles Davis', rank => 13 } ], qr/^INSERT INTO "artist"/ ],
    [ update => [ 'artist', { name => 'X' }, { artistid => 1 } ],
      [ 1 ], [ 1 ], qr/^UPDATE "artist" SET/ ],
    [ delete => [ 'artist', { artistid => 1 } ],
      [ 1 ], [ 1 ], qr/^DELETE FROM "artist"/ ],
  );
}

{
  my ($backend, $schema) = new_backend();

  for my $case (blocking_cases($schema->source('Artist'))) {
    my ($op, $args, $rows, $expect, $sql) = @$case;
    my $async = "${op}_async";

    $backend->{next_rows} = $rows;
    my @resolved  = $backend->$async(@$args)->get;
    my $via_async = $backend->{captured}[-1];
    my $before    = scalar @{ $backend->{captured} };

    $backend->{next_rows} = $rows;
    my @returned = $backend->$op(@$args);

    is_deeply \@returned, $expect, "blocking $op returns the result";
    is_deeply \@returned, \@resolved, "... which is what $async resolves with";
    is scalar(@{ $backend->{captured} }) - $before, 1, "... from one statement";
    like $backend->_last_sql, $sql, "... of its own kind";
    is_deeply statement($backend->{captured}[-1]), statement($via_async),
      "... the statement $async makes, on the pooled runner";

    $backend->{next_rows} = $rows;
    is_deeply scalar $backend->$op(@$args), $expect->[0],
      "blocking $op in scalar context returns the first value";
  }

  # A failed Future is thrown, not returned.
  for my $case (blocking_cases($schema->source('Artist'))) {
    my ($op, $args, undef, undef, $sql) = @$case;
    my ($failing) = new_backend(fail_on => $sql);
    my ($verb) = "$sql" =~ /([A-Z]+)/;
    throws_ok { $failing->$op(@$args) } qr/future failure on \Q$verb\E /,
      "blocking $op throws the failure of its Future";
  }
}

# txn_do: the coderef's result back, BEGIN and COMMIT around it, and the
# blocking forms of the transaction context inside it -- each its *_async twin
# on the pinned connection.
{
  my ($backend, $schema) = new_backend();
  my $source = $schema->source('Artist');
  my (%returned, %resolved, %made, %via_async, $ctx_class);

  my @result = $backend->txn_do(sub {
    my ($ctx) = @_;
    $ctx_class = ref $ctx;
    for my $case (blocking_cases($source)) {
      my ($op, $args, $rows) = @$case;
      my $async = "${op}_async";

      $backend->{next_rows} = $rows;
      $resolved{$op}  = [ $ctx->$async(@$args)->get ];
      $via_async{$op} = $backend->{captured}[-1];

      $backend->{next_rows} = $rows;
      $returned{$op} = [ $ctx->$op(@$args) ];
      $made{$op}     = $backend->{captured}[-1];
    }
    $backend->{next_rows} = [];
    return 'committed';
  });

  is_deeply \@result, ['committed'], 'blocking txn_do returns the coderef result';
  isa_ok $ctx_class, 'DBIO::Storage::Async::TransactionContext',
    'its coderef gets the transaction context';
  is $backend->{captured}[0]{sql}, 'BEGIN', 'blocking txn_do began the transaction';
  is $backend->_last_sql, 'COMMIT', '... and committed it';
  is scalar @{ $backend->pool->{released} }, 1, '... releasing its connection once';
  ok !( grep { !$_->{pinned} } @{ $backend->{captured} } ),
    '... and every statement inside ran pinned';

  for my $case (blocking_cases($source)) {
    my ($op, undef, undef, $expect, $sql) = @$case;
    is_deeply $returned{$op}, $expect, "blocking $op on the transaction context returns the result";
    is_deeply $returned{$op}, $resolved{$op}, "... which is what its ${op}_async resolves with";
    like $made{$op}{sql}, $sql, "... from a statement of its own kind";
    is_deeply statement($made{$op}), statement($via_async{$op}),
      "... the statement ${op}_async makes";
    is $made{$op}{conn}, 'CONN', "... on the transaction's connection";
  }

  # The coderef's death is thrown, after the ROLLBACK.
  my ($failing) = new_backend();
  throws_ok { $failing->txn_do(sub { die "txn_do boom\n" }) } qr/txn_do boom/,
    'blocking txn_do throws what its coderef died of';
  is_deeply [ map { $_->{sql} } @{ $failing->{captured} } ], [ 'BEGIN', 'ROLLBACK' ],
    '... after rolling back';
  is scalar @{ $failing->pool->{released} }, 1, '... and releasing its connection once';
}

done_testing;
