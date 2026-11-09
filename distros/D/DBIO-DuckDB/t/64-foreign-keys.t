#!/usr/bin/env perl
# t/64-foreign-keys.t -- DuckDB enforces foreign keys (karr k49, maintainer
# decision 2026-10-25; docs/adr/0001, addendum 2026-10-25).
#
# The install DDL writes them, in the column order of the parent's key (DuckDB
# takes a foreign key only to a PRIMARY KEY or UNIQUE constraint whose columns
# are in the same order), after the parent. CASCADE, SET NULL and SET DEFAULT
# are refused before the first statement (DuckDB's parser refuses them). A
# change to a foreign key of a table that exists rebuilds the table (karr k50,
# t/66-diff-rebuild.t).
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  eval { require DBD::DuckDB; 1 } or plan skip_all => 'DBD::DuckDB required';
}

use DBIO::DuckDB::DDL;
use DBIO::DuckDB::Deploy;
use DBIO::DuckDB::Introspect;

my $n = 0;
# sources: { Name => { table, columns => {..}, pk => [..], unique => [[..]], rels => [ [name, Target, cond, attrs] ] } }
sub schema_for {
  my (%src) = @_;
  my $ns = 'FKTest' . ++$n;
  my $schema = "$ns\::Schema";
  eval "package $schema; use base 'DBIO::Schema'; 1" or die $@;
  $schema->load_components('DuckDB');
  for my $name (sort keys %src) {
    my $s = $src{$name};
    my $class = "$ns\::Result::$name";
    eval "package $class; use base 'DBIO::Core'; 1" or die $@;
    $class->table($s->{table});
    $class->add_columns(map { $_ => { data_type => 'integer', is_nullable => 0 } } @{ $s->{columns} });
    $class->set_primary_key(@{ $s->{pk} });
    $class->add_unique_constraint($_) for @{ $s->{unique} || [] };
    for my $r (@{ $s->{rels} || [] }) {
      my ($rel, $target, $cond, $attrs) = @$r;
      $class->belongs_to($rel => "$ns\::Result::$target", $cond, $attrs || {});
    }
    $schema->register_class($name => $class);
  }
  return $schema->connect('dbi:DuckDB:dbname=:memory:', '', '', {
    AutoCommit => 1, RaiseError => 1, PrintError => 0,
  });
}

# --- the key columns are written in the order of the parent's key -----------
{
  my $schema = schema_for(
    Parent => { table => 'parent', columns => [qw(a b)], pk => [qw(a b)] },
    Child  => { table => 'child',  columns => [qw(id x y)], pk => ['id'],
                rels => [ [ parent => 'Parent', { 'foreign.b' => 'self.y', 'foreign.a' => 'self.x' } ] ] },
  );
  my $ddl = DBIO::DuckDB::DDL->install_ddl($schema);
  like $ddl, qr/FOREIGN KEY \("x", "y"\) REFERENCES "parent"\("a", "b"\)/,
    'the FK follows the parent key order (a, b), not the alphabetical one of the condition';
  lives_ok { $schema->deploy } 'it deploys';
  my $dbh = $schema->storage->dbh;
  $dbh->do('INSERT INTO parent VALUES (1, 2)');
  lives_ok { $dbh->do('INSERT INTO child VALUES (1, 1, 2)') } 'a row that matches the parent goes in';
  throws_ok { $dbh->do('INSERT INTO child VALUES (2, 2, 1)') } qr/foreign key|constraint/i,
    'one that does not is refused: DuckDB enforces the key';

  # introspect keeps both column lists in order, side by side
  my $fks = DBIO::DuckDB::Introspect->new(dbh => $dbh)->model->{foreign_keys}{child};
  is scalar @$fks, 1, 'one key read back for the composite key';
  is_deeply [ $fks->[0]{from_columns}, $fks->[0]{to_columns} ], [ [qw(x y)], [qw(a b)] ],
    '... with its columns paired in order, not crossed';
}

