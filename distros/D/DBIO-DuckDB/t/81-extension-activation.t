#!/usr/bin/env perl
# t/81-extension-activation.t — a declared extension is INSTALLed and LOADed
# on every new connection (ADR 0066, activation; karr k46).
#
# WHY: a type or function an extension brings has to be there on the
# connection the application works on, with nothing written beyond the
# declaration. DuckDB loads an extension per database instance, so this is per
# connection, and a declaration that cannot be met (an extension DuckDB does not
# have) must fail the connect loudly rather than leave the application on a
# database that lacks what it declared.
#
# What this file claims:
#   1. without a declaration nothing is loaded that was not;
#   2. with one, the extension is loaded after connect (httpfs is installed on
#      the box but not loaded by default), and no other one is;
#   3. a second connection of the same schema gets it too, and activating an
#      installed, loaded extension again is harmless;
#   4. an extension DuckDB does not have makes the connect fail, naming it;
#   5. the activation is data the classes give: a class with an activation of
#      its own is followed, a name that is no identifier is refused.
#
# Runs against :memory:; httpfs must be installed under ~/.duckdb/extensions
# (no network is used for it).

use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::DuckDB::Extension;

my $n = 0;
sub schema_class {
  my (@declaration) = @_;
  my $pkg = 'T81::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Test::Schema); 1" or die $@;
  $pkg->load_components('DuckDB');
  $pkg->duckdb_extensions(@declaration) if @declaration;
  return $pkg;
}

sub loaded {
  my ($schema) = @_;
  my $rows = $schema->storage->dbh->selectall_arrayref(
    'SELECT extension_name FROM duckdb_extensions() WHERE loaded');
  return { map { $_->[0] => 1 } @$rows };
}

my $dsn = 'dbi:DuckDB:dbname=:memory:';

# The premise is httpfs installed under ~/.duckdb/extensions; a machine without
# it has nothing to show here (no network is used to get it).
{
  require DBI;
  my $probe = DBI->connect($dsn, '', '', { RaiseError => 1, PrintError => 0 });
  my ($installed) = $probe->selectrow_array(
    q{SELECT installed FROM duckdb_extensions() WHERE extension_name = 'httpfs'});
  $probe->disconnect;
  plan skip_all => 'httpfs is not installed under ~/.duckdb/extensions' unless $installed;
}

# --- 1. no declaration ----------------------------------------------------------
my $baseline = loaded(schema_class()->connect($dsn));
ok !$baseline->{httpfs}, 'httpfs is not loaded on a fresh connection (the premise of this file)';

# --- 2. a declaration -----------------------------------------------------------
{
  my $schema = schema_class('httpfs')->connect($dsn);
  my $loaded = loaded($schema);
  ok $loaded->{httpfs}, 'a declared extension is loaded after connect';
  is_deeply [ sort grep { !$baseline->{$_} } keys %$loaded ], ['httpfs'],
    '... and nothing else is';
}

# --- 3. every connection, again and again -----------------------------------------
{
  my $class = schema_class('httpfs');
  ok loaded($class->connect($dsn))->{httpfs}, 'a second connection gets it as well';

  my $schema = $class->connect($dsn);
  my $storage = $schema->storage;
  $storage->dbh;
  lives_ok { $storage->_activate_extensions($storage->_extension_activation(undef)) }
    'activating an extension that is installed and loaded is harmless';
  ok loaded($schema)->{httpfs}, '... and it stays loaded';
}

# --- 4. an extension DuckDB does not have -----------------------------------------
{
  my $schema = schema_class('dbio_no_such_extension')->connect($dsn);
  throws_ok { $schema->storage->dbh } qr/dbio_no_such_extension/,
    'an extension DuckDB does not have fails the connect, naming it';
}

# --- 5. the classes' activation is followed ---------------------------------------
{
  package T81::Alias;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub driver { 'DBIO::DuckDB' }
  sub activation { { load => 'httpfs' } }
}
{
  my $schema = schema_class(alias => { class => 'T81::Alias' })->connect($dsn);
  ok loaded($schema)->{httpfs}, 'a class with an activation of its own decides what is loaded, not the name';
  ok !loaded($schema)->{alias}, '... the declared name is not loaded as such';
}

{
  my $storage = schema_class('httpfs')->connect($dsn)->storage;
  throws_ok { $storage->_activate_extensions({ load => ['x; DROP TABLE t'], search_path => [] }) }
    qr/invalid extension name/, 'a name that is no identifier is refused before any statement';
  throws_ok { $storage->_activate_extensions({ load => [], search_path => ['s'] }) }
    qr/no search_path/, 'DuckDB has no search_path to give an extension';
}

done_testing;
