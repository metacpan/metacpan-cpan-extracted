use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Extension;

# OFFLINE test: pg_extensions is the declared list of a schema's database
# extensions and the driver resolves each name to its extension class (ADR
# 0066, section 1.2).
#
# WHY: an application writes its extensions once, in pg_extensions; which class
# stands behind a name decides which rules run for the schema. The fixed table
# of the family, the class option for a foreign extension and the plain class
# for the rest must not blur, and a class that is missing, of the wrong
# interface or of another driver must refuse before anything is deployed.
#
# What this file claims:
#   1. the table of the family names the three classes and their distributions;
#   2. pg_extensions accepts class (beside schema), keeps it apart from the
#      schema, and refuses what is neither;
#   3. a name of the table gets its class, the option class wins over the
#      table, any other name gets the plain class;
#   4. a distribution that is not installed refuses, naming the distribution;
#   5. an interface version outside core's set, and a class of another
#      driver, refuse when the list is resolved;
#   6. the declaration is the list: nothing is in it that is not declared, and
#      a schema that declares none has none.

# --- 1. the table ----------------------------------------------------------
is_deeply [ DBIO::PostgreSQL::Extension->family_class('age') ],
  [ 'DBIO::PostgreSQL::Age::Extension', 'DBIO-PostgreSQL-Age' ], 'age';
is_deeply [ DBIO::PostgreSQL::Extension->family_class('postgis') ],
  [ 'DBIO::PostgreSQL::PostGIS::Extension', 'DBIO-PostgreSQL-PostGIS' ], 'postgis';
is_deeply [ DBIO::PostgreSQL::Extension->family_class('postgis_topology') ],
  [ 'DBIO::PostgreSQL::PostGIS::Topology::Extension', 'DBIO-PostgreSQL-PostGIS' ],
  'postgis_topology: a class of its own, in the distribution of PostGIS';
is_deeply [ DBIO::PostgreSQL::Extension->family_class('vector') ], [],
  'vector is not in the table: it is a plain extension';
is_deeply [ DBIO::PostgreSQL::Extension->family_class('citext') ], [], 'citext neither';

# --- the plain class ----------------------------------------------------------
{
  my $plain = 'DBIO::PostgreSQL::Extension';
  isa_ok $plain, 'DBIO::Extension';
  is $plain->extension_interface, 1, 'the plain class states the interface version';
  is $plain->driver, 'DBIO::PostgreSQL', '... and the driver';
  is $plain->name, undef, '... and no name: one class serves every name';
  lives_ok { DBIO::Extension->check_interface($plain) } '... core accepts it';
  is_deeply $plain->claims({}, {}), [], 'no claims';
  is_deeply $plain->annotate({}, {}), [], 'no annotations';
  is $plain->verdict({ kind => 'column_type' }, {}), undef, 'no verdict';
  is $plain->activation({}), undef, 'no activation';
  is $plain->storage_layer, undef, 'no storage layer';
}

my $n = 0;
sub schema_class {
  my (@declaration) = @_;
  my $pkg = 'T141::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_extensions(@declaration) if @declaration;
  return $pkg;
}

sub list_of {
  my $schema = schema_class(@_);
  return DBIO::PostgreSQL::Deploy->new(schema => $schema)->_resolve_extension_list;
}

# --- 2. the declaration --------------------------------------------------------
{
  my $schema = schema_class(
    'a', b => { schema => 'bs' }, c => { class => 'DBIO::PostgreSQL::Extension' },
    d => { schema => 'ds', class => 'DBIO::PostgreSQL::Extension' },
  );
  is_deeply [ $schema->pg_extensions ], [qw( a b c d )], 'the list in list context: the names, in order';
  is_deeply $schema->pg_extension_schemas, { b => 'bs', d => 'ds' }, 'the schemas';
  is_deeply $schema->pg_extension_classes,
    { c => 'DBIO::PostgreSQL::Extension', d => 'DBIO::PostgreSQL::Extension' }, 'the classes';

  $schema->pg_extension_classes->{a} = 'X';
  is_deeply [ sort keys %{ $schema->pg_extension_classes } ], [qw( c d )], 'a copy: changing it declares nothing';

  $schema->pg_extensions('plain');
  is_deeply $schema->pg_extension_classes, {}, 'declaring again replaces the classes as it replaces the schemas';
}
{
  my $s = schema_class();
  throws_ok { $s->pg_extensions(x => { colour => 'red' }) }
    qr/extension 'x' has no option 'colour'; the options are 'schema' and 'class'/,
    'an unknown option is refused, naming both that exist';
  throws_ok { $s->pg_extensions(x => { schema => 'a', colour => 'red', size => 1 }) }
    qr/no option 'colour', 'size'/, '... all of them';
  throws_ok { $s->pg_extensions(x => {}) }
    qr/extension 'x' has an empty options hashref; give 'schema' or 'class'/, 'an empty hashref';
  throws_ok { $s->pg_extensions(x => { class => '' }) }
    qr/extension 'x' needs a 'class', a class name/, 'an empty class';
  throws_ok { $s->pg_extensions(x => { class => 'Not A::Class' }) }
    qr/needs a 'class', a class name/, 'not a class name';
  throws_ok { $s->pg_extensions(x => { class => [] }) }
    qr/needs a 'class', a class name/, 'a reference';
  throws_ok { $s->pg_extensions(x => { class => undef }) }
    qr/needs a 'class', a class name/, 'undef';
  throws_ok { $s->pg_extensions(x => { schema => '' }) }
    qr/needs a 'schema', a plain non-empty string/, 'the schema is still checked';
  throws_ok { $s->pg_extensions(x => { schema => 'a' }, { class => 'A' }) }
    qr/an extension name is expected, got a HASH reference/, 'a second hashref for one name';
}

