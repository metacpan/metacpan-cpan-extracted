use strict;
use warnings;

# ---------------------------------------------------------------------------
# t/50-logic-proofs.t -- Formal logic proofs for Database::Join
#
# Each test is framed as a syllogism:
#   Major Premise  (MP): a system invariant guaranteed by construction
#   Minor Premise  (mn): the specific state or input under test
#   Conclusion     (C):  the logically guaranteed outcome
#
# Equivalence-partition discipline: one test per logical partition boundary.
# No two tests exercise the same logical gate on values from the same partition.
# ---------------------------------------------------------------------------

use Test::More;
use Test::Exception;

BEGIN {
	eval { require DBD::SQLite; require Database::Abstraction };
	plan skip_all => 'DBD::SQLite and Database::Abstraction required' if $@;
	plan tests => 33;
}

use lib 't/lib';
use DBI;
use File::Temp qw(tempdir);
use Database::lp_a;
use Database::lp_b;
use Database::Join;

# ---------------------------------------------------------------------------
# Fixtures
#
#   lp_a: entry TEXT PK | name TEXT | tier TEXT
#     A1  Alice  gold
#     A2  Bob    silver
#     A3  Carol  gold      <- present only in lp_a (tests left/outer boundary)
#
#   lp_b: entry TEXT PK | score INTEGER
#     A1  95
#     A2  70
#     B1  88                <- present only in lp_b (tests outer boundary)
#
# Key-set analysis:
#   Left  join on entry: {A1, A2, A3}    (primary defines set; B1 excluded)
#   Inner join on entry: {A1, A2}        (intersection only)
#   Outer join on entry: {A1, A2, A3, B1} (union; A3 has no score, B1 no name)
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/lp_a.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE lp_a (entry TEXT PRIMARY KEY, name TEXT, tier TEXT)');
	$dbh->do(q{INSERT INTO lp_a VALUES ('A1','Alice', 'gold'  )});
	$dbh->do(q{INSERT INTO lp_a VALUES ('A2','Bob',   'silver')});
	$dbh->do(q{INSERT INTO lp_a VALUES ('A3','Carol', 'gold'  )});
	$dbh->disconnect;
}

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/lp_b.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE lp_b (entry TEXT PRIMARY KEY, score INTEGER)');
	$dbh->do(q{INSERT INTO lp_b VALUES ('A1', 95)});
	$dbh->do(q{INSERT INTO lp_b VALUES ('A2', 70)});
	$dbh->do(q{INSERT INTO lp_b VALUES ('B1', 88)});
	$dbh->disconnect;
}

my $lp_a = Database::lp_a->new(directory => $dir);
my $lp_b = Database::lp_b->new(directory => $dir);

# ---------------------------------------------------------------------------
# SECTION 1 — Pre-condition enforcement (impossible states must croak)
#
# MP: new() validates every element of databases before the bless.
# MP: add_database() validates its first arg before touching internal state.
# MP: remove_column() blocks the join_column as a structural invariant.
# ---------------------------------------------------------------------------

# Test 1
# MP: #databases >= 1 is a strict pre-condition.
# mn: databases => [] has zero elements.
# C:  new() must croak with the no-databases error before any object is created.
throws_ok {
	Database::Join->new(databases => [], join_column => 'entry');
} qr/at least one/i, 'pre-condition: empty databases arrayref is rejected';

# Test 2
# MP: every element of databases must be a blessed Database::Abstraction subclass.
# mn: 'plain_string' is neither blessed nor a reference.
# C:  new() must croak at index 0 with the invalid-db error.
throws_ok {
	Database::Join->new(databases => ['plain_string'], join_column => 'entry');
} qr/not a Database::Abstraction/i, 'pre-condition: non-object in databases is rejected';

# Test 3
# MP: join_column must be present in every database's column list.
# mn: 'no_such_col' does not exist in lp_a.
# C:  _build_col_index() must croak before the object is returned.
throws_ok {
	Database::Join->new(databases => [$lp_a], join_column => 'no_such_col');
} qr/join_column.*absent/i, 'pre-condition: join_column missing from database is rejected';

# Test 4
# MP: join_type is constrained to {left, inner, outer} by validate_strict enum.
# mn: 'full' is outside that set.
# C:  validate_strict must die before our code runs.
dies_ok {
	Database::Join->new(
		databases   => [$lp_a, $lp_b],
		join_column => 'entry',
		join_type   => 'full',
	);
} 'pre-condition: invalid join_type value is rejected by validate_strict';

