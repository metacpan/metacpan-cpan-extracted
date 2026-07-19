#!/usr/bin/env perl

# t/edge_cases.t — destructive, boundary-condition, and security subtests
# designed to actively break or subvert Date::Cmp::datecmp.
#
# Strategy:
#   • Hostile inputs:  undef, "", 0, scalar/array/code/glob refs, circular
#                      objects, 5-digit years, binary data, Unicode, long strings
#   • State abuse:     list vs scalar context, $_ and $@ mutation
#   • Security:        injection attempts, non-coderef $complain callbacks
#   • DFG failure:     mock DFG returning undef / dying to verify propagation
#   • Singleton:       repeated calls must not corrupt the shared $dfg instance

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Test::Mockingbird qw(mock restore_all);
use Scalar::Util qw(blessed);

use Date::Cmp qw(datecmp);

# ─── helper packages ─────────────────────────────────────────────────────────

# A well-behaved record object used as a positive control in object tests
package FakeRecord;
sub new  { bless { date => $_[1] }, $_[0] }
sub date { $_[0]->{date} }

# A blessed object that exposes NO date() method — should die after Fix 2
package FakeRecord::NoDate;
sub new  { bless {}, $_[0] }

# A blessed object whose date() returns undef — after Fix 1 datecmp returns 0
package FakeRecord::UndefDate;
sub new  { bless {}, $_[0] }
sub date { undef }

# A blessed object whose date() method dies — exception must propagate
package FakeRecord::DyingDate;
sub new  { bless {}, $_[0] }
sub date { die "date() method exploded\n" }

# A blessed object whose date() returns itself (circular) — rejected by Fix 2
package FakeRecord::SelfReturn;
sub new  { bless {}, $_[0] }
sub date { $_[0] }

# Mock DFG that always returns an empty list → triggers "Date parse failure"
package MockDFG::Empty;
sub new            { bless {}, $_[0] }
sub parse_datetime { return () }

# Mock DFG that returns a blessed object with NO year() method
package FakeDateTime::NoYear;
use overload '""' => sub { 'FAKEYEAR' }, fallback => 1;
sub new { bless {}, $_[0] }

package MockDFG::NoYear;
sub new            { bless {}, $_[0] }
sub parse_datetime { return FakeDateTime::NoYear->new() }

# Mock DFG that itself dies
package MockDFG::Dying;
sub new            { bless {}, $_[0] }
sub parse_datetime { die "DFG exploded\n" }

# ─── main ────────────────────────────────────────────────────────────────────

package main;

# ─────────────────────────────────────────────────────────────────────────────
# §1  Smoke: module loads and basic contract holds
# ─────────────────────────────────────────────────────────────────────────────
subtest 'smoke — basic three-way returns' => sub {
	is(datecmp('1900', '1950'), -1, '1900 < 1950 → -1');
	is(datecmp('1950', '1900'),  1, '1950 > 1900 → 1');
	is(datecmp('1900', '1900'),  0, '1900 == 1900 → 0');

	returns_ok(datecmp('1900', '1950'), { type => 'integer' }, 'return is integer');
	returns_ok(datecmp('1950', '1900'), { type => 'integer' }, 'return is integer');
	returns_ok(datecmp('1900', '1900'), { type => 'integer' }, 'return is integer');
};

# ─────────────────────────────────────────────────────────────────────────────
# §2  Undef inputs (documented: return 0, print STDERR)
# ─────────────────────────────────────────────────────────────────────────────
subtest 'undef inputs return 0 per POD' => sub {
	my $r;

	$r = datecmp(undef, '1900');
	is($r, 0, 'undef left → 0');
	returns_ok($r, { type => 'integer' }, 'undef left → integer');

	$r = datecmp('1900', undef);
	is($r, 0, 'undef right → 0');

	$r = datecmp(undef, undef);
	is($r, 0, 'both undef → 0');
};

# ─────────────────────────────────────────────────────────────────────────────
# §3  Empty-string inputs
# ─────────────────────────────────────────────────────────────────────────────
subtest 'empty-string inputs' => sub {
	# Both empty strings are equal → early-exit returning 0
	is(datecmp('', ''), 0, 'two empty strings are "equal" (both invalid, both eq)');

	# One empty string fails the [A-S0-9] character check → die
	throws_ok { datecmp('', '1900') }
		qr/Date parse failure/,
		'empty left with valid right dies';

	throws_ok { datecmp('1900', '') }
		qr/Date parse failure/,
		'valid left with empty right dies';
};

