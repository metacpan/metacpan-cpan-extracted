use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# karr k81 -- the member functions of an installed extension belong to the
# extension, not to the schema. Introspection used to report every one of
# them (over a hundred for pgvector 0.8), so diffing a database that has the
# extension against a schema that does not declare it gave DROP EXTENSION
# vector followed by a DROP FUNCTION per member. Those functions had already
# gone with the extension, so apply died on the first one. The other
# direction was wrong as well: a declared extension missing from the database
# came out as CREATE EXTENSION plus a CREATE OR REPLACE for every member.
# That is what made t/09 die whenever pgvector was installed in the shared
# test database.
#
# Runs in a database of its own: it installs and drops the extension, which
# the shared database must not see.

{
  my $h = LiveServer->control_dbh;
  my ($has_vector) = $h->selectrow_array(
    q{SELECT 1 FROM pg_catalog.pg_available_extensions WHERE name = 'vector'}
  );
  $h->disconnect;
  plan skip_all => 'pgvector (CREATE EXTENSION vector) not available on the server'
    unless $has_vector;
}

($dsn, $user, $pass) = PrivatePgDatabase->create('t66');

my $dbh = LiveServer->control_dbh(login => [ $dsn, $user, $pass ]);
$dbh->do('CREATE EXTENSION vector');
$dbh->do(q{CREATE FUNCTION public.k81_own() RETURNS integer LANGUAGE sql AS 'SELECT 1'});

# Keyed exactly like Introspect::Functions keys its entries.
my $members = $dbh->selectcol_arrayref(q{
  SELECT n.nspname || '.' || p.proname
         || '(' || pg_catalog.pg_get_function_identity_arguments(p.oid) || ')'
  FROM pg_catalog.pg_depend d
  JOIN pg_catalog.pg_extension e ON e.oid = d.refobjid
  JOIN pg_catalog.pg_proc p ON p.oid = d.objid
  JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
  WHERE d.classid = 'pg_catalog.pg_proc'::pg_catalog.regclass
    AND d.deptype = 'e'
    AND e.extname = 'vector'
});
ok(scalar @$members, 'precondition: pgvector installs member functions');

subtest 'introspection leaves extension members out' => sub {
  my $functions = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model->{functions};
  ok(exists $functions->{'public.k81_own()'}, "the schema's own function is reported");
  is_deeply([ grep { exists $functions->{$_} } @$members ], [],
    'no member function of the extension is reported');
};

{
  package K81::Bare;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
{
  package K81::WithVector;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions('vector');
}

# "Kind action" of every op, e.g. "Extension drop".
sub op_kinds {
  my ($diff) = @_;
  return [ map { (ref($_) =~ /::(\w+)\z/)[0] . ' ' . $_->action } @{ $diff->operations } ];
}

subtest 'dropping an undeclared extension drops it, not its members' => sub {
  my $deploy = DBIO::PostgreSQL::Deploy->new(schema => K81::Bare->connect($dsn, $user, $pass));
  my $diff = $deploy->diff;

  # The function first: drops come in the reverse of the order of dependency,
  # and a function may use what an extension brings (karr k108, t/92).
  is_deeply(op_kinds($diff), [ 'Function drop', 'Extension drop' ],
    'one DROP EXTENSION, and the only DROP FUNCTION is for the own function');
  like($diff->as_sql, qr/DROP FUNCTION public\.k81_own\(\);/,
    'the own function is the one dropped');

  lives_ok { $deploy->apply($diff, allow_destructive => 1) } 'apply lives (it drops the undeclared extension and a function)';
  my ($still) = $dbh->selectrow_array(
    q{SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'vector'});
  ok(!$still, 'extension is gone');
};

subtest 'adding a declared extension creates it, not its members' => sub {
  my $deploy = DBIO::PostgreSQL::Deploy->new(schema => K81::WithVector->connect($dsn, $user, $pass));
  my $diff = $deploy->diff;

  is_deeply(op_kinds($diff), [ 'Extension create' ],
    'the only op is CREATE EXTENSION');

  lives_ok { $deploy->apply($diff) } 'apply lives';
  ok(!$deploy->diff->has_changes, 'nothing left to change once the extension is in');
};

$dbh->disconnect;

done_testing;
