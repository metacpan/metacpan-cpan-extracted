use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff::Extension;

# OFFLINE test for karr k120, point 8 (maintainer's decision 2026-10-12):
# pg_extensions can name the schema an extension is installed in.
#
#   pg_extensions('pgcrypto', vector => { schema => 'extensions' })
#
# WHAT IT PINS:
#   - the list form (names only) is what it was: the same names, the same
#     CREATE EXTENSION, and an extension a list names is never moved by a diff;
#   - the install writes CREATE EXTENSION ... WITH SCHEMA <schema>, and the
#     schema is there before the extension;
#   - the diff moves a relocatable extension whose schema deviates from the
#     declared one (ALTER EXTENSION ... SET SCHEMA) and REFUSES to move one
#     that is not relocatable -- when the operations are built, not when the
#     statements are written;
#   - what karr k89 decided stays: a restricted deploy still drops no extension.

my $n = 0;
sub fresh_schema {
  my (%o) = @_;
  my $pkg = 'ExtSchema' . ++$n . '::Schema';
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_schemas(@{ $o{schemas} }) if $o{schemas};
  $pkg->pg_extensions(@{ $o{extensions} }) if $o{extensions};
  return $pkg;
}

# ---- declaration ---------------------------------------------------------

{
  my $s = fresh_schema(extensions => [ 'pgcrypto', 'vector' ]);
  is_deeply [ $s->pg_extensions ], [ 'pgcrypto', 'vector' ],
    'list form: the names, as before';
  is_deeply scalar $s->pg_extension_schemas, {}, '... and no schema declared';
}
{
  my $s = fresh_schema(
    extensions => [ 'pgcrypto', vector => { schema => 'extensions' }, 'hstore' ],
  );
  is_deeply [ $s->pg_extensions ], [ 'pgcrypto', 'vector', 'hstore' ],
    'with a schema: pg_extensions still answers the names, in order';
  is_deeply scalar $s->pg_extension_schemas, { vector => 'extensions' },
    '... and pg_extension_schemas the schema of the one that names it';
}

for my $case (
  [ 'a hash with no name before it'  => [ { schema => 'x' } ],                      qr/pg_extensions.*name/i ],
  [ 'two hashes for one name'        => [ 'vector', { schema => 'x' }, { schema => 'y' } ], qr/pg_extensions.*name/i ],
  [ 'an unknown key'                 => [ 'vector', { schemas => 'x' } ],             qr/pg_extensions.*vector.*schemas/s ],
  [ 'an empty schema'                => [ 'vector', { schema => '' } ],               qr/pg_extensions.*vector.*schema/s ],
  [ 'a schema that is a reference'   => [ 'vector', { schema => ['x'] } ],            qr/pg_extensions.*vector.*schema/s ],
  [ 'no schema key'                  => [ 'vector', {} ],                             qr/pg_extensions.*vector.*schema/s ],
) {
  my ($what, $args, $like) = @$case;
  throws_ok { fresh_schema(extensions => $args) } $like, "refused: $what";
}

# ---- install -------------------------------------------------------------

sub script { DBIO::PostgreSQL::DDL->install_ddl($_[0]) }
sub pos_of { my ($sql, $re) = @_; $sql =~ $re ? $-[0] : undef }

