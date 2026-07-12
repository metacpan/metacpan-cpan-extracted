use strict;
use warnings;
use Test::More;
use Test::Exception;

# ADR 0030/0031 (core karr #65 + dbio-mysql karr #18): the future_io async mode
# resolves its transport adapter by CONVENTION -- ref($storage) . '::Async' --
# off the concrete MySQL driver storage. This dist ships that adapter,
# DBIO::MySQL::Storage::Async (over DBD::MariaDB's mariadb_async binding), plus
# the thin DBIO::MySQL::Storage::MariaDB::Async that the MariaDB-DSN convention
# resolves to.
#
# These are pure class/registry/introspection assertions: no event loop, no
# real database, no Future::IO dep. The live roundtrip lives in
# t/55-future-io-live.t (gated on DBIO_TEST_MYSQL_*).

use DBIO::Storage::DBI;
use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;

# The future_io transport base (DBIO::Async::Storage) ships in dbio-async, which
# is only a recommends -- a minimal install may not have it. Load the adapters
# (which pull the base) defensively so this offline suite skips cleanly instead
# of dying at compile time when dbio-async is absent.
BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require DBIO::MySQL::Storage::MariaDB::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

# -----------------------------------------------------------------------
# 1. The adapter is a concrete future_io transport
# -----------------------------------------------------------------------
isa_ok 'DBIO::MySQL::Storage::Async', 'DBIO::Async::Storage',
  'adapter is a Future::IO transport (DBIO::Async::Storage)';
isa_ok 'DBIO::MySQL::Storage::Async', 'DBIO::Storage::Async',
  'adapter is a DBIO::Storage::Async (Model-B orchestration base)';
isa_ok 'DBIO::MySQL::Storage::MariaDB::Async', 'DBIO::MySQL::Storage::Async',
  'the MariaDB-DSN convention adapter is a subclass of the MySQL adapter';

# -----------------------------------------------------------------------
# 2. future_io is resolved by CONVENTION, not by an explicit registration
# -----------------------------------------------------------------------
is(
  DBIO::MySQL::Storage->_resolve_async_mode_class('future_io', exclude => 'DBIO::Storage::DBI'),
  undef,
  'no explicit per-driver future_io registration -- the class is resolved by convention',
);
is(
  DBIO::MySQL::Storage::MariaDB->_resolve_async_mode_class('future_io', exclude => 'DBIO::Storage::DBI'),
  undef,
  '... same on the MariaDB storage subclass',
);

# -----------------------------------------------------------------------
# 3. The core resolver resolves future_io to the adapter off a MySQL storage.
#    Drive the REAL resolver end-to-end (offline: a bare reblessed storage,
#    no connect -- _determine_driver does not rebless a non-base class, and
#    async(undef) does not touch the database).
# -----------------------------------------------------------------------
{
  my $storage = bless {}, 'DBIO::MySQL::Storage';
  $storage->_async_mode('future_io');
  delete $storage->{_async_storage_obj};

  my $async = $storage->async;
  isa_ok $async, 'DBIO::MySQL::Storage::Async',
    'connect(dbi:mysql:..., { async => future_io }) resolves the convention adapter';
  is $storage->async, $async,
    'the same adapter is cached and feeds the *_async CRUD dispatch';
}
{
  # A dbi:MariaDB: connection reblesses to DBIO::MySQL::Storage::MariaDB, so the
  # convention derives DBIO::MySQL::Storage::MariaDB::Async.
  my $storage = bless {}, 'DBIO::MySQL::Storage::MariaDB';
  $storage->_async_mode('future_io');
  delete $storage->{_async_storage_obj};

  my $async = $storage->async;
  isa_ok $async, 'DBIO::MySQL::Storage::MariaDB::Async',
    'a MariaDB-reblessed storage resolves the MariaDB convention adapter';
  isa_ok $async, 'DBIO::MySQL::Storage::Async',
    '... which is the same MySQL transport';
}

# -----------------------------------------------------------------------
# 4. Every DB-specific transport seam is overridden -- none left croaking
#    "Subclass must override" in the abstract base. Comparing the resolved
#    coderef against the base's croaking one proves the override concretely.
# -----------------------------------------------------------------------
{
  # Seams the dbio-async Future::IO base (DBIO::Async::Storage) leaves croaking:
  my @async_base_seams = qw(
    _submit_query _collect_result _normalize_conninfo
    _create_pool_connection _shutdown_pool_connection
    _conn_ready _conn_fileno _txn_context_class _txn_conn_accessor
  );
  # Seams the Model-B base (DBIO::Storage::Async) leaves croaking:
  my @orch_base_seams = qw( sql_maker_class _transform_sql _post_insert_sql );

  for my $seam (@async_base_seams) {
    my $ours = DBIO::MySQL::Storage::Async->can($seam);
    my $base = DBIO::Async::Storage->can($seam);
    ok $ours && $base && $ours != $base,
      "seam $seam is overridden (not the croaking DBIO::Async::Storage default)";
  }
  for my $seam (@orch_base_seams) {
    my $ours = DBIO::MySQL::Storage::Async->can($seam);
    my $base = DBIO::Storage::Async->can($seam);
    ok $ours && $base && $ours != $base,
      "seam $seam is overridden (not the croaking DBIO::Storage::Async default)";
  }
}

