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

# LIVE test for the second review of karr k139 and k140 (cases the rename of
# t/163 did not reach, measured on PostgreSQL 18).
#
# 1. The target's constraint name is taken by another index (not unique, so the
#    rename does not apply to it): the colliding index goes first, then the
#    unique index under the old name is renamed and the constraint put on it.
#    Before, the old index was dropped at the end while the key sat on it.
# 2. The unique constraint of the database has another name than the target's:
#    ALTER TABLE ... RENAME CONSTRAINT instead of ADD and DROP (which the
#    foreign key on it forbids).
# 3. What cannot be ordered is refused ahead of the apply: a key the target
#    creates would be bound by the server to a unique index the same run drops,
#    and so would a key that is there. The message names the way out.
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
    ok(eval { $deploy->apply($diff); 1 }, "$label: the upgrade runs") or diag $@;
    my $again = eval { $schema->pg_deploy->diff };
    ok($again && !$again->has_changes, "$label: the second diff is empty") or diag $again ? join "\n", @{ statements($again) } : $@;
    is_deeply(catalog($dbh), catalog($want_dbh), "$label: keys and indexes read like an install of the classes");
  }
  $_->storage->disconnect for $schema, $want;
  return $diff;
}

my $PARENT_PLAIN = 'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY, code bigint NOT NULL)';
my $CHILD_PLAIN_TABLE = 'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_code bigint NOT NULL)';
my $FK = 'ALTER TABLE child ADD CONSTRAINT child_parent_code_fkey FOREIGN KEY (parent_code) REFERENCES parent (code)';
my $tables = { Parent => parent(unique => 1), Child => child('parent_code', 'code') };

# ---------------------------------------------------------------------------
# 1. The name of the constraint is taken by another index
# ---------------------------------------------------------------------------
{
  my @collider = ($PARENT_PLAIN, 'CREATE UNIQUE INDEX parent_code_uidx ON parent (code)',
    'CREATE INDEX parent_code_key ON parent (id, code)', $CHILD_PLAIN_TABLE);
  my @renamed = (
    'DROP INDEX public.parent_code_key;',
    'ALTER INDEX public.parent_code_uidx RENAME TO parent_code_key;',
    'ALTER TABLE public.parent ADD CONSTRAINT parent_code_key UNIQUE USING INDEX parent_code_key;',
  );
  upgrade('colliding index, key to create', 't164a', $tables, [ @collider ],
    [ @renamed, 'ALTER TABLE public.child ADD CONSTRAINT child_parent_code_fkey FOREIGN KEY (parent_code) REFERENCES public.parent (code);' ]);
  upgrade('colliding index, key on the old index', 't164b', $tables, [ @collider, $FK ], [ @renamed ]);
}

# ---------------------------------------------------------------------------
# 2. The unique constraint has another name
# ---------------------------------------------------------------------------
{
  my @old = ($PARENT_PLAIN, 'ALTER TABLE parent ADD CONSTRAINT parent_code_uniq UNIQUE (code)', $CHILD_PLAIN_TABLE);
  my $rename = 'ALTER TABLE public.parent RENAME CONSTRAINT parent_code_uniq TO parent_code_key;';
  my $diff = upgrade('unique constraint under another name, key on it', 't164c', $tables, [ @old, $FK ], [ $rename ]);
  like($diff->summary, qr/^  ~constraint: parent_code_uniq -> parent_code_key \(on public\.parent\)$/m, '... the summary says the rename')
    if $diff;
  upgrade('unique constraint under another name, key to create', 't164d', $tables, [ @old ], [
    $rename,
    'ALTER TABLE public.child ADD CONSTRAINT child_parent_code_fkey FOREIGN KEY (parent_code) REFERENCES public.parent (code);',
  ]);
  upgrade('primary key under another name', 't164e', { Parent => [ 'parent', ['id'], ['id'] ], Child => child('parent_id', 'id') }, [
    'CREATE TABLE parent (id bigint NOT NULL, CONSTRAINT parent_id_pk PRIMARY KEY (id))',
    'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL)',
    'ALTER TABLE child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent (id)',
  ], [ 'ALTER TABLE public.parent RENAME CONSTRAINT parent_id_pk TO parent_pkey;' ]);
}

# ---------------------------------------------------------------------------
# 3. A key and an index the run drops
# ---------------------------------------------------------------------------
{
  # the index differs (a storage parameter), so it is no index to rename: it is
  # dropped at the end, and the key the target creates would bind to it
  for my $case (
    [ 't164f', 'key to create', [] ],
    [ 't164g', 'key that is there', [ $FK ] ],
  ) {
    my ($tag, $label, $fk) = @$case;
    my ($schema, $dbh) = stock($tag, $tables, $PARENT_PLAIN, 'CREATE UNIQUE INDEX parent_code_uidx ON parent (code) WITH (fillfactor = 70)',
      $CHILD_PLAIN_TABLE, @$fk);
    my $diff = eval { $schema->pg_deploy->diff };
    my $error = $@;
    ok(!$diff, "$label: the diff is refused");
    like($error, qr/refusing to diff/, "$label: ... as a refusal");
    like($error, qr/parent_code_uidx/, "$label: ... that names the index");
    like($error, qr/child_parent_code_fkey/, "$label: ... and the key");
    like($error, qr/DROP (?:INDEX public\.parent_code_uidx|CONSTRAINT child_parent_code_fkey)/, "$label: ... and the way out");
    $schema->storage->disconnect;
  }
}

done_testing;
