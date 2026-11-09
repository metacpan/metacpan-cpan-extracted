use strict;
use warnings;
use Test::More;
use DBI;

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

use DBIO::SQLite::Introspect;
use DBIO::SQLite::Diff;

# Regression for karr k44.
#
# A virtual table keeps its data in shadow tables, and sqlite_master lists
# every one of them as type = 'table' with an ordinary name. The only filter
# Introspect::Tables applied was `name NOT LIKE 'sqlite_%'`, so an FTS5 table
# `docs` used to introspect as SEVEN user tables:
#
#   artist, docs, docs_config, docs_content, docs_data, docs_docsize, docs_idx
#
# Diffed against a target that only knows `artist`, that produced SIX drop
# operations. Executed in order, only the first one works:
#
#   DROP TABLE docs          -> OK   (SQLite drops the shadow tables with it)
#   DROP TABLE docs_config   -> no such table: docs_config
#   ... and so on for the remaining four
#
# Same class of defect as k14 (DROP TABLE / DROP INDEX collision): a cascade
# SQLite performs itself, emitted a second time as individual statements, which
# fail. DBIO::SQLite::Deploy's DDL loop is explicitly non-atomic, so an upgrade
# against any database holding a virtual table aborted midway, after the first
# DROP had already run.
#
# The fix classifies via `PRAGMA table_list` (libsqlite 3.37+) and drops the
# shadow tables from the model. The virtual table itself stays.

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 });

my ($libversion) = $dbh->selectrow_array('SELECT sqlite_version()');
my @v = split /\./, $libversion;
plan skip_all => "libsqlite $libversion has no PRAGMA table_list (needs 3.37); "
  . 'fetch deliberately croaks there rather than guessing shadow names'
  if $v[0] < 3 || ($v[0] == 3 && ($v[1] // 0) < 37);

$dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
eval { $dbh->do('CREATE VIRTUAL TABLE docs USING fts5(title, body)'); 1 }
  or plan skip_all => 'FTS5 not compiled into this libsqlite';

my $model = DBIO::SQLite::Introspect->new(dbh => $dbh)->model;

# --- 1. The model holds the user tables, not the shadow tables --------------
is_deeply [ sort keys %{ $model->{tables} } ], [ qw(artist docs) ],
  'introspect returns exactly artist and docs (was: those plus five shadows)';

my @shadow = sort grep { /^docs_/ } keys %{ $model->{tables} };
is_deeply \@shadow, [],
  'none of docs_config/docs_content/docs_data/docs_docsize/docs_idx is a table';

# --- 2. The diff against a target without docs is ONE operation -------------
# Target = the live model minus docs, so nothing but the drop can differ.
my $target = {
  tables       => { artist => $model->{tables}{artist} },
  columns      => { artist => $model->{columns}{artist} },
  indexes      => { artist => $model->{indexes}{artist} // {} },
  foreign_keys => {},
};

my $diff = DBIO::SQLite::Diff->new(source => $model, target => $target);
ok $diff->has_changes, 'diff detects the removed virtual table';

my @ops = @{ $diff->operations };
is scalar(@ops), 1,
  'exactly one operation (was: six — one per shadow table plus docs)'
  or diag 'ops: ' . join ' | ', map { $_->as_sql } @ops;

is $ops[0]->action,     'drop', 'the single operation is a drop';
is $ops[0]->table_name, 'docs', 'and it drops the virtual table itself';

my $sql = $diff->as_sql;
like   $sql, qr/DROP TABLE "docs";/, 'DROP TABLE docs is emitted';
unlike $sql, qr/DROP TABLE "docs_/,
  'no DROP TABLE for a shadow table (the first DROP already removes them)';

# --- 3. Counter-check: the fix removes shadows, it does not hide virtuals ----
ok $model->{tables}{docs}, 'the virtual table is still in the model';
is $model->{tables}{docs}{kind}, 'table',
  'docs keeps kind = table (sqlite_master reports type = table for it)';
like $model->{tables}{docs}{sql}, qr/CREATE VIRTUAL TABLE/i,
  'and keeps its original CREATE VIRTUAL TABLE statement';

is_deeply [ map { $_->{column_name} } @{ $model->{columns}{artist} } ],
  [ qw(id name) ],
  'the ordinary table next to it is untouched';

done_testing;
