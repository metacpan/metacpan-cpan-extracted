#!/usr/bin/env perl
# t/12-set-operations.t — the six set-operation keywords as DuckDB
# resolves them (ADR 0039). No database: _set_operation_keyword is a
# static class fact by contract, and this test is partly here to prove it.
#
# DuckDB has all six ANSI operations
# (https://duckdb.org/docs/stable/sql/query_syntax/setops), so this driver
# declares nothing and inherits core's base map. "Nothing to declare" is
# cheap to get wrong silently, hence the pinning:
#
#   - core's map is what answers here, not a driver override;
#   - core routing all six through one hook (ADR 0039 replaced the
#     single-operation _except_operator) left the emitted SQL
#     byte-identical for an engine that has the full set. That claim was
#     made in core against a HEAD worktree; this is the counter-check from
#     a driver that inherits every keyword.

use strict;
use warnings;
use Test::More;
use DBIO::DuckDB::Storage;
use DBIO::Test::Schema;

# The canonical operation name => the keyword DuckDB spells it with.
# Identical to ANSI, which is the point: nothing is overridden.
my @OPS = (
  [ union         => 'UNION'         ],
  [ union_all     => 'UNION ALL'     ],
  [ intersect     => 'INTERSECT'     ],
  [ intersect_all => 'INTERSECT ALL' ],
  [ except        => 'EXCEPT'        ],
  [ except_all    => 'EXCEPT ALL'    ],
);

# --- 1. the driver overrides nothing -----------------------------------

is( DBIO::DuckDB::Storage->can('_set_operation_keyword'),
    DBIO::Storage::DBI->can('_set_operation_keyword'),
  '_set_operation_keyword resolves to core: no driver override' );

ok !defined( *{DBIO::DuckDB::Storage::_set_operation_keyword}{CODE} ),
  'no _set_operation_keyword in the driver symbol table either';

# ADR 0039 also removed _except_operator outright. An override left behind
# under the old name would not fail loudly -- it would simply stop being
# called -- so its absence is asserted rather than assumed.
ok !DBIO::DuckDB::Storage->can('_except_operator'),
  'the superseded _except_operator is gone everywhere, driver included';

# --- 2. all six keywords, pinned ---------------------------------------

for my $pair (@OPS) {
  my ($op, $keyword) = @$pair;
  is( DBIO::DuckDB::Storage->_set_operation_keyword($op), $keyword,
    "$op => $keyword" );
}

# An unknown operation is a core programming error, not an engine fact.
# The driver must not absorb it; the base throw has to arrive intact.
my $err;
eval { DBIO::DuckDB::Storage->_set_operation_keyword('symmetric_difference'); 1 }
  or $err = $@;
like "$err", qr/Unknown set operation 'symmetric_difference'/,
  'an unknown operation throws from core, listing the valid names';

# --- 3. resolved without a connection ----------------------------------
# ADR 0039 section 7: the keyword is baked into a literal FROM clause at
# construction time, so it must come from a class fact. A DuckDB storage
# that was given its DSN answers with no $dbh.

my $storage = DBIO::DuckDB::Storage->new;
$storage->connect_info(['dbi:DuckDB:dbname=:memory:']);

is $storage->_set_operation_keyword('except'), 'EXCEPT',
  'never-connected storage answers from class facts alone';
is $storage->_dbh, undef, 'and did so without connecting';

# The DSN names its driver through a function, not by reblessing a generic
# storage once asked (core ADR 0067).
SKIP: {
  skip 'core predates ADR 0067 (no DBIO->driver_for)', 1
    unless DBIO->can('driver_for');

  is( DBIO->driver_for('dbi:DuckDB:dbname=:memory:'), 'DuckDB',
    'DBIO->driver_for names DuckDB for a DuckDB DSN' );
}

# --- 4. the emitted SQL, byte-for-byte ---------------------------------
# Both operands are the same query, so the whole statement is predictable
# from one template. Compared as exact strings rather than through
# is_same_sql_bind, whose normalisation would hide a whitespace drift --
# which is the only kind of drift a pure routing change could introduce.
# The shared test schema keeps no driver in its class; this use declares
# DuckDB on a clone.

my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('+DBIO::DuckDB::Storage');
$schema = $schema->connect('dbi:DuckDB:dbname=:memory:');

my $left   = $schema->resultset('Artist')->search({ name => 'a' });
my $right  = $schema->resultset('Artist')->search({ name => 'b' });

my $cols    = '"me"."artistid", "me"."name", "me"."rank", "me"."charfield"';
my $operand = qq{SELECT $cols FROM "artist" "me" WHERE ( "name" = ? )};

for my $pair (@OPS) {
  my ($op, $keyword) = @$pair;
  my $query = $left->$op($right)->as_query;

  is ${$query}->[0],
    qq{(SELECT $cols FROM ($operand $keyword $operand) "me")},
    "\$rs->$op renders $keyword";
}

is $schema->storage->_dbh, undef,
  'building all six opened no connection';

# Without that declaration no keyword is DuckDB's: a schema that names no
# driver is refused at connect (core ADR 0067).
SKIP: {
  skip 'core predates ADR 0067 (no refusal of a schema without a driver)', 1
    unless DBIO->can('driver_for');

  my $err = do {
    local $@;
    eval { DBIO::Test::Schema->clone->connect('dbi:DuckDB:dbname=:memory:'); 1 } ? '' : "$@";
  };
  like $err, qr/declares no driver.*ADR 0067/s,
    'the shared test schema without a declared driver is refused at connect';
}

done_testing;
