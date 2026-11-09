use strict;
use warnings;
use Test::More;

# Offline test for the capabilities DBIO::ClickHouse::Storage *declares*.
# No DBI, no DSN, no server -- both capabilities are class-level facts and
# reading them never touches a handle.
#
# Why this file exists at all: for both capabilities core's fallback happens
# to produce a usable value already (DBIO::Storage::DBI::Capabilities defines
# _determine_supports_transactional_ddl => 0). Asserting only the value would
# therefore pass just as well with nothing declared, and the driver's position
# would keep resting on a core default that core is free to change. Every
# block below pairs the value with get_inherited(), which is defined only for
# a value this class set itself -- that is the part that cannot drift back
# into an accident.

use DBIO::ClickHouse::Storage;
use DBIO::Deploy::Base ();
use DBIO::Diff::Op ();
use DBIO::Storage::DBI ();
use DBIO::Test;

# --- transactional_ddl: declared 0 ------------------------------------------

is(DBIO::ClickHouse::Storage->_use_transactional_ddl, 0,
  'transactional_ddl is 0 -- ClickHouse has no transactions, so no atomic DDL');

isnt(DBIO::ClickHouse::Storage->get_inherited('_use_transactional_ddl'), undef,
  '... and the driver states it, rather than inheriting core\'s default');

# --- ... and what that buys: deploy never brackets DDL in txn_do ------------
#
# The point of the declaration is this path. DBIO::Deploy::Base::_execute_ddl
# wraps its DDL loop in $storage->txn_do only when the storage reports
# transactional DDL. Our txn_do neither brackets nor rolls back and warns that
# nothing is atomic (ADR 0003), so being wrapped would mean deploy promising
# an atomicity this engine cannot deliver. Exercised against core's real
# _execute_ddl with a real ClickHouse storage; DBIO::ClickHouse::Deploy is not
# involved, the capability is what core keys on.
{
  package MyTest::CH::SpyStorage;
  our @ISA = ('DBIO::ClickHouse::Storage');
  our @TXN_DO;
  sub txn_do { my ($self, $code) = @_; push @TXN_DO, 1; return $code->() }
}
{
  package MyTest::CH::FakeDbh;
  sub new { bless { stmts => [] }, shift }
  sub do { push @{ $_[0]->{stmts} }, $_[1]; 1 }
}
{
  package MyTest::CH::FakeSchema;
  sub new { my ($class, %args) = @_; bless { %args }, $class }
  sub storage { $_[0]->{storage} }
}

{
  my $storage = MyTest::CH::SpyStorage->new;
  my $deploy  = DBIO::Deploy::Base->new(
    schema => MyTest::CH::FakeSchema->new(storage => $storage),
  );
  my $dbh = MyTest::CH::FakeDbh->new;

  # core carps once that the DDL loop is not atomic -- that is the expected
  # companion of the declaration, not noise to be silenced permanently.
  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $deploy->_execute_ddl(
      $dbh,
      "CREATE TABLE t1 (id UInt64) ENGINE = MergeTree ORDER BY id;\n"
      . "CREATE TABLE t2 (id UInt64) ENGINE = MergeTree ORDER BY id;",
    );
  }

  is scalar(@MyTest::CH::SpyStorage::TXN_DO), 0,
    'deploy does not bracket the DDL loop in txn_do';
  is scalar(@{ $dbh->{stmts} }), 2,
    '... and still runs every statement, one at a time';
}

# --- supports_if_exists: declared 1 -----------------------------------------

is(DBIO::ClickHouse::Storage->_use_supports_if_exists, 1,
  'supports_if_exists is 1 -- ClickHouse parses IF [NOT] EXISTS');

isnt(DBIO::ClickHouse::Storage->get_inherited('_use_supports_if_exists'), undef,
  '... and the driver states it, rather than inheriting core\'s default');

# The declaration is the engine fact; the rendering is core's to consume, and
# DBIO::Diff::Op::should_emit_if_exists is the helper a per-driver as_sql calls
# to ask for it. This asserts our declaration actually reaches that helper --
# which is not the same as it being stored: core once probed _use_if_exists, a
# name no capability ever mints, leaving the helper inert for every real
# storage no matter what a driver declared (core k117, fixed). Hence the probe
# rather than a second read of the accessor.
#
# It says nothing about emitted SQL: no diff op in this distribution calls the
# helper yet, and DBIO::ClickHouse::DDL::Emit's drop_table / alter_table_*
# forms take no if_exists at all, so the diff still renders unguarded DDL.
ok(DBIO::Diff::Op::should_emit_if_exists(DBIO::ClickHouse::Storage->new),
  'should_emit_if_exists follows the declared capability');

# --- supports_exists_query: declared 1 (ADR 0037) ---------------------------
#
# Read off the driver class, never off a storage object built by
# DBIO::Test->init_schema: that one is a
# DBIO::Test::Storage::_hybrid_::DBIO::ClickHouse::Storage, and core's fake
# storage declares _use_supports_exists_query(1) itself. Asked through the
# hybrid this passes with nothing declared here at all -- so the assertion
# would be about core's mock, not about this driver.

is(DBIO::ClickHouse::Storage->_use_supports_exists_query, 1,
  'supports_exists_query is 1 -- ClickHouse takes core\'s base EXISTS rendering');

isnt(DBIO::ClickHouse::Storage->get_inherited('_use_supports_exists_query'), undef,
  '... and the driver states it, rather than inheriting core\'s default');

# The declaration says "the statement core renders is one this engine
# accepts", so the pairing has to be the statement itself. Two things are
# asserted about it, and both are the point of the ticket:
#
#  * it is core's BASE rendering, character for character -- this driver
#    overrides _exists_value_sql with nothing, and a future override would
#    have to come with its own evidence rather than slip in behind a passing
#    capability test;
#  * that rendering is the one ClickHouse documents: EXISTS used as a value
#    (documented to return 0 or 1) inside a CASE, in a SELECT with no FROM.
is(DBIO::ClickHouse::Storage->_exists_value_sql('(SELECT 42 FROM `hit` `me`)'),
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM `hit` `me`) THEN 1 ELSE 0 END',
  '_exists_value_sql is core\'s base CASE form, unmodified');

is(DBIO::ClickHouse::Storage->can('_exists_value_sql'),
  DBIO::Storage::DBI->can('_exists_value_sql'),
  '... because the driver does not override the hook at all');

# ... and the same statement once more through the whole ResultSet path, which
# is what a caller actually gets. What this adds over the two assertions above
# is the inner half: the subquery is rendered by this driver's SQL maker, with
# ClickHouse backtick quoting, inside the fragment core wraps.
#
# The capability *gate* on this path is not ours -- init_schema hands back a
# DBIO::Test::Storage::_hybrid_::DBIO::ClickHouse::Storage and core's fake
# storage declares supports_exists_query too, so the gate would open even if
# this driver declared nothing. The declaration is pinned above, on the class;
# what is pinned here is the text.
{
  my $schema = DBIO::Test->init_schema(
    storage_type => 'DBIO::ClickHouse::Storage',
    no_deploy    => 1,
  );

  my $query = $schema->resultset('Artist')
    ->search_rs({ name => 'foo' })->results_exist_as_query;
  my ($sql, @bind) = @{$$query};

  is $sql,
    '( SELECT CASE WHEN EXISTS (SELECT 42 FROM `artist` `me` '
    . 'WHERE ( `name` = ? )) THEN 1 ELSE 0 END )',
    'results_exist_as_query renders the base form over ClickHouse quoting';

  is scalar(@bind), 1, '... carrying the search bind through';
}

done_testing;
