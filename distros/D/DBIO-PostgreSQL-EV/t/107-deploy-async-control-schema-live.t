use strict;
use warnings;

use Test::More;
use Test::Exception;

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $ENV{DBIO_TEST_PG_DSN};

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use GuardedWait;

# A server that is not there fails the file, with a plan.
LiveServer->require_server;

# A process has one alarm: the file's backstop, set once, never cleared.
alarm 120;

# karr k96 -- deploy_async of the ev transport follows the rule of the sync
# deploy for the schema of a CREATE EXTENSION (dbio-postgresql k141, k142):
# the declared schema, else the one the control file fixes, else public. The
# transport asks the server over a pooled connection before it builds the DDL.
# With pg_extensions('age', 'postgis') and no schema declared, age is written
# without the clause (the server installs it in ag_catalog and refuses WITH
# SCHEMA public), postgis WITH SCHEMA public.
#
# Needs age and postgis on the server and their DBIO distributions; skipped,
# with the reason, where one is missing. Runs in a database of its own
# (dbio_pgev_k96_<pid>), created here and dropped at the end, also after a
# failure; nothing else on the server is touched.

for my $module (qw(EV::Pg DBIO::PostgreSQL::Age DBIO::PostgreSQL::PostGIS)) {
  eval "require $module; 1"
    or plan skip_all => "$module not installed";
}

{
  my $h = LiveServer->control_dbh;
  my %avail = map { $_ => 1 } @{ $h->selectcol_arrayref(
    q{SELECT name FROM pg_catalog.pg_available_extensions WHERE name IN ('age', 'postgis')}
  ) };
  $h->disconnect;
  plan skip_all => 'extension age not available on the server' unless $avail{age};
  plan skip_all => 'extension postgis not available on the server' unless $avail{postgis};
}

my $dbname = "dbio_pgev_k96_$$";
my $created;

sub drop_private {
  return unless $created;
  my $dbh = eval { LiveServer->control_dbh(attrs => { RaiseError => 0, PrintWarn => 0 }) }
    or return;
  $dbh->do('DROP DATABASE IF EXISTS ' . $dbh->quote_identifier($dbname) . ' WITH (FORCE)');
  $dbh->disconnect;
  $created = 0;
}
END { drop_private() }

my ($dsn, $user, $pass) = LiveServer->login;
{
  (my $private = $dsn) =~ s/(?<![\w])(?:dbname|database|db)=[^;]+/dbname=$dbname/
    or BAIL_OUT('DBIO_TEST_PG_DSN names no dbname= to replace with the private database');
  my $dbh = LiveServer->control_dbh(attrs => { PrintWarn => 0 });
  my $quoted = $dbh->quote_identifier($dbname);
  $dbh->do("DROP DATABASE IF EXISTS $quoted WITH (FORCE)");
  $dbh->do("CREATE DATABASE $quoted");
  $created = 1;
  $dbh->disconnect;
  $dsn = $private;
}

{
  package K96Live::Result::Place;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('public');
  __PACKAGE__->table('k96_place');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    geom => { data_type => 'geometry(Point,4326)', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package K96Live::Schema;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::Age', 'PostgreSQL::PostGIS');
  __PACKAGE__->pg_extensions('age', 'postgis');
  __PACKAGE__->register_class(Place => 'K96Live::Result::Place');
}

my %attrs = (AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0);

my $ev = K96Live::Schema->connect($dsn, $user, $pass,
  { %attrs, async => 'ev', on_connect_call => 'load_age' });

my $f = $ev->storage->async->deploy_async($ev);
lives_ok { GuardedWait->until_ready($f, 60, 'TIMEOUT awaiting deploy_async')->get }
  'deploy_async over ev lives, age and postgis undeclared as to schema, geometry column included';

# observer in the private database
my $control = LiveServer->control_dbh(login => [ $dsn, $user, $pass ]);
sub ext_schema {
  my ($name) = @_;
  return scalar $control->selectrow_array(
    q{SELECT n.nspname FROM pg_catalog.pg_extension e
        JOIN pg_catalog.pg_namespace n ON n.oid = e.extnamespace
       WHERE e.extname = ?}, undef, $name);
}

is ext_schema('postgis'), 'public', 'postgis is installed in public, not in ag_catalog';
is ext_schema('age'), 'ag_catalog', 'age is installed in the schema its control file fixes';

# the database deploy_async made is the one the sync deploy would make
my $sync = K96Live::Schema->connect($dsn, $user, $pass,
  { %attrs, on_connect_call => 'load_age' });
my $again = $sync->pg_deploy->diff;
ok !$again->has_changes, 'a diff of the deployed database is empty'
  or diag $again->as_sql;

# A declared schema against the one the control file fixes: the Future fails
# before any statement of the DDL.
{
  package K96Live::Clash;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::Age');
  __PACKAGE__->pg_extensions(age => { schema => 'public' });
}
{
  my $clash = K96Live::Clash->connect($dsn, $user, $pass, { %attrs, async => 'ev' });
  my $cf = $clash->storage->async->deploy_async($clash);
  GuardedWait->until_ready($cf, 60, 'TIMEOUT awaiting refused deploy_async');
  ok $cf->is_failed, 'a declared schema other than the fixed one fails deploy_async';
  like scalar($cf->failure),
    qr/extension age is declared in schema public, but its control file fixes schema ag_catalog/,
    '... naming the extension and both schemas';
  $clash->storage->disconnect;
}

$ev->storage->disconnect;
$sync->storage->disconnect;
$control->disconnect;
drop_private();

done_testing;
