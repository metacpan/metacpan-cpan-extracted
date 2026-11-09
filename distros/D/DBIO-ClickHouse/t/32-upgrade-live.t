use strict;
use warnings;
use Test::More;

# t/32-upgrade-live.t — a schema-driven upgrade, v1 -> v2, against a live
# ClickHouse server reached over the MySQL wire protocol.
#
# t/30-deploy.t covers drift made by hand (one DROP COLUMN). This file covers
# what upgrade is FOR: two versions of a schema, declared as two Perl schema
# classes over the SAME table names, the second installed over the first.
# ClickHouse has no embedded mode, so this is gated on DBIO_TEST_CLICKHOUSE_DSN
# and skips cleanly without it. The offline counterparts are t/40, t/41 and
# t/44 (the diff logic on hand-built models) and t/39 (which storage the
# Diff is handed).
#
# What only a server can answer, and what the assertions below are about:
#
#   1. Does ONE apply of the diff converge? A second diff must be clean, which
#      holds only if every ADD / MODIFY / DROP / CREATE the Diff renders is
#      accepted by the server AND reads back through system.* as the type the
#      desired model declared. A phantom diff here is an upgrade that never
#      finishes.
#   2. Does the data survive? The row written under v1 is still readable and
#      the server-side defaults fill the columns v2 added.
#   3. Does the guard do its job? Deploy->diff hands the Diff its storage, so
#      the statements carry IF [NOT] EXISTS, and applying the same -- now
#      stale -- diff a second time is a no-op instead of an error. That is
#      the whole reason for karr k20: re-running after a partial failure.
#      (karr k29 is the fix that makes Deploy->diff reach it at all.)
#   4. Does the Diff refuse what ClickHouse cannot do in place? Engine,
#      sorting key and partition expression are immutable.
#
# The last block checks that a table created by upgrade carries its declared
# SETTINGS (karr k30) and holds one TODO test for a known gap that is a design
# question, not a bug this file may paper over: karr k31 (views are not
# created by upgrade). It runs, and must stay "not ok # TODO" until that card
# lands.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;
use DBIO::ClickHouse::Deploy;

# no_deploy: this file wants an empty database of its own and deploys its own
# schema classes into it. The per-process database and its cleanup come with
# init_schema; the schema it returns is only used for the admin queries.
my $admin = DBIO::ClickHouse::Test->init_schema(no_deploy => 1);
my $dbh   = $admin->storage->dbh;

sub scratch_databases {
  my $rows = $dbh->selectall_arrayref(
    q{SELECT name FROM system.databases WHERE name LIKE 'dbio_deploy_tmp_%'});
  return map { $_->[0] } @$rows;
}
my %pre_existing = map { $_ => 1 } scratch_databases();

# A connected schema over a fresh set of throwaway result classes, pointed at
# THIS process's test database. Each call gets its own package so that v1 and
# v2 can declare the same table names with different columns.
my $ns_count = 0;
sub mk_schema {
  my (%sources) = @_;
  my $ns = 'DBIO::ClickHouse::Test::Upgrade' . ++$ns_count;
  for my $name (sort keys %sources) {
    my $def = $sources{$name};
    my $pkg = "${ns}::Result::$name";
    eval qq{package $pkg; use base 'DBIO::Core'; 1} or die $@;
    $pkg->load_components('ClickHouse::Result');
    if ($def->{view}) {
      $pkg->table_class('DBIO::ResultSource::View');
      $pkg->table($def->{table});
      $pkg->result_source_instance->view_definition($def->{view});
      $pkg->result_source_instance->is_virtual(0);
    }
    else {
      $pkg->table($def->{table});
    }
    $pkg->add_columns(@{ $def->{cols} });
    $pkg->set_primary_key(@{ $def->{pk} }) if $def->{pk};
    $pkg->clickhouse_table($def->{ch}) if $def->{ch};
  }
  eval qq{package $ns; use base 'DBIO::Schema'; 1} or die $@;
  $ns->load_components('ClickHouse');
  $ns->register_class($_, "${ns}::Result::$_") for sort keys %sources;
  return $ns->connect(DBIO::ClickHouse::Test->test_connect_info);
}

