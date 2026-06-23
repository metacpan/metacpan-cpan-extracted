use strict;
use warnings;
use Test::More;

# Live introspection test. Requires a real Firebird database -- the offline
# fixtures in t/50 cannot catch SQL-level mistakes (wrong rdb$ columns, hash
# key case, referenced-index resolution). Skipped unless a DSN is provided.
#
#   DBIO_TEST_FIREBIRD_DSN  e.g. dbi:Firebird:dbname=localhost/3050:/path/test.fdb
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run live introspection tests'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Firebird::Introspect;

my $dbh = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, AutoCommit => 1, PrintError => 0, ib_dialect => 3 })
  or plan skip_all => 'Cannot connect: ' . DBI->errstr;

# --- (re)build a known schema ------------------------------------------------
# Drop in dependency order; ignore "does not exist".
for my $ddl (
  'DROP VIEW v_authors',
  'DROP TABLE tag',
  'DROP TABLE book',
  'DROP TABLE author',
) { eval { $dbh->do($ddl) }; }

$dbh->do($_) for (
  q{CREATE TABLE author (
      id   INTEGER NOT NULL,
      name VARCHAR(128) NOT NULL,
      CONSTRAINT pk_author PRIMARY KEY (id),
      CONSTRAINT uq_author_name UNIQUE (name)
    )},
  q{CREATE TABLE book (
      id        INTEGER NOT NULL PRIMARY KEY,
      author_id INTEGER NOT NULL,
      price     DECIMAL(10,2),
      title     VARCHAR(256),
      CONSTRAINT fk_book_author FOREIGN KEY (author_id) REFERENCES author(id)
        ON UPDATE CASCADE ON DELETE SET NULL
    )},
  q{CREATE TABLE tag (
      book_id INTEGER NOT NULL,
      label   VARCHAR(64) NOT NULL,
      CONSTRAINT pk_tag PRIMARY KEY (book_id, label)
    )},
  q{CREATE INDEX idx_book_title ON book (title)},
  q{CREATE VIEW v_authors AS SELECT id, name FROM author},
);

my $intro = DBIO::Firebird::Introspect->new(dbh => $dbh);
my $model = $intro->model;

# --- tables / views ----------------------------------------------------------
is($model->{tables}{AUTHOR}{kind}, 'table', 'AUTHOR is a table');
is($model->{tables}{V_AUTHORS}{kind}, 'view', 'V_AUTHORS is a view');
is_deeply([sort @{ $intro->table_keys }],
  [qw/AUTHOR BOOK TAG V_AUTHORS/], 'table_keys lists tables + view');
ok(!$intro->table_is_view('AUTHOR'), 'AUTHOR not a view');
ok($intro->table_is_view('V_AUTHORS'), 'V_AUTHORS is a view');

# --- columns: type, not_null, bare decimal + separate size -------------------
my $bcols = $intro->table_columns_info('BOOK');
is($bcols->{ID}{is_nullable},    0, 'BOOK.ID NOT NULL (rdb$null_flag)');
is($bcols->{PRICE}{is_nullable}, 1, 'BOOK.PRICE nullable');
is($bcols->{PRICE}{data_type}, 'decimal', 'BOOK.PRICE bare decimal type');
is_deeply($bcols->{PRICE}{size}, [10, 2], 'BOOK.PRICE size [10,2] (abs scale)');
is($bcols->{TITLE}{size}, 256, 'BOOK.TITLE size 256');

# --- primary keys: single + composite ordering -------------------------------
is_deeply($intro->table_pk_info('BOOK'), ['ID'], 'BOOK single-column PK');
is_deeply($intro->table_pk_info('TAG'), [qw/BOOK_ID LABEL/],
  'TAG composite PK in declaration order (pk_position)');

# --- unique constraints ------------------------------------------------------
my $uq = $intro->table_uniq_info('AUTHOR');
is(scalar @$uq, 1, 'AUTHOR has one UNIQUE constraint');
is($uq->[0][0], 'UQ_AUTHOR_NAME', 'unique constraint name');
is_deeply($uq->[0][1], ['NAME'], 'unique constraint columns');

# --- standalone index survives; constraint-backed indexes filtered -----------
is_deeply([sort keys %{ $model->{indexes}{BOOK} }], ['IDX_BOOK_TITLE'],
  'only the standalone CREATE INDEX surfaces for BOOK');

# --- foreign key: local/remote columns + referential actions -----------------
my $fk = $intro->table_fk_info('BOOK');
is(scalar @$fk, 1, 'BOOK has one FK');
is_deeply($fk->[0]{local_columns},  ['AUTHOR_ID'], 'FK local columns');
is($fk->[0]{remote_table}, 'AUTHOR', 'FK remote table');
is_deeply($fk->[0]{remote_columns}, ['ID'], 'FK remote columns (referenced index)');
is($fk->[0]{attrs}{on_update}, 'CASCADE',  'FK ON UPDATE CASCADE');
is($fk->[0]{attrs}{on_delete}, 'SET NULL', 'FK ON DELETE SET NULL');

# --- cleanup -----------------------------------------------------------------
for my $ddl (
  'DROP VIEW v_authors',
  'DROP TABLE tag',
  'DROP TABLE book',
  'DROP TABLE author',
) { eval { $dbh->do($ddl) }; }

$dbh->disconnect;
done_testing;
