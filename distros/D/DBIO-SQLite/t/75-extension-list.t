use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::SQLite::Deploy;
use DBIO::SQLite::Extension;

# OFFLINE test: sqlite_extensions is the declared list of a schema's database
# extensions and the driver resolves each name to its extension class (ADR
# 0066, section 1.2; karr k85).
#
# WHY: an application writes its extensions once, in sqlite_extensions; which
# class stands behind a name decides which rules run for the schema. The fixed
# table of the family, the class option for a foreign extension and the plain
# class for the rest must not blur, and a class that is missing, of the wrong
# interface or of another driver must refuse before anything is deployed. And
# the extension mechanism never decides the driver (ADR 0032 section 7).
#
# What this file claims:
#   1. the table of the family names fts5 and rtree; anything else (a loadable
#      library such as vec0 or spatialite) is not in it;
#   2. sqlite_extensions accepts library and class, keeps them apart, and
#      refuses what is neither; a second call replaces the list;
#   3. a name of the table gets its class, the option class wins over the
#      table, any other name gets the plain class;
#   4. a distribution that is not installed refuses, naming it;
#   5. an interface version outside core's set, and a class of another
#      driver, refuse when the list is resolved;
#   6. the declaration is the list: nothing is in it that is not declared, and
#      a schema that declares none has none;
#   7. declaring extensions does not touch the driver: the storage type is
#      the SQLite one, no extension class is a schema component, and a
#      storage layer an extension class names is registered, not the driver.

# --- 1. the table ----------------------------------------------------------
is_deeply [ DBIO::SQLite::Extension->family_class('fts5') ],
  [ 'DBIO::SQLite::Extension::FTS5', 'DBIO-SQLite' ], 'fts5';
is_deeply [ DBIO::SQLite::Extension->family_class('rtree') ],
  [ 'DBIO::SQLite::Extension::RTree', 'DBIO-SQLite' ], 'rtree';
is_deeply [ DBIO::SQLite::Extension->family_class('spatialite') ], [],
  'spatialite is not in the table: a gap, documented, not a guess';
is_deeply [ DBIO::SQLite::Extension->family_class('vec0') ], [], 'a loadable library neither';

# --- the plain class and the family's classes --------------------------------
{
  my $plain = 'DBIO::SQLite::Extension';
  isa_ok $plain, 'DBIO::Extension';
  is $plain->extension_interface, 1, 'the plain class states the interface version';
  is $plain->driver, 'DBIO::SQLite', '... and the driver';
  is $plain->name, undef, '... and no name: one class serves every name';
  lives_ok { DBIO::Extension->check_interface($plain) } '... core accepts it';
  is_deeply $plain->claims({}, {}), [], 'no claims';
  is_deeply $plain->annotate({}, {}), [], 'no annotations';
  is $plain->verdict({ kind => 'column_type' }, {}), undef, 'no verdict';
  is $plain->storage_layer, undef, 'no storage layer';
  is $plain->activation({ self => { name => 'x', options => {} } }), undef, 'no activation without a library';
  is_deeply $plain->activation({ self => { name => 'vec0', options => { library => '/opt/vec0.so' } } }),
    { load => { vec0 => '/opt/vec0.so' } }, '... with a library: that library is loaded, under the name';

  for my $name (qw( fts5 rtree )) {
    my ($class) = DBIO::SQLite::Extension->family_class($name);
    eval "require $class; 1" or die $@;
    isa_ok $class, 'DBIO::SQLite::Extension', $class;
    is $class->name, $name, "$class: the engine's name";
    is $class->driver, 'DBIO::SQLite', '... the driver';
    lives_ok { DBIO::Extension->check_interface($class) } '... core accepts it';
  }
}

my $n = 0;
sub schema_class {
  my (@declaration) = @_;
  my $pkg = 'T75::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('SQLite');
  $pkg->sqlite_extensions(@declaration) if @declaration;
  return $pkg;
}

sub list_of {
  my $schema = schema_class(@_);
  return DBIO::SQLite::Deploy->new(schema => $schema)->_resolve_extension_list;
}

