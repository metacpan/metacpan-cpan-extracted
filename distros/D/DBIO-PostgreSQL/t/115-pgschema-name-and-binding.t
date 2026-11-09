use strict;
use warnings;

use Test::More;

use DBIO::Core ();
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Deploy;

# OFFLINE test for karr k103 (maintainer's decision 2026-10-12).
#
# Claims:
#  (a) pg_schemas answers the names in the order they were declared, not in
#      hash order; install_ddl creates schemas and types in that order.
#  (b) a pg_schema_class binding never restricts the deploy: only pg_schemas
#      does (Deploy::_schema_filter). A binding for a name no declared
#      pg_schemas list names is refused loudly; without a list the bound
#      class is still installed, after any declared names.
#  (c) a PgSchema class has no class setter pg_schema_name: a class maps to a
#      namespace by one source, pg_schema_class on the schema class. The
#      instance form new(pg_schema_name => ...) keeps its reader.

{
  package K103::PgSchema::Auth;
  use base 'DBIO::PostgreSQL::PgSchema';
  __PACKAGE__->pg_enum('role_type' => [qw( admin user )]);
}
{
  package K103::PgSchema::Api;
  use base 'DBIO::PostgreSQL::PgSchema';
  __PACKAGE__->pg_enum('kind_type' => [qw( a b )]);
}

# --- (c) no class setter -------------------------------------------------------

{
  my $ok = eval { K103::PgSchema::Auth->pg_schema_name('auth'); 1 };
  ok(!$ok, 'pg_schema_name has no class form: the call dies');
}
is(K103::PgSchema::Auth->new(pg_schema_name => 'auth')->pg_schema_name, 'auth',
  'the instance reader answers the value given to new');
is(K103::PgSchema::Auth->new->pg_schema_name, undef,
  'an instance without a name has none');

# --- (a) declaration order -------------------------------------------------------

my @decl = qw( zeta alpha mid public beta gamma delta );
{
  package K103::Ordered;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas(@decl);
}
is_deeply([ K103::Ordered->pg_schemas ], \@decl,
  'pg_schemas answers the names in declaration order') or diag explain [ K103::Ordered->pg_schemas ];

{
  my $sql = DBIO::PostgreSQL::DDL->install_ddl('K103::Ordered');
  my @created = $sql =~ /CREATE SCHEMA IF NOT EXISTS (\w+);/g;
  is_deeply(\@created, [ grep { $_ ne 'public' } @decl ],
    'the schemas are created in declaration order');
}

{
  package K103::Ordered2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas(qw( zeta api auth alpha ));
  __PACKAGE__->pg_schema_class(auth => 'K103::PgSchema::Auth');
  __PACKAGE__->pg_schema_class(api  => 'K103::PgSchema::Api');
}
{
  my $sql = DBIO::PostgreSQL::DDL->install_ddl('K103::Ordered2');
  my @types = $sql =~ /CREATE TYPE (\w+\.\w+) AS ENUM/g;
  is_deeply(\@types, [qw( api.kind_type auth.role_type )],
    'the types of the PgSchema classes follow the declared schema order');
}

# --- (b) a binding does not restrict ---------------------------------------------

{
  package K103::BoundOnly;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schema_class(auth => 'K103::PgSchema::Auth');
}
is_deeply([ K103::BoundOnly->pg_schemas ], [],
  'pg_schema_class alone declares no pg_schemas');
{
  my $deploy = DBIO::PostgreSQL::Deploy->new(schema => K103::BoundOnly->clone);
  is($deploy->_schema_filter, undef,
    'a binding alone leaves the deploy unrestricted');
  my $sql = DBIO::PostgreSQL::DDL->install_ddl('K103::BoundOnly');
  like($sql, qr/CREATE TYPE auth\.role_type AS ENUM/,
    'the bound class is still installed');
}

{
  my $err;
  { local $@; eval { K103::Ordered2->pg_schema_class(nope => 'K103::PgSchema::Api'); 1 } or $err = $@; }
  like($err // '', qr/nope/, 'a binding for a name pg_schemas does not name is refused, naming it');
  is(K103::Ordered2->pg_schema_class('nope'), undef, 'and is not set');
  is_deeply([ K103::Ordered2->pg_schemas ], [qw( zeta api auth alpha )],
    'and the declared list is untouched');
}

# --- pg_schemas after a binding ---------------------------------------------------

{
  my $err;
  { local $@; eval { K103::Ordered2->pg_schemas(qw( api auth )); 1 } or $err = $@; }
  ok(defined $err, 'pg_schemas after pg_schema_class dies');
  like($err // '', qr/api, auth/, 'the message names the bound schemas');
  is(K103::Ordered2->pg_schema_class('auth'), 'K103::PgSchema::Auth',
    'the binding is untouched by the refusal');
}
{
  package K103::Plain;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas(qw( public auth ));
  __PACKAGE__->pg_schemas(qw( public api ));
}
is_deeply([ K103::Plain->pg_schemas ], [qw( public api )],
  'pg_schemas again, nothing bound: replaces the list');

done_testing;
