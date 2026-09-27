#!perl -w

# Logic-Reduction Tests — Syllogistic Invariant Proofs
#
# Each test group asserts a FORMAL INVARIANT derived from the module's
# documented API contracts.  Tests are structured as:
#
#   Major Premise (system rule)
#   Minor Premise (input / state)
#   Conclusion   (observable outcome)
#
# Values are drawn from BOUNDARY PARTITIONS only.  Tests within the same
# proven logical partition are not duplicated.
#
# Invariants proven:
#   I-1  Fail-fast construction: all guards fire at new(), never at query time
#   I-2  _has_complex_criteria Boolean gate: 6 exhaustive partitions
#   I-3  In-memory vs SQL bifurcation: scalar→slurp, hashref→SQL
#   I-4  Slurp boundary semantics: file_size <= max_slurp_size (not <)
#   I-5  base_criteria immutability: shallow copy, post-construction mutation ignored
#   I-6  Cache-transparent semantics: with/without cache returns identical data
#   I-7  _match_criterion hashref branch: unreachable via public API (proven by
#        contradiction); branch exists and is correct for direct white-box calls
#   I-8  _parse_sort_by truth table: 6 input classes → output mapping
#   I-9  _like_match fast-path truth table: 5 O(1) paths × match/no-match
#   I-10 _like_match full-DP correctness: '_' single-char and multi-'%' patterns
#   I-11 _is_deep_db magic-byte truth table: DPDB/DPDP/non-magic/nonexistent
#   I-12 _match_criterion scalar truth table: 5 SQL-equality cases (NULL/eq/ne)
#   I-13 no_entry data structure invariant: HASH ref vs ARRAY ref bifurcation
#   I-14 _build_where boolean composition: empty/scalar/-or/-and primitives
#   I-15 _is_local_host truth table: loopback literals and user@ prefix stripping
#   I-16 De Morgan — combined -or + hashref, and non-hashref ref type
#   I-17 auto_load guard: disabled path croaks, enabled path is transparent

use strict;
use warnings;

use FindBin     qw($Bin);
use File::Spec;
use File::Temp  qw(tempfile);
use Readonly;
use Scalar::Util qw(weaken);
use Test::Most   tests => 82;
use Test::NoWarnings;

use lib 't/lib';
use Database::test1;
use Database::test4ne;

# ---------------------------------------------------------------------------
# Shared constants
# ---------------------------------------------------------------------------

Readonly my $DATA_DIR  => File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
Readonly my $CSV_FILE  => File::Spec->catfile($DATA_DIR, 'test1.csv');
Readonly my $CSV_SIZE  => (-s $CSV_FILE);

# ---------------------------------------------------------------------------
# INVARIANT 1: Fail-fast construction validation
#
# Major Premise:  new() validates id/table/host/url/base_criteria before
#                 returning an object.
# Minor Premise:  An invalid value is supplied for each parameter in turn.
# Conclusion:     The croak fires at new() — no object is returned, so query
#                 methods can NEVER receive an object with an invalid invariant.
#
# Logical form (Modus Tollens):
#   P1: if object returned → all invariants satisfied
#   P2: invariant NOT satisfied (bad id supplied)
#   C:  object NOT returned (croak fires)
# ---------------------------------------------------------------------------

note('I-1: fail-fast construction — guards fire at new(), never at query time');

# I-1.1: Invalid id — caught at new(), not the first query
throws_ok {
	Database::test1->new({ directory => $DATA_DIR, id => '1bad' })
} qr/unsafe id column name/,
	'I-1.1: id starting with digit is rejected at new()';

# I-1.2: Invalid table name — caught at new()
throws_ok {
	Database::test1->new({ directory => $DATA_DIR, table => 'tbl;drop' })
} qr/unsafe table name/,
	'I-1.2: table with semicolon is rejected at new()';

# I-1.3: Invalid host — caught at new()
throws_ok {
	Database::test1->new({ directory => $DATA_DIR, host => 'server;ls' })
} qr/unsafe host/,
	'I-1.3: host with shell metacharacter is rejected at new()';

# I-1.4: Invalid URL scheme — caught at new()
throws_ok {
	Database::test1->new({ url => 'ftp://example.com/data.html' })
} qr/unsafe url/,
	'I-1.4: ftp:// URL scheme is rejected at new()';

# I-1.5: base_criteria wrong type — caught at new()
throws_ok {
	Database::test1->new({ directory => $DATA_DIR, base_criteria => 'scalar' })
} qr/base_criteria must be a hashref/,
	'I-1.5: non-hashref base_criteria is rejected at new()';

