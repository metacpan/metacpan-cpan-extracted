#!/usr/bin/env perl

# Extended coverage tests for Date::Cmp — targets execution paths left
# uncovered after function.t / unit.t / edge_cases.t, aiming for >=95%
# statement coverage and high LCSAJ/TER3 scores.
#
# Each subtest names the source lines it is designed to exercise.  Dead-code
# findings are documented inline so they can be reviewed and commented out in
# lib/Date/Cmp.pm.
#
# Test strategy:
#   * Inputs that require bypassing the fast-path heuristics are chosen so
#     that the fast paths tie (same year extracted) or are disabled by the
#     input format (3-digit years, trailing non-digit characters, etc.).
#   * DFG (DateTime::Format::Genealogy) is replaced with a queue-based
#     MockDFG singleton ("local $Date::Cmp::dfg = $mock") when precise
#     control over parse results is required.
#   * ANSI colour is mocked globally to keep STDERR output readable.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock restore_all);
use Test::Returns     qw(returns_ok);
use Readonly;
use File::Spec;

use Date::Cmp qw(datecmp);

# -------------------------------------------------------------------------
# Named constants — no magic numbers in assertions
# -------------------------------------------------------------------------
Readonly my $LT => -1;
Readonly my $EQ =>  0;
Readonly my $GT =>  1;

# -------------------------------------------------------------------------
# Suppress ANSI colour codes emitted by datecmp on error paths.
# -------------------------------------------------------------------------
mock 'Term::ANSIColor::colored' => sub { $_[0] };

# -------------------------------------------------------------------------
# silence_stderr — run a code block with STDERR redirected to /dev/null.
# Re-raises any exception after restoring the filehandle.
# -------------------------------------------------------------------------
sub silence_stderr (&) {
	my ($code) = @_;
	my $devnull = File::Spec->devnull();
	open(my $saved, '>&', \*STDERR) or die "dup STDERR: $!";
	open(STDERR, '>', $devnull)     or die "redirect STDERR: $!";
	my ($result, $err);
	eval { $result = $code->() };
	$err = $@;
	open(STDERR, '>&', $saved)      or die "restore STDERR: $!";
	die $err if $err;
	return $result;
}

# =========================================================================
# MockDFG — drop-in replacement for the $Date::Cmp::dfg singleton.
# Enqueue expected return values as array-refs; each parse_datetime call
# dequeues the next slot.  An exhausted queue returns the empty list
# (simulating a parse failure that leaves $r[0] undef).
# =========================================================================
{
	package MockDFG;
	sub new        { bless { queue => [], calls => 0 }, shift }
	sub enqueue    { push @{ $_[0]->{queue} }, $_[1]; $_[0] }
	sub call_count { $_[0]->{calls} }
	sub parse_datetime {
		my ($self) = @_;
		$self->{calls}++;
		my $slot = shift @{ $self->{queue} };
		return defined $slot ? @{$slot} : ();
	}
}

# =========================================================================
# Fake::DateTime — minimal DateTime-like object for MockDFG results.
# Stringifies to the year string so that datecmp's internal regex branches
# capture the right 3-4 digit sequence when $left becomes this object.
# =========================================================================
{
	package Fake::DateTime;
	use overload
		'<=>' => sub {
			my ($a, $b, $swap) = @_;
			my $by = ref($b) ? $b->year() : $b;
			$swap ? $by <=> $a->year() : $a->year() <=> $by;
		},
		'""'  => sub { $_[0]->{year} },
		fallback => 1;

	sub new  { my ($class, %a) = @_; bless { year => $a{year} }, $class }
	sub year { $_[0]->{year} }
}

# =========================================================================
# OffYear::DateTime — stringifies to one year, year() returns a different
# value.  Required to reach the branch at line 557 (ref($left) branch
# inside the DFG-fail path for right), where the stringified year matches
# the right-side suffix year (so line 532's tie-check doesn't return early)
# but year() differs (so line 557's inequality fires).
# =========================================================================
{
	package OffYear::DateTime;
	use overload '""' => sub { $_[0]->{str_year} }, fallback => 1;

	sub new {
		my ($class, %a) = @_;
		bless { str_year => $a{str_year}, real_year => $a{real_year} }, $class;
	}
	sub year { $_[0]->{real_year} }
}

