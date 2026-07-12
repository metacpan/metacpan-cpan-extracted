use strict;
use warnings;
use Test::More;

use DBIO::DB2::Diff;

# Regression for karr #19.
#
# When DBIO::DB2::Diff reconciles a live schema that contains a table NOT
# present in the target (a table removed from the app's DBIO classes, or an
# unmanaged leftover), the diff used to emit BOTH:
#
#   DROP TABLE leftover;      (Diff::Table, "tables" phase)
#   DROP INDEX idx_leftover;  (Diff::Index, later "indexes" phase)
#
# as_sql runs tables before indexes, and DB2's DROP TABLE already removes the
# table's own indexes. The later standalone DROP INDEX then fails against a real
# DB2 (the index no longer exists), aborting apply()/upgrade().
#
# The fix: Diff::Index must suppress a standalone DROP INDEX for any index whose
# owning table is itself being dropped in the same pass.

# --- Live (source) model: a leftover table with an index present -------------
my $source = {
  tables  => { leftover => { table_name => 'leftover' } },
  columns => {
    leftover => [ { column_name => 'id', data_type => 'integer', is_pk => 1 } ],
  },
  indexes => {
    leftover => {
      idx_leftover_id => { index_name => 'idx_leftover_id', is_unique => 0, columns => ['id'] },
    },
  },
  foreign_keys => {},
};

# --- Target model: the leftover table is gone (removed from the app) ---------
my $target = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };

my $diff = DBIO::DB2::Diff->new(source => $source, target => $target);

ok $diff->has_changes, 'diff detects the removed table';

my $sql = $diff->as_sql;

like   $sql, qr/DROP TABLE leftover;/,
  'DROP TABLE is emitted for the removed table';
unlike $sql, qr/DROP INDEX\s+idx_leftover_id/,
  'no standalone DROP INDEX for the dropped table (DROP TABLE already covers it)';

# DROP TABLE must be the only drop statement -- the whole point is that DB2's
# DROP TABLE handles the index, so apply() never issues the redundant (and
# failing) DROP INDEX.
my @drop_index = ($sql =~ /(DROP INDEX[^\n;]*)/g);
is scalar(@drop_index), 0, 'zero DROP INDEX statements in the full-schema sync';

# --- Guard against over-suppression -----------------------------------------
# A table that STAYS but loses an index must still get a standalone DROP INDEX --
# the fix only suppresses drops for indexes of dropped tables.
my $src2 = {
  tables  => { users => { table_name => 'users' } },
  columns => { users => [ { column_name => 'id', data_type => 'integer', is_pk => 1 } ] },
  indexes => {
    users => {
      idx_users_email => { index_name => 'idx_users_email', is_unique => 0, columns => ['email'] },
    },
  },
  foreign_keys => {},
};
my $tgt2 = {
  tables  => { users => { table_name => 'users' } },
  columns => { users => [ { column_name => 'id', data_type => 'integer', is_pk => 1 } ] },
  indexes => { users => {} },
  foreign_keys => {},
};

my $sql2 = DBIO::DB2::Diff->new(source => $src2, target => $tgt2)->as_sql;
unlike $sql2, qr/DROP TABLE/, 'surviving table is not dropped';
like   $sql2, qr/DROP INDEX\s+idx_users_email/,
  'index of a surviving table is still dropped standalone';

done_testing;