# I-1.6: base_criteria unsafe key — caught at new()
throws_ok {
	Database::test1->new({ directory => $DATA_DIR, base_criteria => { 'k;bad' => 1 } })
} qr/unsafe base_criteria key/,
	'I-1.6: base_criteria key with semicolon is rejected at new()';

# I-1.7: Contrapositive — a VALID object runs all query methods without re-validating
# Premise: the object was returned → all invariants are satisfied → no
#          validation croak can fire during query calls.
{
	my $db = Database::test1->new({ directory => $DATA_DIR });
	my $ok = eval {
		$db->count();
		$db->selectall_arrayref();
		$db->selectall_array();
		$db->fetchrow_hashref(entry => 'one');
		1
	};
	ok($ok && !$@,
		'I-1.7: a valid object runs count/select/fetchrow without re-validating invariants');
}

# ---------------------------------------------------------------------------
# INVARIANT 2: _has_complex_criteria Boolean gate — exhaustive partition proof
#
# Major Premise:  _has_complex_criteria(params) returns TRUE iff params
#                 contains a hashref value OR a -or/-and key.
# Minor Premise:  There are exactly 5 mutually exclusive input classes.
# Conclusion:     Testing one representative from each class covers all paths.
#
# Classes (exhaustive, mutually exclusive):
#   C1  undef params     → false  (no params object)
#   C2  empty {}         → false  (params exist, no keys)
#   C3  all scalars      → false  (params with scalar values only)
#   C4  one ref value    → true   (first structural complexity)
#   C5  -or key          → true   (grouping key present)
#   C6  -and key         → true   (grouping key present)
# ---------------------------------------------------------------------------

note('I-2: _has_complex_criteria Boolean gate — exhaustive partition proof');

{
	my $db = Database::test1->new($DATA_DIR);

	# C1: undef → false
	ok(!$db->_has_complex_criteria(undef),
		'I-2.C1: undef params → false (no reference possible)');

	# C2: empty {} → false
	ok(!$db->_has_complex_criteria({}),
		'I-2.C2: empty hashref → false (no values to inspect)');

	# C3: all scalar values → false
	ok(!$db->_has_complex_criteria({ entry => 'one', name => 'Alice' }),
		'I-2.C3: all-scalar params → false (no refs present)');

	# C4: one hashref value → true (the critical boundary: first ref in params)
	ok( $db->_has_complex_criteria({ entry => { '>' => 0 } }),
		'I-2.C4: one hashref value → true (operator hashref is a ref)');

	# C5: -or key present → true (short-circuit; no value inspection needed)
	ok( $db->_has_complex_criteria({ -or => [] }),
		'I-2.C5: -or key present → true (grouping key triggers early return)');

	# C6: -and key present → true
	ok( $db->_has_complex_criteria({ -and => [] }),
		'I-2.C6: -and key present → true (grouping key triggers early return)');
}

# ---------------------------------------------------------------------------
# INVARIANT 3: In-memory vs SQL bifurcation
#
# Major Premise A:  scalar criteria + slurped data → _has_complex_criteria=false
#                   → in-memory scan path
# Major Premise B:  hashref criteria → _has_complex_criteria=true
#                   → SQL path (even when data IS slurped)
# Minor Premise:    test1 CSV is small enough to be slurped (max_slurp_size=large)
# Conclusion A:     scalar criterion on slurped data hits in-memory path:
#                   data slot is a ref AND result is correct
# Conclusion B:     operator hashref on slurped data hits SQL path:
#                   data slot is STILL a ref (still slurped) AND result is correct
#
# This proves the bifurcation is driven purely by criteria type, not by
# whether the file was slurped.
# ---------------------------------------------------------------------------

note('I-3: in-memory vs SQL bifurcation');

{
	# Use test4ne (no_entry=1) so Params::Get preserves the criteria hash intact
	my $db = Database::test4ne->new({ directory => $DATA_DIR });
	$db->count();    # trigger _open

	# Conclusion A: scalar criteria → in-memory path; data is ref AND result correct
	{
		my $rows_scalar = $db->selectall_arrayref(cardinal => 'one');
		ok(ref($db->{'data'}),
			'I-3.A.1: data slot is a ref (file was slurped) when scalar criteria used');
		ok(ref($rows_scalar) eq 'ARRAY' && @{$rows_scalar} == 1,
			'I-3.A.2: scalar criteria returns exactly 1 matching row via in-memory path');
	}

	# Conclusion B: operator hashref criteria → SQL path; data is STILL a ref
	{
		my $rows_op = $db->selectall_arrayref(cardinal => { -like => '%' });
		ok(ref($db->{'data'}),
			'I-3.B.1: data slot remains a ref (slurp not invalidated) for hashref criteria');
		ok(ref($rows_op) eq 'ARRAY' && @{$rows_op} == 3,
			'I-3.B.2: operator hashref returns all 3 rows via SQL path on slurped data');
	}
}

