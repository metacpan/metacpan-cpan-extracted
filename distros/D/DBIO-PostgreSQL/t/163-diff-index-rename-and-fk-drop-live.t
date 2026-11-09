use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for the review of karr k139 and k140 (two cases the first fix got
# wrong, measured by an independent reviewer).
#
# 1. A database made by an older upgrade, or by hand, has the key as a unique
#    index under another name than the constraint the schema declares
#    (parent_code_uidx, the schema: parent_code_key), and perhaps a foreign key
#    on it. The diff built a second index and then failed on DROP INDEX
#    ("depends on index") -- the transaction went back. Now the index is renamed
#    and the constraint put on it.
# 2. A constraint a foreign key points at was refused for good. The drops of the
#    keys come ahead of the drops of the indexes, so a constraint goes when
#    the target drops or redirects the key; only a key that stays is refused.
#
# After each upgrade the second diff is empty and the constraints and indexes
# read like the ones an install of the same classes makes.

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
my $serial = 0;

# A schema class with one result class per entry: { Source => [ table,
# \@columns, \@primary_key, sub { my ($result_class, $schema_class) = @_; ... } ] }.
sub schema_class {
  my ($tables) = @_;
  my $name = 'T163::S' . ++$serial;
  no strict 'refs';
  for my $source (sort keys %$tables) {
    my ($table, $columns, $pk) = @{ $tables->{$source} };
    my $result = "${name}::Result::$source";
    @{"${result}::ISA"} = ('DBIO::Core');
    $result->load_components('PostgreSQL::Result');
    $result->table($table);
    $result->add_columns(map { ($_ => { data_type => 'bigint', is_nullable => 0 }) } @$columns);
    $result->set_primary_key(@$pk);
  }
  for my $source (sort keys %$tables) {
    my $extra = $tables->{$source}[3] or next;
    $extra->("${name}::Result::$source", $name);
  }
  @{"${name}::ISA"} = ('DBIO::Schema');
  $name->load_components('PostgreSQL');
  $name->register_class($_ => "${name}::Result::$_") for keys %$tables;
  return $name;
}

# parent(id, code) with its key on code; child(id, <column>) with a belongs_to
# written as a foreign key onto the column of the parent that $to names.
sub parent { my (%o) = @_; [ 'parent', [qw( id code )], ['id'], $o{unique} ? sub { $_[0]->add_unique_constraint(parent_code_key => ['code']) } : undef ] }
sub child {
  my ($column, $foreign) = @_;
  return [ 'child', ['id', $column], ['id'], sub {
    my ($result, $schema_class) = @_;
    $result->belongs_to(parent => "${schema_class}::Result::Parent", { "foreign.$foreign" => "self.$column" });
    $result->pg_fk_constraints_from_rels(1);
  } ];
}
my $CHILD_PLAIN = sub { [ 'child', ['id', $_[0]], ['id'] ] };

sub stock {
  my ($tag, $tables, @stock) = @_;
  my $schema = schema_class($tables)->connect(PrivatePgDatabase->create($tag), @CONNECT);
  my $dbh = $schema->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do($_) for @stock;
  return ($schema, $dbh);
}

sub statements { return [ map { $_->as_sql } @{ $_[0]->operations } ] }

# Keys and indexes of the database as the server reads them back.
sub catalog {
  my ($dbh) = @_;
  return [
    @{ $dbh->selectcol_arrayref(q{
      SELECT conrelid::pg_catalog.regclass::text || ' ' || conname || ' ' || contype::text || ' ' || pg_catalog.pg_get_constraintdef(oid)
      FROM pg_catalog.pg_constraint WHERE contype IN ('p', 'u', 'f') ORDER BY 1}) },
    @{ $dbh->selectcol_arrayref(q{
      SELECT pg_catalog.pg_get_indexdef(indexrelid) FROM pg_catalog.pg_index i
      JOIN pg_catalog.pg_class c ON c.oid = i.indrelid JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' ORDER BY 1}) },
  ];
}

# The upgrade: the statements, the apply, an empty second diff, and the
# catalog of an install of the same classes.
sub upgrade {
  my ($label, $tag, $tables, $stock, $want_statements) = @_;
  my ($want, $want_dbh) = stock("${tag}w", $tables);
  $want->pg_deploy->install;
  my ($schema, $dbh) = stock($tag, $tables, @$stock);
  my $deploy = $schema->pg_deploy;
  my $diff = eval { $deploy->diff };
  ok($diff, "$label: the diff is built") or diag $@;
  if ($diff) {
    is_deeply(statements($diff), $want_statements, "$label: the statements") or diag join "\n", @{ statements($diff) };
    my $risky = () = $diff->destructive_operations;   # the cases drop or narrow: released where the diff says so
    ok(eval { $deploy->apply($diff, allow_destructive => $risky ? 1 : 0); 1 }, "$label: the upgrade runs") or diag $@;
    my $again = eval { $schema->pg_deploy->diff };
    ok($again && !$again->has_changes, "$label: the second diff is empty") or diag $again ? join "\n", @{ statements($again) } : $@;
    is_deeply(catalog($dbh), catalog($want_dbh), "$label: keys and indexes read like an install of the classes");
  }
  $_->storage->disconnect for $schema, $want;
  return $diff;
}

my $PARENT_PLAIN = 'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY, code bigint NOT NULL)';

# ---------------------------------------------------------------------------
# 1. The index under another name
# ---------------------------------------------------------------------------
{
  my $tables = { Parent => parent(unique => 1), Child => child('parent_code', 'code') };
  my $diff = upgrade('unique index under another name', 't163a', $tables, [
      $PARENT_PLAIN,
      'CREATE UNIQUE INDEX parent_code_uidx ON parent (code)',
      'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_code bigint NOT NULL)',
      'INSERT INTO parent SELECT g, g FROM generate_series(1, 5) g',
      'INSERT INTO child SELECT g, g FROM generate_series(1, 5) g',
    ], [
      'ALTER INDEX public.parent_code_uidx RENAME TO parent_code_key;',
      'ALTER TABLE public.parent ADD CONSTRAINT parent_code_key UNIQUE USING INDEX parent_code_key;',
      'ALTER TABLE public.child ADD CONSTRAINT child_parent_code_fkey FOREIGN KEY (parent_code) REFERENCES public.parent (code);',
    ]);
  like($diff->summary, qr/^  ~index: parent_code_uidx -> parent_code_key \(on public\.parent\)$/m, '... the summary says the rename')
    if $diff;

  # the foreign key is on the old index already: it stays on it
  $diff = upgrade('foreign key on the index under another name', 't163c', $tables, [
      $PARENT_PLAIN,
      'CREATE UNIQUE INDEX parent_code_uidx ON parent (code)',
      'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_code bigint NOT NULL)',
      'ALTER TABLE child ADD CONSTRAINT child_parent_code_fkey FOREIGN KEY (parent_code) REFERENCES parent (code)',
    ], [
      'ALTER INDEX public.parent_code_uidx RENAME TO parent_code_key;',
      'ALTER TABLE public.parent ADD CONSTRAINT parent_code_key UNIQUE USING INDEX parent_code_key;',
    ]);

  # a primary key
  my $pk_tables = { Parent => [ 'parent', ['id'], ['id'] ], Child => child('parent_id', 'id') };
  upgrade('primary key index under another name', 't163b', $pk_tables, [
      'CREATE TABLE parent (id bigint NOT NULL)',
      'CREATE UNIQUE INDEX parent_id_uidx ON parent (id)',
      'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL)',
      'ALTER TABLE child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent (id)',
    ], [
      'ALTER INDEX public.parent_id_uidx RENAME TO parent_pkey;',
      'ALTER TABLE public.parent ADD CONSTRAINT parent_pkey PRIMARY KEY USING INDEX parent_pkey;',
    ]);
}

# ---------------------------------------------------------------------------
# 2. A constraint a foreign key points at, and the target drops or moves the key
# ---------------------------------------------------------------------------
my @WITH_KEY = (
  'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY, code bigint NOT NULL, CONSTRAINT parent_code_key UNIQUE (code))',
);
{
  # belongs_to and its UNIQUE removed together
  upgrade('belongs_to and UNIQUE removed', 't163d', { Parent => parent(), Child => $CHILD_PLAIN->('parent_code') }, [
      @WITH_KEY,
      'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_code bigint NOT NULL)',
      'ALTER TABLE child ADD CONSTRAINT child_parent_code_fkey FOREIGN KEY (parent_code) REFERENCES parent (code)',
    ], [
      'ALTER TABLE public.child DROP CONSTRAINT child_parent_code_fkey;',
      'ALTER TABLE public.parent DROP CONSTRAINT parent_code_key;',
    ]);

  # the key moves from code to id, UNIQUE on code removed
  upgrade('key moved from code to id', 't163e', { Parent => parent(), Child => child('p', 'id') }, [
      @WITH_KEY,
      'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, p bigint NOT NULL)',
      'ALTER TABLE child ADD CONSTRAINT child_p_fkey FOREIGN KEY (p) REFERENCES parent (code)',
    ], [
      'ALTER TABLE public.child DROP CONSTRAINT child_p_fkey;',
      'ALTER TABLE public.child ADD CONSTRAINT child_p_fkey FOREIGN KEY (p) REFERENCES public.parent (id);',
      'ALTER TABLE public.parent DROP CONSTRAINT parent_code_key;',
    ]);

  # the referenced column goes with its key
  upgrade('referenced column dropped with its key', 't163f',
    { Parent => [ 'parent', ['id'], ['id'] ], Child => $CHILD_PLAIN->('p') }, [
      @WITH_KEY,
      'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, p bigint NOT NULL)',
      'ALTER TABLE child ADD CONSTRAINT child_p_fkey FOREIGN KEY (p) REFERENCES parent (code)',
    ], [
      'ALTER TABLE public.child DROP CONSTRAINT child_p_fkey;',
      'ALTER TABLE public.parent DROP CONSTRAINT parent_code_key;',
      'ALTER TABLE public.parent DROP COLUMN code;',
    ]);
}

done_testing;