# ─────────────────────────────────────────────────────────────────────────────
# §4  Hashref degenerate cases  (Fix 1 — post-normalisation undef guard)
# ─────────────────────────────────────────────────────────────────────────────
subtest 'hashref with missing / undef date key returns 0' => sub {
	# {} → $left = $href->{date} = undef → post-normalisation guard → return 0
	is(datecmp({}, '1900'), 0, 'empty hashref left → 0');
	is(datecmp('1900', {}), 0, 'empty hashref right → 0');
	is(datecmp({}, {}),     0, 'both empty hashrefs → 0');

	is(datecmp({ date => undef }, '1900'), 0, 'hashref{date=>undef} left → 0');
	is(datecmp('1900', { date => undef }), 0, 'hashref{date=>undef} right → 0');

	# A hashref with a valid date key must still work
	is(datecmp({ date => '1900' }, '1950'), -1, 'hashref{date=>"1900"} < "1950"');
	is(datecmp('1900', { date => '1950' }), -1, '"1900" < hashref{date=>"1950"}');
};

# ─────────────────────────────────────────────────────────────────────────────
# §5  Unsupported reference types  (Fix 2 — ref-rejection guard)
# Without Fix 2 these silently stringify to addresses and produce garbage.
# ─────────────────────────────────────────────────────────────────────────────
subtest 'unsupported reference types die with clear message' => sub {
	my $scalarref = \1900;
	throws_ok { datecmp($scalarref, '1900') }
		qr/Date parse failure.*unsupported reference type/i,
		'scalar ref left dies';

	throws_ok { datecmp('1900', $scalarref) }
		qr/Date parse failure.*unsupported reference type/i,
		'scalar ref right dies';

	throws_ok { datecmp([1900], '1900') }
		qr/Date parse failure.*unsupported reference type/i,
		'array ref left dies';

	throws_ok { datecmp('1900', [1900]) }
		qr/Date parse failure.*unsupported reference type/i,
		'array ref right dies';

	throws_ok { datecmp(sub { 1900 }, '1900') }
		qr/Date parse failure.*unsupported reference type/i,
		'code ref left dies';

	# Typeglob ref — stringifies to 'GLOB(0x…)' which starts with 'G' < 'S'
	# so it would pass the [A-S0-9] char check and be silently mishandled.
	throws_ok { datecmp(\*STDOUT, '1900') }
		qr/Date parse failure.*unsupported reference type/i,
		'typeglob ref left dies';
};

# ─────────────────────────────────────────────────────────────────────────────
# §6  Object edge cases
# ─────────────────────────────────────────────────────────────────────────────
subtest 'object with well-behaved date() method' => sub {
	my $obj = FakeRecord->new('1900');
	is(datecmp($obj, '1950'), -1, 'object->date() = "1900" < "1950"');
	is(datecmp('1950', $obj), 1,  '"1950" > object->date() = "1900"');
	is(datecmp($obj, $obj),   0,  'same object compared to itself → 0');
};

subtest 'object with NO date() method is rejected after Fix 2' => sub {
	my $obj = FakeRecord::NoDate->new();
	throws_ok { datecmp($obj, '1900') }
		qr/Date parse failure.*unsupported reference type/i,
		'blessed object without date() dies';
};

subtest 'object whose date() returns undef → 0 after Fix 1' => sub {
	my $obj = FakeRecord::UndefDate->new();
	is(datecmp($obj, '1900'), 0, 'object->date() = undef left → 0');
	is(datecmp('1900', $obj), 0, 'object->date() = undef right → 0');
};

subtest 'object whose date() dies — exception propagates' => sub {
	my $obj = FakeRecord::DyingDate->new();
	throws_ok { datecmp($obj, '1900') }
		qr/date\(\) method exploded/,
		'dying date() propagates exception for left';
	throws_ok { datecmp('1900', $obj) }
		qr/date\(\) method exploded/,
		'dying date() propagates exception for right';
};