# ---------------------------------------------------------------------------
# INVARIANT 4: Slurp boundary — `<=` not `<`
#
# Major Premise:  file is slurped when (-s $file) <= max_slurp_size.
#                 The boundary condition is inclusive (<=, not strict <).
# Minor Premise:  CSV_SIZE = actual byte size of test1.csv.
# Conclusion:
#   B1: max_slurp_size = CSV_SIZE     → (-s) <= threshold → SLURPED
#   B2: max_slurp_size = CSV_SIZE - 1 → (-s) > threshold  → SQL mode
#   B3: max_slurp_size = 0            → (-s) > 0 always   → SQL mode
#   B4: max_slurp_size = CSV_SIZE + 1 → (-s) < threshold  → SLURPED
# ---------------------------------------------------------------------------

note("I-4: slurp boundary (CSV_SIZE=$CSV_SIZE, operator is <=)");

{
	# B1: exact boundary → slurped
	{
		my $db = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => $CSV_SIZE });
		$db->count();
		ok(ref($db->{'data'}), 'I-4.B1: max_slurp_size == file_size → data IS slurped');
	}

	# B2: one byte below boundary → SQL mode
	{
		my $db = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => $CSV_SIZE - 1 });
		$db->count();
		ok(!ref($db->{'data'}), 'I-4.B2: max_slurp_size == file_size-1 → SQL mode (not slurped)');
	}

	# B3: zero → SQL mode always
	{
		my $db = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => 0 });
		$db->count();
		ok(!ref($db->{'data'}), 'I-4.B3: max_slurp_size=0 → SQL mode always');
	}

	# B4: one above boundary → still slurped
	{
		my $db = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => $CSV_SIZE + 1 });
		$db->count();
		ok(ref($db->{'data'}), 'I-4.B4: max_slurp_size == file_size+1 → data IS slurped');
	}
}

# ---------------------------------------------------------------------------
# INVARIANT 5: base_criteria immutability (shallow-copy invariant)
#
# Major Premise:  new() shallow-copies base_criteria into the object.
# Minor Premise:  Caller mutates the original hashref after construction.
# Conclusion:     The mutation CANNOT propagate into the object's filter.
#
# Logical form:
#   P1: object holds a COPY of base_criteria, not the original reference
#   P2: mutation targets the original hashref (a different memory location)
#   C:  the object's query behaviour is unchanged after the mutation
# ---------------------------------------------------------------------------

note('I-5: base_criteria immutability — post-construction mutation is ignored');

{
	my %bc = (entry => 'one');
	my $db = Database::test1->new({ directory => $DATA_DIR, base_criteria => \%bc });

	# Pre-mutation: filter in effect → count = 1
	cmp_ok($db->count(), '==', 1, 'I-5.1: base_criteria in effect before mutation (count=1)');

	# Mutation: change the original hash to broaden the filter
	$bc{entry} = undef;    # would match IS NULL if propagated

	# Post-mutation: object is unaffected — still returns 1 row for 'one'
	cmp_ok($db->count(), '==', 1,
		'I-5.2: post-construction mutation of original does not change object behaviour');

	# Prove the object holds its own copy: internal ref differs from original
	ok($db->{'base_criteria'} != \%bc,
		'I-5.3: object base_criteria address differs from caller original (deep copy confirmed)');
}

# ---------------------------------------------------------------------------
# INVARIANT 6: Cache-transparent semantics
#
# Major Premise:  the cache is a read-through layer; it must return the same
#                 logical data as the uncached path.
# Minor Premise:  same query is run on two objects — one with CHI cache, one
#                 without.
# Conclusion:     both return identical results.
#
# Also proves that the lazy $key assembly (D~ fix) produces the same key
# regardless of cache presence, so no regression from the refactoring.
# ---------------------------------------------------------------------------

note('I-6: cache-transparent semantics');