# Test 5
# MP: add_database() requires a blessed Database::Abstraction subclass.
# mn: 'not_an_object' is a plain string (!ref).
# C:  Fail-fast guard fires immediately with invalid-db error.
my $join_base = Database::Join->new(
	databases   => [$lp_a, $lp_b],
	join_column => 'entry',
);
throws_ok {
	$join_base->add_database('not_an_object');
} qr/not a Database::Abstraction/i, 'pre-condition: non-object to add_database is rejected';

# Test 6
# MP: remove_column(join_col) would break the merge invariant.
# mn: $join_base->{_join_col} = 'entry'.
# C:  remove_column('entry') must croak with the remove-join-col error.
throws_ok {
	$join_base->remove_column('entry');
} qr/Cannot remove join_column/i, 'pre-condition: removing join_column is rejected';

# Test 7
# MP: query() is not implemented; the chained builder cannot span databases.
# mn: any call to query().
# C:  query() must croak with an explanatory message.
throws_ok {
	$join_base->query();
} qr/not supported/i, 'pre-condition: query() always croaks';

# Test 8
# MP: execute() is not implemented; raw SQL cannot span heterogeneous backends.
# mn: any call to execute().
# C:  execute() must croak with an explanatory message.
throws_ok {
	$join_base->execute();
} qr/not supported/i, 'pre-condition: execute() always croaks';

# Test 9
# MP: AUTOLOAD must not silently swallow private method calls (names starting _).
# MP: Private methods beginning with _ are not part of the public API.
# mn: $join_base->_join_col() -- a real private field name.
# C:  AUTOLOAD must croak immediately with the private-method error.
throws_ok {
	$join_base->_join_col();
} qr/cannot call private method/i, 'pre-condition: private method via AUTOLOAD is rejected';

# Test 10
# MP: AUTOLOAD only routes to columns registered in _col_db.
# MP: 'nonexistent_col' was never added to any component database.
# mn: calling $join_base->nonexistent_col() triggers AUTOLOAD.
# C:  AUTOLOAD must croak with the unknown-column error.
throws_ok {
	$join_base->nonexistent_col();
} qr/unknown column/i, 'pre-condition: AUTOLOAD on unknown column is rejected';

# ---------------------------------------------------------------------------
# SECTION 2 — Join-type boundary conditions
#
# Each join type defines a distinct logical gate on the key set.
# Tests prove exact boundary: one partition per join type × primary-only/secondary-only.
# ---------------------------------------------------------------------------

# Test 11
# MP(left): key_set = keys of primary database (A1, A2, A3).
# MP: secondary keys present only in lp_b (B1) do not enter the key set.
# mn: left join, no criteria.
# C: exactly 3 rows; B1 is absent.
my $join_left = Database::Join->new(
	databases   => [$lp_a, $lp_b],
	join_column => 'entry',
	join_type   => 'left',
);
my $left_rows = $join_left->selectall_arrayref();
is(scalar @{$left_rows}, 3, 'left join: primary key set has 3 rows');

# Test 12
# MP(left): rows for keys absent from secondary have no secondary columns.
# mn: A3 exists in lp_a but not in lp_b.
# C: the A3 row's 'score' key is undef (not 0, not absent-as-error, strictly undef).
my ($a3_row) = grep { $_->{entry} eq 'A3' } @{$left_rows};
ok(!defined($a3_row->{score}),
	'left join: primary-only row has undef for secondary column');

# Test 13
# MP(inner): key_set = intersection({A1,A2,A3}, {A1,A2,B1}) = {A1, A2}.
# mn: inner join, no criteria.
# C: exactly 2 rows; A3 and B1 are both absent.
my $join_inner = Database::Join->new(
	databases   => [$lp_a, $lp_b],
	join_column => 'entry',
	join_type   => 'inner',
);
my $inner_rows = $join_inner->selectall_arrayref();
is(scalar @{$inner_rows}, 2, 'inner join: key set = intersection, 2 rows');

# Test 14
# MP(inner): B1 ∉ dom(lp_a) → B1 is excluded from the intersection.
# C: no row in inner result has entry = 'B1'.
my @b1_inner = grep { $_->{entry} eq 'B1' } @{$inner_rows};
is(scalar @b1_inner, 0, 'inner join: secondary-only key B1 is absent');