# --- 2. the declaration --------------------------------------------------------
{
  my $schema = schema_class(
    'a', b => { library => '/lib/b.so' }, c => { class => 'DBIO::SQLite::Extension' },
    d => { library => 'dlib', class => 'DBIO::SQLite::Extension' },
  );
  is_deeply [ $schema->sqlite_extensions ], [qw( a b c d )], 'the list in list context: the names, in order';
  is_deeply $schema->sqlite_extension_options, {
    b => { library => '/lib/b.so' },
    c => { class => 'DBIO::SQLite::Extension' },
    d => { library => 'dlib', class => 'DBIO::SQLite::Extension' },
  }, 'the options, of the names that gave some';

  $schema->sqlite_extension_options->{a} = { library => 'X' };
  $schema->sqlite_extension_options->{b}{library} = 'X';
  is_deeply [ sort keys %{ $schema->sqlite_extension_options } ], [qw( b c d )], 'a copy: changing it declares nothing';
  is $schema->sqlite_extension_options->{b}{library}, '/lib/b.so', '... also one level down';

  $schema->sqlite_extensions('plain');
  is_deeply $schema->sqlite_extension_options, {}, 'declaring again replaces the options as it replaces the names';
  is_deeply [ $schema->sqlite_extensions ], ['plain'], '... and the names';

  my $other = schema_class('fts5');
  is_deeply [ $other->sqlite_extensions ], ['fts5'], 'a schema class has its own list';
  is_deeply [ $schema->sqlite_extensions ], ['plain'], '... the first one is not changed by it';
}
{
  my $s = schema_class();
  throws_ok { $s->sqlite_extensions(x => { colour => 'red' }) }
    qr/extension 'x' has no option colour; the options are 'library' and 'class'/,
    'an unknown option is refused, naming the ones that exist';
  throws_ok { $s->sqlite_extensions(x => {}) }
    qr/extension 'x' has an empty options hashref; give 'library' or 'class'/, 'an empty hashref';
  throws_ok { $s->sqlite_extensions(x => { class => '' }) }
    qr/extension 'x' needs a 'class', a class name/, 'an empty class';
  throws_ok { $s->sqlite_extensions(x => { class => 'Not A::Class' }) }
    qr/needs a 'class', a class name/, 'not a class name';
  throws_ok { $s->sqlite_extensions(x => { class => [] }) }
    qr/needs a 'class', a class name/, 'a reference';
  throws_ok { $s->sqlite_extensions(x => { library => '' }) }
    qr/extension 'x' needs a 'library', a plain non-empty string/, 'an empty library';
  throws_ok { $s->sqlite_extensions(x => { library => undef }) }
    qr/needs a 'library'/, 'undef';
  throws_ok { $s->sqlite_extensions(x => { library => ['a'] }) }
    qr/needs a 'library'/, 'a reference';
  throws_ok { $s->sqlite_extensions(x => { library => 'a' }, { class => 'A' }) }
    qr/an extension name is expected, got a HASH reference/, 'a second hashref for one name';
  throws_ok { $s->sqlite_extensions({ library => 'a' }) }
    qr/an extension name is expected, got a HASH reference/, 'a hashref without a name';
  throws_ok { $s->sqlite_extensions(undef) } qr/an extension name is expected, got undef/, 'undef for a name';
  is_deeply [ $s->sqlite_extensions ], [], 'a refused declaration declares nothing';
}

# --- 3. resolution --------------------------------------------------------------
{
  package T75::Family;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'fam' }
  sub driver { 'DBIO::SQLite' }
}
{
  package T75::Own;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'spellfix1' }
  sub driver { 'DBIO::SQLite' }
}
$INC{'T75/Family.pm'} = $INC{'T75/Own.pm'} = __FILE__;

{
  my $list = list_of('fts5', 'rtree', spellfix1 => { class => 'T75::Own' }, vec0 => { library => '/opt/vec0.so' }, 'json1');
  my %by = map { $_->{name} => $_ } $list->entries;

  is_deeply [ $list->names ], [qw( fts5 json1 rtree spellfix1 vec0 )], 'the entries, by name';
  is $by{fts5}{class}, 'DBIO::SQLite::Extension::FTS5', 'a name of the table gets its class';
  is $by{rtree}{class}, 'DBIO::SQLite::Extension::RTree', '... both';
  is $by{spellfix1}{class}, 'T75::Own', 'the option class names the class of a foreign extension';
  is $by{json1}{class}, 'DBIO::SQLite::Extension', 'any other name gets the plain class';
  is $by{vec0}{class}, 'DBIO::SQLite::Extension', '... also with a library';
  is_deeply $by{vec0}{options}, { library => '/opt/vec0.so' }, 'the library is an option of the entry';
  is_deeply $by{spellfix1}{options}, {}, '... the class is not';
}
{
  local $DBIO::SQLite::Extension::FAMILY{fam} = [ 'T75::Family', 'DBIO-T75' ];
  throws_ok { list_of(fam => { class => 'T75::Own' }) } qr/is the extension 'spellfix1'/,
    'a class that states another name than the entry refuses';
}
{
  local $DBIO::SQLite::Extension::FAMILY{spellfix1} = [ 'T75::Family', 'DBIO-T75' ];
  my ($entry) = list_of(spellfix1 => { class => 'T75::Own' })->entries;
  is $entry->{class}, 'T75::Own', 'the option class wins over the table entry of the same name';
}

