use strict;
use warnings;
use Test::More;

# ensure_postgis names the schema of the extension, always (karr k27).
#
# An extension belongs to the database. A connection opened with the connect
# key `schema` works in one namespace and has it first in its search_path
# (dbio-postgresql ADR 0008, core ADR 0065), so a CREATE EXTENSION that names
# no schema installs postgis into that namespace -- and postgis is not
# relocatable, it stays there. What this file holds is the statement:
#
#   - the schema is written into it, whatever the session's search_path is;
#   - it is the schema the schema class declares for postgis
#     (pg_extensions(postgis => { schema => ... })), public when none is;
#   - it is never the namespace of the connection: that is refused, and
#     nothing is sent.
#
# No database: the storage is the layer over the real PostgreSQL driver
# storage (the MRO DBIO::Storage::Composed synthesises, as in
# t/30-exceptions.t) with dbh_do handing out a handle that records. The
# namespace reaches the storage the way a connect gives it -- through
# connect_info and the key `schema`, not by setting the accessor.
# t/39-ensure-postgis-tenant-live.t asks the catalog of a real server.

use Scalar::Util ();
use DBIO::Schema;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::PostGIS::Storage;

{
  package _EnsurePostgis::FakeDbh;
  sub new { bless { done => [], asked => [], rows => $_[1] // [] }, $_[0] }
  sub do  { push @{ $_[0]{done} }, $_[1]; return '0E0' }
  sub selectall_arrayref { push @{ $_[0]{asked} }, $_[1]; return $_[0]{rows} }
}

{
  package _EnsurePostgis::TestStorage;
  use base qw( DBIO::PostgreSQL::PostGIS::Storage DBIO::PostgreSQL::Storage );
  use mro 'c3';

  sub dbh_do {
    my ($self, $code) = @_;
    return $code->($self, $self->{_fake_dbh} //= _EnsurePostgis::FakeDbh->new($self->{_control_rows}));
  }
  sub _asked { @{ ($_[0]{_fake_dbh} // { asked => [] })->{asked} } }
  sub _statements { @{ ($_[0]{_fake_dbh} // { done => [] })->{done} } }
}

# --- the schema classes: what each declares for postgis --------------------

{
  # the driver component and the extension, postgis declared without a schema
  package _EnsurePostgis::Undeclared;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->pg_extensions('postgis');
}
{
  package _EnsurePostgis::Declared;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->pg_extensions(postgis => { schema => 'gis' });
}
{
  # a name the server takes only quoted
  package _EnsurePostgis::DeclaredQuoted;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->pg_extensions(postgis => { schema => 'Geo Data' });
}
{
  # another extension names a schema, postgis names none
  package _EnsurePostgis::OtherDeclared;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->pg_extensions(vector => { schema => 'extensions' }, 'postgis');
}
{
  # the extension alone: no pg_extensions to ask
  package _EnsurePostgis::ExtensionOnly;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL::PostGIS');
}

# A storage of $schema_class, connected (lazily -- nothing is opened) with
# the connect key schema when $namespace is given.
my @keep;
sub storage_of {
  my ($schema_class, $namespace, $control_rows) = @_;
  my $schema  = defined $schema_class ? $schema_class->clone : undef;
  push @keep, $schema;   # the storage holds its schema weakly
  my $storage = _EnsurePostgis::TestStorage->new($schema);
  $storage->{_control_rows} = $control_rows;
  $storage->connect_info([
    'dbi:Pg:dbname=dbio_offline_ensure_postgis', '', '',
    defined $namespace ? { schema => $namespace } : (),
  ]);
  return $storage;
}

sub written_is {
  my ($storage, $want, $name) = @_;
  my $ok = eval { $storage->ensure_postgis; 1 };
  ok $ok, "$name: ensure_postgis lives" or diag $@;
  is_deeply [ $storage->_statements ], [ $want ], "$name: the statement"
    or diag explain [ $storage->_statements ];
}

sub refused {
  my ($storage, $namespace, $name) = @_;
  my $ok  = eval { $storage->ensure_postgis; 1 };
  my $err = $@;
  ok !$ok, "$name: ensure_postgis throws";
  ok Scalar::Util::blessed($err) && $err->isa('DBIO::Exception'),
    "$name: a DBIO::Exception"
    or diag 'got: ' . (defined $err ? $err : '(no exception)');
  like "$err", qr/\bpostgis\b.*\bschema \Q$namespace\E, the namespace this connection works in/s,
    "$name: names the extension and the namespace";
  like "$err", qr/pg_extensions\(postgis => \{ schema => \.\.\. \}\)/,
    "$name: names the way out";
  is_deeply [ $storage->_statements ], [],
    "$name: no statement is sent";
}

# --- a connection that names no namespace ----------------------------------

# --- the schema the control file fixes (dbio-postgresql k141/k142) ----------

subtest 'undeclared: the control file of the server decides, then public' => sub {
  my $storage = storage_of('_EnsurePostgis::Undeclared', undef,
    [ [ postgis => 'ctl_gis' ] ]);
  written_is $storage,
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA ctl_gis',
    'a fixed schema of the control file';
  is_deeply [ $storage->_asked ],
    [ DBIO::PostgreSQL::DDL::control_schemas_sql('postgis') ],
    'asked with the driver\'s own statement';

  my $declared = storage_of('_EnsurePostgis::Declared', undef,
    [ [ postgis => 'ctl_gis' ] ]);
  written_is $declared,
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA gis',
    'declared: the declaration wins';
  is_deeply [ $declared->_asked ], [], 'declared: the server is not asked';

  written_is storage_of('_EnsurePostgis::Undeclared', undef, []),
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public',
    'no row (no fixed schema): public';

  refused storage_of('_EnsurePostgis::Undeclared', 'ctl_gis',
      [ [ postgis => 'ctl_gis' ] ]), 'ctl_gis',
    'the schema the control file fixes is the namespace: refused';
};

subtest 'no namespace: the schema is named all the same' => sub {
  written_is storage_of('_EnsurePostgis::Undeclared'),
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public',
    'postgis declared without a schema';

  written_is storage_of('_EnsurePostgis::Declared'),
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA gis',
    'postgis declared in gis';

  written_is storage_of('_EnsurePostgis::DeclaredQuoted'),
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA "Geo Data"',
    'a schema name that needs quotes';

  written_is storage_of('_EnsurePostgis::OtherDeclared'),
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public',
    'the schema of another extension is not postgis\'s';

  written_is storage_of('_EnsurePostgis::ExtensionOnly'),
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public',
    'a schema class without the driver component';

  written_is storage_of(undef),
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public',
    'a storage without a schema class';
};

# --- a connection that works in a namespace --------------------------------

subtest 'connect key schema: postgis goes where it is declared, not into the namespace' => sub {
  my $storage = storage_of('_EnsurePostgis::Undeclared', 'tenant_a');
  is $storage->connection_schema, 'tenant_a',
    'sanity: the connect key schema is the namespace of the storage';

  written_is $storage,
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public',
    'postgis declared without a schema';

  written_is storage_of('_EnsurePostgis::Declared', 'tenant_a'),
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA gis',
    'postgis declared in gis';

  written_is storage_of('_EnsurePostgis::ExtensionOnly', 'tenant_a'),
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public',
    'a schema class without the driver component';
};

subtest 'connect key schema: the namespace of the connection is refused' => sub {
  refused storage_of('_EnsurePostgis::Declared', 'gis'), 'gis',
    'the declared schema is the namespace';

  refused storage_of('_EnsurePostgis::Undeclared', 'public'), 'public',
    'no schema declared and the namespace is public';

  refused storage_of('_EnsurePostgis::ExtensionOnly', 'public'), 'public',
    'no driver component and the namespace is public';

  written_is storage_of('_EnsurePostgis::Declared', 'Gis'),
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA gis',
    'a namespace that differs in case is another schema';
};

done_testing;
