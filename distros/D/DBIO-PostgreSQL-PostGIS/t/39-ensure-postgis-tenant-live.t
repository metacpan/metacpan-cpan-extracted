use strict;
use warnings;

use Test::More;
use Test::Exception;

# Live: where ensure_postgis installs the extension on a connection that
# works in a namespace (karr k27).
#
# A connection opened with the connect key `schema` has its namespace first
# in the search_path (dbio-postgresql ADR 0008, core ADR 0065). An extension
# belongs to the database, not to that namespace, and postgis cannot be moved
# once it is installed. So after ensure_postgis the catalog
# (pg_extension.extnamespace) must name the schema the schema class declares
# for postgis -- public when it declares none -- and never the namespace of
# the connection.
#
# This needs a database WITHOUT postgis: in one that has it, CREATE EXTENSION
# IF NOT EXISTS does nothing and no assertion here could ever fail. The file
# therefore works in a database of its own, created from template0 (which
# carries no extension), with the namespace already there -- an unqualified
# CREATE lands in the first schema of the path that exists -- and drops it at
# END, whatever happened in between. t/31-ensure-postgis.t holds the
# statement itself, offline.
#
# The last subtests start from the opposite state, postgis already installed
# (in public, or in a schema of its own): ensure_postgis must leave it where it
# is, whatever the connection would have chosen.
#
# Gated on DBIO_TEST_PG_DSN; skips quietly without a PostGIS-capable server
# or a role that may create a database.

my ($dsn, $user, $pass) =
  @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};
$dsn  //= $ENV{DBIO_TEST_PG_EXT_DSN};
$user //= $ENV{DBIO_TEST_PG_EXT_USER};
$pass //= $ENV{DBIO_TEST_PG_EXT_PASS};

plan skip_all => 'DBIO_TEST_PG_DSN not set' unless $dsn;

eval { require DBI; require DBD::Pg; 1 }
  or plan skip_all => 'DBI / DBD::Pg not available';

my %attrs = (RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1);

my $control = eval { DBI->connect($dsn, $user, $pass, { %attrs }) };
plan skip_all => "Cannot connect: $@" unless $control;

my ($available) = $control->selectrow_array(
  "SELECT 1 FROM pg_available_extensions WHERE name = 'postgis'");
plan skip_all => 'PostGIS extension not available on this server'
  unless $available;

my $DB  = "dbio_postgis_ensure_$$";
my $NS  = 'dbio_tenant_a';
my $GIS = 'dbio_gis';

# WITH (FORCE) ends the sessions still in the database (PostgreSQL 13+).
my $DROP = "DROP DATABASE IF EXISTS $DB"
  . ($control->{pg_server_version} >= 130000 ? ' WITH (FORCE)' : '');

my $created;
END {
  if ($created) {
    my $h = DBI->connect($dsn, $user, $pass,
      { RaiseError => 0, PrintError => 0, PrintWarn => 0, AutoCommit => 1 });
    $h && $h->do($DROP)
      or diag "database $DB is left behind: " . ($h ? $h->errstr : DBI->errstr);
  }
}

$created = eval {
  $control->do($DROP);
  $control->do("CREATE DATABASE $DB TEMPLATE template0");
  1;
};
plan skip_all => "Cannot create a database of its own: $@" unless $created;

my $private_dsn = $dsn;
$private_dsn =~ s/\b(?:dbname|database|db)=[^;]*/dbname=$DB/i
  or $private_dsn .= ";dbname=$DB";

my $admin = DBI->connect($private_dsn, $user, $pass, { %attrs });
is $admin->selectrow_array('SELECT current_database()'), $DB,
  'working in a database of its own';
$admin->do("CREATE SCHEMA $_") for $NS, $GIS;

# The schema postgis is installed in, by the catalog; undef when it is not.
sub postgis_schema {
  my ($name) = $admin->selectrow_array(q{
    SELECT n.nspname
      FROM pg_extension e
      JOIN pg_namespace n ON n.oid = e.extnamespace
     WHERE e.extname = 'postgis'
  });
  return $name;
}

sub schema_exists {
  my ($found) = $admin->selectrow_array(
    'SELECT 1 FROM pg_namespace WHERE nspname = ?', undef, $_[0]);
  return $found ? 1 : 0;
}

is postgis_schema(), undef,
  'the database starts without postgis -- CREATE EXTENSION IF NOT EXISTS has work to do';

{
  package EnsureGisLive::Undeclared;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->pg_extensions('postgis');
}
{
  package EnsureGisLive::Declared;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->pg_extensions(postgis => { schema => 'dbio_gis' });
}
{
  package EnsureGisLive::DeclaredMissing;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->pg_extensions(postgis => { schema => 'dbio_gis_missing' });
}
{
  package EnsureGisLive::DeclaredInNamespace;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->pg_extensions(postgis => { schema => 'dbio_tenant_a' });
}

# A connection of $class that works in the namespace, in a database that
# has no postgis: every subtest starts from there.
sub tenant {
  my ($class) = @_;
  $admin->do('DROP EXTENSION IF EXISTS postgis');
  return $class->connect($private_dsn, $user, $pass,
    { schema => $NS, PrintWarn => 0 });
}

# As tenant(), but postgis is installed in $into first, from the admin
# connection (no namespace in its way).
sub tenant_installed {
  my ($class, $into) = @_;
  $admin->do('DROP EXTENSION IF EXISTS postgis');
  $admin->do("CREATE EXTENSION postgis WITH SCHEMA $into");
  return $class->connect($private_dsn, $user, $pass,
    { schema => $NS, PrintWarn => 0 });
}

sub postgis_rows {
  my ($n) = $admin->selectrow_array(
    q{SELECT count(*) FROM pg_extension WHERE extname = 'postgis'});
  return $n;
}

