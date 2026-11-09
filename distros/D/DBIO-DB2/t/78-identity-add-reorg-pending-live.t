use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k55), the reorg-pending half of t/77. A table that is
# reorg-pending (an ALTER TABLE ... DROP COLUMN run by hand, no REORG) cannot be
# read: the rows question of an identity ADD (ADR 0012 addendum) died with
# SQL0668N reason code 7 when the diff was handed to $deploy->apply directly;
# only upgrade reorganised first (karr k48). apply now reorganises the tables
# that get an identity ADD itself, before the question:
#
#   - pending and holding a row: apply is refused with the rows exception (not
#     SQL0668N), the table is reorganised, nothing of the diff ran
#   - pending and empty: apply adds the column, REORG_PENDING is N afterwards,
#     the follow-up diff is empty, a new row gets the server's identity value
#
# Own table: dbio_k55_<pid>.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my $T = "dbio_k55_$$";

{
  package DBIO::Test::K55::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  use DBIO::Core ();
  __PACKAGE__->load_components('DB2');

  my $class = 'DBIO::Test::K55::T';
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Core');
  $class->table($T);
  $class->add_columns(
    id => { data_type => 'integer' },
    n  => { data_type => 'integer', is_auto_increment => 1 },
  );
  $class->set_primary_key('id');
  __PACKAGE__->register_class(T => $class);
}

use DBIO::DB2::Deploy;

my $schema = DBIO::Test::K55::Schema->connect($dsn, $user, $pass);

my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $deploy = DBIO::DB2::Deploy->new(schema => $schema);

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
sub drop_table { local $dbh->{PrintError} = 0; eval { $dbh->do(qq{DROP TABLE "$T"}) } }
END {
  if ($dbh && $dbh->{Active}) {
    drop_table();
    my ($n) = eval { $dbh->selectrow_array(
      'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA) };
    $deploy->_drop_test_schema($dbh, $COMPARE_SCHEMA) if $n;
  }
}

my ($CURRENT_SCHEMA) = $dbh->selectrow_array('VALUES CURRENT SCHEMA');
$CURRENT_SCHEMA =~ s/\s+$//;

sub reorg_pending {
  my ($pending) = $dbh->selectrow_array(
    'SELECT reorg_pending FROM sysibmadm.admintabinfo WHERE tabschema = ? AND tabname = ?',
    undef, $CURRENT_SCHEMA, $T);
  return $pending;
}
sub has_n {
  my ($n) = $dbh->selectrow_array(
    q{SELECT COUNT(*) FROM syscat.columns WHERE tabschema = CURRENT SCHEMA AND tabname = ? AND colname = 'n'},
    undef, $T);
  return $n;
}
sub make_pending {
  $dbh->do(qq{ALTER TABLE "$T" ADD COLUMN "tmp" INTEGER});
  $dbh->do(qq{ALTER TABLE "$T" DROP COLUMN "tmp"});
}

drop_table();

$dbh->do(qq{CREATE TABLE "$T" ("id" INTEGER NOT NULL, PRIMARY KEY ("id"))});
$dbh->do(qq{INSERT INTO "$T" ("id") VALUES (1)});
make_pending();

is reorg_pending(), 'Y', 'setup: the table is reorg-pending';
throws_ok { local $dbh->{PrintError} = 0; $dbh->selectrow_array(qq{SELECT 1 FROM "$T" FETCH FIRST 1 ROW ONLY}) }
  qr/SQL0668N/, 'setup: it cannot be read (SQL0668N)';

# --- pending, holding a row: the rows exception, not SQL0668N ---------------------
{
  my $diff = $deploy->diff;
  like $diff->as_sql, qr/ADD COLUMN "n" INTEGER NOT NULL DEFAULT 0;/, 'the diff holds the identity ADD';
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, @_ };
  throws_ok { $deploy->apply($diff) } qr/column "n" to table "\Q$T\E".*rows/s,
    'apply is refused with the rows exception, not SQL0668N';
  unlike $@, qr/SQL0668N/, '... (really not)';
  ok scalar(grep { /reorg/i && /\Q$T\E/ } @warned), '... and a warning says the table was reorganised'
    or diag explain \@warned;
}
is reorg_pending(), 'N', 'the table was reorganised';
is has_n(), 0, '... and nothing of the diff ran: no new column';
is_deeply $dbh->selectall_arrayref(qq{SELECT "id" FROM "$T"}), [ [1] ], '... the row is there';

# --- pending and empty: the column is added by a bare apply -------------------------
$dbh->do(qq{DELETE FROM "$T"});
make_pending();
is reorg_pending(), 'Y', 'setup: pending again, now empty';
{
  my $diff = $deploy->diff;
  local $SIG{__WARN__} = sub { };
  lives_ok { $deploy->apply($diff) } 'apply of the identity ADD onto the reorg-pending, empty table';
}
is has_n(), 1, 'the column is there';
is reorg_pending(), 'N', 'REORG_PENDING is N afterwards';
{
  my $diff = $deploy->diff;
  is scalar(@{ $diff->operations }), 0, 'the follow-up diff is empty' or diag $diff->as_sql;
}
$dbh->do(qq{INSERT INTO "$T" ("id") VALUES (2)});
is_deeply $dbh->selectall_arrayref(qq{SELECT "id", "n" FROM "$T"}), [ [2, 1] ],
  'a new row reads back with the server\'s identity value';

drop_table();
done_testing;