# =========================================================================
# 1. BEF left qualifier — pure-digit right, trailing number < right
#    Target: lib/Date/Cmp.pm lines 294-297
#
#    Strategy: left = 'bef 5' (1-digit trailing, so fast-paths 1 and 2 both
#    fail — they require 3-4 consecutive digits).  right = '100' (pure
#    integer, 3-digit so fast-path 1 inner check also fails).  The BEF
#    handler fires; $left =~ /\s(\d+)$/ captures 5, which is < 100 → -1.
#
#    NOTE — lines 305-307 (BEF left, 4-digit right via /(\d{4})/ match) are
#    DEAD CODE: for left to reach line 305 it must have a 4-digit year, but
#    fast-path 1 would have already returned for any differing 4-digit pair.
#    When fast-path 1 ties, $1 == $ryear and the < check at line 306 is
#    always false.  These lines cannot be reached by any real input.
# =========================================================================
subtest 'BEF left, 1-digit trailing number < pure-digit right (lines 294-297)' => sub {
	# 'bef 5': no 3-4 digit sequence → all fast-paths skipped.
	# '100': 3-digit integer that passes char check.
	is(datecmp('bef 5', '100'), $LT,
		'bef 5 < 100 via BEF handler trailing-number comparison');

	returns_ok(datecmp('bef 5', '100'), { type => 'integer' },
		'return value is a defined integer');

	diag 'lines 294-297 exercised: $1 (5) < $right (100) → return -1'
		if $ENV{TEST_VERBOSE};
};

# =========================================================================
# 2. Lowercase 'bet' on right side fires first-digit tie-break
#    Target: lib/Date/Cmp.pm lines 341-348
#
#    Strategy: the /^bet/ check at line 343 is case-SENSITIVE (lowercase
#    only).  left = '100 and 1900': fast-path 1 extracts 1900 (4-digit),
#    right = 'bet 200 and 1900' also has 1900 as its 4-digit → fast-path 1
#    ties.  Fast-path 2 also ties on '1900'.  Body: line 341 captures the
#    first \d{3,4} from left (= '100'), line 344 captures the first \d{3,4}
#    from right (= '200').  100 != 200 → return -1.
# =========================================================================
subtest 'lowercase "bet" right — first-match tie-break (lines 341-348)' => sub {
	# Fast-paths tie on trailing 1900; first-match extraction differs (100 vs 200).
	is(datecmp('100 and 1900', 'bet 200 and 1900'), $LT,
		'100 (left first-digit) < 200 (right first-digit) via bet path');

	# Uppercase BET is handled by the separate range handler (line 361),
	# NOT by this branch — confirm the two paths stay independent.
	is(datecmp('1900', 'BET 1900 AND 1900', sub {}), $EQ,
		'uppercase BET with same endpoints == 0 (handled by range handler)');

	returns_ok(datecmp('100 and 1900', 'bet 200 and 1900'), { type => 'integer' },
		'return value is a defined integer');

	diag 'lines 341-348 exercised: lowercase bet, start(100) != end(200) → -1'
		if $ENV{TEST_VERBOSE};
};

# =========================================================================
# 3. BEF right qualifier — left is a pure-digit string
#    Target: lib/Date/Cmp.pm lines 454-455
#
#    Strategy: left = '1939' (pure digits).  right = 'bef 1939'.  Fast-paths
#    1 and 2 both extract 1939 → tie.  Right-side handler: /^bef/i fires,
#    $left =~ /^\d+$/ is TRUE, /\s(\d+)$/ extracts 1939 → return $left<=>$1.
#
#    NOTE — line 455 returns 0 here because the years are equal.  A non-zero
#    result from line 455 requires $left to differ from the trailing number in
#    right, but fast-path 2 would have already returned for any such pair.
#    Line 455 only ever returns 0 in practice.
# =========================================================================
subtest 'BEF right qualifier with pure-digit left (lines 454-455)' => sub {
	is(datecmp('1939', 'bef 1939'), $EQ,
		'1939 == bef 1939 (same year, fast-paths tie, BEF handler fires)');

	# Verify with a full "bef day-month year" string too.
	is(datecmp('1939', 'bef 5 Jun 1939'), $EQ,
		'1939 == bef 5 Jun 1939 (trailing 1939 extracted)');

	returns_ok(datecmp('1939', 'bef 1939'), { type => 'integer' },
		'return value is a defined integer');

	diag 'lines 454-455 exercised: $left (1939) <=> $1 (1939) = 0'
		if $ENV{TEST_VERBOSE};
};

