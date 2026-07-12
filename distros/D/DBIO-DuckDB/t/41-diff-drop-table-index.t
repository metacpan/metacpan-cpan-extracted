#!/usr/bin/env perl
# t/41-diff-drop-table-index.t — regression for karr #8.
#
# When DBIO::DuckDB::Diff reconciles a live schema containing a table NOT
# present in the target (a table removed from the app's DBIO classes, or an
# unmanaged leftover), the diff used to emit BOTH:
#
#   DROP TABLE leftover;          (Diff::Table, "tables" phase)
#   DROP INDEX idx_leftover_val;  (Diff::Index, later "indexes" phase)
#
# as_sql runs tables before indexes, and DuckDB's DROP TABLE already removes
# the table's own indexes. The later standalone DROP INDEX then fails against a
# real DB ("index ... does not exist"), aborting apply()/upgrade().
#
# The fix: Diff::Index receives the tables sections and suppresses a standalone
# DROP INDEX for any index whose owning table is itself being dropped in the
# same pass. This is a pure diff-SQL-generation test — no live DB needed.

use strict;
use warnings;
use Test::More;

use DBIO::DuckDB::Diff;
use DBIO::DuckDB::Diff::Index;

# --- Full-diff regression ----------------------------------------------------

# Live (source): a leftover table with its own explicit index.
my $source = {
  tables => {
    leftover => { table_name => 'leftover', kind => 'table', schema => 'main' },
  },
  columns => {
    leftover => [
      { column_name => 'id',  data_type => 'INTEGER', not_null => 1, is_pk => 1 },
      { column_name => 'val', data_type => 'VARCHAR' },
    ],
  },
  indexes => {
    leftover => {
      idx_leftover_val => {
        index_name => 'idx_leftover_val',
        is_unique  => 0,
        columns    => ['val'],
        sql        => 'CREATE INDEX idx_leftover_val ON leftover (val)',
        origin     => 'c',
        partial    => 0,
      },
    },
  },
};

# Desired (target): the leftover table is gone entirely.
my $target = { tables => {}, columns => {}, indexes => {} };

my $diff = DBIO::DuckDB::Diff->new(source => $source, target => $target);

ok $diff->has_changes, 'diff detects the removed table';

my $sql = $diff->as_sql;

like   $sql, qr/DROP TABLE "?leftover"?/,
  'DROP TABLE is emitted for the removed table';
unlike $sql, qr/DROP INDEX\s+"?idx_leftover_val"?/,
  'no standalone DROP INDEX for the dropped table (DROP TABLE already covers it)';

my @drop_index = ($sql =~ /(DROP INDEX[^\n;]*)/g);
is scalar(@drop_index), 0, 'zero DROP INDEX statements in the full-schema sync';

# --- Over-suppression guard (full-diff level) --------------------------------
# A table that STAYS but loses a secondary index must still get a standalone
# DROP INDEX — the fix only suppresses drops for indexes of dropped tables.
my $src2 = {
  tables => {
    users => { table_name => 'users', kind => 'table', schema => 'main' },
  },
  columns => {
    users => [ { column_name => 'id', data_type => 'INTEGER', is_pk => 1 } ],
  },
  indexes => {
    users => {
      idx_users_email => {
        index_name => 'idx_users_email',
        is_unique  => 0,
        columns    => ['email'],
        sql        => 'CREATE INDEX idx_users_email ON users (email)',
        origin     => 'c',
        partial    => 0,
      },
    },
  },
};
my $tgt2 = {
  tables => {
    users => { table_name => 'users', kind => 'table', schema => 'main' },
  },
  columns => {
    users => [ { column_name => 'id', data_type => 'INTEGER', is_pk => 1 } ],
  },
  indexes => { users => {} },
};

my $sql2 = DBIO::DuckDB::Diff->new(source => $src2, target => $tgt2)->as_sql;
unlike $sql2, qr/DROP TABLE/, 'surviving table is not dropped';
like   $sql2, qr/DROP INDEX\s+"?idx_users_email"?/,
  'secondary index of a surviving table is still dropped standalone';

# --- Unit-level Diff::Index->diff cases --------------------------------------

# karr #8: when the owning table is itself being dropped in the same pass
# (present in source tables, absent from target tables), DuckDB's DROP TABLE
# already removes the table's indexes, so no standalone DROP INDEX is emitted.
# The source-index inputs below are identical between the two cases; only the
# target-tables argument differs, so the guard is shown to key off the tables
# section (not the indexes section). A fully dropped table and a surviving
# table that lost all its indexes both present as absent from target indexes.
my @ops = DBIO::DuckDB::Diff::Index->diff(
  {
    leftover => {
      idx_leftover_val => {
        index_name => 'idx_leftover_val',
        is_unique  => 0,
        columns    => ['val'],
      },
    },
  },
  {},
  # source tables: the leftover table exists live
  { leftover => { table_name => 'leftover', kind => 'table', schema => 'main' } },
  # target tables: it is gone -> table is being dropped
  {},
);
is scalar(@ops), 0,
  'no standalone DROP INDEX op when owning table is dropped';

# karr #8 guard: do NOT over-suppress. If the table stays but one of its
# indexes is removed, the standalone DROP INDEX op is still required.
@ops = DBIO::DuckDB::Diff::Index->diff(
  {
    users => {
      idx_users_email => {
        index_name => 'idx_users_email',
        is_unique  => 0,
        columns    => ['email'],
      },
    },
  },
  {},
  # source tables: users exists
  { users => { table_name => 'users', kind => 'table', schema => 'main' } },
  # target tables: users still exists -> only the index is being dropped
  { users => { table_name => 'users', kind => 'table', schema => 'main' } },
);
is scalar(@ops), 1, 'index drop op still emitted when the table itself survives';
is $ops[0]->action, 'drop', 'surviving-table index drop is a drop op';
like $ops[0]->as_sql, qr/DROP INDEX\s+"?idx_users_email"?/,
  'surviving-table index still dropped standalone';

# Backward compatibility: called without the tables sections (two-arg form),
# the dropped-table set is empty and every source-only index is still dropped.
@ops = DBIO::DuckDB::Diff::Index->diff(
  {
    leftover => {
      idx_leftover_val => {
        index_name => 'idx_leftover_val',
        is_unique  => 0,
        columns    => ['val'],
      },
    },
  },
  {},
);
is scalar(@ops), 1, 'two-arg call preserves original drop behaviour';
is $ops[0]->action, 'drop', 'two-arg drop op is a drop';

done_testing;