sub live_column_type {
  my ($table, $column) = @_;
  my ($type) = $dbh->selectrow_array(
    q{SELECT type FROM system.columns
       WHERE database = currentDatabase() AND table = ? AND name = ?},
    undef, $table, $column);
  return $type;
}

# --- the two schema versions -------------------------------------------------

# v1: the table that will change, and the table that will go away.
my %v1 = (
  A => {
    table => 't_a',
    cols  => [
      id   => { data_type => 'uuid', is_auto_increment => 1 },
      n    => { data_type => 'integer' },
      s    => { data_type => 'varchar', size => 20, is_nullable => 1 },
      gone => { data_type => 'text' },
    ],
    pk => ['id'],
  },
  D => {
    table => 't_drop',
    cols  => [ id => { data_type => 'integer' } ],
    pk    => ['id'],
  },
);

# v2's t_a, as a list so the refusal schemas below can reuse the SAME columns:
# a refusal must be down to the key / engine / partition change alone.
my @a_v2_cols = (
  id => { data_type => 'uuid', is_auto_increment => 1 },
  # MODIFY: integer -> bigint
  n  => { data_type => 'bigint' },
  # MODIFY: nullable varchar -> NOT NULL with a default (the default fills
  # rows written AFTER the change; existing values are kept)
  s  => { data_type => 'varchar', size => 20, is_nullable => 0, default_value => 'dflt' },
  # ADD, one per shape worth a different rendering
  added_dt   => { data_type => 'datetime', is_nullable => 1 },
  added_int  => { data_type => 'integer', default_value => 7 },
  added_lc   => { data_type => 'varchar', extra => { low_cardinality => 1 },
                  default_value => "it's" },
  # a NOT NULL ADD over rows needs a default: the upgrade refuses to let the
  # server fill them with a zero nobody wrote (karr k43)
  added_dec  => { data_type => 'decimal', size => [ 10, 2 ], default_value => 3 },
  added_bool => { data_type => 'boolean', default_value => \'true' },
  added_enum => { data_type => 'enum', extra => { list => [qw(a b)] }, default_value => 'b' },
  added_now  => { data_type => 'timestamp', default_value => \'now()' },
  # DROP: `gone` is no longer declared
);

my %v2 = (
  A => { table => 't_a', cols => [@a_v2_cols], pk => ['id'] },
  # a new table, with every MergeTree knob that is not the default
  N => {
    table => 't_new',
    cols  => [
      k   => { data_type => 'varchar' },
      ts  => { data_type => 'datetime' },
      ver => { data_type => 'bigint' },
      v   => { data_type => 'double precision' },
    ],
    pk => ['k'],
    ch => {
      engine       => 'ReplacingMergeTree(ver)',
      partition_by => 'toYYYYMM(ts)',
      primary_key  => ['k'],
      order_by     => [ 'k', 'ts' ],
    },
  },
  # t_drop is gone
);

# --- 1. v1 installs cleanly --------------------------------------------------

my $s1 = mk_schema(%v1);
DBIO::ClickHouse::Deploy->new(schema => $s1)->install;
ok live_column_type('t_a', 'gone'), 'v1 installed: t_a has the column v2 will drop';
ok defined live_column_type('t_drop', 'id'), '... and t_drop exists';
ok !DBIO::ClickHouse::Deploy->new(schema => $s1)->diff->has_changes,
  'a freshly installed v1 has no diff against itself';

# One row written under v1. Its `s` is NOT NULL on purpose: v2 turns the
# nullable column into a non-nullable one, and the server refuses that MODIFY
# for a part that holds a NULL (CANNOT_INSERT_NULL_IN_ORDINARY_COL, raised
# from the background mutation and left stuck, blocking every later ALTER on
# the table). Section 6b below covers the NULL case: apply refuses it up front
# (karr k32).
$s1->resultset('A')->create({ n => 1, s => 'x', gone => 'g' });

# --- 2. v2: what the Diff proposes -------------------------------------------

my $s2     = mk_schema(%v2);
my $deploy = DBIO::ClickHouse::Deploy->new(schema => $s2);
my $diff   = $deploy->diff;
isa_ok $diff, 'DBIO::ClickHouse::Diff', 'v1 -> v2 diff';
ok $diff->has_changes, '... and it has changes';