# --- 3. resolution --------------------------------------------------------------
{
  package T141::Family;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'fam' }
  sub driver { 'DBIO::PostgreSQL' }
}
{
  package T141::Own;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'vector' }
  sub driver { 'DBIO::PostgreSQL' }
}
$INC{'T141/Family.pm'} = $INC{'T141/Own.pm'} = __FILE__;

{
  local $DBIO::PostgreSQL::Extension::FAMILY{fam} = [ 'T141::Family', 'DBIO-T141' ];
  my $list = list_of('fam', vector => { class => 'T141::Own' }, 'citext', pgcrypto => { schema => 'ext' });
  my %by = map { $_->{name} => $_ } $list->entries;

  is_deeply [ $list->names ], [qw( citext fam pgcrypto vector )], 'the entries, by name';
  is $by{fam}{class}, 'T141::Family', 'a name of the table gets its class';
  is $by{vector}{class}, 'T141::Own', 'the option class names the class of a foreign extension';
  is $by{citext}{class}, 'DBIO::PostgreSQL::Extension', 'any other name gets the plain class';
  is $by{pgcrypto}{class}, 'DBIO::PostgreSQL::Extension', '... also with a schema';
  is_deeply $by{pgcrypto}{options}, { schema => 'ext' }, 'the schema is an option of the entry';
  is_deeply $by{vector}{options}, {}, '... the class is not';
}
{
  local $DBIO::PostgreSQL::Extension::FAMILY{fam} = [ 'T141::Family', 'DBIO-T141' ];
  throws_ok { list_of(fam => { class => 'T141::Own' }) } qr/is the extension 'vector'/,
    'a class that states another name than the entry refuses';
}
{
  local $DBIO::PostgreSQL::Extension::FAMILY{vector} = [ 'T141::Family', 'DBIO-T141' ];
  my ($entry) = list_of(vector => { class => 'T141::Own' })->entries;
  is $entry->{class}, 'T141::Own', 'the option class wins over the table entry of the same name';
}

# --- 4. not installed -------------------------------------------------------------
{
  local $DBIO::PostgreSQL::Extension::FAMILY{ghost} = [ 'T141::NotThere::Extension', 'DBIO-T141-NotThere' ];
  throws_ok { list_of('ghost') }
    qr/Extension 'ghost': class T141::NotThere::Extension is not installed -- install the distribution DBIO-T141-NotThere/,
    'a distribution that is not installed refuses, naming it';
  throws_ok { list_of(ghost2 => { class => 'T141::AlsoNotThere' }) }
    qr/class T141::AlsoNotThere is not installed/, 'a named class that is missing: the class';
}

# --- 5. interface and driver -----------------------------------------------------------
{
  package T141::Future;
  use base 'DBIO::Extension';
  sub extension_interface { 99 }
  sub name { 'future' }
  package T141::NoInterface;
  use base 'DBIO::Extension';
  package T141::OtherDriver;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'foreign' }
  sub driver { 'DBIO::MySQL' }
}
$INC{'T141/Future.pm'} = $INC{'T141/NoInterface.pm'} = $INC{'T141/OtherDriver.pm'} = __FILE__;

throws_ok { list_of(future => { class => 'T141::Future' }) }
  qr/T141::Future implements interface version 99.*upgrade DBIO core/s,
  'an interface version outside core\'s set refuses, naming the side to upgrade';
throws_ok { list_of(noif => { class => 'T141::NoInterface' }) }
  qr/T141::NoInterface states no extension_interface/, 'no interface version';
throws_ok { list_of(foreign => { class => 'T141::OtherDriver' }) }
  qr/Extension 'foreign' \(T141::OtherDriver\) belongs to the driver DBIO::MySQL, but the schema's driver is DBIO::PostgreSQL/,
  'a class of another driver refuses, naming both';

# --- 6. the declaration is the list ------------------------------------------------------
is(list_of(), undef, 'a schema that declares nothing has no list');
is_deeply(DBIO::PostgreSQL::Deploy->new(schema => schema_class())->_extension_list, [],
  '... and _extension_list is empty (without reading anything)');
{
  # a class that is loaded in the process is not pulled in
  local $DBIO::PostgreSQL::Extension::FAMILY{fam} = [ 'T141::Family', 'DBIO-T141' ];
  is_deeply [ list_of('citext')->names ], ['citext'], 'a loaded family class is not in a schema that does not declare it';
}

done_testing;