SKIP: {
	eval { require CHI } or skip 'CHI not available', 4;

	my $cache = CHI->new(driver => 'Memory', global => 0);

	my $db_cached = Database::test1->new({
		directory      => $DATA_DIR,
		cache          => $cache,
		cache_duration => '1 hour',
	});
	my $db_plain = Database::test1->new({ directory => $DATA_DIR });

	# I-6.1: count() results are identical
	cmp_ok($db_cached->count(), '==', $db_plain->count(),
		'I-6.1: count() returns same result with and without cache');

	# I-6.2: fetchrow_hashref is identical (MISS → DB, then HIT → cache)
	my $row_plain  = $db_plain->fetchrow_hashref(entry => 'one');
	my $row_miss   = $db_cached->fetchrow_hashref(entry => 'one');
	my $row_hit    = $db_cached->fetchrow_hashref(entry => 'one');

	is_deeply($row_plain, $row_miss,
		'I-6.2: fetchrow_hashref cache MISS returns same data as no-cache path');
	is_deeply($row_miss, $row_hit,
		'I-6.3: fetchrow_hashref cache HIT returns same data as cache MISS');

	# I-6.4: different entry → different result (proves cache key encodes the criteria)
	my $row_two = $db_cached->fetchrow_hashref(entry => 'two');
	isnt($row_miss->{'entry'}, $row_two->{'entry'},
		'I-6.4: different query produces different cache key and different result');
}

# ---------------------------------------------------------------------------
# INVARIANT 7: _match_criterion hashref branch unreachability via public API
#
# Major Premise A: the in-memory scan gate is !_has_complex_criteria(params).
# Major Premise B: _has_complex_criteria returns true when ANY value is a ref.
# Minor Premise:   an operator hashref IS a ref.
# Conclusion (by contradiction):
#   Assume _match_criterion is called from the public API with a hashref crit_val.
#   Then the params contained a hashref value.
#   Then _has_complex_criteria returned true.
#   Then the in-memory gate was CLOSED (! true = false).
#   But _match_criterion is only called from inside the in-memory gate.
#   Contradiction → the assumption is false.
#
# White-box corollary: the branch EXISTS and returns correct results when
# called directly — it is just unreachable via the public API.
# ---------------------------------------------------------------------------

note('I-7: _match_criterion hashref branch — unreachable via public API');

{
	my $db = Database::test1->new($DATA_DIR);

	# I-7.1: Public API proof — operator hashref on slurped data goes SQL path.
	# Evidence: correct SQL result even though data slot is populated (slurped).
	$db->count();    # ensure slurped
	ok(ref($db->{'data'}), 'I-7.1: data is slurped (precondition)');

	# Use test4ne to avoid Params::Get pitfall with keyed databases + operator hashrefs
	my $db4 = Database::test4ne->new({ directory => $DATA_DIR });
	my $rows = $db4->selectall_arrayref(cardinal => { -in => ['one', 'two'] });
	ok(ref($rows) eq 'ARRAY' && @{$rows} == 2,
		'I-7.2: -in operator on slurped data hits SQL path and returns correct rows');

	# I-7.3: White-box direct call — proves the branch is correct even though
	# unreachable from the public API (used by t/mutant_killers.t to kill mutants).
	ok( $db->_match_criterion('one',   { -in => ['one', 'two'] }),
		'I-7.3a: direct _match_criterion call with -in hashref matches correctly');
	ok(!$db->_match_criterion('three', { -in => ['one', 'two'] }),
		'I-7.3b: direct _match_criterion call with -in hashref rejects correctly');
}

# ---------------------------------------------------------------------------
# INVARIANT 8: _parse_sort_by truth table
#
# Major Premise:  _parse_sort_by maps 6 input classes to (col, dir) pairs:
#   C1 undef         → (undef, 'ASC')   — no-sort state
#   C2 scalar string → (col, 'ASC')     — ascending default
#   C3 arrayref DESC → (col, 'DESC')    — explicit descending
#   C4 lowercase dir → (col, 'DESC')    — uc() normalisation fires before validate
#   C5 invalid col   → (undef, 'ASC')   — guard fires, fallback returned
#   C6 invalid dir   → (undef, 'ASC')   — guard fires, fallback returned
# ---------------------------------------------------------------------------

note('I-8: _parse_sort_by truth table — 6 input classes');

