use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k82: DBIO::PostgreSQL::DDL->install_ddl on a schema
# that does NOT load the DBIO::PostgreSQL component.
#
# WHY IT MATTERS: deploy_async reaches install_ddl through the transport's
# _ddl_class (core DBIO::Storage::Async::_install_ddl) with whatever schema it
# is handed, and since dbio-postgresql-ev k36 connecting with
# { async => 'ev' } WITHOUT load_components('PostgreSQL') is a documented
# shape. install_ddl asked that schema for pg_extensions, pg_schemas,
# pg_schema_class, pg_settings and pg_search_path -- methods only the component
# provides -- and died at the first one, so such a schema could not deploy.
#
# WHAT IT PINS: a component-less schema deploys exactly what the component
# deploys when nothing is declared -- the SAME DDL, compared byte for byte, so
# the fallback cannot drift from the component's defaults. Note that "nothing
# declared" is not "no declaration": the component defaults pg_search_path to
# ('public'); the script writes no SET search_path for it any more (karr k121),
# so the two scripts are alike without it.

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::DDL;

my @SCHEMA_DECLS = qw(
  pg_extensions pg_schemas pg_schema_class pg_settings pg_search_path
);

# A plain result class -- no DBIO::PostgreSQL::Result either -- shared by both
# schema classes below, so any difference in their DDL can only come from the
# schema-level declarations.
{
  package NoPgComp::Result::Widget;
  use base 'DBIO::Core';
  __PACKAGE__->table('widget');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
    note => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(widget_name => ['name']);
}
{
  # Does NOT load the PostgreSQL component.
  package NoPgComp::Schema;
  use base 'DBIO::Schema';
}
NoPgComp::Schema->register_class(Widget => 'NoPgComp::Result::Widget');
{
  # Loads the component and declares nothing.
  package WithPgComp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
WithPgComp::Schema->register_class(Widget => 'NoPgComp::Result::Widget');

# -----------------------------------------------------------------------
# 0. The premise: the component-less schema really answers none of the
#    schema-level declarations, and the component-loaded one answers all.
# -----------------------------------------------------------------------
ok !NoPgComp::Schema->can($_), "the component-less schema has no $_"
  for @SCHEMA_DECLS;
ok +WithPgComp::Schema->can($_), "the component-loaded schema has $_"
  for @SCHEMA_DECLS;

# -----------------------------------------------------------------------
# 1. install_ddl lives on it and emits the table, nothing schema-level
# -----------------------------------------------------------------------
my $plain_ddl = eval { DBIO::PostgreSQL::DDL->install_ddl('NoPgComp::Schema') };
ok defined $plain_ddl,
  'install_ddl lives on a schema without the PostgreSQL component'
  or diag "install_ddl died: $@";
$plain_ddl //= '';

like $plain_ddl, qr/^CREATE TABLE widget \(/m, '... and emits the CREATE TABLE';
like $plain_ddl, qr/CONSTRAINT widget_name UNIQUE \(name\)/,
  '... with the result class\'s own constraint';
unlike $plain_ddl, qr/CREATE EXTENSION/, '... no CREATE EXTENSION';
unlike $plain_ddl, qr/CREATE SCHEMA/,    '... no CREATE SCHEMA';
unlike $plain_ddl, qr/CREATE TYPE/,      '... no CREATE TYPE from a PgSchema class';
unlike $plain_ddl, qr/ALTER DATABASE/,   '... no ALTER DATABASE for settings';

# -----------------------------------------------------------------------
# 2. ... and it is exactly what the component deploys with nothing declared
# -----------------------------------------------------------------------
my $comp_ddl = DBIO::PostgreSQL::DDL->install_ddl('WithPgComp::Schema');
is $plain_ddl, $comp_ddl,
  'byte-identical to the DDL of a component-loaded schema that declares nothing';

my $default_path = join ', ', DBIO::PostgreSQL->pg_search_path;
unlike $plain_ddl, qr/search_path/,
  "... and neither writes the component's default search_path ($default_path) (karr k121)";

# -----------------------------------------------------------------------
# 3. The fallback reads the component's defaults, it never writes them
# -----------------------------------------------------------------------
is_deeply [ DBIO::PostgreSQL->pg_extensions ], [], 'the component class still declares no extension';
is_deeply [ DBIO::PostgreSQL->pg_schemas ],    [], '... no namespace';
is_deeply +DBIO::PostgreSQL->pg_settings,      {}, '... no setting';

done_testing;
