use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff::Extension;

# OFFLINE test for karr k141.
#
# An unqualified CREATE EXTENSION lands in the first schema of the session's
# search_path -- ag_catalog after the activation of age. So every CREATE
# EXTENSION, install and diff alike, names its schema: the declared one, else
# public, on a connection without the connect key schema too.
#
# WHAT IT PINS:
#   - the install script of a list-form declaration says WITH SCHEMA public;
#   - the diff of a deploy says the same for an extension it creates;
#   - a declared schema is kept;
#   - (decision of 2026-10-24) the schema comes, in this order, from the
#     declaration, from the control file of the extension (read from the
#     server by the deploy, never from a list of extensions), else public;
#     a declared schema against a fixed one is refused before any statement;
#     the install script alone, which asks no server, has the declaration or
#     public;
#   - the default is for creating only: an extension the database already
#     holds in another schema, declared without one, makes no operation.

my $n = 0;
sub fresh_schema {
  my (%o) = @_;
  my $pkg = 'ExtDefault' . ++$n . '::Schema';
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_schemas(@{ $o{schemas} }) if $o{schemas};
  $pkg->pg_extensions(@{ $o{extensions} }) if $o{extensions};
  return $pkg;
}

{
  package ExtDefaultDeploy;
  use base 'DBIO::PostgreSQL::Deploy';
  our (%LIVE, %DESIRED);
  our %FIXED;
  sub _dbh { {} }
  sub _extension_control_schemas {
    my ($self) = @_;
    my $given = DBIO::PostgreSQL::DDL::_schema_decl($self->schema, 'pg_extension_schemas') // {};
    for my $n (keys %$given) {
      DBIO::PostgreSQL::DDL::refuse_control_schema($n, $given->{$n}, $FIXED{$n})
        if defined $FIXED{$n} && $given->{$n} ne $FIXED{$n};
    }
    return { %FIXED };
  }
  sub _installed_extensions { +{ map { $_ => { installed => 0 } } @{ $_[1] } } }
  sub _introspect_current { +{ extensions => { %LIVE } } }
  sub _build_target_model {
    my ($self) = @_;
    return $self->_mark_extension_schemas({ extensions => { %DESIRED } });
  }
}

sub ext {
  my ($name, %o) = @_;
  return { extension_name => $name, version => '1.0', requires => [], relocatable => 1, %o };
}

