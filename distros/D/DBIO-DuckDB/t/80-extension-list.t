#!/usr/bin/env perl
# t/80-extension-list.t — duckdb_extensions is the declared list of a schema's
# database extensions, and the driver resolves each name to its extension class
# (ADR 0066, section 1.2; karr k46).
#
# WHY: an application writes its extensions once, in duckdb_extensions; which
# class stands behind a name decides which rules run for the schema. The class
# option for an extension with rules and the plain class for the rest must not
# blur, and a declaration that is malformed, or a class of the wrong interface
# or another driver, must refuse before anything is deployed or loaded.
#
# What this file claims:
#   1. the plain class states interface, driver and no name, and asks to be
#      LOADed; the driver ships no family class;
#   2. the declaration accepts names and the option class, and refuses what is
#      neither (unknown option, empty or second hashref, hashref without a
#      name, unusable class name);
#   3. any name gets the plain class, the option class wins;
#   4. a class of the wrong interface or of another driver refuses when the
#      list is resolved, and the driver assertion can wait (check_driver => 0);
#   5. the declaration is the list: a schema that declares none has none, and
#      connecting never lets an extension choose the driver.
#
# Offline: no connection is made before section 5.

use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::DuckDB::Extension;
use DBIO::DuckDB::Deploy;

# --- 1. the plain class -------------------------------------------------------
{
  my $plain = 'DBIO::DuckDB::Extension';
  isa_ok $plain, 'DBIO::Extension';
  is $plain->extension_interface, 1, 'the plain class states the interface version';
  is $plain->driver, 'DBIO::DuckDB', '... and the driver';
  is $plain->name, undef, '... and no name: one class serves every name';
  lives_ok { DBIO::Extension->check_interface($plain) } '... core accepts it';
  is_deeply [ $plain->family_class('spatial') ], [], 'the family ships no class for any name';
  is_deeply $plain->activation({ self => { name => 'httpfs' } }), { load => 'httpfs' },
    'it asks for its own name to be loaded';
  is $plain->storage_layer, undef, 'no storage layer';
}

my $n = 0;
sub schema_class {
  my (@declaration) = @_;
  my $pkg = 'T80::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Test::Schema); 1" or die $@;
  $pkg->load_components('DuckDB');
  $pkg->duckdb_extensions(@declaration) if @declaration;
  return $pkg;
}

sub list_of {
  my $schema = schema_class(@_);
  return DBIO::DuckDB::Deploy->new(schema => $schema)->_resolve_extension_list;
}

# --- 2. the declaration -------------------------------------------------------
{
  my $schema = schema_class(
    'a', b => { class => 'DBIO::DuckDB::Extension' }, 'c',
  );
  is_deeply [ $schema->duckdb_extensions ], [qw( a b c )], 'list context: the names, in order';
  is_deeply $schema->duckdb_extension_classes, { b => 'DBIO::DuckDB::Extension' },
    'only the extension that named a class is in the classes';

  my $copy = $schema->duckdb_extension_classes;
  $copy->{zzz} = 'X';
  is_deeply [ sort keys %{ $schema->duckdb_extension_classes } ], ['b'],
    'duckdb_extension_classes hands out a copy';

  $schema->duckdb_extensions('x');
  is_deeply [ $schema->duckdb_extensions ], ['x'], 'declaring again replaces the list';
  is_deeply $schema->duckdb_extension_classes, {}, '... and the classes with it';
}

