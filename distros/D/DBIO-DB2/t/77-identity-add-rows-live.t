use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k54, ADR 0012 addendum), the counterpart of t/76. An identity
# column added to a table through the public DBIO::DB2::Deploy API, on a table of
# its own (dbio_k54i_<pid>):
#
#   - the table holds a row, the class declares the identity column: upgrade is
#     refused with an exception naming table and column, the table is as it was
#     (no new column, the row is there), and apply of the diff is refused too
#   - the diff itself (as_sql) is still made, it is a read
#   - the table emptied: upgrade adds the column, the follow-up diff is empty, a
#     new row gets the server's identity value

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my $T = "dbio_k54i_$$";

{
  package DBIO::Test::K54I::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  use DBIO::Core ();
  __PACKAGE__->load_components('DB2');

  my $class = 'DBIO::Test::K54I::T';
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

my $schema = DBIO::Test::K54I::Schema->connect($dsn, $user, $pass);

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

sub has_n {
  my ($n) = $dbh->selectrow_array(
    q{SELECT COUNT(*) FROM syscat.columns WHERE tabschema = CURRENT SCHEMA AND tabname = ? AND colname = 'n'},
    undef, $T);
  return $n;
}

drop_table();

# the table as an older class had it: no identity column, one row
$dbh->do(qq{CREATE TABLE "$T" ("id" INTEGER NOT NULL, PRIMARY KEY ("id"))});
$dbh->do(qq{INSERT INTO "$T" ("id") VALUES (1)});

{
  my $diff = eval { $deploy->diff };
  ok $diff, 'the diff is made (a read) although the table holds a row' or diag $@;
  like $diff->as_sql, qr/ADD COLUMN "n" INTEGER NOT NULL DEFAULT 0;/, '... and holds the identity ADD';

  throws_ok { $deploy->apply($diff) } qr/column "n" to table "\Q$T\E".*rows/s,
    'apply is refused, naming table and column';
}
throws_ok { $deploy->upgrade } qr/column "n" to table "\Q$T\E"/, 'upgrade is refused';
is has_n(), 0, 'the table is unchanged: no new column';
is_deeply $dbh->selectall_arrayref(qq{SELECT "id" FROM "$T"}), [ [1] ], '... the row is there';

# empty: as built
$dbh->do(qq{DELETE FROM "$T"});
lives_ok { $deploy->upgrade } 'the emptied table takes the identity column';
is has_n(), 1, 'the column is there';
{
  my ($ident) = $dbh->selectrow_array(
    q{SELECT identity FROM syscat.columns WHERE tabschema = CURRENT SCHEMA AND tabname = ? AND colname = 'n'}, undef, $T);
  is $ident, 'Y', '... as an identity';
}
{
  my $diff = eval { $deploy->diff };
  ok $diff, 'diff after the upgrade' or diag $@;
  is scalar(@{ $diff->operations }), 0, 'the follow-up diff is empty'
    or diag $diff->as_sql;
}
$dbh->do(qq{INSERT INTO "$T" ("id") VALUES (2)});
is_deeply $dbh->selectall_arrayref(qq{SELECT "id", "n" FROM "$T"}), [ [2, 1] ], 'a new row gets the server\'s identity value';

done_testing;
