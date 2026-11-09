use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k45, ADR 0012), the counterpart of t/70. Identity columns
# through the public DBIO::DB2::Deploy API against a real Db2:
#
#   add   a class column is an identity, the table has no such column (the
#         ADD COLUMN ... GENERATED form is refused by the server, SQL0104N)
#   gain  the class column is an identity, the table's is a plain NOT NULL one
#   lose  the class column is plain, the table's is an identity
#   null  the class column is an identity, the table's is a nullable one
#
# Each ends on an empty follow-up diff and on a row that gets (or, once the
# identity is gone, no longer gets) its value from the server.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my %T = map { $_ => "dbio_k45i_${_}_$$" } qw(add gain lose null);

{
  package DBIO::Test::K45I::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  use DBIO::Core ();
  __PACKAGE__->load_components('DB2');

  for my $k (qw(add gain lose null)) {
    my $class = "DBIO::Test::K45I::$k";
    no strict 'refs';
    @{"${class}::ISA"} = ('DBIO::Core');
    $class->table("dbio_k45i_${k}_$$");
    $class->add_columns(
      id => { data_type => 'integer' },
      n  => { data_type => 'integer', ($k eq 'lose' ? () : (is_auto_increment => 1)) },
    );
    $class->set_primary_key('id');
    __PACKAGE__->register_class($k => $class);
  }
}

use DBIO::DB2::Deploy;

my $schema = DBIO::Test::K45I::Schema->connect($dsn, $user, $pass);

my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $deploy = DBIO::DB2::Deploy->new(schema => $schema);