# Objects the namespace holds (relations, functions, types).
sub namespace_objects {
  my ($n) = $admin->selectrow_array(q{
    SELECT (SELECT count(*) FROM pg_class c WHERE c.relnamespace = n.oid)
         + (SELECT count(*) FROM pg_proc p WHERE p.pronamespace = n.oid)
         + (SELECT count(*) FROM pg_type t WHERE t.typnamespace = n.oid)
      FROM pg_namespace n WHERE n.nspname = ?
  }, undef, $NS);
  return $n;
}

subtest 'declared in the namespace of the connection: refused, nothing installed' => sub {
  my $schema = tenant('EnsureGisLive::DeclaredInNamespace');

  throws_ok { $schema->storage->ensure_postgis }
    qr/schema \Q$NS\E, the namespace this connection works in/,
    'ensure_postgis refuses the namespace of the connection';
  isa_ok $@, 'DBIO::Exception', 'the refusal';
  is postgis_schema(), undef, 'postgis is not installed';

  $schema->storage->disconnect;
};

subtest 'declared in a schema the database does not have: the server says so' => sub {
  my $schema = tenant('EnsureGisLive::DeclaredMissing');

  throws_ok { $schema->storage->ensure_postgis }
    qr/schema "dbio_gis_missing" does not exist/,
    'ensure_postgis fails with the error of the server';
  is postgis_schema(), undef, 'postgis is not installed';
  ok !schema_exists('dbio_gis_missing'), 'and the schema was not created';

  $schema->storage->disconnect;
};

subtest 'no schema declared: postgis goes into public, not into the namespace' => sub {
  my $schema  = tenant('EnsureGisLive::Undeclared');
  my $storage = $schema->storage;

  # What makes this a test: an unqualified CREATE on this connection lands
  # in the namespace.
  is $storage->dbh->selectrow_array('SELECT current_schema()'), $NS,
    'the namespace is where this connection creates an unqualified object';
  is postgis_schema(), undef, 'the database has no postgis';

  lives_ok { $storage->ensure_postgis } 'ensure_postgis lives';
  is postgis_schema(), 'public', 'postgis is installed in public';
  isnt postgis_schema(), $NS, 'and not in the namespace of the connection';

  like $storage->postgis_version, qr/POSTGIS="\d/,
    'the connection reaches it: public follows the namespace in its search_path';

  lives_ok { $storage->ensure_postgis } 'a second ensure_postgis lives';
  is postgis_schema(), 'public', 'and leaves postgis where it is';

  $storage->disconnect;
};

subtest 'declared in a schema of its own: postgis goes there, not into the namespace' => sub {
  my $schema  = tenant('EnsureGisLive::Declared');
  my $storage = $schema->storage;

  is $storage->dbh->selectrow_array('SELECT current_schema()'), $NS,
    'the namespace is where this connection creates an unqualified object';
  is postgis_schema(), undef, 'the database has no postgis';

  lives_ok { $storage->ensure_postgis } 'ensure_postgis lives';
  is postgis_schema(), $GIS, 'postgis is installed in the declared schema';
  isnt postgis_schema(), $NS, 'and not in the namespace of the connection';

  like $storage->postgis_version, qr/POSTGIS="\d/,
    'the connection reaches it: the declared schema is in its search_path';

  $storage->disconnect;
};

subtest 'installed in public already: ensure_postgis leaves it, the namespace stays empty' => sub {
  my $schema  = tenant_installed('EnsureGisLive::Undeclared', 'public');
  my $storage = $schema->storage;

  is postgis_schema(), 'public', 'postgis is in public before';
  my $before = namespace_objects();

  lives_ok { $storage->ensure_postgis } 'ensure_postgis lives';
  lives_ok { $storage->ensure_postgis } 'a second ensure_postgis lives';
  is postgis_schema(), 'public', 'postgis is still in public';
  is postgis_rows(), 1, 'exactly one postgis in pg_extension';
  is namespace_objects(), $before, 'the namespace of the connection gained no object';
  like $storage->postgis_version, qr/POSTGIS="\d/, 'the connection reaches it';

  $storage->disconnect;
};

subtest 'installed in a schema of its own already: the undeclared connection does not move it' => sub {
  # Undeclared would choose public.
  my $schema  = tenant_installed('EnsureGisLive::Undeclared', $GIS);
  my $storage = $schema->storage;

  is postgis_schema(), $GIS, 'postgis is in the schema of its own before';
  my $before = namespace_objects();

  lives_ok { $storage->ensure_postgis } 'ensure_postgis lives';
  is postgis_schema(), $GIS, 'postgis stays where it is';
  isnt postgis_schema(), 'public', 'it was not moved to the schema the connection would choose';
  is postgis_rows(), 1, 'no second installation';
  is namespace_objects(), $before, 'the namespace of the connection gained no object';

  $storage->disconnect;
};

subtest 'installed in public, declared in the namespace: refused, installation unchanged' => sub {
  my $schema  = tenant_installed('EnsureGisLive::DeclaredInNamespace', 'public');
  my $storage = $schema->storage;
  my $before  = namespace_objects();

  throws_ok { $storage->ensure_postgis }
    qr/schema \Q$NS\E, the namespace this connection works in/,
    'ensure_postgis still refuses the namespace of the connection';
  isa_ok $@, 'DBIO::Exception', 'the refusal';
  is postgis_schema(), 'public', 'postgis is still in public';
  is postgis_rows(), 1, 'exactly one postgis in pg_extension';
  is namespace_objects(), $before, 'the namespace gained no object';

  $storage->disconnect;
};

$admin->disconnect;
$control->disconnect;

done_testing;