# --- a UNIQUE constraint of the parent is a target too, in its own order ----
{
  my $schema = schema_for(
    Parent => { table => 'parent', columns => [qw(id a b)], pk => ['id'], unique => [[qw(b a)]] },
    Child  => { table => 'child',  columns => [qw(id x y)], pk => ['id'],
                rels => [ [ parent => 'Parent', { 'foreign.a' => 'self.x', 'foreign.b' => 'self.y' } ] ] },
  );
  like(DBIO::DuckDB::DDL->install_ddl($schema),
    qr/FOREIGN KEY \("y", "x"\) REFERENCES "parent"\("b", "a"\)/,
    'a UNIQUE (b, a) is referenced as (b, a)');
  lives_ok { $schema->deploy } '... and deploys';
}

# --- child before parent in the alphabet: the parent is created first -------
{
  my $schema = schema_for(
    AChild => { table => 'a_child', columns => [qw(id parent_id)], pk => ['id'],
                rels => [ [ parent => 'ZParent', { 'foreign.id' => 'self.parent_id' } ] ] },
    ZParent => { table => 'z_parent', columns => ['id'], pk => ['id'] },
  );
  my $ddl = DBIO::DuckDB::DDL->install_ddl($schema);
  cmp_ok index($ddl, 'CREATE TABLE "z_parent"'), '<', index($ddl, 'CREATE TABLE "a_child"'),
    'the parent comes first';
  lives_ok { $schema->deploy } 'and the schema deploys';
}

# --- two relationships, one key: one FK -------------------------------------
{
  my $schema = schema_for(
    Parent => { table => 'parent', columns => ['id'], pk => ['id'] },
    Child  => { table => 'child',  columns => [qw(id parent_id)], pk => ['id'],
                rels => [ [ parent     => 'Parent', { 'foreign.id' => 'self.parent_id' } ],
                          [ parent_alt => 'Parent', { 'foreign.id' => 'self.parent_id' } ] ] },
  );
  my $ddl = DBIO::DuckDB::DDL->install_ddl($schema);
  my @fk = $ddl =~ /(FOREIGN KEY)/g;
  is scalar @fk, 1, 'two relationships on one column write one key';
}

# --- actions -----------------------------------------------------------------
for my $action ('CASCADE', 'SET NULL', 'SET DEFAULT') {
  my $schema = schema_for(
    Parent => { table => 'parent', columns => ['id'], pk => ['id'] },
    Child  => { table => 'child',  columns => [qw(id parent_id)], pk => ['id'],
                rels => [ [ parent => 'Parent', { 'foreign.id' => 'self.parent_id' }, { on_delete => $action } ] ] },
  );
  throws_ok { DBIO::DuckDB::DDL->install_ddl($schema) }
    qr/child\.parent_id.*ON DELETE \Q$action\E.*(?:DuckDB|cannot)/s,
    "ON DELETE $action is refused naming table and column";
  throws_ok { $schema->deploy } qr/child\.parent_id/, '... also by deploy';
  my ($tables) = $schema->storage->dbh->selectrow_array(
    q{SELECT count(*) FROM information_schema.tables WHERE table_schema = 'main'});
  is $tables, 0, '... before the first statement';
}
{
  my $schema = schema_for(
    Parent => { table => 'parent', columns => ['id'], pk => ['id'] },
    Child  => { table => 'child',  columns => [qw(id parent_id)], pk => ['id'],
                rels => [ [ parent => 'Parent', { 'foreign.id' => 'self.parent_id' },
                            { on_delete => 'RESTRICT', on_update => 'NO ACTION' } ] ] },
  );
  lives_ok { $schema->deploy } 'RESTRICT and NO ACTION are accepted';
}