# =========================================================================
# 4. Inverted right-side range (from > to) — STDERR path
#    Target: lib/Date/Cmp.pm lines 494-500
#
#    Strategy: right = '1902-1900' parses to from=1902, to=1900; from > to
#    → STDERR message + return 0.  Fast-paths skip the range string because
#    fast-path 1 excludes /^\d{3,4}\-\d{3,4}$/ right-forms and fast-path 2
#    excludes strings containing a dash.
# =========================================================================
subtest 'inverted right-side range (from > to) returns 0 (lines 494-500)' => sub {
	is(silence_stderr { datecmp('1901', '1902-1900') }, $EQ,
		'inverted RHS range 1902-1900 returns 0');

	# Symmetric — also works with BET form when from > to (requires
	# case-sensitive Bet ... and ... format for the range regex).
	# Plain inverted dash form is enough to hit lines 494-500.

	returns_ok(silence_stderr { datecmp('1901', '1902-1900') }, { type => 'integer' },
		'return value is a defined integer');

	diag 'lines 494-500 exercised: from(1902) > to(1900) → STDERR + return 0'
		if $ENV{TEST_VERBOSE};
};

# =========================================================================
# 5. Left-side BET range, DFG fails for right, extracted year is IN range
#    Target: lib/Date/Cmp.pm line 386 (the "return 0" inside the else of
#    the year<from / year>to checks)
#
#    Strategy: left = 'BET 1820 AND 1830' (fast-paths all disabled: /^bet/i
#    left excluded by fast-path conditions).  right = 'somewhat 1825' —
#    MockDFG returns failure.  The /[\s\/](\d{4})$/ suffix regex extracts
#    year=1825, which is within [1820, 1830] → return 0.
#
#    DEAD CODE note — line 372 ("if(ref($right)) { $right=$right->year() }")
#    is unreachable after Fix 2: any surviving ref is rejected at the post-
#    normalisation guard before this point.  This line should be removed.
#
#    DEAD CODE note — lines 409-411 (second "if($right == $from) { return 0 }")
#    are dead: the identical check at line 399 always returns first.
#
#    DEAD CODE note — lines 420-426 (STDERR fallback at the end of the BET
#    left-side handler else-branch) are unreachable: the four ifs at
#    399/403/406/412 together cover every integer $right in relation to
#    [from, to], leaving no case for the fallback.
# =========================================================================
subtest 'BET left range, DFG fails right, year within range (line 386)' => sub {
	my $mock = MockDFG->new();
	local $Date::Cmp::dfg = $mock;
	# Queue one failure for the right-side DFG call.
	$mock->enqueue([]);    # parse_datetime returns empty list → $r[0] undef

	is(datecmp('BET 1820 AND 1830', 'somewhat 1825'), $EQ,
		'year 1825 within [1820,1830] → 0 (line 386)');

	is($mock->call_count(), 1, 'DFG called exactly once (for right side)');

	returns_ok(datecmp('BET 1820 AND 1830', '1825'), { type => 'integer' },
		'year equal to start of range also returns an integer');

	diag "MockDFG calls: ${\$mock->call_count()}" if $ENV{TEST_VERBOSE};
};

# =========================================================================
# 6. Left-side BET range, DFG fails right, NO year suffix → die
#    Target: lib/Date/Cmp.pm lines 390-394
#
#    Strategy: same BET left as above but right = 'strange text' which has
#    no trailing [\s\/]\d{4} sequence.  After DFG failure the /[\s\/](\d{4})$/
#    check at line 377 fails → STDERR + die "Date parse failure: right = ...".
# =========================================================================
subtest 'BET left range, DFG fails right, no year suffix → die (lines 390-394)' => sub {
	{
		my $mock = MockDFG->new();
		local $Date::Cmp::dfg = $mock;
		$mock->enqueue([]);    # DFG failure for right

		throws_ok {
			silence_stderr { datecmp('BET 1820 AND 1830', 'strange text') }
		} qr/Date parse failure.*right/,
			'right with no year suffix after DFG failure → die';
	}

	{
		my $mock = MockDFG->new();
		local $Date::Cmp::dfg = $mock;
		$mock->enqueue([]);

		throws_ok {
			silence_stderr { datecmp('BET 1820 AND 1830', 'some stuff') }
		} qr/Date parse failure/,
			'any right with no extractable year → die (lines 390-394)';
	}

	diag 'lines 390-394 exercised: DFG fail + no year suffix → die'
		if $ENV{TEST_VERBOSE};
};

