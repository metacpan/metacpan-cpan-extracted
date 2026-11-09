use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k53). A new table with a primary key is one CREATE TABLE and
# no index operation in the diff.
#
# Why no index operation: Db2 creates the index behind a primary key in schema
# SYSIBM (SYSCAT.INDEXES: INDSCHEMA = 'SYSIBM', UNIQUERULE = 'P'), under a
# name of its own that differs from schema to schema. The model holds it since
# karr k45 (ADR 0011), marked `origin => 'pk'`, and DBIO::DB2::Diff::Index
# leaves every such index alone: it is the primary key, written inline in
# CREATE TABLE, not an index to create or drop. t/66 holds the model side.
#
# Block 3 pins the reason as an assertion: the backing index is in SYSIBM, so
# its name cannot be the same on the live and on the compare side.
# Everything runs through the public DBIO::DB2::Deploy API.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my $TABLE = "dbio_k53_$$";

{
  package DBIO::Test::K53::Item;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k53_$$");
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 50 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIO::Test::K53::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Item => 'DBIO::Test::K53::Item');
}

use DBIO::DB2::Deploy;

my $schema = DBIO::Test::K53::Schema->connect($dsn, $user, $pass);

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

# ============================================================================
# 1. The diff against a schema without the table.
# ============================================================================
{
  my $diff = eval { $deploy->diff };
  ok $diff, 'diff against the empty schema' or diag $@;
  my @ops = $diff ? @{ $diff->operations } : ();
  my @sql = map { $_->as_sql } @ops;

  is scalar(@ops), 1, 'exactly one operation' or diag join "\n", @sql;
  ok $ops[0] && $ops[0]->isa('DBIO::DB2::Diff::Table') && $ops[0]->action eq 'create',
    '... a CREATE TABLE';
  like $sql[0] // '', qr/PRIMARY KEY\s*\("id"\)/, '... with the PRIMARY KEY inline';
  is scalar(grep { $_->isa('DBIO::DB2::Diff::Index') } @ops), 0, 'no index operation';
  unlike join("\n", @sql), qr/CREATE\s+(?:UNIQUE\s+)?INDEX/i, 'no CREATE [UNIQUE] INDEX in the SQL';
}

# ============================================================================
# 2. After install the follow-up diff is empty.
# ============================================================================
lives_ok { $deploy->install } 'install deploys the table';
{
  my $diff = eval { $deploy->diff };
  ok $diff, 'diff after install' or diag $@;
  my @ops = $diff ? @{ $diff->operations } : (1);
  is scalar(@ops), 0, 'follow-up diff is empty'
    or diag join "\n", map { ref $_ ? $_->as_sql : $_ } @ops;
}

# ============================================================================
# 3. The reason: the backing index of the primary key lives in SYSIBM,
# under a name of the server's.
# ============================================================================
{
  my $rows = $dbh->selectall_arrayref(q{
    SELECT RTRIM(indschema), uniquerule FROM syscat.indexes
    WHERE tabschema = CURRENT SCHEMA AND tabname = ? AND uniquerule = 'P'
  }, undef, $TABLE);
  is scalar(@$rows), 1, 'SYSCAT.INDEXES has one primary key index for the table';
  is $rows->[0] && $rows->[0][0], 'SYSIBM', '... in schema SYSIBM, not the schema of the table';
}

done_testing;