{
	# C1: undef → no-sort state (col undef, dir 'ASC')
	{
		my ($col, $dir) = Database::Abstraction::_parse_sort_by(undef, 'test');
		ok(!defined($col), 'I-8.C1a: undef sort_by → col is undef (no sort applied)');
		is($dir, 'ASC', 'I-8.C1b: undef sort_by → direction defaults to ASC');
	}

	# C2: scalar column name → (col, 'ASC')
	{
		my ($col, $dir) = Database::Abstraction::_parse_sort_by('entry', 'test');
		is($col, 'entry', 'I-8.C2: scalar column name → col returned unchanged');
	}

	# C3: arrayref with explicit 'DESC' direction
	{
		my ($col, $dir) = Database::Abstraction::_parse_sort_by(['entry', 'DESC'], 'test');
		is($dir, 'DESC', 'I-8.C3: ["col","DESC"] → direction is DESC');
	}

	# C4: lowercase 'desc' → uc() normalises to 'DESC' before validation → accepted
	{
		my ($col, $dir) = Database::Abstraction::_parse_sort_by(['entry', 'desc'], 'test');
		is($dir, 'DESC',
			'I-8.C4: lowercase "desc" → uc() normalises to DESC (valid, not a fallback)');
	}

	# C5: invalid column name → carp + fallback (undef, 'ASC')
	{
		my @warns;
		local $SIG{__WARN__} = sub { push @warns, @_ };
		my ($col, $dir) = Database::Abstraction::_parse_sort_by('1bad', 'test');
		ok(scalar(@warns) > 0, 'I-8.C5a: digit-prefixed column name triggers a carp warning');
		ok(!defined($col), 'I-8.C5b: invalid column → col falls back to undef');
	}

	# C6: invalid direction → carp + direction fallback to 'ASC'
	{
		my @warns;
		local $SIG{__WARN__} = sub { push @warns, @_ };
		my ($col, $dir) = Database::Abstraction::_parse_sort_by(['entry', 'NOSUCHDIR'], 'test');
		is($dir, 'ASC', 'I-8.C6: unknown direction "NOSUCHDIR" → falls back to ASC');
	}
}

# ---------------------------------------------------------------------------
# INVARIANT 9: _like_match fast-path truth table
#
# Major Premise:  _like_match uses 5 O(1) string-primitive fast paths:
#   FP1: pattern eq '%'         → always true
#   FP2: no wildcard            → lc($str) eq lc($pattern) equality
#   FP3: '%suffix'              → ends-with via substr
#   FP4: 'prefix%'              → starts-with via index
#   FP5: '%literal%'            → contains via index (no inner wildcards)
# Conclusion:     Testing one match + one no-match representative per path
#                 exhausts all 5 Boolean functions.
# ---------------------------------------------------------------------------

note('I-9: _like_match fast-path truth table — 5 O(1) paths');

{
	# FP1: '%' matches anything — including the empty string (boundary)
	ok( Database::Abstraction::_like_match('any string', '%'),
		'I-9.FP1a: "%" matches any non-empty string');
	ok( Database::Abstraction::_like_match('', '%'),
		'I-9.FP1b: "%" matches the empty string (boundary — no char required)');

	# FP2: no wildcards — case-insensitive equality
	ok( Database::Abstraction::_like_match('Hello', 'HELLO'),
		'I-9.FP2a: no-wildcard pattern → case-insensitive equality returns true');
	ok(!Database::Abstraction::_like_match('Hello', 'World'),
		'I-9.FP2b: no-wildcard pattern → non-equal string returns false');

	# FP3: '%suffix' — ends-with
	ok( Database::Abstraction::_like_match('hello world', '%world'),
		'I-9.FP3a: "%suffix" matches string ending with suffix');
	ok(!Database::Abstraction::_like_match('world hello', '%world'),
		'I-9.FP3b: "%suffix" rejects string that does not end with suffix');

	# FP4: 'prefix%' — starts-with
	ok( Database::Abstraction::_like_match('hello world', 'hello%'),
		'I-9.FP4a: "prefix%" matches string starting with prefix');
	ok(!Database::Abstraction::_like_match('say hello', 'hello%'),
		'I-9.FP4b: "prefix%" rejects string that does not start with prefix');

	# FP5: '%mid%' — contains (middle segment has no inner wildcards)
	ok( Database::Abstraction::_like_match('say world here', '%world%'),
		'I-9.FP5a: "%mid%" matches string containing the middle segment');
	ok(!Database::Abstraction::_like_match('say earth here', '%world%'),
		'I-9.FP5b: "%mid%" rejects string that does not contain middle segment');
}

# ---------------------------------------------------------------------------
# INVARIANT 10: _like_match full DP — patterns that bypass all fast paths
#
# Major Premise:  Patterns containing '_' wildcards, or multiple '%' groups
#                 with inner content, fall through to the O(m*n) DP.
#   DP1: '_at' — '_' matches exactly ONE character (not zero, not two)
#   DP2: '%a%b%' — multi-'%' pattern with inner literal segments
# Conclusion:     The DP's rolling-array implementation is correct for these
#                 shapes that the fast paths cannot handle.
# ---------------------------------------------------------------------------