{
  my $s = schema_class();
  throws_ok { $s->duckdb_extensions(a => { schema => 'x' }) } qr/extension 'a' has no option 'schema'; the only option is 'class'/,
    'an unknown option is refused (and schema is PostgreSQL\'s)';
  throws_ok { $s->duckdb_extensions(a => {}) } qr/empty options hashref/, 'an empty hashref is refused';
  throws_ok { $s->duckdb_extensions(a => { class => 'X::Y' }, { class => 'X::Y' }) }
    qr/an extension name is expected, got a HASH reference/, 'a second hashref is refused';
  throws_ok { $s->duckdb_extensions({ class => 'X::Y' }) }
    qr/an extension name is expected, got a HASH reference/, 'a hashref without a name is refused';
  throws_ok { $s->duckdb_extensions(undef) } qr/an extension name is expected, got undef/, 'undef is no name';
  throws_ok { $s->duckdb_extensions('') } qr/an extension name is expected, got ''/, 'neither is the empty string';
  throws_ok { $s->duckdb_extensions(a => { class => 'not a class' }) } qr/needs a 'class', a class name/,
    'an unusable class name is refused';
  throws_ok { $s->duckdb_extensions(a => { class => undef }) } qr/needs a 'class', a class name/,
    'so is an undefined one';
  is_deeply [ $s->duckdb_extensions ], [], 'a refused declaration leaves the schema without a list';
}

# --- 3. resolution ------------------------------------------------------------
{
  my $list = list_of('httpfs', 'whatever');
  isa_ok $list, 'DBIO::Extension::List';
  is_deeply [ $list->names ], [qw( httpfs whatever )], 'one entry per declared name';
  is $_->{class}, 'DBIO::DuckDB::Extension', "$_->{name}: an unknown name gets the plain class"
    for $list->entries;
}

{
  package T80::Own;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub driver { 'DBIO::DuckDB' }
  sub activation { { load => 'own' } }
}

{
  my $list = list_of(httpfs => { class => 'T80::Own' }, 'json');
  my %class = map { $_->{name} => $_->{class} } $list->entries;
  is $class{httpfs}, 'T80::Own', 'the option class wins over the plain class';
  is $class{json}, 'DBIO::DuckDB::Extension', '... for its own name only';
}

# --- 4. refusals --------------------------------------------------------------
{
  package T80::OldInterface;
  use base 'DBIO::Extension';
  sub extension_interface { 99 }
  sub driver { 'DBIO::DuckDB' }

  package T80::OtherDriver;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub driver { 'DBIO::PostgreSQL' }
}

throws_ok { list_of(x => { class => 'T80::OldInterface' }) } qr/interface/i,
  'a class of an interface core does not accept is refused';
throws_ok { list_of(x => { class => 'T80::OtherDriver' }) }
  qr/Extension 'x' \(T80::OtherDriver\) belongs to the driver DBIO::PostgreSQL, but the schema's driver is DBIO::DuckDB/,
  'a class of another driver is refused when the list is resolved';
lives_ok { DBIO::DuckDB::Extension->resolve_list(schema_class(x => { class => 'T80::OtherDriver' }), check_driver => 0) }
  'the assertion can wait for the first use (check_driver => 0)';
throws_ok { list_of(x => { class => 'T80::NoSuchClassAnywhere' }) } qr/T80::NoSuchClassAnywhere/,
  'a class that does not load is refused';

# --- 5. no declaration, no list; an extension never picks the driver ----------
{
  is list_of(), undef, 'a schema that declares none has no list';
  is_deeply(DBIO::DuckDB::Deploy->new(schema => schema_class())->_extension_list, [],
    '... and an empty extension list for the deploy');
  is(DBIO::DuckDB::Extension->resolve_list('DBIO::Test::Schema'), undef,
    'a schema without the component declares none');
}

{
  package T80::Layer;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub driver { 'DBIO::DuckDB' }
  sub storage_layer { 'T80::LayerStorage' }

  package T80::LayerStorage;
  use base 'DBIO::Storage::DBI';
}

{
  my $schema = schema_class(layered => { class => 'T80::Layer' });
  my $connected = $schema->connect('dbi:DuckDB:dbname=:memory:');
  $connected->storage->dbh;   # driver resolution is lazy: first dbh
  isa_ok $connected->storage, 'DBIO::DuckDB::Storage', 'the storage stays the DuckDB one';
  isa_ok $connected->storage, 'T80::LayerStorage', '... with the layer of the declared extension composed in';
}

done_testing;
