use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();
use DBIO::Test;

# Live integration test for the karr #14 FK feature, end-to-end against a REAL
# DB2 (the orchestrator runs it inside the maint/docker stack). Covers:
#   * install_ddl emitting a NAMED, deterministic FK constraint
#   * RI actually enforced by the server
#   * DBIO::DB2::Diff::ForeignKey ALTER TABLE ADD / DROP / modify(drop+add)
#   * the test-deploy-and-compare round-trip being idempotent (zero FK ops)
#
# Kept separate from t/10-db2.t, which is focused on storage. Skips cleanly with
# no live DB2, exactly like t/10-db2.t.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

# ----------------------------------------------------------------------------
# A small, self-contained 2-table schema with one FK relationship, mirroring
# the inline-schema pattern of t/35-ddl-fk.t (belongs_to +
# is_foreign_key_constraint). DBIO::Test::Schema is much larger and its full
# DDL roundtrip is unrelated to the FK path under test, so a focused schema is
# less friction and makes the assertions unambiguous.
#
# Deterministic FK name (DBIO::DB2::DDL::_fk_constraint_name) is
# fk_<table>_<from_cols> => "fk_dbiofk_child_parent_id". DB2 folds unquoted
# identifiers to UPPERCASE, so the live catalog (and thus every introspected
# model) carries it as FK_DBIOFK_CHILD_PARENT_ID.
{
  package DBIO::Test::FK::Parent;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbiofk_parent');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 255, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many('children', 'DBIO::Test::FK::Child', 'parent_id');
}

{
  package DBIO::Test::FK::Child;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbiofk_child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 1 },
    label     => { data_type => 'varchar', size => 255, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  # Default belongs_to -> NO ACTION rules; FK still emitted (DB2 enforces RI).
  __PACKAGE__->belongs_to('parent', 'DBIO::Test::FK::Parent', 'parent_id');
}

{
  package DBIO::Test::FK::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Parent => 'DBIO::Test::FK::Parent');
  __PACKAGE__->register_class(Child  => 'DBIO::Test::FK::Child');
}

use DBIO::DB2::Deploy;
use DBIO::DB2::Introspect;
use DBIO::DB2::Diff;

my $PARENT = 'dbiofk_parent';
my $CHILD  = 'dbiofk_child';
my $FK_NAME = 'FK_DBIOFK_CHILD_PARENT_ID';   # uppercase: DB2 folds unquoted names

my $schema = DBIO::Test::FK::Schema->connect($dsn, $user, $pass)
  or plan skip_all => "Cannot connect: $DBI::errstr";

my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

# The introspector default schema is 'USER', which does not match the connected
# user's real CURRENT SCHEMA (e.g. DB2INST1). Resolve the live schema so the
# source side of a diff actually sees our tables. This is also why the FK
# add/drop/modify/idempotency blocks below drive DBIO::DB2::Introspect +
# DBIO::DB2::Diff directly rather than $deploy->diff/upgrade: the high-level
# diff path introspects the live side with the default 'USER' schema and would
# phantom-create everything instead of producing the targeted FK op we assert.
# (install, step 1, does NOT introspect the live schema -- it just runs
# install_ddl -- so it is driven via the public $deploy->install.)
my $live_schema = eval {
  my ($s) = $dbh->selectrow_array('VALUES CURRENT SCHEMA');
  $s =~ s/\s+$// if defined $s;   # CURRENT SCHEMA is CHAR(128), space-padded
  $s;
} or plan skip_all => "Cannot determine CURRENT SCHEMA: $@";

my $deploy = DBIO::DB2::Deploy->new(schema => $schema);

# Introspect the live (connected-user) schema. Helper so every block reads the
# same way the source model is built.
sub live_model { DBIO::DB2::Introspect->new(dbh => $dbh, schema => $live_schema)->model }

# FK list for a table out of an introspected model (canonical shape from
# DBIO::DB2::Introspect::ForeignKeys: constraint_name, from_columns, to_table,
# to_columns, on_delete, on_update). Table key is uppercase in the live catalog.
sub fks_for {
  my ($model, $table) = @_;
  return $model->{foreign_keys}{ uc $table } || [];
}

# --- hygiene: clear leftovers from a previous run (child before parent) ------
sub drop_test_tables {
  eval { $dbh->do("DROP TABLE $CHILD") };
  eval { $dbh->do("DROP TABLE $PARENT") };
}
drop_test_tables();

# ============================================================================
# 1. install: deploy parent + child(FK to parent) via the public API.
#    Assert the FK landed as a NAMED constraint with the deterministic name,
#    correct from/to columns, and that RI is actually ENFORCED by the server.
# ============================================================================
lives_ok { $deploy->install } 'install deploys parent + child schema';

