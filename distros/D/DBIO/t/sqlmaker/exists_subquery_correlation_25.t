use strict;
use warnings;

use Test::More;
use DBIO::Test ':DiffSQL';
use DBIO::SQLMaker::ClassicExtensions;

my $ROWS = DBIO::SQLMaker::ClassicExtensions->__rows_bindtype;

# karr #25 regression — MOCK ONLY, no real DB, no DSN.
#
# A correlated EXISTS subquery built from a resultset:
#   $owners_rs->search({ 'books.owner' => { -ident => 'owner.id' } }, { alias => 'owner' })
#             ->count_rs
# used as  -exists => $subq->as_query  on an OUTER BooksInLibrary ('me') resultset.
#
# The inner WHERE references  books.owner = owner.id . The OUTER query selects
# from  books me . The inner  books.owner  is meant to correlate to the OUTER
# row (the alias-less "books", physically the "me" row), NOT to a fresh local
# table that core auto-joins inside the subquery.
#
# REGRESSION: DBIO's condition-key auto-join (t/search/auto_join.t) resolved
# 'books.owner' as a has_many traversal on the inner Owners source and emitted
# a LOCAL  LEFT JOIN books books  inside the subquery. By SQL lexical scoping
# that local "books" shadows the outer correlated "books", silently turning the
# EXISTS into a constant "does any owner have any book" -- a data-correctness
# bug. The contract (matching upstream DBIx::Class, and DBIO's documented
# correlated-subquery idiom under the {alias} attribute) is: a dotted key whose
# value is a pure correlation reference ( -ident ) is a join/correlation
# *condition*, not a filter, and must NOT auto-join. Fix lives in
# DBIO::ResultSet::_check_column_rel (_cond_value_is_correlation guard).
#
# We pin the EXACT corrected SQL structure via is_same_sql_bind.

my $s = DBIO::Test->init_schema(
  no_deploy  => 1,
  quote_char => '',          # mirror rownum.t: unquoted identifiers
);

# Inner subquery — exactly the rownum.t shape, on default (non-Oracle) storage.
my $subq = $s->resultset('Owners')->search({
  'books.owner' => { -ident => 'owner.id' },
}, { alias => 'owner', select => ['id'] })->count_rs;

my $rs_exists = $s->resultset('BooksInLibrary')->search(
  { -exists => $subq->as_query },
  { select => ['id', 'owner'], rows => 1 },
);

my $sql = ${ $rs_exists->as_query }->[0];
diag "LIVE generated SQL on current core:\n$sql\n";

# ---------------------------------------------------------------------------
# 1. CORRELATION INTACT — pin the exact subquery body. The EXISTS subselect's
#    FROM is just  owners owner ; the inner  books.owner  is a free reference
#    that binds to the OUTER  books me  row. There is NO  LEFT JOIN books books
#    shadow. This is the upstream-blessed correlated-EXISTS shape.
# ---------------------------------------------------------------------------
is_same_sql_bind(
  $rs_exists->as_query,
  '(
    SELECT me.id, me.owner
      FROM books me
    WHERE (
      EXISTS((
        SELECT COUNT( * )
          FROM owners owner
        WHERE ( books.owner = owner.id )
      ))
      AND source = ?
    )
    LIMIT ?
  )',
  [
    [ { sqlt_datatype => 'varchar', sqlt_size => 100, dbic_colname => 'source' }
      => 'Library' ],
    [ $ROWS => 1 ],
  ],
  'karr #25: EXISTS stays correlated to outer "books me" -- no shadow self-join',
);

# ---------------------------------------------------------------------------
# 2. Belt-and-suspenders: assert the shadow join is literally absent, so a
#    future regression that re-introduces it fails loudly even if the
#    surrounding SQL drifts.
# ---------------------------------------------------------------------------
unlike(
  $sql,
  qr/\bLEFT \s+ JOIN \s+ books \s+ books\b/xi,
  'karr #25: no local "LEFT JOIN books books" shadowing the outer correlation',
);

# ---------------------------------------------------------------------------
# 3. Guard against over-correction: a genuine inner filter on a related table
#    ('books.title' => literal value) MUST still auto-join. This proves the
#    fix discriminates correlation from filter, rather than blanket-disabling
#    relationship auto-joins.
# ---------------------------------------------------------------------------
my $filter_subq = $s->resultset('Owners')->search({
  'books.title' => 'Some Book',
}, { alias => 'owner', select => ['id'] })->count_rs;

my $filter_sql = ${ $filter_subq->as_query }->[0];
diag "filter-value subquery SQL:\n$filter_sql\n";

like(
  $filter_sql,
  qr/\bJOIN \s+ books \s+ books\b/xi,
  'auto-join preserved: a filter value on books.title still joins books',
);

done_testing;
