use strict;
use warnings;
use Test::More;
use DBI;

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

use_ok 'DBIO::SQLite::Introspect';

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 });
$dbh->do('PRAGMA foreign_keys = ON');

$dbh->do(q{
  CREATE TABLE author (
    id   INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    bio  TEXT
  )
});
$dbh->do(q{
  CREATE TABLE book (
    id        INTEGER PRIMARY KEY,
    author_id INTEGER NOT NULL REFERENCES author(id) ON DELETE CASCADE,
    title     TEXT NOT NULL,
    rating    REAL
  )
});
$dbh->do('CREATE UNIQUE INDEX book_title_idx ON book(title)');
$dbh->do('CREATE INDEX book_partial ON book(rating) WHERE rating IS NOT NULL');

my $intro = DBIO::SQLite::Introspect->new(dbh => $dbh);
my $model = $intro->model;

# --- Tables ---
is_deeply([sort keys %{ $model->{tables} }], ['author', 'book'], 'two tables found');
is($model->{tables}{author}{kind}, 'table', 'author kind = table');
is($model->{tables}{author}{without_rowid}, 0, 'author not WITHOUT ROWID');

# --- Columns ---
my @author_cols = map { $_->{column_name} } @{ $model->{columns}{author} };
is_deeply(\@author_cols, [qw(id name bio)], 'author columns in order');

my ($name_col) = grep { $_->{column_name} eq 'name' } @{ $model->{columns}{author} };
is($name_col->{not_null}, 1, 'name is NOT NULL');
is($name_col->{is_pk},    0, 'name is not PK');

my ($id_col) = grep { $_->{column_name} eq 'id' } @{ $model->{columns}{author} };
is($id_col->{is_pk},       1, 'id is PK');
is($id_col->{pk_position}, 1, 'id pk_position 1');

# --- Foreign keys ---
ok($model->{foreign_keys}{book}, 'book has FKs');
my $book_fk = $model->{foreign_keys}{book}[0];
is($book_fk->{to_table},          'author', 'book FK targets author');
is_deeply($book_fk->{from_columns}, ['author_id'], 'FK from author_id');
is_deeply($book_fk->{to_columns},   ['id'],        'FK to id');
is($book_fk->{on_delete}, 'CASCADE', 'ON DELETE CASCADE captured');

# --- Indexes ---
ok($model->{indexes}{book}{book_title_idx}, 'unique index found');
is($model->{indexes}{book}{book_title_idx}{is_unique}, 1, 'is_unique flag');
is_deeply($model->{indexes}{book}{book_title_idx}{columns}, ['title'], 'index columns');

ok($model->{indexes}{book}{book_partial}, 'partial index found');
is($model->{indexes}{book}{book_partial}{partial}, 1, 'partial flag');

# --- WITHOUT ROWID detection ---
$dbh->do('CREATE TABLE kv (k TEXT PRIMARY KEY, v TEXT) WITHOUT ROWID');
my $model2 = DBIO::SQLite::Introspect->new(dbh => $dbh)->model;
is($model2->{tables}{kv}{without_rowid}, 1, 'WITHOUT ROWID detected');

# --- Composite FK ---
$dbh->do(q{
  CREATE TABLE parent (
    a INTEGER, b INTEGER, name TEXT,
    PRIMARY KEY (a, b)
  )
});
$dbh->do(q{
  CREATE TABLE child (
    id INTEGER PRIMARY KEY,
    pa INTEGER, pb INTEGER,
    FOREIGN KEY (pa, pb) REFERENCES parent(a, b)
  )
});
my $model3 = DBIO::SQLite::Introspect->new(dbh => $dbh)->model;
my $child_fk = $model3->{foreign_keys}{child}[0];
is_deeply($child_fk->{from_columns}, ['pa', 'pb'], 'composite FK from cols');
is_deeply($child_fk->{to_columns},   ['a',  'b'],  'composite FK to cols');

done_testing;
