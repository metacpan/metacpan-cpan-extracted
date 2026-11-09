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

# --- Table options ---
#
# WITHOUT ROWID and STRICT stand behind the closing parenthesis of the column
# list, in either order and in any letter case. They are read there and
# nowhere else: the same words in a column's name, in a string or in a view do
# not make a table one. DBIO::SQLite::Diff rebuilds a table for an option the
# target has and the database has not, so both fields have to be right.
{
  my $opt = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 });
  my @cases = (
    [ plain   => ''                                 => 0, 0 ],
    [ wr      => 'WITHOUT ROWID'                    => 1, 0 ],
    [ st      => 'STRICT'                           => 0, 1 ],
    [ wr_st   => 'WITHOUT ROWID, STRICT'            => 1, 1 ],
    [ st_wr   => 'STRICT, WITHOUT ROWID'            => 1, 1 ],
    [ lower   => "strict ,\n  without   rowid"      => 1, 1 ],
    [ comment => 'WITHOUT /* not strict */ ROWID'   => 1, 0 ],
  );
  $opt->do("CREATE TABLE $_->[0] (k TEXT PRIMARY KEY, v TEXT) $_->[1]") for @cases;

  # The words where they are no option.
  $opt->do(q{CREATE TABLE decoy_column ("strict" TEXT, strict_too TEXT, rowid_note TEXT)});
  $opt->do(q{CREATE TABLE decoy_string (k TEXT PRIMARY KEY,
    v TEXT DEFAULT 'WITHOUT ROWID', w TEXT DEFAULT ') STRICT')});
  $opt->do(q{CREATE TABLE "without rowid" (k TEXT PRIMARY KEY, "strict" TEXT)});
  $opt->do(q{CREATE VIEW decoy_view AS SELECT 'WITHOUT ROWID' AS x, ') STRICT' AS y});

  my $tables = DBIO::SQLite::Introspect->new(dbh => $opt)->model->{tables};
  for my $case (@cases) {
    my ($name, $options, $without_rowid, $strict) = @$case;
    (my $shown = $options || 'no option') =~ s/\s+/ /g;
    is_deeply(
      [ @{ $tables->{$name} }{qw(without_rowid strict)} ],
      [ $without_rowid, $strict ],
      "table options <$shown>: without_rowid $without_rowid, strict $strict",
    );
  }
  for my $name ('decoy_column', 'decoy_string', 'without rowid', 'decoy_view') {
    is_deeply([ @{ $tables->{$name} }{qw(without_rowid strict)} ], [ 0, 0 ],
      "<$name> has the words but neither option");
  }
}

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

# --- Triggers ---
#
# Carried in the model with the statement they were created by, under the
# table or view they are on (karr k69). The table is named as the model names
# it: sqlite_master lists a trigger under the spelling of its own statement,
# here "item" for the table "Item".
is_deeply($model->{triggers}, {},
  'a database without triggers has an empty triggers section');

{
  my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 });
  $dbh->do('CREATE TABLE Item (id INTEGER PRIMARY KEY, name TEXT)');
  $dbh->do('CREATE TABLE log (msg TEXT)');
  $dbh->do('CREATE VIEW item_names AS SELECT id, name FROM Item');

  my %sql = (
    item_ai => q{CREATE TRIGGER item_ai AFTER INSERT ON item BEGIN
      INSERT INTO log VALUES ('new ' || NEW.name);
      INSERT INTO log VALUES ('; in a string');
    END},
    item_ad => q{CREATE TRIGGER item_ad AFTER DELETE ON Item BEGIN
      INSERT INTO log VALUES ('gone ' || OLD.name);
    END},
    names_ii => q{CREATE TRIGGER names_ii INSTEAD OF INSERT ON item_names BEGIN
      INSERT INTO Item (name) VALUES (NEW.name);
    END},
  );
  $dbh->do($sql{$_}) for sort keys %sql;

  my $entry = sub {
    my ($name, $table) = @_;
    return { trigger_name => $name, table_name => $table, sql => $sql{$name} };
  };

  is_deeply(
    DBIO::SQLite::Introspect->new(dbh => $dbh)->model->{triggers},
    {
      Item => {
        item_ai => $entry->(item_ai => 'Item'),
        item_ad => $entry->(item_ad => 'Item'),
      },
      item_names => { names_ii => $entry->(names_ii => 'item_names') },
    },
    'triggers of tables and of views, by owner and name, each with its statement',
  );
}

done_testing;