# -----------------------------------------------------------------------
# 4b. The DBD-specific async primitives carry the DBD::mysql binding on the
#     base and are overridden with DBD::MariaDB's mariadb_* binding on the
#     MariaDB subclass -- so each DSN flavour drives its own DBD's async API
#     (the async analogue of the sync mysql_insertid / mariadb_insertid split).
# -----------------------------------------------------------------------
{
  my @dbd_primitives = qw(
    _async_prepare_attrs _conn_socket_fd _async_ready _async_result _async_insertid
  );
  for my $prim (@dbd_primitives) {
    my $base = DBIO::MySQL::Storage::Async->can($prim);
    my $mdb  = DBIO::MySQL::Storage::MariaDB::Async->can($prim);
    ok $base && $mdb && $base != $mdb,
      "$prim is overridden on the MariaDB subclass (drives its own DBD binding)";
  }

  is_deeply(DBIO::MySQL::Storage::Async->_async_prepare_attrs, { async => 1 },
    'base arms DBD::mysql async with { async => 1 }');
  is_deeply(DBIO::MySQL::Storage::MariaDB::Async->_async_prepare_attrs, { mariadb_async => 1 },
    'MariaDB subclass arms DBD::MariaDB async with { mariadb_async => 1 }');
}

# -----------------------------------------------------------------------
# 5. SQL-shaping seams produce the MySQL shapes
# -----------------------------------------------------------------------
is( DBIO::MySQL::Storage::Async->sql_maker_class, 'DBIO::MySQL::SQLMaker',
  'sql_maker_class is the MySQL SQLMaker' );
is( DBIO::MySQL::Storage::Async->_post_insert_sql, '',
  '_post_insert_sql is empty (MySQL has no RETURNING; last_insert_id instead)' );
is( DBIO::MySQL::Storage::Async->_txn_context_class, 'DBIO::Async::TransactionContext',
  '_txn_context_class is the future_io transaction context' );
is( DBIO::MySQL::Storage::Async->_txn_conn_accessor, 'txn_conn',
  '_txn_conn_accessor matches the generic pinned-connection key' );

# -----------------------------------------------------------------------
# 6. _transform_sql: identity -- MySQL keeps standard '?' placeholders
# -----------------------------------------------------------------------
is(
  DBIO::MySQL::Storage::Async->_transform_sql(
    q{SELECT `artistid`, `name` FROM `artist` WHERE `name` = ? AND `rank` = ?}
  ),
  q{SELECT `artistid`, `name` FROM `artist` WHERE `name` = ? AND `rank` = ?},
  'SQL is passed through unchanged -- MySQL uses ? placeholders',
);

# -----------------------------------------------------------------------
# 7. _insert_returned_columns assembles the returned-columns hashref from the
#    captured mariadb_insertid (the key divergence from PostgreSQL's RETURNING).
#    Exercised here without a DB via a minimal fake source.
# -----------------------------------------------------------------------
{
  package My::FakeSource;
  sub new { bless { %{ $_[1] } }, $_[0] }
  sub columns         { @{ $_[0]->{columns} } }
  sub columns_info    { $_[0]->{columns_info} }
  sub primary_columns { @{ $_[0]->{primary_columns} } }
}

{
  my $source = My::FakeSource->new({
    columns         => [qw/artistid name rank/],
    columns_info    => { artistid => { is_auto_increment => 1 } },
    primary_columns => ['artistid'],
  });

  my $storage = bless { _last_insert_id => 42 }, 'DBIO::MySQL::Storage::Async';
  my $ret = $storage->_insert_returned_columns($source, { name => 'Miles' }, 1);
  is_deeply $ret, { name => 'Miles', artistid => 42 },
    'the auto-increment id is folded onto the autoinc PK column, overlaid on the insert data';

  # No id generated (explicit PK supplied) -> supplied data untouched.
  my $storage2 = bless { _last_insert_id => 0 }, 'DBIO::MySQL::Storage::Async';
  my $ret2 = $storage2->_insert_returned_columns(
    $source, { artistid => 7, name => 'Given' }, 1,
  );
  is_deeply $ret2, { artistid => 7, name => 'Given' },
    'no generated id -> the supplied insert data is returned untouched';

  is $storage->last_insert_id, 42, 'last_insert_id exposes the captured id for legacy callers';
}

done_testing;
