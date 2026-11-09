#!/usr/bin/env perl
# t/66-diff-rebuild.t -- table rebuild for what DuckDB cannot ALTER (karr k50,
# docs/adr/0010; the pattern of dbio-sqlite ADR 0003).
#
# DuckDB cannot drop a column while an index or UNIQUE stands on it or on a
# later column, cannot drop a UNIQUE constraint, and has no ALTER TABLE for a
# foreign key. The diff then rebuilds the table: a new one under a temporary
# name, the rows of the common columns copied, the old one dropped, the new one
# renamed, the indexes created again -- all in the one transaction of the
# apply. A foreign key of ANOTHER table to the rebuilt one stops DuckDB's DROP
# ("main key table of the table ..."; measured libduckdb 1.5.3), a self
# reference loses its target in the rename: both are refused before the first
# statement, naming the tables.
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  eval { require DBD::DuckDB; 1 } or plan skip_all => 'DBD::DuckDB required';
}

use DBIO::DuckDB::Deploy;
use DBIO::DuckDB::Introspect;

my $n = 0;
# sources: { Name => { table, columns => [..], pk => [..], unique => [[name => [cols]]],
#                      indexes => { name => [cols] }, rels => [ [name, Target, { foreign.x => self.y }] ] } }
sub schema_for {
  my (%src) = @_;
  my $ns = 'RbTest' . ++$n;
  my $schema = "$ns\::Schema";
  eval "package $schema; use base 'DBIO::Schema'; 1" or die $@;
  $schema->load_components('DuckDB');
  for my $name (sort keys %src) {
    my $s = $src{$name};
    my $class = "$ns\::Result::$name";
    eval "package $class; use base 'DBIO::Core'; 1" or die $@;
    $class->table($s->{table});
    my %pk = map { $_ => 1 } @{ $s->{pk} };
    $class->add_columns(map { $_ => { data_type => 'integer', is_nullable => $pk{$_} ? 0 : 1 } } @{ $s->{columns} });
    $class->set_primary_key(@{ $s->{pk} });
    $class->add_unique_constraint(@$_) for @{ $s->{unique} || [] };
    $class->mk_classdata(duckdb_indexes => { map { $_ => { columns => $s->{indexes}{$_} } } keys %{ $s->{indexes} } })
      if $s->{indexes};
    for my $r (@{ $s->{rels} || [] }) {
      my ($rel, $target, $cond) = @$r;
      $class->belongs_to($rel => "$ns\::Result::$target", $cond);
    }
    $schema->register_class($name => $class);
  }
  return $schema->connect('dbi:DuckDB:dbname=:memory:', '', '', {
    AutoCommit => 1, RaiseError => 1, PrintError => 0,
  });
}
sub deploy_of { DBIO::DuckDB::Deploy->new(schema => $_[0]) }
sub model_of  { DBIO::DuckDB::Introspect->new(dbh => $_[0])->model }
sub colnames  { join ',', map { $_->{column_name} } @{ model_of($_[0])->{columns}{$_[1]} || [] } }
sub tables    { join ',', sort keys %{ model_of($_[0])->{tables} } }

# --- DROP COLUMN under a later index and UNIQUE: rebuilt, rows and the rest kept
{
  my $schema = schema_for(W => { table => 'wide', columns => [qw(id c)], pk => ['id'],
                                 indexes => { wide_c_idx => ['c'] } });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE wide (id INTEGER PRIMARY KEY, a INTEGER, b INTEGER, c INTEGER, UNIQUE (b, c))');
  $dbh->do('CREATE INDEX wide_a_idx ON wide (a)');
  $dbh->do('INSERT INTO wide VALUES (1, 1, 2, 3), (2, 4, 5, 6)');
  my $deploy = deploy_of($schema);
  my $diff   = $deploy->diff;
  like $diff->as_sql, qr/CREATE TABLE "wide__dbio_rebuild".*INSERT INTO "wide__dbio_rebuild".*DROP TABLE "wide";.*RENAME TO "wide"/s,
    'the drop becomes a rebuild: create, copy, drop, rename';
  like $diff->summary, qr/rebuild.*wide/i, 'the summary says so';
  lives_ok { $deploy->apply($diff, allow_destructive => 1) } 'and it is applied (columns a and b go, so it needs the release)';
  is colnames($dbh, 'wide'), 'id,c', 'the column is gone';
  is_deeply $dbh->selectall_arrayref('SELECT id, c FROM wide ORDER BY id'), [ [1, 3], [2, 6] ], 'the rows are kept';
  my $m = model_of($dbh);
  is_deeply [ sort keys %{ $m->{indexes}{wide} || {} } ], ['wide_c_idx'], 'the target index is there, the old one is not';
  is_deeply $m->{unique_constraints}{wide}, undef, 'the UNIQUE (b, c) is gone with its column';
  is tables($dbh), 'wide', 'no table under the temporary name is left';
  ok !deploy_of($schema)->diff->has_changes, 'the diff afterwards is empty';
}