# --- 4. not installed -------------------------------------------------------------
{
  local $DBIO::SQLite::Extension::FAMILY{ghost} = [ 'T75::NotThere::Extension', 'DBIO-T75-NotThere' ];
  throws_ok { list_of('ghost') }
    qr/Extension 'ghost': class T75::NotThere::Extension is not installed -- install the distribution DBIO-T75-NotThere/,
    'a distribution that is not installed refuses, naming it';
  throws_ok { list_of(ghost2 => { class => 'T75::AlsoNotThere' }) }
    qr/class T75::AlsoNotThere is not installed/, 'a named class that is missing: the class';
}

# --- 5. interface and driver -----------------------------------------------------------
{
  package T75::Future;
  use base 'DBIO::Extension';
  sub extension_interface { 99 }
  sub name { 'future' }
  package T75::OtherDriver;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'foreign' }
  sub driver { 'DBIO::PostgreSQL' }
}
$INC{'T75/Future.pm'} = $INC{'T75/OtherDriver.pm'} = __FILE__;

throws_ok { list_of(future => { class => 'T75::Future' }) }
  qr/T75::Future implements interface version 99.*upgrade DBIO core/s,
  'an interface version outside core\'s set refuses, naming the side to upgrade';
throws_ok { list_of(foreign => { class => 'T75::OtherDriver' }) }
  qr/Extension 'foreign' \(T75::OtherDriver\) belongs to the driver DBIO::PostgreSQL, but the schema's driver is DBIO::SQLite/,
  'a class of another driver refuses, naming both';

# --- 6. the declaration is the list ------------------------------------------------------
is(list_of(), undef, 'a schema that declares nothing has no list');
is_deeply(DBIO::SQLite::Deploy->new(schema => schema_class())->_extension_list, [],
  '... and _extension_list is empty (without reading anything)');
{
  local $DBIO::SQLite::Extension::FAMILY{fam} = [ 'T75::Family', 'DBIO-T75' ];
  is_deeply [ list_of('json1')->names ], ['json1'], 'a loaded family class is not in a schema that does not declare it';
}
{
  my $bare = 'T75::Bare';
  eval "package $bare; use base q(DBIO::Schema); 1" or die $@;
  is(DBIO::SQLite::Extension->resolve_list($bare), undef,
    'a schema class that does not load the component declares none (and does not die)');
}

# --- 7. the driver is not decided here -------------------------------------------------------
{
  package T75::Layered;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'layered' }
  sub driver { 'DBIO::SQLite' }
  sub storage_layer { 'T75::Layer' }
  package T75::Layer;
  sub t75_layered { 'layered' }
}
$INC{'T75/Layered.pm'} = $INC{'T75/Layer.pm'} = __FILE__;

{
  my $class = schema_class(layered => { class => 'T75::Layered' }, 'fts5');
  is_deeply $class->storage_layers, [], 'declaring registers nothing yet';
  my $schema = $class->connect('dbi:SQLite::memory:');
  is_deeply $schema->storage_layers, ['T75::Layer'], 'connect registers the layer the class names';
  isa_ok $schema->storage, 'DBIO::SQLite::Storage', 'the storage: the driver stays the SQLite one';
  ok $schema->storage->can('t75_layered'), '... with the layer composed over it';

  my $plain = schema_class('fts5', 'rtree', vec0 => { library => 'x' })->connect('dbi:SQLite::memory:');
  is_deeply $plain->storage_layers, [], 'extensions that name no layer register none';
  isa_ok $plain->storage, 'DBIO::SQLite::Storage', 'the storage';
  is $plain->storage_type, '+DBIO::SQLite::Storage', 'the storage type is the component\'s, as before';
}
for my $class (qw( DBIO::SQLite::Extension DBIO::SQLite::Extension::FTS5 DBIO::SQLite::Extension::RTree )) {
  ok !$class->isa('DBIO::Base') && !$class->can('connection') && !$class->can('storage_type'),
    "$class is no schema component and has no connect hook of its own";
}

done_testing;
