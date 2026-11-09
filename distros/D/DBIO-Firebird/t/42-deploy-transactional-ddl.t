use strict;
use warnings;

use Test::More;
use Scalar::Util ();

use DBIO::Storage::DBI::Capabilities;
use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;
use DBIO::Firebird::Diff;
use DBIO::Firebird::Deploy;

# F02 / F10 -- the transactional_ddl capability DBIO::Firebird::Storage::Common
# declares (karr #18, handoff from core karr #130).
#
# Entirely offline: no DSN, no server, no DBIO_TEST_* anything. That is not a
# convenience here, it is the point -- the reason the declaration is 0 on an
# engine that HAS transactional DDL is precisely that the remaining questions
# need a Firebird server and this distribution has never had one. So this file
# pins what can be established without one: the value, that it was declared,
# the emitted statement pattern the value rests on, and that the value really
# does steer DBIO::Deploy::Base::_execute_ddl.
#
# Asserting the VALUE alone is weaker than it looks, because core's answer for
# an undeclared capability is 0 as well (DBIO::Storage::DBI::Capabilities
# defines _determine_supports_transactional_ddl => 0) -- on a storage INSTANCE
# the read below would quietly return the identical number with nothing
# declared at all. What saves it here is core rather than this file: a
# capability read as a CLASS method throws unless it was declared outright
# (core karr #119), so strip the declaration and this file does not go red, it
# dies on the first assertion. The get_inherited assertion is the one that says
# the intended thing in its own right -- defined only for a value a class in
# this chain set itself -- and it is the form the rest of the family pins.

# ---------------------------------------------------------------------------
# 1. the declaration, and that it is one
# ---------------------------------------------------------------------------

is (
  DBIO::Firebird::Storage::Common->_use_transactional_ddl,
  0,
  'transactional_ddl is 0 -- DBIO::Deploy::Base::_execute_ddl must not bracket '
. 'the DDL loop in txn_do',
);

isnt (
  DBIO::Firebird::Storage::Common->get_inherited('_use_transactional_ddl'),
  undef,
  '... and this distribution states it rather than falling through to core\'s '
. 'identical default. The two are indistinguishable by value, which is why '
. 'this assertion and not the one above is the one that can fail',
);

# The engine question and the declaration are not the same question, and the
# whole file exists so the 0 is not read as the wrong answer to the first one.
# Firebird has transactional DDL; what is withheld is the atomicity of a
# BRACKETED BATCH of the statements THIS driver emits. Sections 2 and 3 are
# that distinction, made checkable.

for my $class (qw(
  DBIO::Firebird::Storage
  DBIO::Firebird::Storage::InterBase
  DBIO::Firebird::Storage::ODBC
)) {
  is (
    $class->_use_transactional_ddl,
    0,
    "$class answers 0 too -- the declaration sits on Storage::Common and "
  . 'reaches all three transports, because the reasons for it are facts about '
  . 'the engine and about the DDL the shared Diff/DDL classes emit',
  );
}

# ---------------------------------------------------------------------------
# 2. the emitted pattern the 0 rests on, and why the per-statement hook is
#    not an escape from it
# ---------------------------------------------------------------------------
#
# DBIO::Firebird::Diff::Index renders a changed index as a DROP and a CREATE
# carrying the SAME name. Statement-at-a-time that pair has a real COMMIT
# between its halves; bracketed it does not, and the re-create then stores an
# rdb$indices row whose rdb$index_name duplicates one this very transaction has
# deleted without committing.
#
# This is asserted here because it is the load-bearing fact: the day the diff
# renames through a distinct index name instead, the main reason for the 0 is
# gone and whoever made that change should be told so by a failing test rather
# than discover it years later.

my %COLS = (
  t => [
    { column_name => 'a', data_type => 'INTEGER', is_pk => 1, not_null => 1 },
    { column_name => 'b', data_type => 'INTEGER' },
  ],
);