{
  my $model = live_model();

  ok exists $model->{tables}{ uc $PARENT }, 'parent table created';
  ok exists $model->{tables}{ uc $CHILD },  'child table created';

  my $fks = fks_for($model, $CHILD);
  is scalar(@$fks), 1, 'child has exactly one FK after install';

  my $fk = $fks->[0];
  is uc($fk->{constraint_name}), $FK_NAME,
    'FK landed as a NAMED constraint with the deterministic fk_<table>_<cols> name';
  is_deeply [ map { lc } @{ $fk->{from_columns} } ], ['parent_id'],
    'FK from_columns is the child local column';
  is uc($fk->{to_table}), uc($PARENT),
    'FK references the parent table';
  is_deeply [ map { lc } @{ $fk->{to_columns} } ], ['id'],
    'FK to_columns is the parent primary key';

  # RI enforced: a child row pointing at a non-existent parent must die.
  dies_ok {
    $dbh->do("INSERT INTO $CHILD (parent_id, label) VALUES (99999, 'orphan')");
  } 'inserting a child with a non-existent parent key violates RI (dies)';

  # A valid child (pointing at a real parent) must live.
  $dbh->do("INSERT INTO $PARENT (name) VALUES ('p1')");
  my ($pid) = $dbh->selectrow_array("SELECT id FROM $PARENT WHERE name = 'p1'");
  ok $pid, 'parent row inserted';
  lives_ok {
    $dbh->do("INSERT INTO $CHILD (parent_id, label) VALUES ($pid, 'ok')");
  } 'inserting a child with a valid parent key satisfies RI (lives)';
}

# ============================================================================
# 5. idempotency (asserted right after install, the key round-trip guard):
#    diff the live model against itself-shaped target -> ZERO FK ops.
#    Both source and target carry the SAME introspected (uppercase, rule-coded)
#    FK, so a name-based, field-based FK diff must produce nothing. This is the
#    regression guard for the test-deploy-and-compare round-trip: if install_ddl
#    stopped emitting the FK, or the name/rule did not round-trip, this fails.
# ============================================================================
{
  my $model = live_model();
  my $diff  = DBIO::DB2::Diff->new(source => $model, target => $model);
  my @fk_ops = grep { $_->isa('DBIO::DB2::Diff::ForeignKey') } @{ $diff->operations };
  is scalar(@fk_ops), 0,
    'idempotent: introspected model diffed against itself yields zero FK ops';
}

# ============================================================================
# 6. HIGH-LEVEL path (karr #17): drive $deploy->diff itself, not the direct
#    Introspect+Diff bypass the blocks above use. This now works because
#    DBIO::DB2::Deploy->_introspect_current resolves the connection's CURRENT
#    SCHEMA for the source model -- before the #17 fix it introspected the
#    introspector-default 'USER' schema, came back empty, and phantom-created
#    the entire freshly-installed schema. _build_target_model deploys the
#    desired schema into a throwaway _dbio_test_<pid> schema (the FK's
#    REFERENCES target is now qualified into that schema too, so the compare
#    child does not cross-reference the live parent) and introspects it.
#
#    Run this BEFORE the drop/add/modify FK blocks below mutate the live FK:
#    the DB is still in the exact state install_ddl produced, so a true
#    high-level round-trip must report ZERO changes.
# ============================================================================
{
  my $diff = $deploy->diff;   # _introspect_current (CURRENT SCHEMA) vs throwaway

  ok !$diff->has_changes,
    'high-level $deploy->diff is a true no-op against the freshly-installed DB';

  my @ops = @{ $diff->operations };
  is scalar(@ops), 0,
    'high-level diff emits zero ops (source schema resolved, not phantom-recreated)';

  my @fk_ops = grep { $_->isa('DBIO::DB2::Diff::ForeignKey') } @ops;
  is scalar(@fk_ops), 0,
    'high-level diff emits zero FK ops (the throwaway compare FK round-trips)';
}

# ============================================================================
# 3. drop FK: diff toward a target whose child carries NO FK -> a single
#    ALTER TABLE ... DROP FOREIGN KEY op (using the real server name). Apply it,
#    re-introspect, assert the FK is gone but the tables remain.
# ============================================================================
{
  my $source = live_model();
  my $target = live_model();
  $target->{foreign_keys}{ uc $CHILD } = [];   # desired: child without the FK

  my @ops = DBIO::DB2::Diff::ForeignKey->diff(
    $source->{foreign_keys}, $target->{foreign_keys},
    $source->{tables},       $target->{tables},
  );
  is scalar(@ops), 1, 'dropping the only FK yields one op';
  is $ops[0]->action, 'drop', 'op is a DROP';
  like $ops[0]->as_sql,
    qr/^ALTER TABLE \Q$CHILD\E DROP FOREIGN KEY \Q$FK_NAME\E;$/i,
    'DROP FOREIGN KEY uses the real server-carried constraint name';

  $dbh->do($_->as_sql) for @ops;

  my $after = fks_for(live_model(), $CHILD);
  is scalar(@$after), 0, 'FK is gone after applying the DROP';
  ok exists live_model()->{tables}{ uc $CHILD }, 'child table still present';
}

