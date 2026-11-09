use strict;
use warnings;
use Test::More;
use DBI;

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

use DBIO::SQLite::Introspect;
use DBIO::SQLite::Introspect::Tables;

# karr k53.
#
# Telling the shadow tables of a virtual table from user tables needs PRAGMA
# table_list, which libsqlite has from 3.37 on. Below that,
# Introspect::Tables refuses a database that holds a virtual table -- guessing
# the shadow tables from their names would bring back the unexecutable DROP
# chain of karr k44 -- and introspects every other database as it always did.
# The README states both halves. t/43-introspect-virtual-shadow.t skips
# itself below 3.37, so neither was held by a test.
#
# No old libsqlite is needed: the version the introspection reads is faked.
# Only the answer of `SELECT sqlite_version()` is replaced; the driver's own
# reading of that string stays in play, so the limit below is the driver's.

{
  package K53::Version;
  sub new { bless { version => $_[1] }, $_[0] }
  sub selectrow_array { $_[0]{version} }
}

my $real_version = \&DBIO::SQLite::Introspect::Tables::_libsqlite_version;

# the model of $dbh as a libsqlite of that version would give it, or the
# reason it gives none
my $model_under = sub {
  my ($version, $dbh) = @_;

  local *DBIO::SQLite::Introspect::Tables::_libsqlite_version = sub {
    $real_version->( K53::Version->new($version) );
  };

  my $model = eval { DBIO::SQLite::Introspect->new(dbh => $dbh)->model };
  return ($model, $@);
};

my $connect = sub { DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 }) };

# --- a database that holds a virtual table ---
SKIP: {
  my $dbh = $connect->();
  $dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');

  eval { $dbh->do('CREATE VIRTUAL TABLE docs USING fts5(title, body)'); 1 }
    or skip 'FTS5 not compiled into this libsqlite', 20;

  # 3.9.2 is the one a comparison as text gets wrong: "3.9" sorts behind "3.37"
  for my $version (qw( 3.36.0 3.36.2 3.9.2 )) {
    my ($model, $error) = $model_under->($version, $dbh);

    is $model, undef, "libsqlite $version: a database with a virtual table is refused";

    like $error, qr/virtual table 'docs'/, '... naming the virtual table';
    like $error, qr/on libsqlite \Q$version\E:/, '... and the libsqlite it runs on';
    like $error, qr/PRAGMA table_list \(libsqlite 3\.37\+\)/, '... and what it lacks';
  }

  # from 3.37 on PRAGMA table_list answers, and the shadow tables go
  for my $version (qw( 3.37.0 3.37.2 3.100.0 )) {
    my ($model, $error) = $model_under->($version, $dbh);

    is $error, '', "libsqlite $version: not refused";

    is_deeply [ sort keys %{ ( $model || {} )->{tables} || {} } ], [ qw(artist docs) ],
      '... the model holds the virtual table and none of its shadow tables';
  }

  # the refusal looks at what the database holds, not at what it once held
  $dbh->do('DROP TABLE docs');
  my ($model, $error) = $model_under->('3.36.0', $dbh);

  is $error, '', 'libsqlite 3.36.0: the same database without the virtual table is not refused';
  is_deeply [ sort keys %{ ( $model || {} )->{tables} || {} } ], [ qw(artist) ],
    '... and introspects';
}

# --- a database that holds none ---
{
  my $dbh = $connect->();

  $dbh->do($_) for (
    'CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT NOT NULL)',
    'CREATE TABLE cd (
       id INTEGER PRIMARY KEY,
       artist_id INTEGER NOT NULL REFERENCES artist(id) ON DELETE CASCADE,
       title TEXT
     )',
    'CREATE INDEX cd_artist ON cd (artist_id)',
    'CREATE TABLE tag (cd_id INTEGER, word TEXT, PRIMARY KEY (cd_id, word)) WITHOUT ROWID',
    'CREATE VIEW cd_titles AS SELECT title FROM cd',
    'CREATE TRIGGER cd_touch AFTER INSERT ON cd BEGIN UPDATE artist SET name = name; END',

    # user tables that are named the way FTS5 names its shadow tables: nothing
    # below 3.37 may take a table for a shadow table by its name
    'CREATE TABLE notes (id INTEGER PRIMARY KEY)',
    'CREATE TABLE notes_content (id INTEGER PRIMARY KEY, c0 TEXT)',
    'CREATE TABLE notes_data (id INTEGER PRIMARY KEY, block BLOB)',
  );

  my $with_table_list = DBIO::SQLite::Introspect->new(dbh => $dbh)->model;

  is_deeply [ sort keys %{ $with_table_list->{tables} } ],
    [ qw(artist cd cd_titles notes notes_content notes_data tag) ],
    'reference: what this libsqlite introspects';

  for my $version (qw( 3.36.0 3.9.2 )) {
    my ($model, $error) = $model_under->($version, $dbh);

    is $error, '', "libsqlite $version: a database without a virtual table is not refused";

    is_deeply $model, $with_table_list,
      '... and introspects to the very model it gives with PRAGMA table_list';
  }
}

# --- a statement that only mentions one ---
#
# A virtual table is known by how its stored statement begins. The words in a
# string, in a comment or in a view's SELECT make no virtual table, and so no
# refusal.
for my $spec (
  [ q{a default holding the words} =>
    q{CREATE TABLE howto (id INTEGER PRIMARY KEY, note TEXT DEFAULT 'CREATE VIRTUAL TABLE x USING fts5(y)')} ],
  [ q{a comment holding the words} =>
    q{CREATE TABLE legacy (id INTEGER PRIMARY KEY /* was a CREATE VIRTUAL TABLE once */)} ],
  [ q{a view selecting the words} =>
    q{CREATE VIEW words AS SELECT 'CREATE VIRTUAL TABLE' AS said} ],
) {
  my ($desc, $ddl) = @$spec;

  my $dbh = $connect->();
  $dbh->do($ddl);

  my $with_table_list = DBIO::SQLite::Introspect->new(dbh => $dbh)->model;

  my ($model, $error) = $model_under->('3.36.0', $dbh);

  is $error, '', "libsqlite 3.36.0: $desc is no virtual table, and not refused";
  is_deeply $model, $with_table_list, '... and introspects as with PRAGMA table_list';
}

done_testing;