# --- a key that is not a key of the parent -----------------------------------
{
  my $schema = schema_for(
    Parent => { table => 'parent', columns => [qw(id other)], pk => ['id'] },
    Child  => { table => 'child',  columns => [qw(id parent_id)], pk => ['id'],
                rels => [ [ parent => 'Parent', { 'foreign.other' => 'self.parent_id' } ] ] },
  );
  throws_ok { DBIO::DuckDB::DDL->install_ddl($schema) } qr/child.*other.*parent.*PRIMARY KEY or UNIQUE/s,
    'columns that are neither PRIMARY KEY nor UNIQUE of the parent are refused, naming both';
}

# --- the diff -----------------------------------------------------------------
my @two = (
  Parent => { table => 'parent', columns => ['id'], pk => ['id'] },
  Child  => { table => 'child',  columns => [qw(id parent_id)], pk => ['id'],
              rels => [ [ parent => 'Parent', { 'foreign.id' => 'self.parent_id' } ] ] },
);
my @bare = (
  Parent => { table => 'parent', columns => ['id'], pk => ['id'] },
  Child  => { table => 'child',  columns => [qw(id parent_id)], pk => ['id'] },
);
sub deploy_of { DBIO::DuckDB::Deploy->new(schema => $_[0]) }

{
  # new tables with their key: parent first, key written
  my $schema = schema_for(@two);
  my $deploy = deploy_of($schema);
  my $diff   = $deploy->diff;
  my $sql    = $diff->as_sql;
  like $sql, qr/FOREIGN KEY \("parent_id"\) REFERENCES "parent"\("id"\)/, 'a new table brings its key';
  cmp_ok index($sql, 'CREATE TABLE "parent"'), '<', index($sql, 'CREATE TABLE "child"'), '... after its parent';
  lives_ok { $deploy->apply($diff) } 'and applies';
  ok !$deploy->diff->has_changes, 'diff is empty afterwards';
}
{
  # key missing on a table that exists: the table is rebuilt with it
  my $schema = schema_for(@two);
  my $dbh    = $schema->storage->dbh;
  $dbh->do('CREATE TABLE parent (id INTEGER NOT NULL PRIMARY KEY)');
  $dbh->do('CREATE TABLE child (id INTEGER NOT NULL PRIMARY KEY, parent_id INTEGER NOT NULL)');
  my $deploy = deploy_of($schema);
  like $deploy->diff->summary, qr/rebuild table: child.*FOREIGN KEY \(parent_id\).*added/is,
    'a foreign key to add to a table that exists rebuilds it';
  lives_ok { $deploy->upgrade } '... and it is applied';
  throws_ok { $dbh->do('INSERT INTO child VALUES (1, 99)') } qr/foreign key/i, '... the key is enforced';
}
{
  # key on the live table that the declaration lacks
  my $schema = schema_for(@bare);
  my $dbh    = $schema->storage->dbh;
  $dbh->do('CREATE TABLE parent (id INTEGER NOT NULL PRIMARY KEY)');
  $dbh->do('CREATE TABLE child (id INTEGER NOT NULL PRIMARY KEY, parent_id INTEGER NOT NULL, '
         . 'FOREIGN KEY (parent_id) REFERENCES parent(id))');
  my $deploy = deploy_of($schema);
  like $deploy->diff->summary, qr/rebuild table: child.*FOREIGN KEY \(parent_id\).*dropped/is,
    'a foreign key that is no longer declared rebuilds the table';
  lives_ok { $deploy->upgrade } '... and it is applied';
  lives_ok { $dbh->do('INSERT INTO child VALUES (1, 99)') } '... the key is gone';
}
{
  # a table that is to be created next to an unchanged one: still fine
  my $schema = schema_for(@two);
  my $dbh    = $schema->storage->dbh;
  $dbh->do('CREATE TABLE parent (id INTEGER NOT NULL PRIMARY KEY)');
  $dbh->do('CREATE TABLE child (id INTEGER NOT NULL PRIMARY KEY, parent_id INTEGER NOT NULL, '
         . 'FOREIGN KEY (parent_id) REFERENCES parent(id))');
  ok !deploy_of($schema)->diff->has_changes, 'the same key on both sides: nothing to do';
}

done_testing;