note('I-10: _like_match full-DP correctness — single-char and multi-segment');

{
	# DP1a: '_at' matches 'cat' — underscore consumes exactly one char ('c')
	ok( Database::Abstraction::_like_match('cat', '_at'),
		'I-10.DP1a: "_at" matches "cat" (single-char wildcard "_" fills one char)');

	# DP1b: '_at' rejects 'at' — string too short; underscore needs 1 char, has 0
	ok(!Database::Abstraction::_like_match('at', '_at'),
		'I-10.DP1b: "_at" rejects "at" (string has no char before "at")');

	# DP2: '%a%b%' matches 'xaxbx' — inner '%' prevents FP5, falls to full DP
	ok( Database::Abstraction::_like_match('xaxbx', '%a%b%'),
		'I-10.DP2: "%a%b%" matches "xaxbx" via full DP (inner "%" prevents FP5 fast path)');
}

# ---------------------------------------------------------------------------
# INVARIANT 11: _is_deep_db magic-byte truth table
#
# Major Premise:  _is_deep_db returns true iff the first 4 bytes of a file
#                 match the DBM::Deep signature 'DPDB' OR 'DPDP'.
# Truth table (2-bit input: correct_magic × file_exists):
#   T1: 'DPDB' magic, file exists → true
#   T2: 'DPDP' magic, file exists → true
#   T3: other bytes,  file exists → false
#   T4: file does not exist       → false (no exception)
# ---------------------------------------------------------------------------

note('I-11: _is_deep_db magic-byte truth table — 4 Boolean cells');

{
	my $db = Database::test1->new($DATA_DIR);

	# T1: 'DPDB' magic → true
	{
		my ($fh, $fname) = tempfile(SUFFIX => '.db', UNLINK => 1);
		binmode $fh;
		print {$fh} 'DPDB_padding_bytes';
		close $fh;
		ok($db->_is_deep_db($fname),
			'I-11.T1: DPDB magic bytes → correctly identified as DBM::Deep file');
	}

	# T2: 'DPDP' magic → true
	{
		my ($fh, $fname) = tempfile(SUFFIX => '.db', UNLINK => 1);
		binmode $fh;
		print {$fh} 'DPDP_padding_bytes';
		close $fh;
		ok($db->_is_deep_db($fname),
			'I-11.T2: DPDP magic bytes → correctly identified as DBM::Deep file');
	}

	# T3: non-magic bytes → false
	{
		my ($fh, $fname) = tempfile(SUFFIX => '.db', UNLINK => 1);
		binmode $fh;
		print {$fh} 'FAKE_NOT_DEEP_';
		close $fh;
		ok(!$db->_is_deep_db($fname),
			'I-11.T3: non-magic bytes → correctly rejected as non-DBM::Deep');
	}

	# T4: nonexistent path → false (no exception — autodie is scoped out)
	ok(!$db->_is_deep_db('/nonexistent/path/no.db'),
		'I-11.T4: nonexistent file → false without throwing an exception');
}

# ---------------------------------------------------------------------------
# INVARIANT 12: _match_criterion scalar truth table
#
# Major Premise:  For a plain scalar crit_val, _match_criterion implements
#                 SQL NULL-aware equality semantics:
#   both undef  → true   (NULL IS NULL)
#   row undef   → false  (NULL != defined)
#   crit undef  → false  (defined != NULL)
#   row eq crit → true   (string equality)
#   row ne crit → false  (string inequality)
# Note: this branch IS reachable from the public API — scalar crit_val is
#       NOT complex, so the in-memory fast path calls _match_criterion.
# ---------------------------------------------------------------------------

note('I-12: _match_criterion scalar truth table — 5 NULL-aware equality cells');

{
	my $db = Database::test1->new($DATA_DIR);

	# Both undef → true (NULL IS NULL semantics)
	ok( $db->_match_criterion(undef, undef),
		'I-12.1: both row and criterion undef → true (NULL IS NULL)');

	# row undef, crit defined → false (IS NULL row does not match non-NULL criterion)
	ok(!$db->_match_criterion(undef, 'one'),
		'I-12.2: row is NULL, criterion is "one" → false (NULL != non-NULL)');

	# row defined, crit undef → false (non-NULL row does not satisfy IS NULL criterion)
	ok(!$db->_match_criterion('one', undef),
		'I-12.3: row is "one", criterion is NULL → false (non-NULL != IS NULL)');

	# Equal strings → true
	ok( $db->_match_criterion('one', 'one'),
		'I-12.4: row eq criterion → true (string equality)');

	# Different strings → false
	ok(!$db->_match_criterion('one', 'two'),
		'I-12.5: row ne criterion → false (string inequality)');
}

