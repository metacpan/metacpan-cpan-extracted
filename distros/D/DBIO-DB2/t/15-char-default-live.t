use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k46). A default_value of a result class on a character
# column is text, whatever it looks like. install_ddl used to write
# `DEFAULT 00000` on a CHAR(5): measured on Db2 12.1, the server takes it
# without an error and the default is the number 0, so an inserted row holds
# '0    ' -- the leading zeros are lost silently. 'USER' on a VARCHAR became the
# special register (the inserting user), 'NULL' became NULL.
# Everything runs through the public DBIO::DB2::Deploy API.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my $TABLE = "dbio_k46_$$";

{
  package DBIO::Test::K46::Item;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k46_$$");
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    plz     => { data_type => 'char', size => 5, is_nullable => 1, default_value => '00000' },
    who     => { data_type => 'varchar', size => 32, is_nullable => 1, default_value => 'USER' },
    nothing => { data_type => 'varchar', size => 32, is_nullable => 1, default_value => 'NULL' },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIO::Test::K46::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Item => 'DBIO::Test::K46::Item');
}

use DBIO::DB2::Deploy;

my $schema = DBIO::Test::K46::Schema->connect($dsn, $user, $pass);

my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $deploy = DBIO::DB2::Deploy->new(schema => $schema);

sub drop_test_table {
  local $dbh->{PrintError} = 0;
  eval { $dbh->do(qq{DROP TABLE "$TABLE"}) };
}

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
sub compare_schema_count {
  my ($n) = $dbh->selectrow_array(
    'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA);
  return $n;
}

END {
  if ($dbh && $dbh->{Active}) {
    drop_test_table();
    $deploy->_drop_test_schema($dbh, $COMPARE_SCHEMA)
      if eval { compare_schema_count() };
  }
}

drop_test_table();

lives_ok { $deploy->install } 'install deploys the table';

$dbh->do(qq{INSERT INTO "$TABLE" ("id") VALUES (DEFAULT)});
my ($plz, $who, $nothing) = $dbh->selectrow_array(
  qq{SELECT "plz", "who", "nothing" FROM "$TABLE"});

is $plz, '00000', 'CHAR(5) default 00000 keeps its leading zeros';
is $who, 'USER', "VARCHAR default 'USER' is the text, not the special register";
is $nothing, 'NULL', "VARCHAR default 'NULL' is the text, not NULL";

{
  my $diff = eval { $deploy->diff };
  ok $diff, 'diff after install' or diag $@;
  my @ops = $diff ? @{ $diff->operations } : (1);
  is scalar(@ops), 0, 'follow-up diff is empty'
    or diag join "\n", map { ref $_ ? $_->as_sql : $_ } @ops;
}

done_testing;
