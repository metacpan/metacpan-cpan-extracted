use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k48, ADR 0008 addendum). A table that is reorg-pending BEFORE
# the diff is made: an upgrade that stopped between ALTER and REORG, a REORG that
# failed, an ALTER TABLE run by hand. Reorg-pending is a state of the table and
# not part of the introspected model, so the diff sees no column difference and
# writes no REORG -- and the CREATE INDEX in the same diff, like every INSERT,
# died with SQL0668N rc 7. "Run upgrade again" did not heal it.
#
# $deploy->upgrade now reads SYSIBMADM.ADMINTABINFO.REORG_PENDING for the tables
# the diff can touch and runs the REORG first. This file brings a table into the
# state by hand (ALTER TABLE ... DROP COLUMN without a REORG, the columns left
# equal to the desired class), lets upgrade create the missing index on it, and
# asks for what an operator relies on: not pending afterwards, an empty diff, a
# row that can be inserted and read back. A table that is not pending gets no
# REORG (second block); a pending table the desired schema does not know gets none either
# (third block: the diff drops it).
#
# Own namespace: tables dbio_k48_<pid>_*.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my $P = "dbio_k48_$$";

{
  package DBIO::Test::K48::Item;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("${P}_item");
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 40 },
  );
  __PACKAGE__->set_primary_key('id');
  sub db2_indexes { { "${P}_idx_name" => { columns => ['name'] } } }
}

{
  package DBIO::Test::K48::Calm;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("${P}_calm");
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 40 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIO::Test::K48::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Item => 'DBIO::Test::K48::Item');
  __PACKAGE__->register_class(Calm => 'DBIO::Test::K48::Calm');
}

use DBIO::DB2::Deploy;

my $schema = DBIO::Test::K48::Schema->connect($dsn, $user, $pass);

my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $deploy = DBIO::DB2::Deploy->new(schema => $schema);

my @TABLES = map { "${P}_$_" } qw(item calm stray);

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

my ($CURRENT_SCHEMA) = $dbh->selectrow_array('VALUES CURRENT SCHEMA');
$CURRENT_SCHEMA =~ s/\s+$//;

sub reorg_pending {
  my ($table) = @_;
  my ($pending) = $dbh->selectrow_array(
    'SELECT reorg_pending FROM sysibmadm.admintabinfo WHERE tabschema = ? AND tabname = ?',
    undef, $CURRENT_SCHEMA, $table);
  return $pending;
}

sub shape {
  my ($diff) = @_;
  return [ map {
    my $kind = ref $_; $kind =~ s/^DBIO::DB2::Diff:://;
    join ' ', $kind, $_->action, $_->table_name;
  } @{ $diff->operations } ];
}

my $ID = '"id" INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1)';

# Takes the table into reorg-pending state by hand: add a column, drop it again,
# no REORG. The columns end up as the desired class has them.
sub make_pending {
  my ($table) = @_;
  $dbh->do(qq{ALTER TABLE "$table" ADD COLUMN "tmp" INTEGER});
  $dbh->do(qq{ALTER TABLE "$table" DROP COLUMN "tmp"});
}

drop_test_tables();

# Present from the start, so the diff of block 1 holds nothing for it.
$dbh->do(qq{CREATE TABLE "${P}_calm" ($ID, "name" VARCHAR(40) NOT NULL, PRIMARY KEY ("id"))});

# ============================================================================
# 1. The failure: pending before the diff, a new index in the same diff.
# ============================================================================
$dbh->do(qq{CREATE TABLE "${P}_item" ($ID, "name" VARCHAR(40) NOT NULL, PRIMARY KEY ("id"))});
$dbh->do(qq{INSERT INTO "${P}_item" ("name") VALUES ('before')});
make_pending("${P}_item");

is reorg_pending("${P}_item"), 'Y', 'setup: the table is reorg-pending, by hand';
throws_ok {
  local $dbh->{PrintError} = 0;
  $dbh->do(qq{INSERT INTO "${P}_item" ("name") VALUES ('x')});
} qr/SQL0668N/, 'setup: it refuses an INSERT (SQL0668N)';

my $diff = $deploy->diff;
is_deeply shape($diff), [ "Index create ${P}_item" ],
  'the diff holds the index and no REORG -- the state is not in the model';
is reorg_pending("${P}_item"), 'Y', 'diff is a read: the table is still reorg-pending';

my @warnings;
{
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  lives_ok { $deploy->upgrade } 'upgrade runs the REORG first, so the CREATE INDEX succeeds';
}
ok scalar(grep { /reorg/i && /\Q${P}_item\E/ } @warnings),
  'upgrade says which table it reorganised'
  or diag explain \@warnings;

is reorg_pending("${P}_item"), 'N', 'the table is not reorg-pending afterwards';
is_deeply shape($deploy->diff), [], 'the diff after the upgrade has no operations';
{
  my ($n) = $dbh->selectrow_array(
    'SELECT COUNT(*) FROM syscat.indexes WHERE tabschema = ? AND indname = ?',
    undef, $CURRENT_SCHEMA, "${P}_idx_name");
  is $n, 1, '... and the index exists';
}
{
  my $row = eval { $schema->resultset('Item')->create({ name => 'after' }) };
  diag "insert failed: $@" unless $row;
  is $row && $schema->resultset('Item')->find($row->id)->name, 'after',
    'a row inserted afterwards can be read back';
  is eval { $schema->resultset('Item')->search({ name => 'before' })->count }, 1,
    '... and the row that was there is still there';
}

# ============================================================================
# 2. A table that is not pending: no REORG, no warning.
# ============================================================================
is reorg_pending("${P}_calm"), 'N', 'setup: not pending';
@warnings = ();
{
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  lives_ok { $deploy->upgrade } 'upgrade of a table that is not pending';
}
ok !(grep { /reorg/i } @warnings), 'no REORG is reported for it' or diag explain \@warnings;
is_deeply shape($deploy->diff), [], 'follow-up diff empty';

# ============================================================================
# 3. A pending table the desired schema does not know is in the source model
#    only: the diff drops it, so no REORG is spent on it.
# ============================================================================
$dbh->do(qq{CREATE TABLE "${P}_stray" ($ID, "name" VARCHAR(20) NOT NULL, PRIMARY KEY ("id"))});
make_pending("${P}_stray");
@warnings = ();
{
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  lives_ok { $deploy->upgrade(allow_destructive => 1) } 'upgrade with a pending table outside the desired schema';
}
ok !(grep { /\Q${P}_stray\E/ } @warnings), '... no REORG is reported for it' or diag explain \@warnings;
is eval { reorg_pending("${P}_stray") }, undef, '... the diff dropped it';

drop_test_tables();
is compare_schema_count(), 0, 'the compare schema is gone';

done_testing;