# --- a column dropped with nothing on it stays a plain ALTER -----------------
{
  my $schema = schema_for(W => { table => 'wide', columns => [qw(id a)], pk => ['id'] });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE wide (id INTEGER PRIMARY KEY, a INTEGER, b INTEGER)');
  my $sql = deploy_of($schema)->diff->as_sql;
  like $sql, qr/ALTER TABLE "wide" DROP COLUMN "b"/, 'a free column is dropped by ALTER';
  unlike $sql, qr/__dbio_rebuild/, '... no rebuild';
}

# --- UNIQUE constraint dropped -----------------------------------------------
{
  my $schema = schema_for(T => { table => 't', columns => [qw(id code)], pk => ['id'] });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, code INTEGER, UNIQUE (code))');
  $dbh->do('INSERT INTO t VALUES (1, 5)');
  lives_ok { deploy_of($schema)->upgrade } 'a UNIQUE constraint that is no longer declared is dropped';
  lives_ok { $dbh->do('INSERT INTO t VALUES (2, 5)') } 'the duplicate is accepted now';
  is_deeply $dbh->selectall_arrayref('SELECT id FROM t ORDER BY id'), [ [1], [2] ], 'rows kept';
  ok !deploy_of($schema)->diff->has_changes, 'the diff afterwards is empty';
}

# --- foreign key dropped from a table that exists ----------------------------
{
  my %parent = (table => 'parent', columns => [qw(id)], pk => ['id']);
  my $schema = schema_for(
    Parent => \%parent,
    Child  => { table => 'child', columns => [qw(id pid)], pk => ['id'] },
  );
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE parent (id INTEGER PRIMARY KEY)');
  $dbh->do('CREATE TABLE child (id INTEGER PRIMARY KEY, pid INTEGER, FOREIGN KEY (pid) REFERENCES parent(id))');
  $dbh->do('INSERT INTO parent VALUES (1)');
  $dbh->do('INSERT INTO child VALUES (1, 1)');
  lives_ok { deploy_of($schema)->upgrade } 'a foreign key that is no longer declared is dropped';
  is scalar(@{ model_of($dbh)->{foreign_keys}{child} || [] }), 0, 'the key is gone';
  lives_ok { $dbh->do('INSERT INTO child VALUES (2, 999)') } 'an orphan is accepted';
  is_deeply $dbh->selectall_arrayref('SELECT id, pid FROM child WHERE id = 1'), [ [1, 1] ], 'rows kept';
  ok !deploy_of($schema)->diff->has_changes, 'the diff afterwards is empty';
}

# --- foreign key added to a table that exists --------------------------------
{
  my @src = (
    Parent => { table => 'parent', columns => [qw(id)], pk => ['id'] },
    Child  => { table => 'child', columns => [qw(id pid)], pk => ['id'],
                rels => [ [ parent => 'Parent', { 'foreign.id' => 'self.pid' } ] ] },
  );
  my $schema = schema_for(@src);
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE parent (id INTEGER PRIMARY KEY)');
  $dbh->do('CREATE TABLE child (id INTEGER PRIMARY KEY, pid INTEGER)');
  $dbh->do('INSERT INTO parent VALUES (1)');
  $dbh->do('INSERT INTO child VALUES (1, 1), (2, 999)');

  # orphans: the copy fails, the transaction takes everything back
  throws_ok { deploy_of($schema)->upgrade } qr/foreign key|constraint/i,
    'a key over orphan rows fails the copy';
  is tables($dbh), 'child,parent', 'the failed rebuild left no table behind';
  is_deeply $dbh->selectall_arrayref('SELECT id, pid FROM child ORDER BY id'), [ [1, 1], [2, 999] ],
    '... and the table has its rows';
  is colnames($dbh, 'child'), 'id,pid', '... and its columns';

  $dbh->do('DELETE FROM child WHERE id = 2');
  lives_ok { deploy_of($schema)->upgrade } 'without the orphan it is added';
  is scalar(@{ model_of($dbh)->{foreign_keys}{child} || [] }), 1, 'the key is there';
  throws_ok { $dbh->do('INSERT INTO child VALUES (3, 999)') } qr/foreign key/i, 'and enforced';
  ok !deploy_of($schema)->diff->has_changes, 'the diff afterwards is empty';
}

