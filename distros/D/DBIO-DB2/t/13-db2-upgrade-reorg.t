use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k42, ADR 0008). $deploy->upgrade through the public
# DBIO::DB2::Deploy API, for the changes t/12-db2-upgrade.t leaves out: the
# ALTER TABLE statements after which Db2 holds a table in reorg-pending state.
#
# Measured on Db2 12.1.5: after DROP COLUMN, SET NOT NULL, DROP NOT NULL and
# nearly every SET DATA TYPE, SYSIBMADM.ADMINTABINFO.REORG_PENDING is 'Y', and
# INSERT, UPDATE and CREATE INDEX on the table fail with SQL0668N rc 7
# (SQLSTATE 57007) until a REORG has run. The diff emitted the ALTER and no
# REORG. An upgrade whose diff dropped a column and created an index on the same
# table died at the CREATE INDEX with the column already gone (DDL is not
# transactional here), and the table took no row afterwards.
#
# The diff now carries the REORG as an operation of its own, between the column
# pass and the index pass. So every block ends on what an operator relies on:
# the table is not reorg-pending, the diff after the upgrade is empty, and a row
# inserted afterwards can be read back.
#
# The last block is the other half of the claim: a VARCHAR that only gets longer
# does not put the table in reorg-pending, and its upgrade runs no REORG.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

# Inline result classes, as in t/12-db2-upgrade.t. These are the DESIRED tables;
# each block below writes a live table by hand that differs from its class.
{
  package DBIO::Test::Reorg::Item;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbiorg_item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 40 },
    qty  => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  sub db2_indexes { { dbiorg_idx_item_name => { columns => ['name'] } } }
}

