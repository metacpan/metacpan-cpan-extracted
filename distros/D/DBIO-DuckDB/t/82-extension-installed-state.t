#!/usr/bin/env perl
# t/82-extension-installed-state.t — the deploy reads the installed state of the
# declared extensions from duckdb_extensions(), and the diff's target database
# has them active (ADR 0066; karr k46).
#
# WHY: the protocol asks the driver for the list with the installed state
# attached, and a declared extension DuckDB does not have must read as not
# installed, not as an error and not as installed. The diff compares the live
# database with a model built in a throwaway in-memory database; if that
# database lacked the extension, a column of a type the extension brings could
# not be created there and the diff would fail on a schema that deploys fine.
# An upgrade also never drops an extension: DuckDB has no such statement for
# an INSTALLed extension, and the list only holds what is declared.
#
# What this file claims:
#   1. an installed extension reads as installed, with the engine's version;
#   2. a name DuckDB does not have reads as not installed, no version;
#   3. only declared names are in the list;
#   4. the diff builds its target in a database where the declared extension is
#      loaded, and not one that is undeclared;
#   5. the diff and the apply run through with an extension declared and the
#      next diff is empty.

use strict;
use warnings;
use Test::More;

use DBIO::DuckDB::Test;
use DBIO::DuckDB::Deploy;

my $n = 0;
sub schema_class {
  my (@declaration) = @_;
  my $pkg = 'T82::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Test::Schema); 1" or die $@;
  $pkg->load_components('DuckDB');
  $pkg->duckdb_extensions(@declaration) if @declaration;
  # the core fixture declares foreign key actions DuckDB refuses (karr k49)
  DBIO::DuckDB::Test->_without_unsupported_fk_actions($pkg);
  return $pkg;
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

# --- 1.-3. the installed state ------------------------------------------------
{
  my $schema = schema_class('httpfs', 'json');
  my $deploy = DBIO::DuckDB::Deploy->new(schema => $schema->connect($dsn));
  my %entry  = map { $_->{name} => $_ } @{ $deploy->_extension_list };

  is_deeply [ sort keys %entry ], [qw( httpfs json )], 'the list holds the declared names, no other';
  ok $entry{httpfs}{installed}, 'httpfs: installed (it is, on this box, though not loaded)';
  like $entry{httpfs}{version}, qr/\S/, '... with a version';
  ok $entry{json}{installed}, 'json: installed';
  like $entry{json}{version}, qr/^v?\d/, '... with the engine\'s version';
  is $entry{httpfs}{class}, 'DBIO::DuckDB::Extension', 'the entries carry their class';
}

{
  # declared after the connect: a connection that declared it would not open
  my $class     = schema_class();
  my $connected = $class->connect($dsn);
  $connected->storage->dbh;
  $class->duckdb_extensions('dbio_no_such_extension');
  my $deploy = DBIO::DuckDB::Deploy->new(schema => $connected);
  my ($entry) = @{ $deploy->_extension_list };
  ok defined $entry->{installed} && !$entry->{installed}, 'a name DuckDB does not have reads as not installed';
  ok !defined $entry->{version}, '... without a version';
}

# --- 4. the target database has the declared extension loaded ----------------------
{
  package T82::Deploy;
  use base 'DBIO::DuckDB::Deploy';

  our @seen;
  sub _execute_ddl {
    my ($self, $dbh, @rest) = @_;
    # the target is the handle that is not the storage's own
    if ($dbh != $self->_dbh) {
      my $rows = $dbh->selectall_arrayref('SELECT extension_name FROM duckdb_extensions() WHERE loaded');
      push @seen, { map { $_->[0] => 1 } @$rows };
    }
    return $self->SUPER::_execute_ddl($dbh, @rest);
  }
}

{
  # an empty live database, so that the target is built
  my $schema = schema_class('httpfs')->connect($dsn);
  @T82::Deploy::seen = ();
  my $diff = T82::Deploy->new(schema => $schema)->diff;
  ok scalar(@T82::Deploy::seen), 'the diff built a target database';
  ok $T82::Deploy::seen[0]{httpfs}, 'the declared extension is loaded in it before the DDL runs';

  my $plain = schema_class()->connect($dsn);
  @T82::Deploy::seen = ();
  T82::Deploy->new(schema => $plain)->diff;
  ok !$T82::Deploy::seen[0]{httpfs}, 'an undeclared one is not';
}

# --- 5. diff, apply, diff again -------------------------------------------------------
{
  my $schema = schema_class('httpfs')->connect($dsn);
  my $deploy = DBIO::DuckDB::Deploy->new(schema => $schema);

  my $diff = $deploy->diff;
  ok $diff->has_changes, 'an empty database has changes against the schema';
  like $diff->as_sql, qr/CREATE TABLE "?artist"?/, '... the tables';
  unlike $diff->as_sql, qr/EXTENSION/i, '... and no statement about the extension: it is activated, not diffed';

  $deploy->apply($diff);
  my $again = $deploy->diff;
  ok !$again->has_changes, 'the next diff is empty'
    or diag $again->as_sql;
  ok scalar(grep { $_->{name} eq 'httpfs' } @{ $deploy->_extension_list }), 'the list is still read after the apply';
}

done_testing;
