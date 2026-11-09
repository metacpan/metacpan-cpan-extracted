use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k39, ADR 0009). The counterpart of t/58-unique-constraint.t.
#
# A result class with add_unique_constraint, through the public
# DBIO::DB2::Deploy API: install deploys a named UNIQUE constraint (SYSCAT.TABCONST
# type U) and the server refuses a duplicate; the diff straight after is empty
# (the index Db2 makes behind the constraint is neither dropped nor created a
# second time); a constraint added to and dropped from an existing table goes
# through ALTER TABLE and ends on an empty diff; a constraint over a nullable
# column is refused when the DDL is rendered (Db2 itself answers SQL0542N).
#
# Tables carry the pid, only they are touched.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my $TABLE = "dbio_k39_$$";
my $OTHER = "dbio_k39n_$$";

{
  package DBIO::Test::K39::With;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k39_$$");
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    sku  => { data_type => 'varchar', size => 20 },
    shop => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(sku_uq      => ['sku']);
  __PACKAGE__->add_unique_constraint(shop_sku_uq => [qw(shop sku)]);
}
{
  package DBIO::Test::K39::Without;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k39_$$");
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    sku  => { data_type => 'varchar', size => 20 },
    shop => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package DBIO::Test::K39::Nullable;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k39n_$$");
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    email => { data_type => 'varchar', size => 50, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(email_uq => ['email']);
}
{
  package DBIO::Test::K39::WithSchema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Item => 'DBIO::Test::K39::With');
}
{
  package DBIO::Test::K39::WithoutSchema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Item => 'DBIO::Test::K39::Without');
}
{
  package DBIO::Test::K39::NullableSchema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Item => 'DBIO::Test::K39::Nullable');
}

use DBIO::DB2::Deploy;
use DBIO::DB2::DDL;

my $with    = DBIO::Test::K39::WithSchema->connect($dsn, $user, $pass);
my $without = DBIO::Test::K39::WithoutSchema->connect($dsn, $user, $pass);

my $dbh = eval { $with->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $deploy_with    = DBIO::DB2::Deploy->new(schema => $with);
my $deploy_without = DBIO::DB2::Deploy->new(schema => $without);

sub drop_test_tables {
  local $dbh->{PrintError} = 0;
  eval { $dbh->do(qq{DROP TABLE "$_"}) } for $TABLE, $OTHER;
}

sub constraints {
  my $rows = $dbh->selectcol_arrayref(q{
    SELECT constname FROM syscat.tabconst
    WHERE tabschema = CURRENT SCHEMA AND tabname = ? AND type = 'U' ORDER BY constname
  }, undef, $TABLE);
  return [ map { s/\s+$//r } @$rows ];
}

sub ops_of {
  my ($deploy) = @_;
  my $diff = eval { $deploy->diff } or return ([ "diff died: $@" ], undef);
  return ([ map { $_->as_sql } @{ $diff->operations } ], $diff);
}

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
END {
  if ($dbh && $dbh->{Active}) {
    drop_test_tables();
    my ($n) = eval { $dbh->selectrow_array(
      'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA) };
    $deploy_with->_drop_test_schema($dbh, $COMPARE_SCHEMA) if $n;
  }
}

drop_test_tables();

# ============================================================================
# 1. install: the constraints exist, the server enforces them.
# ============================================================================
lives_ok { $deploy_with->install } 'install deploys the table';
is_deeply constraints(), [qw(shop_sku_uq sku_uq)], 'SYSCAT.TABCONST holds both UNIQUE constraints';

lives_ok { $dbh->do(qq{INSERT INTO "$TABLE" ("sku", "shop") VALUES ('a', 1)}) } 'a first row goes in';
lives_ok { $dbh->do(qq{INSERT INTO "$TABLE" ("sku", "shop") VALUES ('b', 1)}) } '... and one with another sku';
throws_ok { $dbh->do(qq{INSERT INTO "$TABLE" ("sku", "shop") VALUES ('a', 2)}) }
  qr/SQLSTATE=23505/, 'a duplicate sku is refused by the server (SQLSTATE 23505)';

# ============================================================================
# 2. the follow-up diff is empty: the index behind the constraint is not
#    dropped, nor created a second time.
# ============================================================================
{
  my ($sql) = ops_of($deploy_with);
  is_deeply $sql, [], 'diff right after install is empty' or diag join "\n", @$sql;
}

# ============================================================================
# 3. an existing table: DROP UNIQUE, then ADD CONSTRAINT.
# ============================================================================
{
  my ($sql, $diff) = ops_of($deploy_without);
  is_deeply $sql, [ 'ALTER TABLE "' . $TABLE . '" DROP UNIQUE "shop_sku_uq";',
                    'ALTER TABLE "' . $TABLE . '" DROP UNIQUE "sku_uq";' ],
    'a schema without the constraints: the diff drops both, and only them' or diag join "\n", @$sql;
  lives_ok { $deploy_without->apply($diff, allow_destructive => 1) } '... applied';
  is_deeply constraints(), [], 'no UNIQUE constraint is left';
  ($sql) = ops_of($deploy_without);
  is_deeply $sql, [], '... and the diff is empty' or diag join "\n", @$sql;
}
{
  my ($sql, $diff) = ops_of($deploy_with);
  is_deeply $sql, [ 'ALTER TABLE "' . $TABLE . '" ADD CONSTRAINT "shop_sku_uq" UNIQUE ("shop", "sku");',
                    'ALTER TABLE "' . $TABLE . '" ADD CONSTRAINT "sku_uq" UNIQUE ("sku");' ],
    'a schema with them: the diff adds both' or diag join "\n", @$sql;
  lives_ok { $deploy_with->apply($diff) } '... applied';
  is_deeply constraints(), [qw(shop_sku_uq sku_uq)], 'both constraints are back';
  ($sql) = ops_of($deploy_with);
  is_deeply $sql, [], '... and the diff is empty' or diag join "\n", @$sql;
  throws_ok { $dbh->do(qq{INSERT INTO "$TABLE" ("sku", "shop") VALUES ('a', 3)}) }
    qr/SQLSTATE=23505/, 'the server enforces the added constraint';
}

# ============================================================================
# 3b. a missing table: CREATE TABLE of the diff carries the constraints inline.
# ============================================================================
{
  drop_test_tables();
  my ($sql, $diff) = ops_of($deploy_with);
  is scalar(@$sql), 1, 'a missing table: one operation (no constraint or index op)' or diag join "\n", @$sql;
  like $sql->[0] // '', qr/CONSTRAINT "sku_uq" UNIQUE \("sku"\)/, '... CREATE TABLE with the constraint inline';
  lives_ok { $deploy_with->apply($diff) } '... applied';
  is_deeply constraints(), [qw(shop_sku_uq sku_uq)], 'both constraints exist';
  ($sql) = ops_of($deploy_with);
  is_deeply $sql, [], '... and the diff is empty' or diag join "\n", @$sql;
}

# ============================================================================
# 4. a nullable column is refused when rendering.
# ============================================================================
{
  my $null = DBIO::Test::K39::NullableSchema->connect($dsn, $user, $pass);
  throws_ok { DBIO::DB2::DDL->install_ddl($null) } qr/"email".*"\Q$OTHER\E"|"\Q$OTHER\E".*"email"/s,
    'install_ddl refuses a UNIQUE constraint over a nullable column, naming table and column';
  my $exists = $dbh->selectrow_array(
    'SELECT COUNT(*) FROM syscat.tables WHERE tabschema = CURRENT SCHEMA AND tabname = ?', undef, $OTHER);
  is $exists, 0, '... and nothing was created';
}

done_testing;