{
  my $sql = script(fresh_schema(extensions => [ 'pgcrypto' ]));
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;$/m,
    'list form: CREATE EXTENSION names public (karr k141)';
  unlike $sql, qr/CREATE SCHEMA/, '... and creates no schema for it';
}
{
  my $sql = script(fresh_schema(
    schemas    => [ 'extensions' ],
    extensions => [ pgcrypto => { schema => 'extensions' }, 'hstore' ],
  ));
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;$/m,
    'the extension is created WITH SCHEMA';
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;$/m,
    '... one without a schema is created in public (karr k141)';
  my $schema_at = pos_of($sql, qr/^CREATE SCHEMA IF NOT EXISTS extensions;$/m);
  my $ext_at    = pos_of($sql, qr/^CREATE EXTENSION IF NOT EXISTS pgcrypto /m);
  ok defined $schema_at && defined $ext_at && $schema_at < $ext_at,
    'the declared schema is created ahead of the extension'
    or diag $sql;
  is scalar(() = $sql =~ /CREATE SCHEMA IF NOT EXISTS extensions;/g), 1,
    '... once';
}
{
  # With no pg_schemas list: a schema only the extension names is refused,
  # not created (maintainer's call: the smaller surface).
  my $schema = fresh_schema(extensions => [ pgcrypto => { schema => 'extensions' } ]);
  throws_ok { script($schema) }
    qr/refusing to write the install DDL.*pgcrypto.*extensions.*add 'extensions' to pg_schemas.*restricted.*manage_extensions_when_restricted/s,
    'no pg_schemas list: a schema only the extension names is refused';
}
{
  my $sql = script(fresh_schema(
    schemas    => [ 'app', 'extensions' ],
    extensions => [ vector => { schema => 'extensions' } ],
  ));
  is scalar(() = $sql =~ /CREATE SCHEMA IF NOT EXISTS extensions;/g), 1,
    'a schema pg_schemas names is created once, not twice';
  my $schema_at = pos_of($sql, qr/^CREATE SCHEMA IF NOT EXISTS extensions;$/m);
  my $ext_at    = pos_of($sql, qr/^CREATE EXTENSION IF NOT EXISTS vector /m);
  ok $schema_at < $ext_at, '... ahead of the extension' or diag $sql;
}
{
  my $sql = script(fresh_schema(extensions => [ vector => { schema => 'public' } ]));
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;$/m,
    'public is named as any schema';
  unlike $sql, qr/CREATE SCHEMA/, '... and is not created';
}
{
  my $sql = script(fresh_schema(schemas => [ 'MySchema' ], extensions => [ vector => { schema => 'MySchema' } ]));
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA "MySchema";$/m,
    'the schema is a name, quoted by the rule of every name';
  like $sql, qr/^CREATE SCHEMA IF NOT EXISTS "MySchema";$/m, '... where it is created too';
}
{
  my $schema = fresh_schema(
    schemas    => [ 'app' ],
    extensions => [ vector => { schema => 'extensions' } ],
  );
  throws_ok { script($schema) }
    qr/refusing to write the install DDL.*vector.*extensions.*pg_schemas/s,
    'a pg_schemas list that does not name the extension\'s schema is refused, '
    . 'naming extension and schema';
}

# ---- diff ----------------------------------------------------------------

sub ext {
  my ($name, %o) = @_;
  return { extension_name => $name, version => '1.0', requires => [], %o };
}
sub ops_of {
  return [ DBIO::PostgreSQL::Diff::Extension->diff(@_) ];
}

{
  my $ops = ops_of(
    { vector => ext('vector', schema_name => 'public', relocatable => 1) },
    { vector => ext('vector', schema_name => 'extensions', declared_schema => 'extensions') },
  );
  is scalar @$ops, 1, 'relocatable, in another schema than declared: one operation';
  is $ops->[0]->action, 'move', '... a move';
  is $ops->[0]->as_sql, 'ALTER EXTENSION vector SET SCHEMA extensions;', '... SET SCHEMA';
  like $ops->[0]->summary, qr/~extension: vector.*public.*extensions/, '... and says from where to where';
}
is scalar @{ ops_of(
  { vector => ext('vector', schema_name => 'extensions', relocatable => 1) },
  { vector => ext('vector', schema_name => 'extensions', declared_schema => 'extensions') },
) }, 0, 'in the declared schema: nothing to do';
is scalar @{ ops_of(
  { vector => ext('vector', schema_name => 'extensions', relocatable => 1) },
  { vector => ext('vector', schema_name => 'public') },
) }, 0, 'a schema nobody declared is not compared: the list form never moves';
{
  my $ops = ops_of(
    { vector => ext('vector', version => '0.7', schema_name => 'public', relocatable => 1) },
    { vector => ext('vector', version => '0.8', schema_name => 'x', declared_schema => 'x') },
  );
  is_deeply [ map { $_->action } @$ops ], [ 'update', 'move' ],
    'a new version and another schema: both, the update first';
}
{
  my $ops = ops_of(
    { vector => ext('vector', schema_name => 'public', relocatable => 1) },
    { vector => ext('vector', schema_name => 'q"x', declared_schema => 'q"x') },
  );
  is $ops->[0]->as_sql, 'ALTER EXTENSION vector SET SCHEMA "q""x";',
    'the schema is written as an identifier';
}
throws_ok {
  ops_of(
    { postgis => ext('postgis', schema_name => 'public', relocatable => 0) },
    { postgis => ext('postgis', schema_name => 'gis', declared_schema => 'gis') },
  );
} qr/refusing to diff: extension postgis.*public.*gis.*not relocatable/s,
  'not relocatable: refused when the operations are built, naming extension and both schemas';