my $sql = $diff->as_sql;

# The guards. Without Deploy handing the Diff its storage (karr k29) every
# one of these is a bare statement.
like $sql, qr/DROP TABLE IF EXISTS `t_drop`/,
  'the removed table is dropped with IF EXISTS';
like $sql, qr/CREATE TABLE IF NOT EXISTS `t_new`/,
  'the new table is created with IF NOT EXISTS';
like $sql, qr/ADD COLUMN IF NOT EXISTS `added_dt`/,
  'an added column is added with IF NOT EXISTS';
like $sql, qr/DROP COLUMN IF EXISTS `gone`/,
  'the removed column is dropped with IF EXISTS';
unlike $sql, qr/MODIFY COLUMN IF/,
  'MODIFY COLUMN carries no guard -- ClickHouse has no such form (t/38)';
like $sql, qr/MODIFY COLUMN `n`/, '... and the integer -> bigint change is proposed';
like $sql, qr/MODIFY COLUMN `s`/, '... and so is nullable -> NOT NULL with a default';

# --- 3. apply converges in one pass ------------------------------------------

ok eval { $deploy->apply($diff, allow_destructive => 1); 1 }, 'apply runs the whole v1 -> v2 diff'
  or diag "server said: $@\nstatements:\n$sql";

my $again = $deploy->diff;
ok !$again->has_changes, 'the second diff is clean: one apply converged'
  or diag "phantom diff:\n" . $again->as_sql;

ok !defined $deploy->upgrade, 'upgrade on the converged database returns undef';

# What the server says the columns now are -- the other half of "clean": the
# model compares equal, but is that the type the schema asked for?
is live_column_type('t_a', 'n'), 'Int64', 'integer -> bigint is Int64 on the server';
is live_column_type('t_a', 's'), 'String', 'nullable varchar -> NOT NULL is a plain String';
is live_column_type('t_a', 'added_dt'), 'Nullable(DateTime64(3))',
  'a nullable datetime was added as Nullable(DateTime64(3))';
is live_column_type('t_a', 'added_dec'), 'Decimal(10, 2)', 'decimal(10,2) was added';
is live_column_type('t_a', 'added_bool'), 'Bool', 'boolean was added as Bool, not UInt8';
is live_column_type('t_a', 'added_lc'), 'LowCardinality(String)',
  'a low_cardinality varchar was added as LowCardinality(String)';
ok !defined live_column_type('t_a', 'gone'), 'the dropped column is gone';
ok !defined live_column_type('t_drop', 'id'), 'the removed table is gone';
is live_column_type('t_new', 'k'), 'String', 'the new table exists';

# The data survived, and the server-side defaults filled what v2 added.
my $row = $s2->resultset('A')->search->first;
ok $row, 'the row written under v1 is still readable';
is $row->get_column('n'), 1, '... n kept its value across the MODIFY';
is $row->get_column('s'), 'x', '... s kept its value across nullable -> NOT NULL';
is $row->get_column('added_int'), 7, '... an added Int32 column has its DEFAULT';
is $row->get_column('added_lc'), "it's",
  '... a default with an apostrophe survived quoting';
ok $row->get_column('added_bool'), q{... a Bool column has its DEFAULT true};
ok defined $row->get_column('added_now'), '... a DEFAULT now() column was filled';
is $row->get_column('added_enum'), 'b', '... an added Enum column has its DEFAULT';

# --- 4. the guard makes a re-apply a no-op -----------------------------------
# $diff was computed against v1 and is now STALE: every statement in it has
# already been applied. Without the guards the first of them to be repeated
# (DROP TABLE, ADD COLUMN, DROP COLUMN, CREATE TABLE) throws. With them the
# replay is silent -- which is what lets a partially failed upgrade be re-run.
# MODIFY has no guard but is idempotent by nature.

ok eval { $deploy->apply($diff, allow_destructive => 1); 1 }, 'applying the same, now stale, diff again does not throw'
  or diag "server said: $@";
ok !$deploy->diff->has_changes, '... and the database is still converged';

# --- 5. what cannot be done in place is refused ------------------------------
# t_a now exists with ORDER BY id, MergeTree, no partitioning. A schema that
# declares the same columns with a different key / engine / partition cannot
# be reached by ALTER; the Diff must say so rather than emit nothing and
# report success.