sub model_with_index {
  my ($index) = @_;
  return {
    tables             => { t => { table_name => 't', kind => 'table' } },
    columns            => { %COLS },
    indexes            => { t => { t_idx => $index } },
    unique_constraints => {},
    foreign_keys       => {},
  };
}

my $diff = DBIO::Firebird::Diff->new(
  source => model_with_index({ columns => ['a'],      is_unique => 0 }),
  target => model_with_index({ columns => ['a', 'b'], is_unique => 1 }),
);

my @batch = split /\n/, $diff->as_sql;

is_deeply (
  \@batch,
  [
    'DROP INDEX "t_idx";',
    'CREATE UNIQUE INDEX "t_idx" ON "t" ("a", "b");',
  ],
  'a changed index becomes a DROP and a CREATE for THE SAME NAME, adjacent in '
. 'one batch. This is the pattern the declaration is about: today a commit '
. 'separates the two halves because every statement runs on its own',
);

is (
  DBIO::Firebird::Storage::Common->can('_ddl_statement_is_transactional'),
  DBIO::Storage::DBI::Capabilities->can('_ddl_statement_is_transactional'),
  'this driver does not override the per-statement hook, and that is '
. 'deliberate: the hook is per STATEMENT and the constraint above is on a '
. 'PAIR. It can say "this statement may not be inside a transaction"; it '
. 'cannot say "these two may not be inside the same one"',
);

# ---------------------------------------------------------------------------
# 3. the counterfactual, through the real _execute_ddl, in both directions
# ---------------------------------------------------------------------------
#
# The two precedents in the family (dbio-sqlite, dbio-duckdb) drive this
# against a real local database, which Firebird has no equivalent of -- it is a
# server, and starting one is out of scope here. So the storage is a double
# with exactly two seams replaced: the handle (a recorder instead of a DBI
# handle) and the connection state. Everything the assertion depends on is
# real -- DBIO::Deploy::Base::_execute_ddl, its capability read, its
# _storage_owns_dbh check, its statement grouping, core's txn_do and the
# capability accessors carrying this driver's own declaration down @ISA.
#
# The recorder logs the transaction verbs and the DDL into ONE ordered list, so
# what is asserted is not "a transaction happened somewhere" but where the
# BEGIN and COMMIT fall relative to the two halves of the index pair.

{
  package TxnDdl::Dbh;

  sub new { bless { log => [] }, ref $_[0] || $_[0] }

  sub log { @{ $_[0]->{log} } }
  sub reset_log { @{ $_[0]->{log} } = () }

  sub do         { push @{ $_[0]->{log} }, $_[1]; 1 }
  sub begin_work { push @{ $_[0]->{log} }, 'BEGIN';    1 }
  sub commit     { push @{ $_[0]->{log} }, 'COMMIT';   1 }
  sub rollback   { push @{ $_[0]->{log} }, 'ROLLBACK'; 1 }

  sub FETCH { $_[1] eq 'AutoCommit' ? 1 : undef }
  sub STORE { 1 }
  sub ping       { 1 }
  sub disconnect { 1 }
}

{
  package TxnDdl::Storage;

  use base 'DBIO::Firebird::Storage';

  sub new {
    my $self = shift->next::method(@_);
    $self->{_fake_dbh} = TxnDdl::Dbh->new;
    $self->{_driver_determined} = 1;
    $self;
  }

  sub fake_dbh { $_[0]->{_fake_dbh} }

  sub _dbh     { $_[0]->{_fake_dbh} }
  sub _get_dbh { $_[0]->{_fake_dbh} }
  sub dbh      { $_[0]->{_fake_dbh} }

  sub connected        { 1 }
  sub _seems_connected { 1 }
  sub ensure_connected { 1 }
  sub _populate_dbh    { }
  sub _dbh_autocommit  { 1 }

  # _init on DBIO::Firebird::Storage::InterBase rewrites the connect string to
  # force ib_dialect=3 and reconnects. There is no connect string here.
  sub _init             { }
  sub _determine_driver { $_[0]->{_driver_determined} = 1; '' }
  sub _server_info      { { dbms_version => 0, normalized_dbms_version => 0 } }
}