# --- foreign key to a column that gets a UNIQUE: the parent is rebuilt first ---
{
  my $schema = schema_for(
    Parent => { table => 'parent', columns => [qw(id code)], pk => ['id'], unique => [ [ parent_code => ['code'] ] ] },
    Child  => { table => 'child', columns => [qw(id pcode)], pk => ['id'],
                rels => [ [ parent => 'Parent', { 'foreign.code' => 'self.pcode' } ] ] },
  );
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE parent (id INTEGER PRIMARY KEY, code INTEGER)');
  $dbh->do('CREATE TABLE child (id INTEGER PRIMARY KEY, pcode INTEGER)');
  $dbh->do('INSERT INTO parent VALUES (1, 10)');
  $dbh->do('INSERT INTO child VALUES (1, 10)');
  my $diff = deploy_of($schema)->diff;
  like $diff->as_sql, qr/__dbio_rebuild.*parent.*__dbio_rebuild.*child|parent__dbio_rebuild.*child__dbio_rebuild/s,
    'parent first: DuckDB takes a key only to a UNIQUE constraint, not to a unique index';
  lives_ok { deploy_of($schema)->upgrade } 'applied';
  throws_ok { $dbh->do('INSERT INTO child VALUES (2, 99)') } qr/foreign key/i, 'the key is enforced';
  ok !deploy_of($schema)->diff->has_changes, 'the diff afterwards is empty';
}

# --- a NEW table with a key to the new UNIQUE of a rebuilt parent ---------------
{
  my $schema = schema_for(
    Parent => { table => 'parent', columns => [qw(id code)], pk => ['id'], unique => [ [ parent_code => ['code'] ] ] },
    Kid    => { table => 'kid', columns => [qw(id pcode)], pk => ['id'],
                rels => [ [ parent => 'Parent', { 'foreign.code' => 'self.pcode' } ] ] },
  );
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE parent (id INTEGER PRIMARY KEY, code INTEGER)');
  $dbh->do('INSERT INTO parent VALUES (1, 10)');
  my $diff = deploy_of($schema)->diff;
  like $diff->as_sql, qr/parent__dbio_rebuild.*CREATE TABLE "kid"/s,
    'the rebuild of the parent comes before the creation of the new table that points to it';
  lives_ok { deploy_of($schema)->upgrade } 'applied';
  throws_ok { $dbh->do('INSERT INTO kid VALUES (1, 99)') } qr/foreign key/i, 'the key is enforced';
  ok !deploy_of($schema)->diff->has_changes, 'the diff afterwards is empty';
}

# --- a rebuilt child with a key to a NEW parent: the create comes first ---------
{
  my $schema = schema_for(
    Parent => { table => 'parent', columns => [qw(id)], pk => ['id'] },
    Child  => { table => 'child', columns => [qw(id pid)], pk => ['id'],
                rels => [ [ parent => 'Parent', { 'foreign.id' => 'self.pid' } ] ] },
  );
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE child (id INTEGER PRIMARY KEY, pid INTEGER)');
  $dbh->do('INSERT INTO child VALUES (1, NULL)');
  my $diff = deploy_of($schema)->diff;
  like $diff->as_sql, qr/CREATE TABLE "parent".*child__dbio_rebuild/s,
    'the creation of the new parent comes before the rebuild of the child';
  lives_ok { deploy_of($schema)->upgrade } 'applied';
  throws_ok { $dbh->do('INSERT INTO child VALUES (2, 99)') } qr/foreign key/i, 'the key is enforced';
  ok !deploy_of($schema)->diff->has_changes, 'the diff afterwards is empty';
}

# --- a foreign key of another table to the rebuilt one: refused ---------------
{
  my $schema = schema_for(
    Parent => { table => 'parent', columns => [qw(id b)], pk => ['id'] },
    Child  => { table => 'child', columns => [qw(id pid)], pk => ['id'],
                rels => [ [ parent => 'Parent', { 'foreign.id' => 'self.pid' } ] ] },
  );
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE parent (id INTEGER PRIMARY KEY, a INTEGER, b INTEGER, UNIQUE (b))');
  $dbh->do('CREATE TABLE child (id INTEGER PRIMARY KEY, pid INTEGER, FOREIGN KEY (pid) REFERENCES parent(id))');
  throws_ok { deploy_of($schema)->diff }
    qr/refus.*(?:child.*parent|parent.*child).*(?:foreign key|rebuil)|(?:foreign key|rebuil).*(?:child.*parent|parent.*child)/is,
    'rebuilding a table another one points to is refused, naming both tables';
  is colnames($dbh, 'parent'), 'id,a,b', '... and nothing was changed';
}

