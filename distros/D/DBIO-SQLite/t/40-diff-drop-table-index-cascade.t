use strict;
use warnings;
use Test::More;

use DBIO::SQLite::Diff;

# Regression for karr #14.
#
# When DBIO::SQLite::Diff reconciles a live schema that contains a table NOT
# present in the target (a table removed from the app's DBIO classes, or an
# unmanaged leftover table), the diff used to emit BOTH:
#
#   DROP TABLE leftover;                 (Diff::Table, "tables" phase)
#   DROP INDEX idx_leftover_name;        (Diff::Index, later "indexes" phase)
#
# as_sql runs tables before indexes, and SQLite's DROP TABLE automatically
# removes the table's own indexes/triggers. The later standalone
# DROP INDEX idx_leftover_name then fails against a real DB with
# "no such index: idx_leftover_name", aborting apply()/upgrade().
#
# The fix: Diff::Index must suppress a standalone DROP INDEX for any index whose
# owning table is itself being dropped in the same pass.

# --- Live (source) model: a leftover table with an explicit index -----------
my $source = {
  tables  => { leftover => { table_name => 'leftover' } },
  columns => {
    leftover => [
      { column_name => 'id',   data_type => 'INTEGER', is_pk => 1, not_null => 0 },
      { column_name => 'name', data_type => 'TEXT' },
    ],
  },
  indexes => {
    leftover => {
      idx_leftover_name => {
        index_name => 'idx_leftover_name',
        is_unique  => 0,
        columns    => ['name'],
        origin     => 'c',
        sql        => 'CREATE INDEX idx_leftover_name ON leftover(name)',
      },
    },
  },
  foreign_keys => {},
};

# --- Target model: the leftover table is gone (removed from the app) ---------
my $target = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };

my $diff = DBIO::SQLite::Diff->new(source => $source, target => $target);

ok $diff->has_changes, 'diff detects the removed table';

my $sql = $diff->as_sql;

like   $sql, qr/DROP TABLE leftover;/,
  'DROP TABLE is emitted for the removed table';
unlike $sql, qr/DROP INDEX\s+idx_leftover_name/,
  'no standalone DROP INDEX for the dropped table (DROP TABLE already covers it)';

# The DROP TABLE must be the only drop statement in the output — the whole
# point is that SQLite's DROP TABLE handles the index, so apply() never issues
# the redundant (and failing) DROP INDEX.
my @drop_index = ($sql =~ /(DROP INDEX[^\n;]*)/g);
is scalar(@drop_index), 0, 'zero DROP INDEX statements in the full-schema sync';

# --- Guard against over-suppression -----------------------------------------
# A table that STAYS but loses a secondary index must still get a standalone
# DROP INDEX — the fix only suppresses drops for indexes of dropped tables.
my $src2 = {
  tables  => { users => { table_name => 'users' } },
  columns => { users => [ { column_name => 'id', data_type => 'INTEGER', is_pk => 1 } ] },
  indexes => {
    users => {
      idx_users_email => {
        index_name => 'idx_users_email',
        is_unique  => 0,
        columns    => ['email'],
        origin     => 'c',
        sql        => 'CREATE INDEX idx_users_email ON users(email)',
      },
    },
  },
  foreign_keys => {},
};
my $tgt2 = {
  tables  => { users => { table_name => 'users' } },
  columns => { users => [ { column_name => 'id', data_type => 'INTEGER', is_pk => 1 } ] },
  indexes => { users => {} },
  foreign_keys => {},
};

my $sql2 = DBIO::SQLite::Diff->new(source => $src2, target => $tgt2)->as_sql;
unlike $sql2, qr/DROP TABLE/, 'surviving table is not dropped';
like   $sql2, qr/DROP INDEX\s+idx_users_email/,
  'secondary index of a surviving table is still dropped standalone';

done_testing;