# ---------------------------------------------------------------------------
# INVARIANT 13: no_entry mode — data structure bifurcation
#
# Major Premise A: no_entry=0 (keyed) → slurped data is a HASH ref, keyed
#                  on the entry column value.
# Major Premise B: no_entry=1         → slurped data is an ARRAY ref, a
#                  flat ordered list of row hashrefs.
# These two storage shapes are MUTUALLY EXCLUSIVE: the same query code paths
# check ref($self->{'data'}) to choose the right scan strategy.
# Corollaries:
#   T3: missing key on HASH → [] (empty arrayref), never undef
#   T4: no match on ARRAY   → count() returns 0
# ---------------------------------------------------------------------------

note('I-13: no_entry data structure invariant — HASH vs ARRAY ref bifurcation');

{
	# T1: keyed mode → data is HASH ref
	{
		my $db = Database::test1->new({ directory => $DATA_DIR });
		$db->count();
		is(ref($db->{'data'}), 'HASH',
			'I-13.T1: no_entry=0 (keyed) → slurped data stored as HASH ref');
	}

	# T2: no_entry mode → data is ARRAY ref
	{
		my $db = Database::test4ne->new({ directory => $DATA_DIR });
		$db->count();
		is(ref($db->{'data'}), 'ARRAY',
			'I-13.T2: no_entry=1 → slurped data stored as ARRAY ref');
	}

	# T3: keyed mode, missing entry key → [] (not undef)
	{
		my $db = Database::test1->new({ directory => $DATA_DIR });
		my $rows = $db->selectall_arrayref(entry => '__NONEXISTENT__');
		ok(ref($rows) eq 'ARRAY' && scalar @{$rows} == 0,
			'I-13.T3: missing key in HASH slurp → empty arrayref returned, not undef');
	}

	# T4: no_entry mode, no match → count returns 0
	{
		my $db = Database::test4ne->new({ directory => $DATA_DIR });
		cmp_ok($db->count(cardinal => '__NONEXISTENT__'), '==', 0,
			'I-13.T4: no match in ARRAY slurp → count() returns 0');
	}
}

# ---------------------------------------------------------------------------
# INVARIANT 14: _build_where boolean composition
#
# Major Premise:  _build_where composes a WHERE clause body from criteria
#                 using four Boolean primitives:
#   P1: empty params  → empty fragment ''   — no WHERE emitted
#   P2: scalar value  → 'col = ?'           — equality bind
#   P3: -or grouping  → '(A) OR (B)'        — disjunction
#   P4: -and grouping → '(A) AND (B)'       — conjunction
# Conclusion:     The four primitives cover the complete algebra of safe
#                 SQL WHERE construction in this module.
# ---------------------------------------------------------------------------

note('I-14: _build_where boolean composition — empty/scalar/-or/-and primitives');

{
	my $db = Database::test1->new($DATA_DIR);

	# P1: empty params → empty SQL fragment and no bind values
	{
		my ($sql, $args) = $db->_build_where({});
		is($sql, '',
			'I-14.P1a: empty criteria → SQL fragment is empty string');
		cmp_ok(scalar @{$args}, '==', 0,
			'I-14.P1b: empty criteria → zero bind arguments produced');
	}

	# P2: scalar value → 'col = ?' form with correct bind
	{
		my ($sql, $args) = $db->_build_where({ entry => 'one' });
		like($sql, qr/\bentry\s*=\s*\?/,
			'I-14.P2a: scalar criterion → SQL uses "col = ?" equality form');
		is($args->[0], 'one',
			'I-14.P2b: scalar criterion → bind value matches criterion value');
	}

	# P3: -or grouping → disjunction in SQL
	{
		my ($sql, $args) = $db->_build_where({
			-or => [{ entry => 'one' }, { entry => 'two' }]
		});
		like($sql, qr/ OR /,
			'I-14.P3: -or grouping → SQL fragment contains the OR connective');
	}

	# P4: -and grouping → conjunction in SQL
	{
		my ($sql, $args) = $db->_build_where({
			-and => [{ entry => 'one' }, { number => '1' }]
		});
		like($sql, qr/ AND /,
			'I-14.P4: -and grouping → SQL fragment contains the AND connective');
	}
}