for my $case (
  [ 'a changed order_by'     => { order_by     => [ 'id', 'n' ] } ],
  [ 'a changed engine'       => { engine       => 'ReplacingMergeTree' } ],
  [ 'a changed partition_by' => { partition_by => 'n' } ],
) {
  my ($what, $ch) = @$case;
  my $refused = mk_schema(
    A => { table => 't_a', cols => [@a_v2_cols], pk => ['id'], ch => $ch },
    N => $v2{N},
  );
  my $err = do {
    local $@;
    eval { DBIO::ClickHouse::Deploy->new(schema => $refused)->diff->as_sql; 1 };
    $@;
  };
  like "$err", qr/cannot be upgraded in place/, "$what is refused, not silently ignored";
}

# --- 6. known gaps, as TODO --------------------------------------------------
# One more upgrade, from the converged v2: a table with a SETTINGS clause and
# a (non-virtual) view, both new. Neither is a failure of the assertions
# above, and neither is fixed here -- they are design questions with cards.

my %v3 = (
  %v2,
  G => {
    table => 't_gran',
    cols  => [ id => { data_type => 'integer' } ],
    pk    => ['id'],
    ch    => { settings => { index_granularity => 1024 } },
  },
  V => {
    table => 'v_new',
    view  => 'SELECT id FROM t_gran WHERE id > 1',
    cols  => [ id => { data_type => 'integer' } ],
  },
);
my $s3      = mk_schema(%v3);
my $deploy3 = DBIO::ClickHouse::Deploy->new(schema => $s3);
my $up3     = eval { $deploy3->upgrade };
ok !$@, 'v2 -> v3 upgrade runs' or diag "server said: $@";
ok !$deploy3->diff->has_changes, '... and converges (the follow-up diff is clean)';

my ($engine_full) = $dbh->selectrow_array(
  q{SELECT engine_full FROM system.tables
     WHERE database = currentDatabase() AND name = 't_gran'});
my ($view_seen) = $dbh->selectrow_array(
  q{SELECT count() FROM system.tables
     WHERE database = currentDatabase() AND name = 'v_new'});

like $engine_full // '', qr/index_granularity = 1024/,
  'a table created by upgrade carries the SETTINGS the result class declares';
ok $view_seen, 'a view newly declared in the schema exists after upgrade (karr k31)';
ok !$deploy3->diff->has_changes,
  '... and a second diff is empty once the view exists';

# --- 6b. Nullable -> NOT NULL over a column that holds NULL (karr k32) --------
# Section 3 sidesteps this on purpose (its row has no NULL). Here the NULL is
# there. Left to the server, the MODIFY is accepted, the metadata flips at
# once and the background mutation fails: the column is then unreadable and
# the NULLs uncountable. So apply must look BEFORE its first statement, refuse
# loudly, and leave the table exactly as it was -- including the unrelated
# ADD COLUMN in the same plan, which would otherwise have run first.

my @nn_v1 = ( id => { data_type => 'integer' },
              c  => { data_type => 'varchar', is_nullable => 1 } );
my @nn_v2 = ( id => { data_type => 'integer' },
              c  => { data_type => 'varchar', is_nullable => 0 },
              extra => { data_type => 'integer', default_value => 3 } );

my $sn1 = mk_schema(%v3, NN => { table => 't_nn', cols => [@nn_v1], pk => ['id'] });
DBIO::ClickHouse::Deploy->new(schema => $sn1)->upgrade;
is live_column_type('t_nn', 'c'), 'Nullable(String)', 't_nn.c starts out Nullable(String)';
$dbh->do(q{INSERT INTO t_nn (id, c) VALUES (1, NULL), (2, 'kept')});

my $sn2     = mk_schema(%v3, NN => { table => 't_nn', cols => [@nn_v2], pk => ['id'] });
my $deploy4 = DBIO::ClickHouse::Deploy->new(schema => $sn2);
my $diff4   = $deploy4->diff;
like $diff4->as_sql, qr/MODIFY COLUMN `c`/, 'the diff proposes the narrowing MODIFY (the diff itself sees no data)';

