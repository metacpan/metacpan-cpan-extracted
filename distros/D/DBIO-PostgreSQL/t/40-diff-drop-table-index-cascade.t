use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff;

# Regression for karr #32.
#
# When DBIO::PostgreSQL::Diff reconciles a live schema that contains a table
# NOT present in the target (a table removed from the app's DBIO classes, or an
# unmanaged leftover table in public), the diff used to emit BOTH:
#
#   DROP TABLE public.leftover CASCADE;   (Diff::Table, "tables" phase)
#   DROP INDEX leftover_pkey;             (Diff::Index, later "indexes" phase)
#
# as_sql runs tables before indexes, so DROP TABLE ... CASCADE already removes
# the table's own indexes (PK index included). The later standalone
# DROP INDEX leftover_pkey then fails against a real DB with
# "index leftover_pkey does not exist", aborting apply().
#
# The fix: Diff::Index must suppress a standalone DROP INDEX for any index whose
# owning table is itself being dropped in the same pass.

# --- Live (source) model: a leftover table with its PK index present ---------
my $source = {
  tables => {
    'public.leftover' => {
      schema_name => 'public',
      table_name  => 'leftover',
      kind        => 'r',
    },
  },
  columns => {
    'public.leftover' => [
      { column_name => 'id', data_type => 'integer', not_null => 1, identity => 'a' },
    ],
  },
  indexes => {
    'public.leftover' => {
      leftover_pkey => {
        index_name    => 'leftover_pkey',
        access_method => 'btree',
        is_unique     => 1,
        is_primary    => 1,
        definition    => 'CREATE UNIQUE INDEX leftover_pkey ON public.leftover USING btree (id)',
        columns       => ['id'],
      },
    },
  },
};

# --- Target model: the leftover table is gone (removed from the app) ---------
my $target = { tables => {}, columns => {}, indexes => {} };

my $diff = DBIO::PostgreSQL::Diff->new( source => $source, target => $target );

ok $diff->has_changes, 'diff detects the removed table';

my $sql = $diff->as_sql;

like   $sql, qr/DROP TABLE public\.leftover CASCADE;/,
  'DROP TABLE ... CASCADE is emitted for the removed table';
unlike $sql, qr/DROP INDEX\s+leftover_pkey/,
  'no standalone DROP INDEX for the dropped table (CASCADE already covers it)';

# The DROP TABLE must be the only drop statement in the output — the whole point
# is that the CASCADE handles the index, so apply() never issues the redundant
# (and failing) DROP INDEX.
my @drop_index = ($sql =~ /(DROP INDEX[^\n;]*)/g);
is scalar(@drop_index), 0, 'zero DROP INDEX statements in the full-schema sync';

# --- Guard against over-suppression -----------------------------------------
# A table that STAYS but loses a secondary index must still get a standalone
# DROP INDEX — the fix only suppresses drops for indexes of dropped tables.
my $src2 = {
  tables  => { 'public.users' => { schema_name => 'public', table_name => 'users', kind => 'r' } },
  columns => { 'public.users' => [ { column_name => 'id', data_type => 'integer' } ] },
  indexes => {
    'public.users' => {
      idx_users_email => {
        index_name    => 'idx_users_email',
        access_method => 'btree',
        definition    => 'CREATE INDEX idx_users_email ON public.users USING btree (email)',
        columns       => ['email'],
      },
    },
  },
};
my $tgt2 = {
  tables  => { 'public.users' => { schema_name => 'public', table_name => 'users', kind => 'r' } },
  columns => { 'public.users' => [ { column_name => 'id', data_type => 'integer' } ] },
  indexes => { 'public.users' => {} },
};

my $sql2 = DBIO::PostgreSQL::Diff->new( source => $src2, target => $tgt2 )->as_sql;
unlike $sql2, qr/DROP TABLE/, 'surviving table is not dropped';
like   $sql2, qr/DROP INDEX\s+idx_users_email/,
  'secondary index of a surviving table is still dropped standalone';

done_testing;
