use strict;
use warnings;
use Test::More;

# Offline test for the Informix SKIP/FIRST limit dialect. No live DB and no
# SQLite test infrastructure -- exercises DBIO::Informix::SQLMaker->apply_limit
# directly, which is what the storage invokes to slice result sets (Informix
# has no LIMIT/OFFSET keyword).

use_ok 'DBIO::Informix::SQLMaker';

my $maker = DBIO::Informix::SQLMaker->new(quote_char => '"', name_sep => '.');

# --- rows + offset -> SKIP ? FIRST ? ----------------------------------------
{
  local $maker->{pre_select_bind} = [];
  my $sql = $maker->apply_limit(q{SELECT "id", "name" FROM "artist"}, {}, 10, 5);
  is($sql, q{SELECT SKIP ? FIRST ? "id", "name" FROM "artist"},
    'rows + offset emit SKIP ? FIRST ?');
  is_deeply([ map { $_->[1] } @{ $maker->{pre_select_bind} } ], [5, 10],
    'SKIP/FIRST binds are (offset, rows) in order');
}

# --- rows only (offset 0) -> FIRST ? ----------------------------------------
{
  local $maker->{pre_select_bind} = [];
  my $sql = $maker->apply_limit(q{SELECT "id" FROM "artist"}, {}, 3, 0);
  is($sql, q{SELECT FIRST ? "id" FROM "artist"},
    'rows without offset emit FIRST ? only');
  is_deeply([ map { $_->[1] } @{ $maker->{pre_select_bind} } ], [3],
    'FIRST-only bind is (rows)');
}

# --- the storage wires this SQLMaker as its sql_maker_class ------------------
use_ok 'DBIO::Informix::Storage';
is(DBIO::Informix::Storage->sql_maker_class,
  'DBIO::Informix::SQLMaker',
  'Storage uses DBIO::Informix::SQLMaker');

done_testing;
