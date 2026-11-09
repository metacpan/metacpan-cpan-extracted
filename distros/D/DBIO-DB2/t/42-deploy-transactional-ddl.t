use strict;
use warnings;
use Test::More;

use DBIO::Deploy::Base;
use DBIO::DB2::Deploy;
use DBIO::DB2::Diff;
use DBIO::DB2::Storage;
use DBIO::SQL::Util ();

# F02 / F10 -- the transactional_ddl capability DBIO::DB2::Storage declares.
# Offline: no DSN, no server, no DBD::DB2. The declaration is a class-level
# fact, and the counterfactual below runs core's real _execute_ddl over this
# driver's real diff output with a recording handle in place of a connection.
#
# Asserting the VALUE alone would prove nothing. Core's default for an
# undeclared capability is 0 as well (DBIO::Storage::DBI::Capabilities defines
# _determine_supports_transactional_ddl => 0), so the first assertion below is
# green with nothing declared at all. The get_inherited assertion is the
# tripwire: it is defined only for a value this class set itself.
#
# It matters here for the same reason it matters on SQLite: Db2 LUW HAS
# transactional DDL -- its COMMIT topic lists CREATE and DROP among the
# statements a commit commits, and ROLLBACK backs "all changes made to the
# database during the unit of work" out -- and this driver still answers no.
# The rest of this file is why.

# --- the declaration --------------------------------------------------------

is(DBIO::DB2::Storage->_use_transactional_ddl, 0,
  'transactional_ddl is 0 -- the deploy loop must not be bracketed in txn_do');

isnt(DBIO::DB2::Storage->get_inherited('_use_transactional_ddl'), undef,
  '... and the driver states it, rather than inheriting core\'s default');

# --- the batch the declaration answers for ----------------------------------
#
# Not a hand-written string: an FK whose referential rule changed, run through
# the real DBIO::DB2::Diff. DB2 has no ALTER for a foreign key definition, so
# the diff emits a drop-then-add PAIR on ONE constraint name -- the shape that
# would have to survive a single unit of work if this capability were true.

my %tables  = (author => { table_name => 'author' }, book => { table_name => 'book' });
my %columns = (
  author => [ { column_name => 'id',        data_type => 'integer', is_pk => 1 } ],
  book   => [ { column_name => 'author_id', data_type => 'integer' } ],
);
my $fk = sub {
  my ($on_delete) = @_;
  return {
    book => [ {
      constraint_name => 'fk_book_author_id',
      from_columns    => ['author_id'],
      to_table        => 'author',
      to_columns      => ['id'],
      on_delete       => $on_delete,
      on_update       => 'NO ACTION',
    } ],
  };
};

my $diff = DBIO::DB2::Diff->new(
  source => { tables => \%tables, columns => \%columns, indexes => {},
              foreign_keys => $fk->('NO ACTION') },
  target => { tables => \%tables, columns => \%columns, indexes => {},
              foreign_keys => $fk->('CASCADE') },
);
ok($diff->has_changes, 'the FK rule change is a change');

my $sql = $diff->as_sql;
like($sql, qr/DROP FOREIGN KEY "fk_book_author_id".*ADD CONSTRAINT "fk_book_author_id"/s,
  'an FK definition change is a drop-then-add pair on one constraint name');

# --- a storage that answers, and a handle that records ----------------------
#
# A real DBIO::DB2::Storage subclass, so the capability answer below is this
# driver's declaration reached by inheritance rather than a stub's opinion.
# Constructed with no connect info, which is what keeps the capability getter
# from trying to determine a driver (DBIO::Storage::DBI wraps
# get_use_dbms_capability and only probes when there is a DSN to probe with).
#
# Only the two things that need a live connection are replaced: txn_do, which
# would open a real transaction, and dbh, which hands out the handle the
# storage holds -- exactly what a connected DBIO::Storage::DBI does, and what
# makes core's _storage_owns_dbh answer true below.
{
  package TxnDdl::Storage;
  use base 'DBIO::DB2::Storage';
  sub txn_do { my ($self, $code) = @_; push @{ $self->{txn_calls} }, 1; $code->() }
  sub dbh    { $_[0]->_dbh }
}
{
  package TxnDdl::Dbh;
  sub new  { bless { stmts => [] }, shift }
  sub do   { push @{ $_[0]{stmts} }, $_[1]; 1 }
}
{
  package TxnDdl::Schema;
  sub new     { bless { storage => $_[1] }, $_[0] }
  sub storage { $_[0]{storage} }
}