sub drop_tables {
  local $dbh->{PrintError} = 0;
  eval { $dbh->do(qq{DROP TABLE "$_"}) } for values %T;
}

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
sub compare_schema_count {
  my ($n) = $dbh->selectrow_array(
    'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA);
  return $n;
}

END {
  if ($dbh && $dbh->{Active}) {
    drop_tables();
    $deploy->_drop_test_schema($dbh, $COMPARE_SCHEMA)
      if eval { compare_schema_count() };
  }
}

sub rows {
  my ($k) = @_;
  return join ',', map { join ':', map { $_ // 'NULL' } @$_ }
    @{ $dbh->selectall_arrayref(qq{SELECT "id", "n" FROM "$T{$k}" ORDER BY "id"}) };
}

sub reorg_pending {
  my ($k) = @_;
  my ($p) = $dbh->selectrow_array(
    q{SELECT reorg_pending FROM sysibmadm.admintabinfo WHERE tabschema = CURRENT SCHEMA AND tabname = ?},
    undef, $T{$k});
  return $p;
}

sub is_identity {
  my ($k) = @_;
  my ($i) = $dbh->selectrow_array(
    q{SELECT identity FROM syscat.columns WHERE tabschema = CURRENT SCHEMA AND tabname = ? AND colname = 'n'},
    undef, $T{$k});
  return $i;
}

drop_tables();

# ---------------------------------------------------------------------------
# install, and the diff after it is empty.
# ---------------------------------------------------------------------------
lives_ok { $deploy->install } 'install deploys the four tables';
is is_identity($_), ($_ eq 'lose' ? 'N' : 'Y'), "after install: $_ n identity as declared"
  for qw(add gain lose null);

{
  my $diff = eval { $deploy->diff };
  ok $diff, 'diff after install' or diag $@;
  my @ops = $diff ? @{ $diff->operations } : (1);
  is scalar(@ops), 0, 'follow-up diff after install is empty'
    or diag join "\n", map { ref $_ ? $_->as_sql : $_ } @ops;
}

# ---------------------------------------------------------------------------
# Bring the tables into the four starting states by hand.
# ---------------------------------------------------------------------------
# add: no rows. An identity column added to a table with rows is refused (karr k54,
# ADR 0012 addendum: Db2 would set them to 0), t/77 is that case.
$dbh->do(qq{ALTER TABLE "$T{add}" DROP COLUMN "n"});              # reorg-pending

$dbh->do(qq{ALTER TABLE "$T{gain}" ALTER COLUMN "n" DROP IDENTITY});
$dbh->do(qq{INSERT INTO "$T{gain}" VALUES (1, 10)});
$dbh->do(qq{INSERT INTO "$T{gain}" VALUES (2, 20)});

$dbh->do(qq{ALTER TABLE "$T{lose}" ALTER COLUMN "n" SET GENERATED ALWAYS AS IDENTITY});
$dbh->do(qq{INSERT INTO "$T{lose}" ("id") VALUES (1)});

$dbh->do(qq{ALTER TABLE "$T{null}" ALTER COLUMN "n" DROP IDENTITY});
$dbh->do(qq{ALTER TABLE "$T{null}" ALTER COLUMN "n" DROP NOT NULL});
$dbh->do(qq{CALL SYSPROC.ADMIN_CMD('REORG TABLE "$T{null}"')});
$dbh->do(qq{INSERT INTO "$T{null}" VALUES (1, 5)});

is is_identity('add'), undef, 'add: the column is gone';
is is_identity('gain'), 'N', 'gain: plain column';
is is_identity('lose'), 'Y', 'lose: identity column';
is is_identity('null'), 'N', 'null: plain column';

# ---------------------------------------------------------------------------
# The diff names every one of them.
# ---------------------------------------------------------------------------
{
  my $sql = $deploy->diff->as_sql;
  like $sql, qr/ALTER TABLE "\Q$T{add}\E" ADD COLUMN "n" INTEGER NOT NULL DEFAULT 0;\s+ALTER TABLE "\Q$T{add}\E" ALTER COLUMN "n" DROP DEFAULT;\s+ALTER TABLE "\Q$T{add}\E" ALTER COLUMN "n" SET GENERATED ALWAYS AS IDENTITY;/,
    'add: the three statements';
  like $sql, qr/ALTER TABLE "\Q$T{gain}\E" ALTER COLUMN "n" SET GENERATED ALWAYS AS IDENTITY;/,
    'gain: SET GENERATED';
  like $sql, qr/ALTER TABLE "\Q$T{lose}\E" ALTER COLUMN "n" DROP IDENTITY;/, 'lose: DROP IDENTITY';
  like $sql, qr/ALTER TABLE "\Q$T{null}\E" ALTER COLUMN "n" SET NOT NULL;\s+ALTER TABLE "\Q$T{null}\E" ALTER COLUMN "n" SET GENERATED ALWAYS AS IDENTITY;/,
    'null: SET NOT NULL, then SET GENERATED';
}

# ---------------------------------------------------------------------------
# upgrade, and what the tables are afterwards.
# ---------------------------------------------------------------------------
{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  lives_ok { $deploy->upgrade } 'upgrade runs through';
}

is is_identity($_), ($_ eq 'lose' ? 'N' : 'Y'), "after upgrade: $_ n identity as declared"
  for qw(add gain lose null);
is reorg_pending($_), 'N', "after upgrade: $_ is not reorg-pending" for qw(add gain lose null);

{
  my $diff = eval { $deploy->diff };
  ok $diff, 'diff after upgrade' or diag $@;
  my @ops = $diff ? @{ $diff->operations } : (1);
  is scalar(@ops), 0, 'follow-up diff after upgrade is empty'
    or diag join "\n", map { ref $_ ? $_->as_sql : $_ } @ops;
}

# Rows that existed are as they were; a new one gets the server's value.
$dbh->do(qq{INSERT INTO "$T{$_}" ("id") VALUES (3)}) for qw(add gain null);
is rows('add'),  '3:1',           'add: the new row has its identity';
is rows('gain'), '1:10,2:20,3:1', 'gain: existing values kept, the new row has its identity';
is rows('null'), '1:5,3:1',       'null: existing value kept, the new row has its identity';

throws_ok { $dbh->do(qq{INSERT INTO "$T{gain}" VALUES (4, 99)}) or die $dbh->errstr }
  qr/SQL0798N/, 'gain: the server now refuses a value for the identity column';

# lose: the column takes a value of its own now.
lives_ok { $dbh->do(qq{INSERT INTO "$T{lose}" VALUES (2, 77)}) or die $dbh->errstr }
  'lose: an explicit value is accepted';
is rows('lose'), '1:1,2:77', 'lose: the row that had an identity value keeps it';

done_testing;
