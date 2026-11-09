use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff::Extension;

# OFFLINE test for karr k131 (c): the diff of a connection that names its
# namespace (connect key schema) creates the schema of an extension.
#
# CLAIM: the deploy of such a connection is restricted to the namespace, so
# the model of the database holds no schema but that one. The schema an
# extension is declared in (pg_extensions(vector => { schema => 'extensions' }))
# is not in it, whether the database has that schema or not -- and a diff
# before the first install cannot tell. The CREATE EXTENSION ... WITH SCHEMA
# it writes would fail at the server with "schema does not exist". So the
# diff writes the schema ahead of it, looked up in pg_namespace first (the
# schema may be there already). Nothing is written for public, which always
# exists, nor for an extension whose control file fixes its schema (the
# server creates it), nor on a connection without the key (there pg_schemas
# lists the schema and the ordinary schema diff creates it).
#
# WHAT RUNS FOR REAL: Deploy->diff, _mark_extension_schemas, the extension
# diff class and its as_sql. THE SUBSTITUTIONS: no server -- the two models
# and the installed state are given.

my @LOGIN = ('dbi:Pg:dbname=k131_offline', 'u', 'p');

{
  package K131::Deploy;
  use base 'DBIO::PostgreSQL::Deploy';
  sub _dbh { {} }
  sub _extension_control_schemas { { pg_cron => 'pg_catalog' } }
  sub _installed_extensions { +{ map { $_ => { installed => 0 } } @{ $_[1] } } }
  sub _introspect_current { +{ extensions => {}, schemas => {} } }
  sub _build_target_model { $_[0]->_mark_extension_schemas({ extensions => {
    hstore => { extension_name => 'hstore', version => '1.8', schema_name => 'public' },
    vector => { extension_name => 'vector', version => '0.8', schema_name => 'extensions' },
    pg_cron => { extension_name => 'pg_cron', version => '1.6', schema_name => 'pg_catalog' },
  }, schemas => {} }) }
}

my $n = 0;
sub schema_class {
  my $pkg = 'K131::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_schemas(@{ $_[0] });
  $pkg->pg_extensions(@{ $_[1] });
  return $pkg;
}
sub pos_of { my ($sql, $re) = @_; $sql =~ $re ? $-[0] : undef }

my $class = schema_class([ 'extensions' ],
  [ 'hstore', 'pg_cron', vector => { schema => 'extensions' } ]);

my $sql = K131::Deploy->new(schema => $class->connect(@LOGIN, { schema => 'tenant_a' }))->diff->as_sql;

like $sql, qr/nspname = 'extensions'/,
  'a connection with the key: the diff creates the declared schema of an extension';
my $schema_at = pos_of($sql, qr/nspname = 'extensions'/);
my $ext_at    = pos_of($sql, qr/^CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;$/m);
ok defined $schema_at && defined $ext_at && $schema_at < $ext_at,
  '... ahead of the CREATE EXTENSION that names it';
is scalar(() = $sql =~ /CREATE SCHEMA/g), 1,
  '... and no other schema: not public (hstore), not the fixed schema of pg_cron';
like $sql, qr/^CREATE EXTENSION IF NOT EXISTS pg_cron;$/m,
  '... an extension whose control file fixes its schema is written as before';

my $plain = K131::Deploy->new(schema => $class->connect(@LOGIN))->diff->as_sql;
unlike $plain, qr/CREATE SCHEMA/,
  'without the key nothing is added: pg_schemas has the schema, the schema diff creates it';

done_testing;