{
  package TxnDdl::Schema;

  sub new     { bless { storage => $_[1] }, $_[0] }
  sub storage { $_[0]->{storage} }
}

my $storage = TxnDdl::Storage->new;
my $deploy  = DBIO::Firebird::Deploy->new(
  schema => TxnDdl::Schema->new($storage),
);
my $dbh = $storage->fake_dbh;

my $sql = $diff->as_sql;

# What _execute_ddl hands to $dbh->do: DBIO::SQL::Util::_split_statements drops
# the terminator, so these are @batch above without the trailing semicolon.
my @executed = (
  'DROP INDEX "t_idx"',
  'CREATE UNIQUE INDEX "t_idx" ON "t" ("a", "b")',
);

# --- forced true: what a "Firebird is transactional, so this should be 1"
#     cleanup would amount to. The force is tier 1, above the class
#     declaration.
$storage->_use_transactional_ddl(1);
$dbh->reset_log;
$deploy->_execute_ddl($dbh, $sql);

is_deeply (
  [ $dbh->log ],
  [ 'BEGIN', @executed, 'COMMIT' ],
  'with the capability forced true the whole batch is bracketed -- and the '
. 'drop and the re-create of t_idx land inside ONE transaction, with no '
. 'commit between them. That is the state this declaration exists to avoid '
. 'promising',
);

# --- force cleared: undef DELETES the tier-1 slot rather than leaving a
#     tombstone (ADR 0041 / core karr #137), so the question falls back to the
#     class declaration -- not to core's default, even though both read 0.
$storage->_use_transactional_ddl(undef);

is (
  $storage->_use_transactional_ddl,
  0,
  'clearing the force hands the question back to the driver\'s declaration, '
. 'not to a tombstone',
);

my @warnings;
{
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  $dbh->reset_log;
  $deploy->_execute_ddl($dbh, $sql);
}

is_deeply (
  [ $dbh->log ],
  [ @executed ],
  '... and the identical batch then runs statement at a time, unbracketed: '
. 'with AutoCommit on, each statement is its own transaction and the pair is '
. 'separated by a real commit',
);

like (
  join('', @warnings),
  qr/non-transactional DDL on DBIO::Firebird::Deploy/,
  'core announces the cost once, naming this deploy class. The notice is '
. 'accurate and is the price of the declaration: an apply that dies half way '
. 'leaves the earlier statements applied, and recovery is re-running upgrade '
. 'against a freshly computed diff',
);

# ---------------------------------------------------------------------------
# 4. the temp-database handle is never bracketed, whatever the capability says
# ---------------------------------------------------------------------------
#
# DBIO::Firebird::Deploy inherits DBIO::Deploy::Base::TempDatabase, whose
# _deploy_and_introspect_temp opens its OWN DBI handle to the throwaway
# database and deploys into that. Bracketing there would open a transaction on
# the LIVE connection around DDL executing on a different one -- no atomicity
# bought, and a failure rolling back whatever the caller had open. Core karr
# #131 made _execute_ddl check handle ownership; this is that fix held to
# account from the side that depends on it, because it is what made declaring
# anything here safe in the first place.

{
  my $foreign = TxnDdl::Dbh->new;

  $storage->_use_transactional_ddl(1);
  $deploy->_execute_ddl($foreign, $sql);

  isnt (
    Scalar::Util::refaddr($foreign),
    Scalar::Util::refaddr($storage->_dbh),
    'the temp-database shape: a handle the live storage does not own',
  );

  is_deeply (
    [ $foreign->log ],
    [ @executed ],
    '... is run unbracketed even with the capability forced true, and the live '
  . 'connection is not wrapped around it',
  );

  is_deeply (
    [ $storage->_dbh->log ],
    [ @executed ],
    '... which is to say the live handle saw nothing at all from that call -- '
  . 'its log still holds only the statements section 3 left there',
  );

  $storage->_use_transactional_ddl(undef);
}

done_testing;