# --- a table that points to itself: refused ----------------------------------
{
  my $schema = schema_for(
    Node => { table => 'node', columns => [qw(id par)], pk => ['id'],
              rels => [ [ parent => 'Node', { 'foreign.id' => 'self.par' } ] ] },
  );
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE node (id INTEGER PRIMARY KEY, x INTEGER, par INTEGER, UNIQUE (par), FOREIGN KEY (par) REFERENCES node(id))');
  throws_ok { deploy_of($schema)->diff } qr/refus.*node.*(?:itself|self)/is,
    'a table that points to itself is not rebuilt, the message names it';
}

# --- a rebuild that would leave a NOT NULL without value: refused first --------
{
  my $schema = schema_for(T => { table => 't', columns => [qw(id code)], pk => ['id'] });
  $schema->source('T')->add_columns(extra => { data_type => 'integer', is_nullable => 0 });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, code INTEGER, UNIQUE (code))');
  $dbh->do('INSERT INTO t VALUES (1, 5)');
  throws_ok { deploy_of($schema)->upgrade } qr/NOT NULL.*t\.extra|t\.extra.*NOT NULL/s,
    'a new NOT NULL column without default over rows is refused in a rebuild too';
  is colnames($dbh, 't'), 'id,code', '... before the first statement';
}

# --- a table of another schema ------------------------------------------------
{
  my $schema = schema_for(T => { table => 'other.t', columns => [qw(id c)], pk => ['id'] });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE SCHEMA other');
  $dbh->do('CREATE TABLE other.t (id INTEGER PRIMARY KEY, a INTEGER, c INTEGER, UNIQUE (c))');
  $dbh->do('INSERT INTO other.t VALUES (1, 1, 3)');
  lives_ok { deploy_of($schema)->upgrade(allow_destructive => 1) } 'a table of a schema is rebuilt in its schema (column a goes)';
  is_deeply $dbh->selectall_arrayref('SELECT id, c FROM other.t'), [ [1, 3] ], 'rows kept';
}

# --- a rebuild that loses a column needs allow_destructive (core k399) ---------
{
  my $schema = schema_for(T => { table => 't', columns => [qw(id code)], pk => ['id'] });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, code INTEGER, gone INTEGER, UNIQUE (code))');
  $dbh->do('INSERT INTO t VALUES (1, 5, 777), (2, 6, 888)');
  my $before = $dbh->selectall_arrayref('SELECT * FROM t ORDER BY id');
  my $diff = deploy_of($schema)->diff;
  like $diff->as_sql, qr/__dbio_rebuild/, 'the dropped column and the dropped UNIQUE make a rebuild';
  throws_ok { deploy_of($schema)->apply($diff) } 'DBIO::Exception',
    'without allow_destructive the rebuild is refused';
  my $err = "$@";
  like $err, qr/\bt\b.*\bt\.gone\b|\bt\.gone\b.*\bt\b/s, '... naming table and column';
  unlike $err, qr/777|888/, '... and no value';
  is_deeply $dbh->selectall_arrayref('SELECT * FROM t ORDER BY id'), $before, '... the rows are as they were';
  is colnames($dbh, 't'), 'id,code,gone', '... and so are the columns';
  lives_ok { deploy_of($schema)->apply($diff, allow_destructive => 1) } 'with allow_destructive it runs';
  is_deeply $dbh->selectall_arrayref('SELECT * FROM t ORDER BY id'), [ [1, 5], [2, 6] ], '... the rest of the rows is kept';
}

# --- a rebuild that changes a column lossily needs it too ---------------------
{
  my $schema = schema_for(T => { table => 't', columns => [qw(id code)], pk => ['id'] });
  $schema->source('T')->add_columns(code => { data_type => 'smallint', is_nullable => 1 });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, code INTEGER, UNIQUE (code))');
  $dbh->do('INSERT INTO t VALUES (1, 5)');
  throws_ok { deploy_of($schema)->upgrade } qr/\bt\.code\b/, 'a narrowing inside a rebuild is refused, naming table and column';
  is_deeply $dbh->selectall_arrayref('SELECT * FROM t'), [ [1, 5] ], '... the rows are as they were';
}

# --- a rebuild that keeps every column runs without the release --------------
{
  my $schema = schema_for(T => { table => 't', columns => [qw(id code)], pk => ['id'] });
  $schema->source('T')->add_columns(code => { data_type => 'bigint', is_nullable => 1 });
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, code INTEGER, UNIQUE (code))');
  $dbh->do('INSERT INTO t VALUES (1, 5)');
  lives_ok { deploy_of($schema)->upgrade } 'UNIQUE dropped and a widened column: a lossless rebuild needs no release';
  is_deeply $dbh->selectall_arrayref('SELECT * FROM t'), [ [1, 5] ], '... rows kept';
}

done_testing;