my $refusal = do { local $@; eval { $deploy4->apply($diff4, allow_destructive => 1); 1 } ? '' : "$@" };
like $refusal, qr/t_nn/,         'apply refuses: the message names the table';
like $refusal, qr/`?c`?\b/,      '... and the column';
like $refusal, qr/\b1 NULL row/, '... and the number of NULL rows';
like $refusal, qr/UPDATE `c` = <value> WHERE `c` IS NULL SETTINGS mutations_sync = 1/,
  '... and the way out';
is live_column_type('t_nn', 'c'), 'Nullable(String)', 'nothing ran: the column is still Nullable';
ok !defined live_column_type('t_nn', 'extra'), '... and the ADD COLUMN ahead of it in the plan did not run either';
is_deeply $dbh->selectall_arrayref(q{SELECT id, c FROM t_nn ORDER BY id}),
  [ [ 1, undef ], [ 2, 'kept' ] ], '... the column is readable, NULL included';
my ($stuck) = $dbh->selectrow_array(
  q{SELECT count() FROM system.mutations
     WHERE database = currentDatabase() AND table = 't_nn' AND NOT is_done});
is $stuck, 0, '... and no mutation was left hanging';

# the refusal's own remedy, then the same upgrade again
$dbh->do(q{ALTER TABLE t_nn UPDATE c = 'filled' WHERE c IS NULL SETTINGS mutations_sync = 1});
ok eval { $deploy4->upgrade(allow_destructive => 1); 1 }, 'after filling the NULLs by hand the upgrade goes through'
  or diag "server said: $@";
is live_column_type('t_nn', 'c'), 'String', '... c is a plain String now';
is_deeply $dbh->selectall_arrayref(q{SELECT id, c, extra FROM t_nn ORDER BY id}),
  [ [ 1, 'filled', 3 ], [ 2, 'kept', 3 ] ], '... both rows readable, the filled value kept';
ok !$deploy4->diff->has_changes, '... and the second diff is empty';

# --- 6b. the last skipping index goes with its column (karr k43) -------------
# A table whose only skipping index reads column x; the next version has neither
# x nor the index. The server refuses DROP COLUMN while the index stands, so the
# upgrade has to send DROP INDEX first although the target carries no index.

{
  my $with_idx = mk_schema(IX => {
    table => 't_ix',
    cols  => [ id => { data_type => 'integer' }, x => { data_type => 'integer' } ],
    pk    => ['id'],
  });
  $with_idx->source('IX')->add_index_declaration({
    name => 'ix_x', columns => ['x'],
    driver => { clickhouse => { type => 'minmax', granularity => 1 } },
  });
  DBIO::ClickHouse::Deploy->new(schema => $with_idx)->upgrade(allow_destructive => 1);  # the earlier tables of this database are dropped on purpose
  my ($n_idx) = $dbh->selectrow_array(
    q{SELECT count() FROM system.data_skipping_indices
       WHERE database = currentDatabase() AND table = 't_ix'});
  is $n_idx, 1, 't_ix starts out with its one skipping index';

  my $without = mk_schema(IX => {
    table => 't_ix', cols => [ id => { data_type => 'integer' } ], pk => ['id'],
  });
  my $d = DBIO::ClickHouse::Deploy->new(schema => $without);
  my $sql = $d->diff->as_sql;
  like $sql, qr/DROP INDEX .*`ix_x`.*DROP COLUMN .*`x`/s,
    'the diff drops the index before the column';
  ok eval { $d->upgrade(allow_destructive => 1); 1 }, 'the upgrade goes through' or diag "server said: $@";
  ($n_idx) = $dbh->selectrow_array(
    q{SELECT count() FROM system.data_skipping_indices
       WHERE database = currentDatabase() AND table = 't_ix'});
  is $n_idx, 0, 'the index is gone';
  ok !defined live_column_type('t_ix', 'x'), 'the column is gone';
  ok !$d->diff->has_changes, 'and the next diff is empty';
}

# --- 7. no scratch database leaked -------------------------------------------

my @leaked = grep { !$pre_existing{$_} } scratch_databases();
is_deeply \@leaked, [], 'no scratch database leaked across the whole upgrade cycle'
  or diag "leaked: @leaked";

done_testing;