# ============================================================================
# 2. add FK to an existing table: the child now has no FK (we just dropped it).
#    Build a target that desires the FK back (deterministic name + parent ref)
#    -> a single ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY op. Apply it,
#    re-introspect, assert the FK exists again and RI is enforced.
# ============================================================================
{
  my $source = live_model();   # child currently FK-less
  is scalar(@{ fks_for($source, $CHILD) }), 0,
    'precondition: child has no FK before the ADD';

  # Desired FK, in the canonical introspected shape the Diff/DDL clause expects.
  my $desired_fk = {
    constraint_name => lc $FK_NAME,            # deterministic name from DDL
    from_columns    => ['parent_id'],
    to_table        => $PARENT,
    to_columns      => ['id'],
    on_delete       => 'NO ACTION',
    on_update       => 'NO ACTION',
  };
  my $target = live_model();
  $target->{foreign_keys}{ uc $CHILD } = [ $desired_fk ];

  my @ops = DBIO::DB2::Diff::ForeignKey->diff(
    $source->{foreign_keys}, $target->{foreign_keys},
    $source->{tables},       $target->{tables},
  );
  is scalar(@ops), 1, 'adding an FK to an existing table yields one op';
  is $ops[0]->action, 'add', 'op is an ADD';
  like $ops[0]->as_sql,
    qr/^ALTER TABLE \Q$CHILD\E ADD CONSTRAINT \Q$FK_NAME\E FOREIGN KEY \(parent_id\) REFERENCES \Q$PARENT\E\(id\);$/i,
    'ADD CONSTRAINT ... FOREIGN KEY ... renders the named clause';

  $dbh->do($_->as_sql) for @ops;

  my $after = fks_for(live_model(), $CHILD);
  is scalar(@$after), 1, 'FK exists again after applying the ADD';
  is uc($after->[0]{constraint_name}), $FK_NAME,
    're-added FK round-trips with the deterministic name';

  # RI is enforced again by the freshly added constraint.
  dies_ok {
    $dbh->do("INSERT INTO $CHILD (parent_id, label) VALUES (88888, 'orphan2')");
  } 'RI enforced by the re-added FK (orphan child dies)';
}

