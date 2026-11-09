use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Test;
use DBIO::MySQL::EV::Storage;

# OFFLINE regression for karr k26: the storage-decides identity contract
# (ADR 0036 §4) exercised through the REAL async call path -- upsert_async ->
# insert_async -> _run_crud_pinned -> sql_maker->insert -- with no EV::MariaDB
# socket and no database. t/17-upsert-live.t covers the same seam against a
# live server; this file freezes the offline half so a refactor of the ev
# insert path fails fast without a DSN.
#
# PREMISE -- what k26 pins: dbio-mysql k44 (commit 46d5baa) made the SQLMaker
# derive identity_column from the ResultSource it was handed; that approach was
# REVERTED (k45, commit 6a3d892). The installed SQLMaker only reads
# identity_column off the on_conflict hash it is given and has no Source branch
# left. The decision now lives in the storage: DBIO::MySQL::Storage::_mysql_upsert_plan
# computes identity_column (single auto_increment PK, not supplied in the data,
# not assigned in the set) and each driver layer folds the plan's private keys
# into the on_conflict structure before rendering -- the sync insert in
# DBIO::MySQL::Storage::insert, the ev backend in
# DBIO::MySQL::EV::Storage::_run_crud_pinned, which resolves the fold against
# its OWNING sync storage (the _owner_storage back-ref core wires in
# _async_storage).
#
# What core hands the ev backend (upsert_async -> _upsert_prepare): an
# on_conflict WITHOUT identity_column -- that key exists only inside the plan
# the owning sync storage computes. The whole question this file answers: does
# the LII identity idiom (`` `artistid` = LAST_INSERT_ID(`artistid`) ``) still
# reach the wire once the plan fold runs -- the claim k44's revert was meant
# to preserve. Five assertions:
#   1. upsert_async resolves a Row carrying the LII fold (artistid => 42) --
#      the real path runs end to end offline.
#   2. exactly two pinned queries: the INSERT, then SELECT LAST_INSERT_ID().
#   3. the INSERT carries ON DUPLICATE KEY UPDATE with the identity idiom.
#   4. core's on_conflict has no identity_column (the storage-decides contract,
#      probed via _upsert_prepare's flat return).
#   5. the same core-built on_conflict fed DIRECTLY to the SQLMaker produces NO
#      idiom -- only the storage fold brings it in (negative evidence).

# The pool answers acquire with a fake connection; the executor replies purely
# from the SQL text, recording every (conn, sql, bind) so the pinned-runner
# contract (same conn for both queries) is directly assertable.
{
  package K26::FakeConn;
  sub new { bless { id => $_[1] }, $_[0] }
}
{
  package K26::FakePool;
  sub new      { bless {}, $_[0] }
  sub acquire  { Future->done(K26::FakeConn->new(1)) }
  sub release  { }
  sub _lease   { 1 }   # the lease of a borrow (core k275, karr k91)
  sub shutdown { }
}
{
  package K26::MockExecutor;
  sub new { bless { calls => [], next_lii => 42, affected_rows => 1 }, $_[0] }
  sub execute {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{calls} }, { conn => $conn, sql => $sql, bind => [ @{ $bind || [] } ] };

    if ($sql =~ /LAST_INSERT_ID/) {
      return Future->done([ $self->{next_lii} ]);
    }
    if ($sql =~ /^SELECT/) {
      return Future->done([ 1, 'row' ]);
    }
    # INSERT: the affected-rows shape (a plain scalar), like the wire.
    return Future->done($self->{affected_rows});
  }
}

# DBIO::Test's fake hybrid storage (DBIO::Test::Storage + DBIO::MySQL::Storage,
# C3 mro) stands in for a connected MySQL storage: it reports dbms_version 0,
# so _is_mariadb is false, insert_returning is off, and the LII identity idiom
# is the chosen row-identity channel -- exactly like a MySQL 8 server.
my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::MySQL::Storage',
);
my $storage = $schema->storage;