my $dbh     = TxnDdl::Dbh->new;
my $storage = TxnDdl::Storage->new;
$storage->_dbh($dbh);
my $deploy  = DBIO::DB2::Deploy->new(schema => TxnDdl::Schema->new($storage));

is($storage->_use_transactional_ddl, 0,
  'an instance inherits the class declaration without connecting to ask');

# --- what a 1 would sweep in ------------------------------------------------
#
# The handle the deploy path uses IS the one the storage owns, which is the
# condition core checks before bracketing. Unlike the other transactional
# engines in this family, DB2 has no throwaway *database* to deploy the
# compare schema into -- _build_target_model builds it on this very handle --
# so nothing here is exempt from a bracket the way a TempDatabase driver's
# target build is.
ok(!DBIO::DB2::Deploy->isa('DBIO::Deploy::Base::TempDatabase'),
  'DB2 has no throwaway database: the compare deploy shares the live connection');
isnt(DBIO::DB2::Deploy->can('_build_target_model'),
     DBIO::Deploy::Base->can('_build_target_model'),
  '... because this driver overrides _build_target_model itself');
ok(DBIO::Deploy::Base::_storage_owns_dbh($storage, $deploy->_dbh),
  'and the storage owns the handle the whole deploy path runs on -- core would bracket it');

# --- the counterfactual, through core's real _execute_ddl -------------------

$deploy->_execute_ddl($dbh, $sql);
is(scalar @{ $dbh->{stmts} }, 2,
  'with the declaration answering, both statements run');
is(scalar @{ $storage->{txn_calls} || [] }, 0,
  '... one at a time, with no txn_do around them');

# Force the capability true on the storage (tier 1, above the class
# declaration) -- which is what a future "Db2 is transactional, so this should
# be 1" cleanup would amount to -- and core brackets the identical batch.
$storage->_use_transactional_ddl(1);
is($storage->_use_transactional_ddl, 1, 'the per-storage force takes');

$deploy->_execute_ddl($dbh, $sql);
is(scalar @{ $storage->{txn_calls} || [] }, 1,
  'forced true, the identical batch is bracketed in exactly one txn_do');
is(scalar @{ $dbh->{stmts} }, 4,
  '... carrying the same two statements');

# The pair is ONE run, not two: nothing in this driver answers
# _ddl_statement_is_transactional false, so the DROP and the re-ADD of the same
# constraint name would reach the server inside a single unit of work. That is
# the shape no live Db2 was available to confirm.
my @runs = DBIO::Deploy::Base::_group_ddl_statements(
  $storage, [ grep { !/^\s*--/ } DBIO::SQL::Util::_split_statements($sql) ]);
is(scalar @runs, 1,
  'drop and re-add of one constraint name would share a single unit of work');

# Clearing the force hands the question back to the class declaration (undef
# deletes the tier-1 slot rather than tombstoning it), and the same batch runs
# bare again.
$storage->_use_transactional_ddl(undef);
is($storage->_use_transactional_ddl, 0,
  'clearing the force falls through to the class declaration, not to a tombstone');

$deploy->_execute_ddl($dbh, $sql);
is(scalar @{ $storage->{txn_calls} || [] }, 1,
  'back to the declaration, no further txn_do');
is(scalar @{ $dbh->{stmts} }, 6,
  '... and the statements still run');

done_testing;