{
  package DBIO::Test::Reorg::Type;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbiorg_type');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer', is_auto_increment => 1 },
    qty    => { data_type => 'bigint', is_nullable => 1 },
    amount => { data_type => 'decimal', size => '12,2', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIO::Test::Reorg::Null;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbiorg_null');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    label => { data_type => 'varchar', size => 20 },
    memo  => { data_type => 'varchar', size => 20, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIO::Test::Reorg::Wide;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbiorg_wide');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 40 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIO::Test::Reorg::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Item => 'DBIO::Test::Reorg::Item');
  __PACKAGE__->register_class(Type => 'DBIO::Test::Reorg::Type');
  __PACKAGE__->register_class(Null => 'DBIO::Test::Reorg::Null');
  __PACKAGE__->register_class(Wide => 'DBIO::Test::Reorg::Wide');
}

use DBIO::DB2::Deploy;

my $schema = DBIO::Test::Reorg::Schema->connect($dsn, $user, $pass);

my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $deploy = DBIO::DB2::Deploy->new(schema => $schema);

my @TABLES = qw(dbiorg_item dbiorg_type dbiorg_null dbiorg_wide);

# Raw SQL in this file quotes its identifiers: the DDL does (karr k28), and an
# unquoted name folds to uppercase and misses the object.
sub drop_test_tables {
  local $dbh->{PrintError} = 0;
  eval { $dbh->do(qq{DROP TABLE "$_"}) } for @TABLES;
}

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
sub compare_schema_count {
  my ($n) = $dbh->selectrow_array(
    'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA);
  return $n;
}

END {
  if ($dbh && $dbh->{Active}) {
    drop_test_tables();
    $deploy->_drop_test_schema($dbh, $COMPARE_SCHEMA)
      if eval { compare_schema_count() };
  }
}

# The schema the unqualified names of this file land in.
my ($CURRENT_SCHEMA) = $dbh->selectrow_array('VALUES CURRENT SCHEMA');
$CURRENT_SCHEMA =~ s/\s+$//;

# 'Y' while the table waits for a REORG, 'N' otherwise -- the server's own word.
sub reorg_pending {
  my ($table) = @_;
  my ($pending) = $dbh->selectrow_array(
    'SELECT reorg_pending FROM sysibmadm.admintabinfo WHERE tabschema = ? AND tabname = ?',
    undef, $CURRENT_SCHEMA, $table);
  return $pending;
}

# The operations of a fresh $deploy->diff, or the reason there is none.
sub diff_ops {
  my $diff = eval { $deploy->diff };
  return (undef, $@) unless $diff;
  return [ @{ $diff->operations } ];
}

# One line per operation: what it is and on which table.
sub shape {
  my ($ops) = @_;
  return [ map {
    my $kind = ref $_; $kind =~ s/^DBIO::DB2::Diff:://;
    join ' ', $kind, $_->action, $_->table_name;
  } @{ $ops || [] } ];
}

sub diff_is {
  my ($expect, $name) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($ops, $err) = diff_ops();
  is_deeply shape($ops), $expect, $name
    or diag $err // join "\n", map { $_->as_sql } @$ops;
}

# Where every block ends: no REORG outstanding, nothing left to do.
sub settled {
  my ($table, $what) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is reorg_pending($table), 'N', "$what: the table is not reorg-pending";
  diff_is([], "$what: the diff after the upgrade has no operations");
}

# The identity primary key every table here has, as install_ddl writes it.
my $ID = '"id" INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1)';

drop_test_tables();

lives_ok { $deploy->install } 'install deploys the four tables';
diff_is([], 'diff right after install has no operations');

# ============================================================================
# 1. The failure on the card: one table loses a column and gains an index in
#    the same diff. Without the REORG between them the CREATE INDEX dies with
#    SQL0668N rc 7, the column is already gone, and the table takes no row.
# ============================================================================
$dbh->do('DROP TABLE "dbiorg_item"');
$dbh->do(qq{
  CREATE TABLE "dbiorg_item" (
    $ID,
    "name" VARCHAR(40) NOT NULL,
    "legacy" VARCHAR(10),
    "qty" INTEGER,
    PRIMARY KEY ("id")
  )
});
$dbh->do(q{INSERT INTO "dbiorg_item" ("name", "legacy", "qty") VALUES ('before', 'x', 1)});

diff_is([
  'Column drop dbiorg_item',
  'Reorg reorg dbiorg_item',
  'Index create dbiorg_item',
], 'diff: the dropped column, then the REORG, then the index on the same table');

lives_ok { $deploy->upgrade(allow_destructive => 1) } 'upgrade drops the column and creates the index on the same table';

settled('dbiorg_item', 'DROP COLUMN and CREATE INDEX');

{
  my $item = eval { $schema->resultset('Item')->create({ name => 'after', qty => 2 }) };
  diag "insert into the upgraded table failed: $@" unless $item;
  my $row = $item ? $schema->resultset('Item')->find($item->id) : undef;
  is $row && $row->name, 'after', 'a row inserted after the upgrade can be read back';
  is eval { $schema->resultset('Item')->search({ name => 'before' })->count }, 1,
    '... and the row that was there is still there';
  my ($index) = $dbh->selectrow_array(
    'SELECT COUNT(*) FROM syscat.indexes WHERE tabschema = ? AND indname = ?',
    undef, $CURRENT_SCHEMA, 'dbiorg_idx_item_name');
  is $index, 1, '... and the index exists';
}

# ============================================================================
# 2. A changed type: INTEGER -> BIGINT and DECIMAL(10,2) -> DECIMAL(12,2), two
#    statements that each ask for a REORG, on one table: one REORG.
# ============================================================================
$dbh->do('DROP TABLE "dbiorg_type"');
$dbh->do(qq{
  CREATE TABLE "dbiorg_type" (
    $ID,
    "qty" INTEGER,
    "amount" DECIMAL(10,2),
    PRIMARY KEY ("id")
  )
});
$dbh->do(q{INSERT INTO "dbiorg_type" ("qty", "amount") VALUES (7, 1.25)});

diff_is([
  'Column alter dbiorg_type',
  'Column alter dbiorg_type',
  'Reorg reorg dbiorg_type',
], 'diff: two changed types on one table, and one REORG after them');

lives_ok { $deploy->upgrade } 'upgrade changes both types';

settled('dbiorg_type', 'SET DATA TYPE');

{
  my $type = eval { $schema->resultset('Type')->create({ qty => 5_000_000_000, amount => '1234567890.12' }) };
  diag "insert into the upgraded table failed: $@" unless $type;
  my $row = $type ? $schema->resultset('Type')->find($type->id) : undef;
  is $row && $row->qty, '5000000000', 'a row with a value only a BIGINT holds can be read back';
  is $row && $row->amount, '1234567890.12', '... and one only a DECIMAL(12,2) holds';
  is eval { $schema->resultset('Type')->search({ qty => 7 })->count }, 1,
    '... and the row that was there is still there';
}

# ============================================================================
# 3. Nullability, both directions on one table: "label" becomes NOT NULL,
#    "memo" loses it.
# ============================================================================
$dbh->do('DROP TABLE "dbiorg_null"');
$dbh->do(qq{
  CREATE TABLE "dbiorg_null" (
    $ID,
    "label" VARCHAR(20),
    "memo" VARCHAR(20) NOT NULL,
    PRIMARY KEY ("id")
  )
});
$dbh->do(q{INSERT INTO "dbiorg_null" ("label", "memo") VALUES ('before', 'm')});

diff_is([
  'Column alter dbiorg_null',
  'Column alter dbiorg_null',
  'Reorg reorg dbiorg_null',
], 'diff: SET NOT NULL and DROP NOT NULL on one table, and one REORG after them');

lives_ok { $deploy->upgrade } 'upgrade changes the nullability of both columns';

settled('dbiorg_null', 'SET NOT NULL and DROP NOT NULL');

{
  my $null = eval { $schema->resultset('Null')->create({ label => 'after', memo => undef }) };
  diag "insert into the upgraded table failed: $@" unless $null;
  my $row = $null ? $schema->resultset('Null')->find($null->id) : undef;
  is $row && $row->label, 'after', 'a row inserted after the upgrade can be read back';
  ok $row && !defined $row->memo, '... with a NULL in the column that lost NOT NULL';
  throws_ok {
    local $dbh->{PrintError} = 0;
    $dbh->do(q{INSERT INTO "dbiorg_null" ("memo") VALUES ('no label')});
  } qr/SQL0407N/, '... and the column that became NOT NULL refuses a NULL';
}

# ============================================================================
# 4. The other half: a VARCHAR that only gets longer. The server does not ask
#    for a REORG after it, and the diff carries none.
# ============================================================================
$dbh->do('DROP TABLE "dbiorg_wide"');
$dbh->do(qq{
  CREATE TABLE "dbiorg_wide" (
    $ID,
    "name" VARCHAR(20) NOT NULL,
    PRIMARY KEY ("id")
  )
});
$dbh->do(q{INSERT INTO "dbiorg_wide" ("name") VALUES ('before')});

diff_is([ 'Column alter dbiorg_wide' ],
  'diff: a longer VARCHAR is one column operation, and no REORG');

lives_ok { $deploy->upgrade } 'upgrade makes the VARCHAR longer';

settled('dbiorg_wide', 'a longer VARCHAR, without a REORG');

{
  my $long = 'x' x 40;
  my $wide = eval { $schema->resultset('Wide')->create({ name => $long }) };
  diag "insert into the upgraded table failed: $@" unless $wide;
  my $row = $wide ? $schema->resultset('Wide')->find($wide->id) : undef;
  is $row && $row->name, $long, 'a row as long as the new length can be read back';
}

# ============================================================================
# 5. Nothing of the compare deploy is left behind.
# ============================================================================
is compare_schema_count(), 0, "no compare schema $COMPARE_SCHEMA is left in the database";

done_testing;