# The hybrid defaults to the 'immediate' async mode; the ev backend is the one
# under test. _async_storage builds a real DBIO::MySQL::EV::Storage and wires
# the _owner_storage back-ref to the hybrid (karr #68) -- the resolution the
# plan fold depends on.
$storage->_async_mode('ev');
my $backend = $storage->_async_storage;
isa_ok $backend, 'DBIO::MySQL::EV::Storage',
  'ev async backend composed over the hybrid sync storage';
is $backend->_owner_storage, $storage,
  'owner back-ref wired to the hybrid sync storage (the fold resolves against it)';

$backend->{pool}     = K26::FakePool->new;
$backend->{executor} = K26::MockExecutor->new;

# --- 4. the storage-decides contract: core builds on_conflict WITHOUT
# identity_column. _upsert_prepare returns the flat shape
# ('flat', $storage, $new, \%rowdata, \%storage_opts, ...), so $rest[3] is the
# exact storage_opts core will hand insert_async.
my $rs = $schema->resultset('Artist');
my ($mode, @rest) = $rs->_upsert_prepare(
  { name => 'Tom', rank => 1 },
  { conflict_target => 'any' },
);
is $mode, 'flat', '_upsert_prepare resolved the upsert in flat mode';
my $core_opts = $rest[3];
is_deeply [ sort keys %{ $core_opts->{on_conflict} } ], [ 'action', 'set', 'target' ],
  'core-built on_conflict carries only target/action/set -- no identity_column '
  . '(the SQLMaker and the ev backend must get it from the plan, not from core)';
ok !exists $core_opts->{on_conflict}{identity_column},
  'explicit negative: identity_column absent from the core-built on_conflict';

# --- 5. negative evidence: the same core-built storage_opts rendered by the
# SQLMaker alone produce the ODKU UPDATE branch WITHOUT the identity idiom. The
# maker only reads identity_column off the on_conflict hash (k45 revert); it
# must not invent the idiom on its own -- only the plan fold in the ev path
# brings it in.
my ($plain_sql) = $backend->sql_maker->insert(
  'artist', { name => 'Tom', rank => 1 }, $core_opts,
);
like $plain_sql, qr/ON DUPLICATE KEY UPDATE/,
  'direct SQLMaker render keeps the ODKU UPDATE branch';
unlike $plain_sql, qr/LAST_INSERT_ID/xi,
  'direct SQLMaker render has NO identity idiom on a core-built on_conflict '
  . '(no Source branch left to invent it -- k45 revert frozen)';

# --- 1+2+3. the real path: upsert_async -> insert_async -> _run_crud_pinned,
# with the mocked pool/executor sitting under the genuine backend.
my $f = $rs->upsert_async(
  { name => 'Tom', rank => 1 },
  { conflict_target => 'any' },
);
ok $f->is_ready && !$f->is_failed,
  'upsert_async (real path) ran to completion against the mock';
my $row = $f->get;
ok $row, 'upsert_async resolved a Row';
is $row->artistid, 42,
  'identity column (artistid) carried the mocked LAST_INSERT_ID() value -- '
  . 'the LII fold reached the returned row';

my $calls = $backend->{executor}{calls};
is scalar(@$calls), 2,
  'the ev insert path issued exactly two pinned queries: the ODKU INSERT and '
  . 'SELECT LAST_INSERT_ID() -- not the one-query generic SUPER path';

my ($insert_sql, $lii_sql) = ($calls->[0]{sql}, $calls->[1]{sql});
like $insert_sql, qr/^INSERT INTO `artist`/, 'first query is the INSERT';
like $insert_sql, qr/ON DUPLICATE KEY UPDATE/,
  'INSERT carries the atomic-upsert UPDATE branch';
like $insert_sql, qr/`artistid` \s* = \s* LAST_INSERT_ID \( `artistid` \)/xi,
  'the plan fold reached the SQLMaker: the UPDATE branch carries the §4 '
  . 'identity idiom (karr #45 fold, frozen)';
is $lii_sql, 'SELECT LAST_INSERT_ID()',
  'second query reads the session LII for the identity fold';
is $calls->[0]{conn}, $calls->[1]{conn},
  'both pinned queries ran on the SAME acquired connection';

diag "recorded INSERT SQL: $insert_sql";

done_testing;