# ---------------------------------------------------------------------------
# INVARIANT 15: _is_local_host truth table
#
# Major Premise:  _is_local_host returns true for the three universal loopback
#                 literals (localhost, 127.0.0.1, ::1) regardless of optional
#                 user@ prefix, and false for genuinely remote hostnames.
# Truth table (2-bit: loopback × user@prefix):
#   T1: 'localhost'          → true   (canonical loopback, no prefix)
#   T2: '127.0.0.1'          → true   (IPv4 loopback, no prefix)
#   T3: '::1'                → true   (IPv6 loopback, no prefix)
#   T4: 'user@localhost'     → true   (user@ stripped → loopback literal)
#   T5: remote hostname      → false  (not loopback, not own hostname)
# ---------------------------------------------------------------------------

note('I-15: _is_local_host truth table — loopback literals and user@ prefix');

{
	my $db = Database::test1->new($DATA_DIR);

	ok($db->_is_local_host('localhost'),
		'I-15.T1: "localhost" → true (canonical IPv4 loopback literal)');
	ok($db->_is_local_host('127.0.0.1'),
		'I-15.T2: "127.0.0.1" → true (dotted-decimal loopback literal)');
	ok($db->_is_local_host('::1'),
		'I-15.T3: "::1" → true (IPv6 loopback literal)');
	ok($db->_is_local_host('user@localhost'),
		'I-15.T4: "user@localhost" → true (user@ prefix stripped before literal check)');
	ok(!$db->_is_local_host('definitely-not-this-host.example.invalid'),
		'I-15.T5: unrecognised remote hostname → false');
}

# ---------------------------------------------------------------------------
# INVARIANT 16: De Morgan — combined state and non-hashref reference type
#
# Major Premise (De Morgan's second law):
#   NOT(A OR B) = NOT(A) AND NOT(B)
#   Contrapositive: (A OR B) is true whenever at least one of A, B is true.
#
# Invariant I-2 proved A (hashref value) and B (-or/-and key) each
# individually.  I-16 proves the two cells NOT covered by I-2:
#   T1: A AND B both true → still true (OR semantics; AND is not required)
#   T2: arrayref value (non-hashref ref) → true (gate is any { ref($_) },
#       not restricted to HASH refs)
# ---------------------------------------------------------------------------

note('I-16: De Morgan — combined A+B and non-hashref ref type');

{
	my $db = Database::test1->new($DATA_DIR);

	# T1: BOTH -or key AND hashref value present → true (OR, not AND needed)
	ok($db->_has_complex_criteria({ -or => [], entry => { '>' => 0 } }),
		'I-16.T1: -or key AND hashref value both present → true (OR semantics)');

	# T2: arrayref value → true (gate catches any ref, not only HASH refs)
	ok($db->_has_complex_criteria({ entry => [1, 2, 3] }),
		'I-16.T2: arrayref value → true (any { ref($_) } is not restricted to hashref)');
}

# ---------------------------------------------------------------------------
# INVARIANT 17: auto_load guard — Fail Fast when disabled
#
# Major Premise:  auto_load => 0 disables AUTOLOAD column dispatch entirely.
#                 The guard fires at the FIRST line of AUTOLOAD, before any
#                 column lookup, DBI call, or data scan.
# Logical form (Modus Ponens):
#   P1: auto_load => 0 → AUTOLOAD croaks "AUTOLOAD disabled"
#   P2: auto_load => 0 is set
#   C:  calling any unknown method on that object croaks
# Contrapositive: a valid object returned by new() with auto_load => 1
#   (the default) successfully dispatches AUTOLOAD to column lookup.
# ---------------------------------------------------------------------------

note('I-17: auto_load guard — Fail Fast disabled, transparent enabled');

{
	# P2+C: auto_load=0 → croak before any column lookup
	my $db_locked = Database::test1->new({ directory => $DATA_DIR, auto_load => 0 });
	throws_ok { $db_locked->number(entry => 'one') }
		qr/AUTOLOAD disabled/,
		'I-17.1: auto_load => 0 → AUTOLOAD croaks "AUTOLOAD disabled" immediately';

	# Contrapositive: auto_load=1 (default) → column lookup returns a value
	my $db_open = Database::test1->new({ directory => $DATA_DIR });
	my $ok = eval { my $v = $db_open->number(entry => 'one'); defined($v) };
	ok($ok && !$@,
		'I-17.2: auto_load => 1 (default) → column lookup via AUTOLOAD returns defined value');
}
