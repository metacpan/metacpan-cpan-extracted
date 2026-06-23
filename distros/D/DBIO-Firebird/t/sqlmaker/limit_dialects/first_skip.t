use strict;
use warnings;
use Test::More;

# Offline test for the Firebird FIRST/SKIP limit dialect. No live DB and no
# SQLite test infrastructure -- exercises DBIO::Firebird::SQLMaker->apply_limit
# directly, which is what the storage invokes to slice result sets (Firebird
# has no LIMIT/OFFSET keyword).

use_ok 'DBIO::Firebird::SQLMaker';

my $maker = DBIO::Firebird::SQLMaker->new(quote_char => '"', name_sep => '.');

# --- rows + offset -> FIRST ? SKIP ? ----------------------------------------
{
  local $maker->{pre_select_bind} = [];
  my $sql = $maker->apply_limit(q{SELECT "id", "name" FROM "artist"}, {}, 10, 5);
  is($sql, q{SELECT FIRST ? SKIP ? "id", "name" FROM "artist"},
    'rows + offset emit FIRST ? SKIP ?');
  is_deeply([ map { $_->[1] } @{ $maker->{pre_select_bind} } ], [10, 5],
    'FIRST/SKIP binds are (rows, offset) in order');
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
use_ok 'DBIO::Firebird::Storage::Common';
is(DBIO::Firebird::Storage::Common->sql_maker_class,
  'DBIO::Firebird::SQLMaker',
  'Storage::Common uses DBIO::Firebird::SQLMaker');

done_testing;