# Test 15
# MP(outer): key_set = union({A1,A2,A3}, {A1,A2,B1}) = {A1,A2,A3,B1}.
# mn: outer join, no criteria.
# C: exactly 4 rows.
my $join_outer = Database::Join->new(
	databases   => [$lp_a, $lp_b],
	join_column => 'entry',
	join_type   => 'outer',
);
my $outer_rows = $join_outer->selectall_arrayref();
is(scalar @{$outer_rows}, 4, 'outer join: key set = union, 4 rows');

# Test 16
# MP(outer): B1 ∈ dom(lp_b) but B1 ∉ dom(lp_a) → B1 row has no primary columns.
# C: the B1 row's 'name' key is undef.
my ($b1_row) = grep { $_->{entry} eq 'B1' } @{$outer_rows};
ok(!defined($b1_row->{name}),
	'outer join: secondary-only row has undef for primary column');

# ---------------------------------------------------------------------------
# SECTION 3 — Invariant identities (post-condition proofs)
#
# These prove that the formal specification equalities hold.
# ---------------------------------------------------------------------------

# Test 17
# MP: count() ≡ scalar @{ _joined_query({}) } (formal spec post-condition).
# MP: selectall_arrayref() ≡ _joined_query({}).
# Transitive conclusion: count() ≡ scalar @{ selectall_arrayref() }.
# mn: no criteria.
is($join_left->count(), scalar @{ $join_left->selectall_arrayref() },
	'invariant: count() = scalar @{selectall_arrayref()} with no criteria');

# Test 18
# MP: same identity holds under active criteria (the criterion restricts both).
# mn: criteria tier => 'gold' narrows to 2 rows (Alice=A1, Carol=A3).
is($join_left->count(tier => 'gold'),
   scalar @{ $join_left->selectall_arrayref(tier => 'gold') },
   'invariant: count(criteria) = scalar @{selectall_arrayref(criteria)}');

# Test 19
# MP: fetchrow_hashref(C) ≡ selectall_arrayref(C)->[0] (formal spec).
# mn: criteria entry => 'A1' produces exactly one row (A1 is a primary key).
my $fetched = $join_left->fetchrow_hashref(entry => 'A1');
my $first   = $join_left->selectall_arrayref(entry => 'A1')->[0];
is_deeply($fetched, $first,
	'invariant: fetchrow_hashref(C) deep-equals selectall_arrayref(C)->[0]');

# Test 20
# MP: fetchrow_hashref returns undef when no row matches (boundary: empty result).
# mn: entry => 'ZZZZ' matches no row in either database.
# C: result must be undef, not an empty hashref or a false-but-defined value.
my $no_match = $join_left->fetchrow_hashref(entry => 'ZZZZ');
ok(!defined($no_match), 'invariant: fetchrow_hashref returns undef on no match');

# Test 21
# MP: selectall_array in list context ≡ @{ selectall_arrayref() }.
# mn: list context, no criteria.
# C: the two forms return identical data structures.
my @arr_list = $join_left->selectall_array();
is_deeply(\@arr_list, $join_left->selectall_arrayref(),
	'invariant: selectall_array (list) = deref selectall_arrayref');

# Test 22
# MP: selectall_array in scalar context returns only the first row.
# MP: rows are sorted ascending by join_column; first row is the smallest key.
# mn: scalar context, no criteria (A1 < A2 < A3 lexicographically).
# C: scalar result deep-equals the [0] element of selectall_arrayref().
my $arr_scalar = $join_left->selectall_array();
is_deeply($arr_scalar, $join_left->selectall_arrayref()->[0],
	'invariant: selectall_array (scalar) = first element of selectall_arrayref');

# ---------------------------------------------------------------------------
# SECTION 4 — Column invariants
#
# MP: columns() is the canonical view; it must be sorted, deduplicated, and
#     free of removed columns and local join-key aliases.
# ---------------------------------------------------------------------------

# Test 23
# MP: columns() is defined as sort(all visible column names).
# mn: join_left has columns: entry, name, score, tier.
# C: the returned arrayref is in strict ascending ASCII order.
my $cols = $join_left->columns();
is_deeply($cols, [sort @{$cols}], 'invariant: columns() is sorted alphabetically');

# Test 24
# MP: join_column appears exactly once in the merged view regardless of how many
#     databases each contain it (deduplication is performed in columns()).
# mn: both lp_a and lp_b have 'entry'.
# C: 'entry' appears exactly once.
my $entry_count = scalar grep { $_ eq 'entry' } @{$cols};
is($entry_count, 1, 'invariant: join_column appears exactly once in columns()');