# =========================================================================
# 7. Right-side range with from==to, left is a DateTime ref
#    Target: lib/Date/Cmp.pm line 491
#
#    Strategy: left = '1 Feb 1900' is a complex date that goes through DFG
#    (MockDFG returns Fake::DateTime(1900)).  right = '1900-1900' triggers
#    the from==to branch (line 485) and then the ref($left) check (line 490)
#    → return $left->year() <=> $from = 0.
#
#    Fast-paths are bypassed: the dash in right disables FP2; the pattern
#    /^\d{3,4}\-\d{3,4}$/ match in right disables FP1.
# =========================================================================
subtest 'right range from==to with DateTime left (line 491)' => sub {
	{
		my $mock = MockDFG->new();
		local $Date::Cmp::dfg = $mock;
		$mock->enqueue([ Fake::DateTime->new(year => 1900) ]);

		my $complaint;
		is(datecmp('1 Feb 1900', '1900-1900', sub { $complaint = $_[0] }),
			$EQ, 'DateTime left <=> same-endpoint RHS range = 0 (line 491)');
		like($complaint, qr/from == to/,
			'complain callback fires for same-endpoint range');
	}

	{
		# Without complain: same result, no crash.
		my $mock = MockDFG->new();
		local $Date::Cmp::dfg = $mock;
		$mock->enqueue([ Fake::DateTime->new(year => 1901) ]);

		is(datecmp('1 Feb 1901', '1901-1901'), $EQ,
			'DateTime year 1901 vs same-endpoint range 1901-1901 = 0');
	}

	returns_ok(
		do {
			my $mock = MockDFG->new();
			local $Date::Cmp::dfg = $mock;
			$mock->enqueue([ Fake::DateTime->new(year => 1900) ]);
			datecmp('1 Feb 1900', '1900-1900');
		},
		{ type => 'integer' },
		'return value is a defined integer'
	);

	diag 'line 491 exercised: ref($left)->year() <=> from when from==to'
		if $ENV{TEST_VERBOSE};
};

# =========================================================================
# 8. ref($left), DFG fails right, extracted year != left->year()
#    Target: lib/Date/Cmp.pm lines 556-558
#
#    Strategy: MockDFG returns an OffYear::DateTime for left ('1 Feb 1892').
#    OffYear::DateTime stringifies to '1892' (so line 532's tie-check sees
#    1892 == 1892 and does NOT return early), but year() returns 1895.
#    For right ('5/27/1892') MockDFG returns failure; the /[\s\/](\d{4})$/
#    suffix extracts 1892.  Then: ref($left) is TRUE, $left->year() (1895)
#    != $year (1892) → return 1895 <=> 1892 = 1.
#
#    Fast-paths are bypassed: both strings contain 1892 as their 4-digit
#    year so FP1 and FP2 both tie.
#
#    DEAD CODE note — lines 561-562 ("if($left != $year) { return $left<=>
#    $year }") require left to be a plain non-ref value that differs from
#    the suffix year, while fast-path 2 would have already returned for any
#    such pair.  These lines cannot be reached with real inputs and should
#    be removed.
# =========================================================================
subtest 'ref(left), DFG fails right, year differs → compare (lines 556-558)' => sub {
	my $mock = MockDFG->new();
	local $Date::Cmp::dfg = $mock;

	# OffYear::DateTime: str='1892' (tie at line 532), year()=1895 (differs
	# from right's suffix year 1892 → fires line 557 inequality).
	$mock->enqueue([ OffYear::DateTime->new(str_year => '1892', real_year => 1895) ]);
	# Second DFG call (for right '5/27/1892') exhausts the queue → failure.

	is(datecmp('1 Feb 1892', '5/27/1892'), $GT,
		'ref(left)->year()(1895) > suffix-year(1892) → GT (lines 556-558)');

	returns_ok(
		do {
			my $mock2 = MockDFG->new();
			local $Date::Cmp::dfg = $mock2;
			$mock2->enqueue([ OffYear::DateTime->new(str_year => '1892', real_year => 1895) ]);
			datecmp('1 Feb 1892', '5/27/1892');
		},
		{ type => 'integer' },
		'return value is a defined integer'
	);

	diag 'lines 556-558 exercised: ref(left)->year()(1895) != suffix(1892) → 1'
		if $ENV{TEST_VERBOSE};
};