subtest 'circular object — date() returns self — rejected by Fix 2' => sub {
	my $obj = FakeRecord::SelfReturn->new();
	throws_ok { datecmp($obj, '1900') }
		qr/Date parse failure.*unsupported reference type/i,
		'circular date() return is rejected';
};

# ─────────────────────────────────────────────────────────────────────────────
# §7  Year digit-count boundary values
# ─────────────────────────────────────────────────────────────────────────────
subtest 'year digit boundaries' => sub {
	# 1-digit: does not satisfy /\d{3,4}/ → falls through to die
	throws_ok { datecmp('1', '2') }
		qr/Date parse failure/,
		'1-digit year dies';

	# 2-digit: same — not a valid genealogy year
	throws_ok { datecmp('19', '20') }
		qr/Date parse failure/,
		'2-digit year dies';

	# 3-digit: valid
	is(datecmp('100', '101'), -1, '3-digit years: 100 < 101');
	is(datecmp('999', '998'),  1, '3-digit years: 999 > 998');
	is(datecmp('500', '500'),  0, '3-digit years: 500 == 500');

	# 4-digit: valid (standard genealogy year)
	is(datecmp('1066', '1215'), -1, '4-digit: 1066 < 1215');
	is(datecmp('9999', '0001'),  1, '4-digit: 9999 > 0001');

	# 5-digit standalone integer: Fix 3 — rejects before the fast-path can
	# silently extract the wrong 4-digit substring (10000 would give 1000).
	throws_ok { datecmp('10000', '9999') }
		qr/Date parse failure.*year must be 3-4 digits/,
		'5-digit left year dies';

	throws_ok { datecmp('9999', '10000') }
		qr/Date parse failure.*year must be 3-4 digits/,
		'5-digit right year dies';

	# Very large standalone integer
	throws_ok { datecmp('99999999', '1900') }
		qr/Date parse failure/,
		'8-digit standalone integer dies';

	diag '5-digit year guard prevents silent year extraction from "10000" as 1000'
		if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# §8  First-character charset boundary ([A-S0-9] with /i flag)
# Letters A–S and digits 0–9 are accepted; T–Z (and non-ASCII) are rejected.
# ─────────────────────────────────────────────────────────────────────────────
subtest 'first-character charset [A-S0-9] boundary' => sub {
	# Letters inside the range (last valid: 'S' / 's')
	lives_ok { datecmp('Sep 1900', '1950') }  'S — valid first char (Sep)';
	lives_ok { datecmp('Abt 1900', '1950') }  'A — valid first char (Abt)';
	lives_ok { datecmp('BEF 1900', '1950') }  'B — valid first char (BEF)';

	# First letter OUTSIDE range — T, U, V, W, X, Y, Z all die
	for my $letter (qw(T U V W X Y Z t u v w x y z)) {
		throws_ok { datecmp("${letter}1900", '1950') }
			qr/Date parse failure/,
			"'$letter' as first char is rejected";
	}

	# Special characters rejected at first position
	for my $ch (';', '`', '$', '!', ' ', "\t", '-', '+') {
		throws_ok { datecmp("${ch}1900", '1950') }
			qr/Date parse failure/,
			"'$ch' as first char is rejected";
	}

	# Digit range — all of 0-9 pass
	for my $digit (0..9) {
		# Use 3-4 digit years to avoid the single-digit-year die
		lives_ok { datecmp("${digit}000", '1000') }
			"digit '$digit' as first char is accepted (${digit}000)";
	}
};

# ─────────────────────────────────────────────────────────────────────────────
# §9  Very long strings (resource / DoS resistance)
# Must complete in under 5 seconds and not hang.
# ─────────────────────────────────────────────────────────────────────────────
subtest 'very long strings — must not hang or exhaust memory' => sub {
	use Time::HiRes qw(time);

	# A string starting with 'A' (valid char) followed by 100 000 'x' chars,
	# then a year.  The lazy regex (.+?)\s?\?$ in the '?' stripper is O(n);
	# verify there is no catastrophic backtracking.
	my $long_no_question = 'A' . ('x' x 100_000) . ' 1900';
	my $t0 = time();
	eval { datecmp($long_no_question, '1950') };
	my $elapsed = time() - $t0;
	ok($elapsed < 5, "long string without '?' at end completes in ${elapsed}s (<5s)");
	diag "long string without '?': elapsed ${elapsed}s" if $ENV{TEST_VERBOSE};

	# A string with a '?' at the end exercises the (.+?)\s?\?$ branch differently.
	my $long_with_question = 'A' . ('x' x 100_000) . ' 1900 ?';
	$t0 = time();
	eval { datecmp($long_with_question, '1950') };
	$elapsed = time() - $t0;
	ok($elapsed < 5, "long string with '?' at end completes in ${elapsed}s (<5s)");
	diag "long string with '?': elapsed ${elapsed}s" if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# §10  Control characters and binary data
# ─────────────────────────────────────────────────────────────────────────────
subtest 'control characters and binary data' => sub {
	# Tab as first char — not in [A-S0-9] → die
	throws_ok { datecmp("\t1900", '1950') }
		qr/Date parse failure/, 'tab as first char dies';

	# Null byte embedded after a valid first char.  The year fast-path may
	# extract 1900 and return without hitting DFG, so we only assert no CRASH.
	eval { datecmp("1900\x00extra", '1901') };
	pass('null byte embedded — no crash');

	# Pure binary junk — first byte likely not in [A-S0-9] → die
	throws_ok { datecmp("\x01\x02\x03", '1950') }
		qr/Date parse failure/, 'binary junk dies';
};

# ─────────────────────────────────────────────────────────────────────────────
# §11  Unicode inputs
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Unicode inputs are rejected at the char check' => sub {
	# Smiley (U+263A) as first character — not in [A-S0-9] → die
	throws_ok { datecmp("\x{263A}1900", '1950') }
		qr/Date parse failure/, 'Unicode smiley as first char dies';

	# Latin-1 supplement  (e.g. é U+00E9) — not in [A-S0-9] → die
	throws_ok { datecmp("\x{00E9}1900", '1950') }
		qr/Date parse failure/, 'Latin-1 é as first char dies';

	# Wide character mid-string, valid first char — no crash
	eval { datecmp("A\x{4E2D}1900", '1901') };
	pass('Unicode mid-string — no crash');
};

# ─────────────────────────────────────────────────────────────────────────────
# §12  Non-coderef $complain callback
# The security fix validates $complain eagerly for truthy non-CODE values.
# Falsy values (undef, 0) are still accepted — they can never be invoked
# since every call site guards with "if($complain)".
# ─────────────────────────────────────────────────────────────────────────────
subtest 'non-coderef $complain — dies when invalid' => sub {
	# Integer 42 — truthy, not a CODE ref.  Eager validation fires before any
	# range processing, reporting "CODE reference" in the error message.
	throws_ok { datecmp('1900-1900', '1950', 42) }
		qr/CODE reference/i,
		'integer $complain dies at input validation';

	# Arrayref — truthy, wrong ref type; same eager check fires.
	throws_ok { datecmp('1900-1900', '1950', []) }
		qr/CODE reference/i,
		'arrayref $complain dies at input validation';

	# Undef — falsy, validation is skipped, never invoked
	lives_ok { datecmp('1900-1900', '1950', undef) }
		'undef $complain is safe — falsy skips validation and guard prevents call';

	# 0 (false) — also falsy; validation skipped, never invoked
	lives_ok { datecmp('1900-1900', '1950', 0) }
		'false $complain is safe — falsy skips validation and guard prevents call';

	# Valid coderef — normal operation
	my $called = 0;
	datecmp('1900-1900', '1950', sub { $called++ });
	ok($called > 0, 'valid coderef $complain is invoked for from==to range');
};

# ─────────────────────────────────────────────────────────────────────────────
# §13  Context sensitivity
# ─────────────────────────────────────────────────────────────────────────────
subtest 'context sensitivity' => sub {
	# Scalar context — the normal use case
	my $s = datecmp('1900', '1950');
	is($s, -1, 'scalar context returns -1');

	# List context — datecmp returns a single value; captured as 1-elem list
	my @list = datecmp('1900', '1950');
	is(scalar(@list), 1,  'list context: one element');
	is($list[0],     -1,  'list context: element value is -1');

	# Void context — must not crash
	lives_ok { datecmp('1900', '1950') } 'void context — no crash';
};

# ─────────────────────────────────────────────────────────────────────────────
# §14  Global state — $_, $@, $! must not be clobbered
# ─────────────────────────────────────────────────────────────────────────────
subtest 'global state preservation' => sub {
	# $_ must survive a fast-path call
	{
		local $_ = 'original-default';
		datecmp('1900', '1901');
		is($_, 'original-default', '$_ not clobbered by fast-path call');
	}

	# $@ must survive a fast-path call (no eval inside datecmp for this path)
	{
		local $@;
		eval { die "sentinel error\n" };
		my $saved = $@;
		datecmp('1900', '1901');   # different years → fast-path, no DFG
		is($@, $saved, '$@ not clobbered by fast-path datecmp');
	}

	# $! (errno) — calls that never touch system calls must not alter it
	{
		# trigger a known errno
		open(my $fh, '<', '/nonexistent/path/for/testing') or do {
			my $saved_errno = $!;
			datecmp('1900', '1901');
			is("$!", "$saved_errno", '$! not clobbered by fast-path datecmp');
		};
	}
};

# ─────────────────────────────────────────────────────────────────────────────
# §15  Code / shell injection patterns — no code execution
# The module never calls eval{} on user input or system(); injected strings
# must be treated as data or rejected by the char check.
# ─────────────────────────────────────────────────────────────────────────────
subtest 'injection patterns are rejected or treated as data' => sub {
	# Shell metacharacters as first char → char-check die (safe rejection)
	throws_ok { datecmp('$(rm -rf /)', '1900') }
		qr/Date parse failure/, 'shell $() prefix rejected';

	throws_ok { datecmp('`id`', '1900') }
		qr/Date parse failure/, 'backtick prefix rejected';

	throws_ok { datecmp('; echo pwned', '1900') }
		qr/Date parse failure/, 'semicolon prefix rejected';

	# Injection after a valid year prefix — the taint-scrubbing charset rejects
	# ';', '(', ')', '"' which appear in the injection payload, so this now
	# dies at the charset check rather than being silently extracted as year 1900.
	throws_ok { datecmp('1900 ; system("ls")', '1901') }
		qr/Date parse failure/,
		'injected system() call rejected at charset check';

	# Perl string interpolation attempt — '$', '{', '\', '}' not in allowed
	# charset; rejected before any evaluation can occur.
	throws_ok { datecmp('1900 ${\ die "injected" }', '1901') }
		qr/Date parse failure/,
		'Perl interpolation attempt rejected at charset check';

	diag 'injection tests confirm no eval on user input' if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# §16  DFG pathological returns — mocked via local $Date::Cmp::dfg
# ─────────────────────────────────────────────────────────────────────────────
subtest 'DFG returning empty list → Date parse failure' => sub {
	local $Date::Cmp::dfg = MockDFG::Empty->new();
	# Two same-year dates force the fast-paths to fall through to DFG.
	throws_ok { datecmp('1 Jan 1900', '2 Feb 1900') }
		qr/Date parse failure.*left/i,
		'DFG returning empty list causes die with Date parse failure';
};

subtest 'DFG dying internally — exception propagates' => sub {
	local $Date::Cmp::dfg = MockDFG::Dying->new();
	throws_ok { datecmp('1 Jan 1900', '2 Feb 1900') }
		qr/DFG exploded/,
		'DFG die propagates out of datecmp';
};

subtest 'DFG returning object without year() → dies on ->year() call' => sub {
	local $Date::Cmp::dfg = MockDFG::NoYear->new();
	# Left is a complex date (same year as right) so fast-paths all fall
	# through to DFG.  Right is a bare 4-digit year, which is handled by the
	# "/^\d{3,4}$/" branch: "if(ref($left)) { return $left->year() <=> $right }".
	# FakeDateTime::NoYear has no year() method → dies.
	throws_ok { datecmp('1 Jan 1900', '1900') }
		qr/Can't locate object method "year"/,
		'DFG returning no-year object causes ->year() die';
};

# ─────────────────────────────────────────────────────────────────────────────
# §17  Singleton stability — many rapid calls must not corrupt shared $dfg
# ─────────────────────────────────────────────────────────────────────────────
subtest 'singleton $dfg is stable across many calls' => sub {
	my @pairs = (
		['1900', '1950', -1],
		['1950', '1900',  1],
		['1900', '1900',  0],
		['100',  '200',  -1],
		['BET 1830 AND 1832', '1831', 0],
		['Abt 1900', '1905', -1],
	);

	for my $iter (1..20) {
		for my $p (@pairs) {
			my ($l, $r, $expected) = @$p;
			is(datecmp($l, $r), $expected,
				"iter $iter: datecmp('$l','$r') = $expected");
		}
	}
};

# ─────────────────────────────────────────────────────────────────────────────
# §18  Numeric (non-string) scalar inputs
# Perl scalars are dual-valued; passing raw integers must work identically
# to passing their string representations.
# ─────────────────────────────────────────────────────────────────────────────
subtest 'numeric scalars work like their string equivalents' => sub {
	is(datecmp(1900, 1950),   -1, 'numeric 1900 < 1950');
	is(datecmp(1950, 1900),    1, 'numeric 1950 > 1900');
	is(datecmp(1900, 1900),    0, 'numeric 1900 == 1900');
	is(datecmp(0,    0),       0, 'numeric 0 == 0 (both equal → 0)');

	# Single-digit numeric: dies (1-digit fails char path eventually)
	throws_ok { datecmp(1, 2) }
		qr/Date parse failure/,
		'numeric 1-digit integers die';
};

# ─────────────────────────────────────────────────────────────────────────────
# §19  Range degenerate edge cases (from==to, from>to, boundary membership)
# ─────────────────────────────────────────────────────────────────────────────
subtest 'range edge cases' => sub {
	# from == to with complain callback
	{
		my $msg = '';
		datecmp('1900-1900', '1900', sub { $msg = $_[0] });
		like($msg, qr/from == to|years are the same/i,
			'from==to on left triggers $complain');
	}

	# from > to on left — inverted range: $complain called, returns 0
	{
		my $warned = 0;
		my $r = datecmp('1902-1900', '1901', sub { $warned++ });
		is($r, 0, 'inverted left range returns 0');
		ok($warned, 'inverted left range triggers $complain');
	}

	# from > to on right — inverted range: no $complain but still returns 0
	{
		my $r = datecmp('1901', '1902-1900');
		is($r, 0, 'inverted right range returns 0');
	}

	# BET range: value inside range → 0
	is(datecmp('BET 1900 AND 1910', '1905'), 0, 'value inside BET range → 0');

	# BET range: value below lower bound → 1 (left range is later)
	is(datecmp('BET 1900 AND 1910', '1895'), 1, 'value below BET range → 1');

	# BET range: value above upper bound → -1
	is(datecmp('BET 1900 AND 1910', '1915'), -1, 'value above BET range → -1');

	# BET range on right, value inside → 0
	is(datecmp('1905', 'BET 1900 AND 1910'), 0, 'value inside right BET range → 0');

	# OR range: different years → uses the start year
	is(datecmp('1900 or 1901', '1902'), -1, '"1900 or 1901" left < 1902');

	# OR range: both years equal triggers $complain.
	# Right must also be 1900 so the year fast-paths (which fire when
	# lyear != ryear) are bypassed and execution reaches the 'or' handler.
	{
		my $warned = 0;
		datecmp('1900 or 1900', '1900', sub { $warned++ });
		ok($warned, '"1900 or 1900" triggers $complain when right is same year');
	}
};

# ─────────────────────────────────────────────────────────────────────────────
# §20  Symmetric property: datecmp(a,b) == -datecmp(b,a) for distinct years
# ─────────────────────────────────────────────────────────────────────────────
subtest 'anti-symmetry: datecmp(a,b) == -datecmp(b,a)' => sub {
	my @samples = (
		['1800', '1900'],
		['100',  '999' ],
		['Abt 1850', '1855'],
		['BEF 1900', '1950'],
	);
	for my $pair (@samples) {
		my ($a, $b) = @$pair;
		my $ab = eval { datecmp($a, $b) };
		my $ba = eval { datecmp($b, $a) };
		next if $@ || !defined($ab) || !defined($ba);
		is($ab, -$ba, "datecmp('$a','$b') == -datecmp('$b','$a')");
	}
};

done_testing();