# ============================================================================
# 4. modify FK (change ON DELETE rule): DB2 has no ALTER for an FK definition,
#    so a change is a drop-then-add pair (drop first). Build a target whose FK
#    has the same name but ON DELETE CASCADE, diff -> assert drop+add, apply,
#    and verify the live catalog now reports the CASCADE delete rule.
#    DB2 SYSCAT stores rule CODES (A=NO ACTION, C=CASCADE, N=SET NULL,
#    R=RESTRICT), but DBIO::DB2::Introspect::ForeignKeys normalizes them to SQL
#    keywords, so we assert the introspected on_delete changed from NO ACTION to
#    CASCADE.
# ============================================================================
{
  my $source = live_model();
  my $cur = fks_for($source, $CHILD)->[0];
  is scalar(@{ fks_for($source, $CHILD) }), 1,
    'precondition: child has the FK before the modify';

  # Desired FK: same identity, ON DELETE CASCADE.
  my $modified_fk = {
    constraint_name => $cur->{constraint_name},   # keep the live (real) name
    from_columns    => ['parent_id'],
    to_table        => $PARENT,
    to_columns      => ['id'],
    on_delete       => 'CASCADE',
    on_update       => 'NO ACTION',
  };
  my $target = live_model();
  $target->{foreign_keys}{ uc $CHILD } = [ $modified_fk ];

  my @ops = DBIO::DB2::Diff::ForeignKey->diff(
    $source->{foreign_keys}, $target->{foreign_keys},
    $source->{tables},       $target->{tables},
  );
  is scalar(@ops), 2, 'changing the ON DELETE rule yields a drop+add pair';
  is $ops[0]->action, 'drop', 'drop first';
  is $ops[1]->action, 'add',  'add second';
  like $ops[1]->as_sql, qr/ON DELETE CASCADE/i,
    'the re-add renders ON DELETE CASCADE';

  $dbh->do($_->as_sql) for @ops;

  my $after = fks_for(live_model(), $CHILD)->[0];
  ok $after, 'FK still present after the modify';
  # DBIO::DB2::Introspect::ForeignKeys normalizes DB2's DELETERULE code (C) to
  # the SQL keyword CASCADE, so the live introspected rule must now report the
  # keyword (it was NO ACTION before the modify).
  is uc($after->{on_delete} // ''), 'CASCADE',
    'live catalog now reports the CASCADE delete rule';
}

# ============================================================================
# 7. HIGH-LEVEL targeted delta (karr #17): prove the high-level $deploy->diff
#    sees the LIVE tables and emits only the genuine difference -- it does NOT
#    full-re-create the schema (the bug this ticket fixes). Add a transient
#    column to the live child so it now has one column the desired schema lacks;
#    $deploy->diff must want to DROP exactly that column, with ZERO table ops.
#
#    Run LAST (after the FK drop/add/modify blocks) for two reasons: (a) those
#    blocks need the pristine install state, which this would perturb; (b) DB2's
#    DROP COLUMN puts a table in reorg-pending, blocking further DDL on it -- so
#    we only do it once nothing else touches the child. We assert on table + the
#    transient-column op specifically and do NOT assert zero FK ops here: block 4
#    left the live FK as ON DELETE CASCADE while the desired schema is NO ACTION,
#    a legitimate FK delta that is beside the point of this re-create guard.
# ============================================================================
{
  my $DELTA_COL = 'dbio_delta_col';
  $dbh->do("ALTER TABLE $CHILD ADD COLUMN $DELTA_COL integer");

  my @delta_ops = @{ $deploy->diff->operations };

  my @tbl_ops = grep { $_->isa('DBIO::DB2::Diff::Table') } @delta_ops;
  is scalar(@tbl_ops), 0,
    'targeted delta: high-level diff emits NO table ops (no full re-create)';

  my @col_ops = grep { $_->isa('DBIO::DB2::Diff::Column') } @delta_ops;
  is scalar(@col_ops), 1, 'targeted delta: exactly one column op';
  is $col_ops[0]->action, 'drop',
    'targeted delta: the op drops the column the live DB has but the schema lacks';
  is lc($col_ops[0]->column_name), $DELTA_COL,
    'targeted delta: the op targets the transient column, not the real ones';

  # Best-effort restore (DROP COLUMN -> reorg-pending; tables are dropped in END
  # regardless, so do not fail the run if this cannot complete).
  eval { $dbh->do("ALTER TABLE $CHILD DROP COLUMN $DELTA_COL") };
}

done_testing;

# clean up our mess (child before parent: FK dependency order)
END {
  if (my $dbh = eval { $schema->storage->_dbh }) {
    eval { $dbh->do("DROP TABLE $CHILD") };
    eval { $dbh->do("DROP TABLE $PARENT") };
    # The high-level $deploy->diff above builds a throwaway DBIO_TEST_<pid>
    # schema and drops it itself; but if that drop was swallowed on a failure
    # path (DBIO::DB2::Deploy::_build_target_model swallows the DROP SCHEMA
    # error when a model was produced), best-effort drop it here so no schema
    # leaks. ADMIN_DROP_SCHEMA needs the SYSTOOLSPACE tablespace (absent on a
    # stock DB2), so tear it down with plain DDL + catalog lookups instead: drop
    # the schema's FK constraints, then its tables, then the empty schema -- each
    # under eval so a stale/already-clean state never fails the run.
    my $test_schema = 'DBIO_TEST_' . $$;
    local $dbh->{FetchHashKeyName} = 'NAME_lc';   # DBD::DB2 upper-cases hashref keys
    for my $fk (@{ $dbh->selectall_arrayref(
        q{SELECT tabname, constname FROM syscat.tabconst WHERE tabschema = ? AND type = 'F'},
        { Slice => {} }, $test_schema) || [] }) {
      eval { local $dbh->{PrintError} = 0;
        $dbh->do("ALTER TABLE $test_schema.$fk->{tabname} DROP FOREIGN KEY $fk->{constname}") };
    }
    for my $t (@{ $dbh->selectall_arrayref(
        q{SELECT tabname FROM syscat.tables WHERE tabschema = ? AND type = 'T'},
        { Slice => {} }, $test_schema) || [] }) {
      eval { local $dbh->{PrintError} = 0; $dbh->do("DROP TABLE $test_schema.$t->{tabname}") };
    }
    eval { local $dbh->{PrintError} = 0; $dbh->do("DROP SCHEMA $test_schema RESTRICT") };
  }
  undef $schema;
}