{
  my @ops = DBIO::PostgreSQL::Diff::Extension->diff(
    {},
    { vector => ext('vector', schema_name => 'extensions', declared_schema => 'extensions') },
  );
  is $ops[0]->as_sql, 'CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;',
    'a create writes WITH SCHEMA for a declared schema';
  @ops = DBIO::PostgreSQL::Diff::Extension->diff(
    {}, { vector => ext('vector', schema_name => 'public') },
  );
  is $ops[0]->as_sql, 'CREATE EXTENSION IF NOT EXISTS vector;',
    '... and as before for one that named none';
}

# ---- deploy --------------------------------------------------------------

{
  package ExtSchemaDeploy;
  use base 'DBIO::PostgreSQL::Deploy';
  our (%LIVE, %DESIRED);
  # The extension protocol (ADR 0066) runs for declared extensions and needs
  # a connection and the installed state; this fake has neither.
  sub _dbh { {} }
  sub _extension_control_schemas { {} }
  sub _installed_extensions { +{ map { $_ => { installed => 0 } } @{ $_[1] } } }
  sub _introspect_current { +{ extensions => { %LIVE } } }
  sub _build_target_model {
    my ($self) = @_;
    return $self->_mark_extension_schemas({ extensions => { %DESIRED } });
  }
}

sub deploy_diff {
  my ($schema, $live, $desired) = @_;
  local %ExtSchemaDeploy::LIVE    = %$live;
  local %ExtSchemaDeploy::DESIRED = %$desired;
  return ExtSchemaDeploy->new(schema => $schema)->diff;
}

{
  my $schema = fresh_schema(
    schemas    => [ 'public', 'extensions' ],
    extensions => [ vector => { schema => 'extensions' } ],
  );
  my $diff = deploy_diff($schema,
    { vector => ext('vector', schema_name => 'public', relocatable => 1),
      hstore => ext('hstore', schema_name => 'public', relocatable => 1) },
    { vector => ext('vector', schema_name => 'public') },
  );
  my %act = map { $_->extension_name => $_->action }
    grep { $_->isa('DBIO::PostgreSQL::Diff::Extension') } @{ $diff->operations };
  is_deeply \%act, { vector => 'move' },
    'the deploy marks the declared schema: moved; the undeclared hstore of a '
    . 'restricted deploy is not dropped (k89)';
  like $diff->as_sql, qr/ALTER EXTENSION vector SET SCHEMA extensions;/, '... in the SQL';
}
{
  my $schema = fresh_schema(extensions => [ 'vector' ]);
  my $diff = deploy_diff($schema,
    { vector => ext('vector', schema_name => 'extensions', relocatable => 1) },
    { vector => ext('vector', schema_name => 'public') },
  );
  ok !$diff->has_changes, 'list form through the deploy: an extension in a schema of its own stays';
}
{
  my $schema = fresh_schema(
    schemas    => [ 'gis' ],
    # postgis is in the driver's table of the family (ADR 0066), whose
    # distribution is not a dependency of this one: the plain class stands in.
    extensions => [ postgis => { schema => 'gis', class => 'DBIO::PostgreSQL::Extension' } ],
  );
  throws_ok {
    deploy_diff($schema,
      { postgis => ext('postgis', schema_name => 'public', relocatable => 0) },
      { postgis => ext('postgis', schema_name => 'gis') },
    );
  } qr/refusing to diff: extension postgis/, 'the deploy refuses in diff(), not in as_sql';
}

done_testing;