# Test 25
# MP: remove_column(col) places col in _removed_cols and deletes it from _col_db.
# MP: columns() filters out every key in _removed_cols.
# Transitive conclusion: col is absent from columns() after removal.
my $join_rm = Database::Join->new(
	databases   => [$lp_a, $lp_b],
	join_column => 'entry',
);
$join_rm->remove_column('tier');
my $cols_after = $join_rm->columns();
ok(!grep { $_ eq 'tier' } @{$cols_after},
	'invariant: removed column absent from columns()');

# Test 26
# MP: _joined_query deletes removed columns from every merged row before appending.
# Transitive conclusion: removed column key absent from every row hashref.
my $rows_after = $join_rm->selectall_arrayref();
my $leaked = grep { exists $_->{tier} } @{$rows_after};
is($leaked, 0, 'invariant: removed column absent from all row hashrefs');

# Test 27
# MP: _partition_criteria routes by _col_db; remove_column deletes the col from _col_db.
# MP: unknown column (col ∉ dom _col_db) falls to carp + drop, criterion ignored.
# Transitive conclusion: count(removed_col => 'x') = count(), the filter has no effect.
# (The expected carp is suppressed locally to keep test output clean.)
local $SIG{__WARN__} = sub {};
my $count_unfiltered = $join_rm->count();
my $count_on_removed = $join_rm->count(tier => 'gold');
is($count_on_removed, $count_unfiltered,
	'invariant: criteria on removed column are silently dropped (count unchanged)');
$SIG{__WARN__} = 'DEFAULT';

# ---------------------------------------------------------------------------
# SECTION 5 — Criteria routing and join semantics
#
# Proves that criteria on primary/secondary columns produce inner-join semantics
# regardless of the declared join_type, matching the formal specification.
# ---------------------------------------------------------------------------

# Test 28
# MP: any database that had criteria in a query call acts as an inner-join partner.
# MP: join_left uses join_type='left', so A3 is normally in the result.
# mn: criterion tier => 'gold' routes to lp_a (the primary database).
# C: lp_a now has effective criteria → inner-join semantics.
#    Only rows where tier='gold' AND present in primary survive.
#    Alice (A1, gold) and Carol (A3, gold) qualify; Bob (A2, silver) is excluded.
#    A3 has no score but is still returned (it passed the primary filter).
my $gold_rows = $join_left->selectall_arrayref(tier => 'gold');
is(scalar @{$gold_rows}, 2, 'criteria routing: primary criterion restricts to 2 gold-tier rows');

# Test 29
# MP: criterion on secondary column routes to lp_b (the secondary database).
# MP: lp_b then acts as inner-join partner → only keys in its filtered result survive.
# mn: criterion score => { '>' => 80 } matches only A1 (score=95) in lp_b.
#     B1 (score=88) is not in lp_a so it cannot appear in the left-join result.
# C: exactly 1 row (A1=Alice); A2 (score=70) and A3 (no score) are both excluded.
my $high_rows = $join_left->selectall_arrayref(score => { '>' => 80 });
is(scalar @{$high_rows}, 1, 'criteria routing: secondary criterion restricts via inner-join semantics');
is($high_rows->[0]{name}, 'Alice', 'criteria routing: surviving row is Alice (score=95)');

# Test 30
# MP: join_column criterion is broadcast to ALL databases via _partition_criteria.
# MP: after broadcast, both databases have effective criteria → intersect semantics.
# mn: criterion entry => 'A1' is the join_column (canonical name = 'entry').
# C: each database filters to only the A1 row; merged result has exactly 1 row
#    with both primary (name, tier) and secondary (score) columns populated.
my $a1_rows = $join_left->selectall_arrayref(entry => 'A1');
is(scalar @{$a1_rows}, 1, 'criteria routing: join_column criterion returns 1 row');
is($a1_rows->[0]{name},  'Alice', 'criteria routing: join_column criterion: name correct');
is($a1_rows->[0]{score}, 95,     'criteria routing: join_column criterion: score correct');

# Release DBI connections before File::Temp's cleanup END block fires.
# On Windows, SQLite keeps files locked until all handles are closed; file-scoped
# 'my' variables outlive END blocks, so we undef explicitly (joins first).
undef $_ for ($join_base, $join_left, $join_inner, $join_outer, $join_rm, $lp_a, $lp_b);