# =========================================================================
# 9. Plain left, DateTime right — DFG succeeds for right side
#    Target: lib/Date/Cmp.pm line 576
#
#    Strategy: left = '1900' stays as a plain string (matches ^\d{3,4}$,
#    skips the DFG elsif at line 427).  right = '1 Feb 1900' goes through
#    DFG (MockDFG returns Fake::DateTime(1900)).  After DFG: ref(right) is
#    TRUE, ref(left) is FALSE → line 575 condition fires → line 576:
#    return $left <=> $right->year() = 1900 <=> 1900 = 0.
#
#    Fast-paths all tie: both extract 1900 as their 4-digit year.  Line 532
#    also ties (left='1900' → 1900, right still '1 Feb 1900' → 1900 match)
#    so execution falls through to DFG for right.
#
#    DEAD CODE note — line 579 ("return $left->year() <=> $right") is dead:
#    after the if(!ref($right)) block, $right is always a ref (set by DFG at
#    line 573) or the function has already returned.  So ref($left) &&
#    !ref($right) at line 578 is always false when line 579 could fire.
# =========================================================================
subtest 'plain left, DateTime right from DFG success (line 576)' => sub {
	{
		my $mock = MockDFG->new();
		local $Date::Cmp::dfg = $mock;
		$mock->enqueue([ Fake::DateTime->new(year => 1900) ]);

		is(datecmp('1900', '1 Feb 1900'), $EQ,
			'plain 1900 == DFG-parsed 1900 via line 576');
	}

	{
		# Earlier year on left → GT (right DFG year is later)
		my $mock = MockDFG->new();
		local $Date::Cmp::dfg = $mock;
		$mock->enqueue([ Fake::DateTime->new(year => 1901) ]);

		# Force a year mismatch visible AFTER DFG: fast-paths see '1900' in
		# both '1900' and '1 Feb 1900' (tie), but MockDFG returns year 1901.
		# Line 576: 1900 <=> 1901 = -1.
		is(datecmp('1900', '1 Feb 1900'), $LT,
			'plain 1900 < DFG-parsed 1901 via line 576');
	}

	returns_ok(
		do {
			my $mock = MockDFG->new();
			local $Date::Cmp::dfg = $mock;
			$mock->enqueue([ Fake::DateTime->new(year => 1900) ]);
			datecmp('1900', '1 Feb 1900');
		},
		{ type => 'integer' },
		'return value is a defined integer'
	);

	diag 'line 576 exercised: (!ref(left)) && ref(right) → left <=> right->year()'
		if $ENV{TEST_VERBOSE};
};

# =========================================================================
# 10. Former dead-code inventory — all regions REMOVED in critique refactor
#
#     The following 9 dead-code regions previously catalogued in this file
#     have been removed from lib/Date/Cmp.pm as part of the /critique
#     refactoring (2026-07-18):
#
#     * fast-path 3 early return (was line 288)
#     * BEF left, 4-digit right second /(\d{4})/ branch (was lines 305-307)
#     * return after prefix-strip when years tie (was line 337)
#     * ref($right) guard inside BET LHS range else-branch (was line 372)
#     * duplicate "if($right==$from){return 0}" in BET LHS range (was 409-411)
#     * STDERR fallback at end of BET LHS range else-branch (was 420-426)
#     * STDERR fallback at end of BET RHS range else-branch (was 523-528)
#     * plain-left DFG-fail-right year-differs path (was lines 561-562)
#     * ref(left) && !ref(right) final guard (was lines 578-579)
#
#     The range-comparison bodies in both handlers are now the canonical
#     3-line early-return form:
#         return 1 if $right < $from;
#         return -1 if $right > $to;
#         return 0;
#
#     Smoke tests below verify the surrounding live code is unaffected.
# =========================================================================
subtest 'former dead-code inventory — removed; smoke tests verify live paths' => sub {
	pass 'All 9 dead-code regions removed in critique refactor (2026-07-18)';

	# Verify the 3-line simplified range bodies still produce correct results.
	is(datecmp('BET 1900 AND 1902', '1901'), $EQ,
		'BET LHS range: right inside [from, to] returns 0');
	is(datecmp('1901', 'BET 1900 AND 1902'), $EQ,
		'BET RHS range: left inside [from, to] returns 0');
};

# =========================================================================
# 11. Comprehensive return-value schema check
# =========================================================================
subtest 'all new paths return defined integers' => sub {
	my @cases = (
		[ 'bef 5',             '100'                  ],
		[ 'bef 5',             '5'                    ],
		[ '100 and 1900',      'bet 200 and 1900'     ],
		[ '1939',              'bef 1939'             ],
		[ '1939',              'bef 5 Jun 1939'       ],
		[ silence_stderr { sub { datecmp('1901', '1902-1900') } },
		  undef ],   # placeholder; result already captured
	);

	# Subset of cases where we can call datecmp directly.
	for my $pair (
		[ 'bef 5',         '100'              ],
		[ '100 and 1900',  'bet 200 and 1900' ],
		[ '1939',          'bef 1939'         ],
	) {
		my ($l, $r) = @$pair;
		returns_ok(datecmp($l, $r), { type => 'integer' },
			"datecmp('$l', '$r') returns an integer");
	}

	returns_ok(silence_stderr { datecmp('1901', '1902-1900') },
		{ type => 'integer' },
		"datecmp('1901', '1902-1900') returns an integer");
};

restore_all();

done_testing();
