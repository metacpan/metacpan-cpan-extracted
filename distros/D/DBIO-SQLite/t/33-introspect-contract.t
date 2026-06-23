use strict;
use warnings;
use Test::More;
use DBI;

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

use_ok 'DBIO::SQLite::Introspect';

# Contract methods are inherited from DBIO::Introspect::Base -- this test
# pins the model to the canonical shape documented there. If a future
# change breaks the defaults, this fails before the contract regresses
# for downstream consumers (DBIO::Generate, etc).

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
$dbh->do('CREATE VIEW doc_view AS SELECT id, name FROM author');

my $intro = DBIO::SQLite::Introspect->new(dbh => $dbh);

# table_keys
is_deeply($intro->table_keys, ['author', 'book', 'doc_view'],
  'table_keys returns sorted bare names from canonical tables section');

# table_columns
is_deeply($intro->table_columns('author'), [qw(id name bio)],
  'table_columns returns column_names in declaration order');
is_deeply($intro->table_columns('book'), [qw(id author_id title rating)],
  'table_columns for book');

# table_columns_info
my $author_info = $intro->table_columns_info('author');
is($author_info->{id}{data_type},   'INTEGER', 'id data_type');
is($author_info->{id}{is_nullable}, 0,        'id is_nullable = 0');
is($author_info->{name}{is_nullable}, 0,      'name is_nullable = 0');
is($author_info->{bio}{is_nullable},  1,      'bio is_nullable = 1');
ok(!exists $author_info->{id}{size}, 'size absent when undef (no field emitted)');

# table_pk_info
is_deeply($intro->table_pk_info('author'), ['id'],
  'table_pk_info returns ordered PK column names');
is_deeply($intro->table_pk_info('book'),   ['id'],
  'table_pk_info for book');

# table_uniq_info (no unique_constraints section in model -- derived from indexes)
my $uniq = $intro->table_uniq_info('book');
is(scalar @$uniq, 1, 'one unique constraint on book');
is($uniq->[0][0], 'book_title_idx', 'uniq name');
is_deeply($uniq->[0][1], ['title'], 'uniq columns');

# table_fk_info
my $fks = $intro->table_fk_info('book');
is(scalar @$fks, 1, 'one FK on book');
is($fks->[0]{remote_table},   'author', 'fk remote_table');
is_deeply($fks->[0]{local_columns},  ['author_id'], 'fk local_columns');
is_deeply($fks->[0]{remote_columns}, ['id'],        'fk remote_columns');
is($fks->[0]{remote_schema}, undef, 'fk remote_schema undef (single-schema)');
is($fks->[0]{attrs}{on_delete}, 'CASCADE', 'fk attrs on_delete');

# table_is_view
is($intro->table_is_view('author'),    0, 'author not a view');
is($intro->table_is_view('doc_view'),  1, 'doc_view is a view');

# Optional hooks -- defaults return undef for a driver that doesn't override
is($intro->view_definition('doc_view'),  undef, 'view_definition undef (default)');
is($intro->table_comment('author'),      undef, 'table_comment undef (default)');
is($intro->column_comment('author', 'id'), undef, 'column_comment undef (default)');

# Composite PK round-trips via table_pk_info
$dbh->do(q{
  CREATE TABLE composite (
    a INTEGER, b INTEGER, val TEXT,
    PRIMARY KEY (a, b)
  )
});
my $intro2 = DBIO::SQLite::Introspect->new(dbh => $dbh);
is_deeply($intro2->table_pk_info('composite'), ['a', 'b'],
  'composite PK keeps declared order via table_pk_info');

done_testing;