sub deploy_diff {
  my ($schema, $live, $desired, $fixed) = @_;
  local %ExtDefaultDeploy::LIVE    = %$live;
  local %ExtDefaultDeploy::DESIRED = %$desired;
  local %ExtDefaultDeploy::FIXED    = %{ $fixed // {} };
  return ExtDefaultDeploy->new(schema => $schema)->diff;
}

# ---- install ---------------------------------------------------------------

{
  my $sql = DBIO::PostgreSQL::DDL->install_ddl(
    fresh_schema(extensions => [ 'pgcrypto', 'hstore' ]));
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;$/m,
    'install, list form: pgcrypto is created WITH SCHEMA public';
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;$/m,
    '... and hstore too';
  unlike $sql, qr/CREATE EXTENSION IF NOT EXISTS \S+;/,
    '... none without the clause';
}
{
  my $sql = DBIO::PostgreSQL::DDL->install_ddl(fresh_schema(
    schemas    => [ 'gis' ],
    extensions => [ 'pgcrypto', hstore => { schema => 'gis' } ],
  ));
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA gis;$/m,
    'install: a declared schema stays';
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;$/m,
    '... the one beside it that names none gets public';
}

# ---- diff ------------------------------------------------------------------

{
  my $diff = deploy_diff(fresh_schema(extensions => [ 'pgcrypto', 'hstore' ]),
    {},
    { pgcrypto     => ext('pgcrypto',     schema_name => 'other_ns'),
      hstore => ext('hstore', schema_name => 'other_ns') },
  );
  like $diff->as_sql, qr/^CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;$/m,
    'diff, list form: a created extension names public, whatever schema the '
    . 'temporary database put it in';
  unlike $diff->as_sql, qr/CREATE EXTENSION IF NOT EXISTS \S+;/m,
    '... none without the clause';
}
{
  my $diff = deploy_diff(
    fresh_schema(
      schemas    => [ 'public', 'gis' ],
      extensions => [ hstore => { schema => 'gis' } ],
    ),
    {},
    { hstore => ext('hstore', schema_name => 'gis') },
  );
  like $diff->as_sql, qr/^CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA gis;$/m,
    'diff: a declared schema stays';
}
{
  my $diff = deploy_diff(fresh_schema(extensions => [ 'hstore' ]),
    { hstore => ext('hstore', schema_name => 'extensions') },
    { hstore => ext('hstore', schema_name => 'public') },
  );
  ok !$diff->has_changes,
    'an extension the database holds in another schema, declared without one, '
    . 'makes no operation (no SET SCHEMA, no create)'
    or diag $diff->as_sql;
}

# ---- the control file of the extension (decision of 2026-10-24) -------------

{
  package ExtFakeDbh;
  our @sql;
  sub new { bless {}, $_[0] }
  sub selectall_arrayref { shift; push @sql, [@_]; return $ExtFixedDeploy::ROWS }
}
{
  package ExtFixedDeploy;
  use base 'DBIO::PostgreSQL::Deploy';
  our $ROWS = [];
  sub _dbh { ExtFakeDbh->new }
}

# offline: the declaration, else public -- the script knows no control file
{
  my $sql = DBIO::PostgreSQL::DDL->install_ddl(fresh_schema(extensions => [ 'age' ]));
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS age WITH SCHEMA public;$/m,
    'offline install, nothing declared: public';
}
{
  my $sql = DBIO::PostgreSQL::DDL->install_ddl(fresh_schema(
    schemas    => [ 'ag_catalog' ],
    extensions => [ age => { schema => 'ag_catalog' } ],
  ));
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS age WITH SCHEMA ag_catalog;$/m,
    'offline install: the declared schema wins';
}

# with the schemas a server fixed
{
  my $sql = DBIO::PostgreSQL::DDL->install_ddl(
    fresh_schema(extensions => [ 'age', 'pgcrypto' ]),
    extension_control_schemas => { age => 'ag_catalog' },
  );
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS age;$/m,
    'install: the schema the control file fixes, none declared: written without '
    . 'the clause, the server installs it there (and refuses WITH SCHEMA for a '
    . 'schema that does not exist yet)';
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;$/m,
    '... one without a fixed schema stays public';
  unlike $sql, qr/ag_catalog/,
    '... the schema is the extension\'s own, named nowhere';
}
{
  my $schema = fresh_schema(
    schemas    => [ 'gis' ],
    extensions => [ age => { schema => 'gis' } ],
  );
  eval { DBIO::PostgreSQL::DDL->install_ddl($schema,
    extension_control_schemas => { age => 'ag_catalog' }) };
  like $@, qr/extension age is declared in schema gis, but its control file fixes schema ag_catalog/,
    'install: a declared schema against the fixed one is refused, naming both';
}

# the diff
{
  my $diff = deploy_diff(fresh_schema(extensions => [ 'fixedext' ]),
    {}, { fixedext => ext('fixedext', schema_name => 'ag_catalog') }, { fixedext => 'ag_catalog' });
  like $diff->as_sql, qr/^CREATE EXTENSION IF NOT EXISTS fixedext;$/m,
    'diff: a created extension with a schema its control file fixes is written '
    . 'without the clause, whatever schema the temporary database put it in';
  like $diff->summary, qr/^  \+extension: fixedext \(1\.0, schema ag_catalog\)$/m,
    '... and the summary says so';
}
{
  my $diff = deploy_diff(fresh_schema(extensions => [ 'fixedext' ]),
    { fixedext => ext('fixedext', schema_name => 'ag_catalog') },
    { fixedext => ext('fixedext', schema_name => 'ag_catalog') }, { fixedext => 'ag_catalog' });
  ok !$diff->has_changes, 'diff: fixedext in its fixed schema on both sides is no change'
    or diag $diff->as_sql;
}
{
  eval { deploy_diff(fresh_schema(
      schemas => [ 'gis' ], extensions => [ fixedext => { schema => 'gis' } ]),
    {}, { fixedext => ext('fixedext') }, { fixedext => 'ag_catalog' }) };
  like $@, qr/fixedext.*gis.*ag_catalog/s, 'diff: the collision is refused';
}

# the query of the deploy itself
{
  local $ExtFixedDeploy::ROWS = [ [ 'fixedext', 'ag_catalog' ] ];
  @ExtFakeDbh::sql = ();
  is_deeply(ExtFixedDeploy->new(schema => fresh_schema(extensions => [ 'fixedext', 'hstore' ]))
      ->_extension_control_schemas,
    { fixedext => 'ag_catalog' }, 'the deploy answers what the server fixes');
  like $ExtFakeDbh::sql[0][0], qr/pg_available_extension_versions/,
    '... from the control files of the available versions';
  # the names are literals of the statement (DDL::control_schemas_sql, karr
  # k142: the same statement goes out over the async transport, no placeholder)
  like $ExtFakeDbh::sql[0][0], qr/v\.name IN \('fixedext', 'hstore'\)/,
    '... for the declared extensions';

  @ExtFakeDbh::sql = ();
  is_deeply(ExtFixedDeploy->new(schema => fresh_schema())->_extension_control_schemas,
    {}, 'nothing declared: nothing fixed') ;
  is scalar @ExtFakeDbh::sql, 0, '... and nothing is read';

  eval { ExtFixedDeploy->new(schema => fresh_schema(
      schemas => [ 'gis' ], extensions => [ fixedext => { schema => 'gis' } ]))
    ->_extension_control_schemas };
  like $@, qr/extension fixedext is declared in schema gis, but its control file fixes schema ag_catalog/,
    'a declared schema against the fixed one is refused by the deploy, before any statement';
}

done_testing;
