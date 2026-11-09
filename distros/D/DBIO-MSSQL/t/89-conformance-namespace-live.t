use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Test::Conformance;

# WHY: the runner of core calls conformance_cleanup always, also when
# conformance_namespace threw (karr k71, ADR 0060). A database that was there
# before the case must survive a case that was refused because its name was
# taken. Needs a server (DBIO_TEST_MSSQL_ODBC_DSN or DBIO_TEST_MSSQL_DSN).

my $base = 'DBIO::MSSQL::Test::Conformance';
eval "require $base; 1" or die $@;
plan skip_all => 'no SQL Server configured' unless $base->conformance_live_available;

my $foreign = sprintf 'dbio_cfx_%d', $$;

{
  package T89::Taken;
  our @ISA = ($base);
  sub _database_name { $foreign }
}

my $dbh = $base->_admin_dbh;
my $exists = sub { my ($id) = $dbh->selectrow_array('SELECT DB_ID(?)', undef, $foreign); defined $id ? 1 : 0 };

$dbh->do("CREATE DATABASE [$foreign]");
$dbh->do("CREATE TABLE [$foreign].dbo.keep (id INT NOT NULL PRIMARY KEY)");
$dbh->do("INSERT INTO [$foreign].dbo.keep VALUES (42)");

my $sc = 'T89::Schema';
{ package T89::Schema; use base 'DBIO::Schema'; }

my $schema = eval { T89::Taken->conformance_connect($sc) };
ok $schema, 'connect builds the lazy connection without touching the database' or diag $@;

my $ns;
my $ran = eval { $ns = T89::Taken->conformance_namespace($schema, {}); 1 };
ok !$ran, 'namespace refuses a name that is taken';
like "$@", qr/exists already/, '... and says why';
ok !defined $ns, '... and returns no token';

ok eval { T89::Taken->conformance_cleanup($schema, {}, $ns); 1 }, 'cleanup (runner order) does not throw';

is $exists->(), 1, 'the foreign database is still there';
my ($v) = eval { $dbh->selectrow_array("SELECT id FROM [$foreign].dbo.keep") };
is $v, 42, '... with its table and row';

END {
  if ($dbh) {
    eval { $dbh->do("IF DB_ID('$foreign') IS NOT NULL BEGIN ALTER DATABASE [$foreign] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$foreign] END") };
    $dbh->disconnect;
  }
}
done_testing;
