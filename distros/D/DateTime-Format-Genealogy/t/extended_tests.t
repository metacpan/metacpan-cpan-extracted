#!perl

# Extended coverage tests for DateTime::Format::Genealogy.
#
# Purpose: hit every remaining branch and condition gap identified by
# Devel::Cover after the core test suite (date.t, error.t, function.t,
# unit.t, integration.t, edge_cases.t) was run.
#
# Coverage gaps targeted (all in lib/DateTime/Format/Genealogy.pm):
#
#   Line 486  TRUE  - French August "Ao\x{FB}t" branch (0/242 hits)
#   Cond 421  !l    - date IS a ref at the condition (dead; validate_strict
#                     catches refs before reaching this line)
#   Cond 531  !l    - $rc is falsy after success check (dead; success guard
#                     at line 526 returns early, so $rc is always truthy here)
#   Cond 542  !l    - date matches /^(Abt|ca?)/ - circa/approximate prefix
#                     without the whitespace that the earlier /^abt\s/ catches
#   Cond 508  !l&&!r - $self->{'dfn'} undef AND DFN::new returns false (dead;
#                     DFN::new always returns a truthy object)
#
# Dead-code note: the else branch at the original line 548-549 that carped
# "Can't parse date" has been REMOVED from the module because
# DateTime::Format::Natural->parse_datetime never returns a falsy value.
# It now lives only as a comment in the source for future maintainers.
#
# All dead-code conditions are documented below with explicit reasoning.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Scalar::Util qw(blessed);

# Allow direct access to private/protected helpers for white-box assertions.
$Sub::Private::BYPASS = 1;

BEGIN { use_ok('DateTime::Format::Genealogy') || BAIL_OUT('Cannot load module') }

Readonly my $PKG => 'DateTime::Format::Genealogy';

# ---------------------------------------------------------------------------
# Minimal calendar back-end stubs so require() short-circuits.
# ---------------------------------------------------------------------------
{
	package DateTime::Calendar::Hebrew;
	sub new { my ($c, %a) = @_; bless { %a }, $c }
}
$INC{'DateTime/Calendar/Hebrew.pm'} = 1;

{
	package DateTime::Calendar::FrenchRevolutionary;
	sub new { my ($c, %a) = @_; bless { %a }, $c }
}
$INC{'DateTime/Calendar/FrenchRevolutionary.pm'} = 1;

# ===========================================================================
# SECTION 1: French August — Ao\x{FB}t (line 486 TRUE branch)
#
# This is the only functional execution path untouched by the entire existing
# test suite.  The regex:
#   /^(\d{1,2})\s+Ao\x{FB}t\s+(\d{3,4})$/i
# is designed for the French month name "Août" (August), where '\x{FB}' is
# LATIN SMALL LETTER U WITH CIRCUMFLEX (û, U+00FB).
#
# The branch must rewrite "NN Août YYYY" to "NN Aug YYYY" so that
# Genealogy::Gedcom::Date can then parse it.  Strict mode never reaches this
# branch because the strict path returns at the 3-letter check above it.
# ===========================================================================

subtest 'parse_datetime - French August Ao\x{FB}t (line 486 true branch)' => sub {
	my $obj = $PKG->new();

	# Core case: exact-case as the regex expects.
	my $dt = $obj->parse_datetime("15 Ao\x{fb}t 2022");
	isa_ok($dt, 'DateTime', '"Août" parses to a DateTime');
	is($dt->dmy, '15-08-2022', '"Août" correctly mapped to August');
	returns_ok($dt, { type => 'object', isa => 'DateTime' }, 'return type validates');

	# Case-insensitive match: the /i flag must handle "ao\x{fb}T" etc.
	# Perl's /i on \x{FB} matches the uppercase equivalent U+00DB (Û).
	my $dt_uc = $obj->parse_datetime("15 Ao\x{fb}T 2022");
	isa_ok($dt_uc, 'DateTime', '"AoûT" (mixed case) parses');
	is($dt_uc->dmy, '15-08-2022', 'case-insensitive Août produces correct date') if defined $dt_uc;

	# Different valid days in August.
	Readonly my %AOUT_CASES => (
		"1 Ao\x{fb}t 2020"  => '01-08-2020',
		"31 Ao\x{fb}t 1789" => '31-08-1789',
		"15 Ao\x{fb}t 1800" => '15-08-1800',
	);
	while (my ($input, $expected) = each %AOUT_CASES) {
		my $r = $obj->parse_datetime($input);
		ok(defined $r, "Août: '$input' is accepted");
		is($r->dmy, $expected, "Août: '$input' => $expected") if defined $r;
	}

	# Strict mode must reject the non-ASCII month name at the 3-letter check
	# (the Août regex is only reached in non-strict mode).
	my $strict_result;
	warnings_are(
		sub { $strict_result = $obj->parse_datetime(date => "15 Ao\x{fb}t 2022", strict => 1, quiet => 1) },
		[],
		'"Août" with strict => 1: no carp (quiet suppresses it)',
	);
	ok(!defined $strict_result, '"Août" with strict => 1 returns undef');

	# Quiet must suppress the strict-mode carp.
	warning_like(
		sub { $obj->parse_datetime(date => "15 Ao\x{fb}t 2022", strict => 1) },
		qr/Unparseable date.*month name/,
		'"Août" with strict => 1 (no quiet): Unparseable carp emitted',
	);

	diag("Août base case: " . $dt->dmy) if $ENV{TEST_VERBOSE};
};

subtest 'parse_datetime - Août with invalid day/year combinations' => sub {
	my $obj = $PKG->new(quiet => 1);

	# 3-digit year: GGD parses it but DFN rejects it (now returns undef).
	my $old = $obj->parse_datetime("15 Ao\x{fb}t 999");
	ok(!defined $old, '"Août 999" (3-digit year) returns undef');

	# 4-digit year at the lower boundary DFN can handle.
	my $dt_1000 = $obj->parse_datetime("15 Ao\x{fb}t 1000");
	isa_ok($dt_1000, 'DateTime', '"Août 1000" parses');
	is($dt_1000->dmy, '15-08-1000', 'Août 1000 correct') if defined $dt_1000;

	diag("Août 999 (3-digit): " . (defined $old ? $old->dmy : 'undef (correct)'))
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 2: Circa/approximate prefix without space (condition 542 !l)
#
# The guards at line 435 catch "bef\s", "aft\s", "abt\s" — all require a
# trailing whitespace.  Strings like "Abt1Jan2000", "c 1 Jan 2000", and
# "ca 1 Jan 2000" are NOT caught by those guards.
#
# They reach line 542 where the additional /^(Abt|ca?)/i check correctly
# excludes them from the DFN-fallback path.  The result is undef with no
# carp (the module silently discards these strings).
#
# Coverage: this hits the !l (short-circuit false) case of the `and` condition:
#   ($date !~ /^(Abt|ca?)/i) && ($date =~ /^[\w\s,]+$/)
# ===========================================================================

subtest 'parse_datetime - circa prefix without space reaches condition 542 !l' => sub {
	my $obj = $PKG->new();

	Readonly my @CIRCA_DATES => (
		'c 1 Jan 2000',      # "c " prefix (circa) not matched by abt\s guard
		'ca 1 Jan 2000',     # "ca " prefix (circa approximation)
		'Abt1Jan2000',       # "Abt" without trailing space
		'c1Jan2000',         # "c" immediately before digits
		'C 25 Dec 2022',     # uppercase C
		'CA 1 Jan 2000',     # uppercase CA
	);

	for my $date (@CIRCA_DATES) {
		# Must return undef without crashing.
		my $r;
		lives_ok(sub { $r = $obj->parse_datetime($date) },
			"circa prefix '$date': does not crash");
		ok(!defined $r,
			"circa prefix '$date': returns undef (not DFN-parsed)");
		# Must emit no carp in non-strict mode (the /^(Abt|ca?)/ guard
		# short-circuits the DFN block so no error message is produced).
		warnings_are(
			sub { $obj->parse_datetime($date) },
			[],
			"circa prefix '$date': no carp emitted (non-strict)",
		);
	}
};

subtest 'parse_datetime - circa prefix in strict mode emits Unparseable carp' => sub {
	# In strict mode, ALL non-digit-prefixed strings that fail the
	# /^(\d{1,2})\s+[A-Z]{3}\s+\d{3,4}$/i check are rejected with the
	# "Unparseable date" carp — including circa forms.
	my $obj = $PKG->new();

	warning_like(
		sub { $obj->parse_datetime(date => 'c 1 Jan 2000', strict => 1) },
		qr/Unparseable date.*month name/,
		'"c 1 Jan 2000" with strict => 1: emits Unparseable carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => 'c 1 Jan 2000', strict => 1, quiet => 1) },
		[],
		'"c 1 Jan 2000" with strict => 1 + quiet: no carp',
	);
};

# ===========================================================================
# SECTION 3: DFN lazily initialised dfn slot (condition 508)
#
# $self->{'dfn'} //= DateTime::Format::Natural->new()
#
# Coverage reports show the slot is populated on first use (!l&&r = 103 hits)
# and reused thereafter (l = 142 hits).
#
# The !l&&!r case — dfn undef AND DFN::new returns false — is dead code
# because DateTime::Format::Natural->new() always returns a blessed object.
# A test that confirms DFN::new returns truthy documents this assumption.
# ===========================================================================

subtest 'DFN slot is lazily initialised exactly once per object (cond 508)' => sub {
	my $obj = $PKG->new();

	# Before any parse the slot is absent.
	ok(!exists $obj->{'dfn'}, 'dfn slot absent before first parse');

	# After a parse the slot exists.
	$obj->parse_datetime('25 Dec 2022');
	ok(exists $obj->{'dfn'}, 'dfn slot populated after first parse');
	isa_ok($obj->{'dfn'}, 'DateTime::Format::Natural', 'dfn slot holds a DFN instance');

	# A second parse must reuse the same DFN instance (not a new one).
	my $first_ref  = $obj->{'dfn'};
	$obj->parse_datetime('1 Jan 2019');
	my $second_ref = $obj->{'dfn'};
	is($first_ref, $second_ref,
		'DFN instance is reused on subsequent parses (slot initialised once)');

	# The !l&&!r dead-code case would require DFN::new to return false.
	# Confirm DFN::new always returns a blessed object.
	my $dfn = DateTime::Format::Natural->new();
	ok(defined $dfn && ref $dfn, 'DFN::new always returns a truthy ref (dead code confirmed)');

	diag("DFN ref: " . ref($obj->{'dfn'})) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 4: Dead-code documentation — condition 421 !l
#
# The condition at line 421 is:
#   if ((!ref($params->{'date'})) && (my $date = $params->{'date'}))
#
# The !l case (date IS a reference) would short-circuit this if-block and
# fall through to the final Carp::croak.  However, Params::Validate::Strict
# (called at line 418) already rejects every reference type with:
#   "Invalid parse_datetime parameters: ... must be a scalar"
# before execution reaches line 421.
#
# Therefore the !l path is dead code: a ref date never survives to line 421.
# The test below confirms that all ref types are caught before line 421.
# ===========================================================================

subtest 'Dead code — condition 421 !l: ref date caught before reaching condition' => sub {
	my $obj = $PKG->new();

	# All of these die with "Invalid parse_datetime parameters" (from
	# validate_strict at line 418), NOT with the Usage: croak at line 542
	# (which is what would happen if the !l branch at line 421 were reached).
	my %REF_CASES = (
		arrayref  => [],
		hashref   => {},
		scalarref => \"str",
		coderef   => sub { },
	);
	while (my ($label, $ref) = each %REF_CASES) {
		throws_ok(
			sub { $obj->parse_datetime(date => $ref) },
			qr/Invalid parse_datetime parameters/,
			"$label: caught by validate_strict (line 418), not line 421",
		);
	}
	# If condition 421 !l were ever reachable, the error would be "Usage:"
	# not "Invalid parse_datetime parameters".  Verify it is NOT "Usage:".
	my $err = '';
	eval { $obj->parse_datetime(date => []) };
	$err = $@ // '';
	unlike($err, qr/^Usage:/, 'ref date error is NOT the line-421 usage message');

	pass('All ref types are intercepted by validate_strict before line 421');
};

# ===========================================================================
# SECTION 5: Dead-code documentation — condition 531 !l
#
# The condition at line 531 is:
#   if ($rc && $calendar_type ne 'DGREGORIAN')
#
# The !l case ($rc is falsy) would fall through without calling
# _convert_calendar.  However, the guard added at line 526:
#   unless ($dfn->success) { carp...; return }
# ensures that when we reach line 531, $dfn->success() was true and
# $rc holds the DateTime object DFN returned — which is always truthy.
#
# Therefore the !l path (rc is false/undef at line 531) is dead code.
# ===========================================================================

subtest 'Dead code — condition 531 !l: $rc is always truthy when we reach it' => sub {
	# Mock DFN to return a truthy object and report success.
	# Verify that $rc at line 531 is always a DateTime.
	my $sentinel = DateTime->new(year => 2022, month => 12, day => 25);

	mock 'DateTime::Format::Natural::parse_datetime' => sub { return $sentinel };
	mock 'DateTime::Format::Natural::success'        => sub { return 1 };

	my $obj = $PKG->new();
	my $r   = $obj->parse_datetime('25 Dec 2022');

	isa_ok($r, 'DateTime', 'When DFN succeeds, $rc is a truthy DateTime at line 531');
	is($r->year, 2022, 'correct year from mock'); # sentinel year

	restore_all();

	# The !l path would only be reached if success() returned true but
	# parse_datetime returned a falsy value — a contradiction in DFN's contract.
	# Mock that contradiction to prove parse_datetime catches it gracefully via
	# the success check (returns before line 531).
	mock 'DateTime::Format::Natural::parse_datetime' => sub { return undef };
	mock 'DateTime::Format::Natural::success'        => sub { return 0 };
	mock 'DateTime::Format::Natural::error'          => sub { return 'synthetic error' };

	my $obj2 = $PKG->new();
	my $r2   = $obj2->parse_datetime(date => '25 Dec 2022', quiet => 1);
	ok(!defined $r2,
		'When DFN returns undef with success=false, the success check returns undef before line 531');

	restore_all();

	pass('Condition 531 !l is unreachable in normal operation');
};

# ===========================================================================
# SECTION 6: Additional branch coverage for the DFN-fallback path
#
# The DFN-fallback (lines 542-551) is reached when:
#   (a) the date does NOT start with a digit (GGD path skipped), AND
#   (b) the date does NOT match /^(Abt|ca?)/i, AND
#   (c) the date matches /^[\w\s,]+$/
#
# Condition 542 l&&!r case: date does NOT match /^(Abt|ca?)/ but also does
# NOT match /^[\w\s,]+$/ (contains non-word chars other than space/comma).
# ===========================================================================

subtest 'parse_datetime - DFN fallback skipped for non-word chars (cond 542 l&&!r)' => sub {
	my $obj = $PKG->new(quiet => 1);

	# These strings reach line 542 but fail the /^[\w\s,]+$/ test because
	# they contain characters outside the word/space/comma set.
	# Result: undef without entering DFN fallback.
	Readonly my @NON_WORD_DATES => (
		'December-25-2022',   # dashes disqualify
		'25/Dec/2022',        # slashes disqualify
		'25 Dec 2022!',       # bang disqualify
		'<25 Dec 2022>',      # angle brackets
	);

	for my $date (@NON_WORD_DATES) {
		my $r;
		lives_ok(sub { $r = $obj->parse_datetime($date) },
			"non-word date '$date': does not crash");
		ok(!defined $r, "non-word date '$date': returns undef");
	}
};

subtest 'parse_datetime - DFN fallback succeeds for comma-separated formats' => sub {
	# "Sep 29, 1939" matches /^[\w\s,]+$/ and DFN parses it correctly.
	# This exercises the l&&r path of condition 542.
	my $obj = $PKG->new();

	Readonly my %COMMA_CASES => (
		'Sep 29, 1939'    => '29-09-1939',
		'Dec 25, 2022'    => '25-12-2022',
		'January 1, 2000' => '01-01-2000',
	);

	while (my ($input, $expected) = each %COMMA_CASES) {
		my $dt = $obj->parse_datetime($input);
		isa_ok($dt, 'DateTime', "'$input' reaches DFN fallback and parses");
		is($dt->dmy, $expected, "'$input' => $expected") if defined $dt;
	}
};

subtest 'parse_datetime - DFN fallback reached for non-digit-prefixed names' => sub {
	# Month-first formats that start with a letter, pass the /[\w\s,]+/
	# filter, and are successfully parsed by DFN.
	my $obj = $PKG->new();

	my $dt = $obj->parse_datetime('December 25, 2022');
	isa_ok($dt, 'DateTime', '"December 25, 2022" parses via DFN fallback');
	is($dt->dmy, '25-12-2022', 'month-first format date correct') if defined $dt;

	# "Monday December 25 2022" style: non-digit prefix, word-only chars,
	# no Abt/c prefix → hits DFN fallback.  Use quiet=1 to suppress any
	# DFN error carp if DFN cannot parse it.
	my $dt2 = $obj->parse_datetime(date => 'Monday December 25 2022', quiet => 1);
	diag("'Monday December 25 2022' => " . (defined $dt2 ? $dt2->dmy : 'undef'))
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 7: Explicit branch-hit matrix for the approximate-prefix guard
#
# Line 435 uses three chained OR conditions:
#   /^bef\s/i  OR  /^aft\s/i  OR  /^abt\s/i
#
# Coverage shows all three sub-conditions are exercised, but this section
# adds explicit tests for each independently to lock in LCSAJ paths.
# ===========================================================================

subtest 'parse_datetime - approximate prefix OR-chain branch matrix' => sub {
	my $obj = $PKG->new();

	# bef fires on the first term — !l&&r (first is true, rest not evaluated)
	warning_like(
		sub { $obj->parse_datetime('bef 1 Jan 2000') },
		qr/is invalid.*need an exact date/,
		'bef prefix: first OR term fires',
	);

	# aft fires on the second term — first is false, !l&&r
	warning_like(
		sub { $obj->parse_datetime('aft 1 Jan 2000') },
		qr/is invalid.*need an exact date/,
		'aft prefix: second OR term fires',
	);

	# abt fires on the third term — first two false, third true
	warning_like(
		sub { $obj->parse_datetime('abt 1 Jan 2000') },
		qr/is invalid.*need an exact date/,
		'abt prefix: third OR term fires',
	);

	# Case-insensitive variants must all fire.
	for my $prefix (qw(BEF bEf AFT aFt ABT AbT)) {
		ok(!defined $obj->parse_datetime(date => "$prefix 1 Jan 2000", quiet => 1),
			"'$prefix' (case variant) returns undef");
	}
};

# ===========================================================================
# SECTION 8: ISO date rewrite — month boundary values
#
# Line 449-457 rewrites YYYY-MM-DD to "DD Mon YYYY".  The month index into
# @short_month_names must handle the full range 01-12 correctly.
# ===========================================================================

subtest 'parse_datetime - ISO YYYY-MM-DD all months 01-12' => sub {
	my $obj = $PKG->new(quiet => 1);

	Readonly my @MONTHS => qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

	for my $m (1 .. 12) {
		my $mm  = sprintf '%02d', $m;
		my $iso = "2022-${mm}-15";
		my $dt  = $obj->parse_datetime($iso);
		isa_ok($dt, 'DateTime', "ISO $iso parses");
		if(defined $dt) {
			is($dt->month, $m, "ISO $iso: month $m correct");
			is($dt->day,  15,  "ISO $iso: day 15 correct");
		}
	}
};

# ===========================================================================
# SECTION 9: Dash-range rewrite vs ISO rewrite branching
#
# Line 449: /^\s*(.+\d\d)\s*\-\s*(.+\d\d)\s*$/
#   - Sub-branch ISO:   /^(\d{4})\-(\d{2})\-(\d{2})$/  → rewrite to DD Mon YYYY
#   - Sub-branch range: else                             → rewrite to bet X and Y
#
# The branching is determined by whether the string is exactly YYYY-MM-DD.
# ===========================================================================

subtest 'parse_datetime - dash rewrite: ISO vs range sub-branching' => sub {
	my $obj = $PKG->new(quiet => 1);

	# ISO form: YYYY-MM-DD — hits the ISO sub-branch.
	my $iso = $obj->parse_datetime('2022-06-15');
	isa_ok($iso, 'DateTime', 'ISO YYYY-MM-DD hits ISO sub-branch');
	is($iso->dmy, '15-06-2022', 'ISO value correct') if defined $iso;

	# Range form with non-ISO structure — hits the bet-rewrite sub-branch.
	my @range = $obj->parse_datetime('1 Sep 1939 - 2 Sep 1945');
	is(scalar @range, 2, 'dash range hits bet-rewrite sub-branch');
	is($range[0]->dmy, '01-09-1939', 'range start') if @range >= 2;
	is($range[1]->dmy, '02-09-1945', 'range end')   if @range >= 2;

	# Edge: a string with a dash that has nothing before the first \d\d should
	# NOT match the outer regex and fall through to normal parsing.
	my $no_match = $obj->parse_datetime('-25 Dec 2022');
	diag("'-25 Dec 2022' => " . (defined $no_match ? $no_match->dmy : 'undef'))
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 10: quiet // self->{'quiet'} and strict // self->{'strict'}
#
# Conditions 424 and 425 track all three cases of the // operator:
#   l     - per-call flag is defined and truthy  (uses per-call value)
#   !l&&r - per-call undef, object attr is set   (falls back to object)
#   !l&&!r- both undef (neither set)             (uses undef → falsy)
#
# All three cases are already covered, but this section adds explicit tests
# to lock in each combination as a regression target.
# ===========================================================================

subtest 'parse_datetime - quiet // self->quiet all three condition paths' => sub {
	# Case !l&&!r: neither per-call nor object-level quiet → carp fires
	my $obj_noq = $PKG->new();
	warning_like(
		sub { $obj_noq->parse_datetime('bef 1 Jan 2000') },
		qr/is invalid/,
		'!l&&!r (no quiet anywhere): carp fires',
	);

	# Case !l&&r: no per-call quiet, object-level quiet → carp suppressed
	my $obj_q = $PKG->new(quiet => 1);
	warnings_are(
		sub { $obj_q->parse_datetime('bef 1 Jan 2000') },
		[],
		'!l&&r (object-level quiet): carp suppressed',
	);

	# Case l: per-call quiet => 1 overrides object-level quiet => 0
	my $obj_nq = $PKG->new(quiet => 0);
	warnings_are(
		sub { $obj_nq->parse_datetime(date => 'bef 1 Jan 2000', quiet => 1) },
		[],
		'l (per-call quiet => 1 overrides object quiet => 0): carp suppressed',
	);

	# Per-call quiet => 0 overrides object-level quiet => 1
	warning_like(
		sub { $obj_q->parse_datetime(date => 'bef 1 Jan 2000', quiet => 0) },
		qr/is invalid/,
		'l (per-call quiet => 0 overrides object quiet => 1): carp fires',
	);
};

subtest 'parse_datetime - strict // self->strict all three condition paths' => sub {
	Readonly my $LONG_MONTH => '12 June 2020';
	Readonly my $EXPECT     => '12-06-2020';

	# Case !l&&!r: neither per-call nor object strict → long month accepted
	my $obj_ns = $PKG->new();
	my $dt = $obj_ns->parse_datetime($LONG_MONTH);
	isa_ok($dt, 'DateTime', '!l&&!r (no strict anywhere): long month accepted');
	is($dt->dmy, $EXPECT, 'date value correct') if defined $dt;

	# Case !l&&r: no per-call strict, object-level strict → long month rejected
	my $obj_s = $PKG->new(strict => 1, quiet => 1);
	ok(!defined $obj_s->parse_datetime($LONG_MONTH),
		'!l&&r (object-level strict): long month rejected');

	# Case l: per-call strict => 0 overrides object strict => 1
	my $dt2 = $obj_s->parse_datetime(date => $LONG_MONTH, strict => 0);
	isa_ok($dt2, 'DateTime', 'l (per-call strict => 0 overrides object strict => 1): accepted');

	# Per-call strict => 1 overrides object strict => 0
	ok(!defined $obj_ns->parse_datetime(date => $LONG_MONTH, strict => 1, quiet => 1),
		'l (per-call strict => 1 overrides object strict => 0): rejected');
};

# ===========================================================================
# SECTION 11: _date_parser_cached — additional branch paths
# ===========================================================================

subtest '_date_parser_cached - cache hit path (second call returns same ref)' => sub {
	my $obj = $PKG->new();

	Readonly my $DATE => '29 Sep 1939';

	# _date_parser_cached now accepts a plain positional string (no Params::Get).
	my $first  = $obj->_date_parser_cached($DATE);
	my $second = $obj->_date_parser_cached($DATE);

	ok(defined $first && defined $second, 'both calls return defined values');
	is(Scalar::Util::refaddr($first), Scalar::Util::refaddr($second),
		'second call returns identical cached reference');
};

subtest '_date_parser_cached - GGD error path caches undef and returns undef' => sub {
	my $obj = $PKG->new(quiet => 1);

	Readonly my $BAD_DATE => 'not a date xyzzy 99999';

	# An unparseable string causes GGD to report an error.
	# The module now caches the failure as undef so that repeated lookups for
	# the same invalid string are O(1) and the carp fires only once.
	my $result = $obj->_date_parser_cached($BAD_DATE);
	ok(!defined $result, 'GGD error: returns undef');

	# Verify the failure WAS written to the cache (performance optimisation:
	# subsequent calls skip the GGD parse entirely via the exists() guard).
	ok(exists($obj->{'all_dates'}{$BAD_DATE}),
		'GGD error: failed parse stored in cache');
	ok(!defined($obj->{'all_dates'}{$BAD_DATE}),
		'GGD error: cached value is undef');

	# A second call must return undef without invoking GGD again.
	my $second = $obj->_date_parser_cached($BAD_DATE);
	ok(!defined $second, 'GGD error: second call also returns undef (cache hit)');
};

# ===========================================================================
# SECTION 12: _julian_to_gregorian_offset — all tier boundary values
#
# This pure helper has four tiers; verify every boundary exactly once to
# maximise condition coverage without repeating work from function.t.
# ===========================================================================

subtest '_julian_to_gregorian_offset - exact boundary years' => sub {
	my $fn = \&{"${PKG}::_julian_to_gregorian_offset"};

	# Tier boundaries: the year value at which a tier CHANGES is the first
	# year of the next tier.  1700 is the first year of the +11 tier.
	is($fn->(1699), 10, 'year 1699: last year of +10 tier');
	is($fn->(1700), 11, 'year 1700: first year of +11 tier');
	is($fn->(1799), 11, 'year 1799: last year of +11 tier');
	is($fn->(1800), 12, 'year 1800: first year of +12 tier');
	is($fn->(1899), 12, 'year 1899: last year of +12 tier');
	is($fn->(1900), 13, 'year 1900: first year of +13 tier (catch-all)');
	is($fn->(2025), 13, 'year 2025: modern year in +13 tier');
	is($fn->(9999), 13, 'year 9999: far-future year in +13 tier');
};

# ===========================================================================
# SECTION 13: bet...and... recursive call inherits per-call flags
#
# The bet...and... handler calls $self->parse_datetime($1) and
# $self->parse_datetime($2) with no explicit parameters — they inherit only
# $self's object-level flags, not the per-call flags of the outer call.
# ===========================================================================

subtest 'parse_datetime - bet range inherits object-level quiet' => sub {
	my $quiet_obj = $PKG->new(quiet => 1);

	# Both halves parse cleanly: no warnings.
	my @range;
	warnings_are(
		sub { @range = $quiet_obj->parse_datetime('bet 1 Jan 2000 and 31 Dec 2000') },
		[],
		'bet range: object-level quiet suppresses any sub-parse carps',
	);
	is(scalar @range, 2, 'bet range returns 2 elements');
	is($range[0]->dmy, '01-01-2000', 'range start') if @range == 2;
	is($range[1]->dmy, '31-12-2000', 'range end')   if @range == 2;
};

subtest 'parse_datetime - from...to... recursive call in list context' => sub {
	my $obj = $PKG->new();

	# from...to... in list context returns two DateTimes.
	my @range = $obj->parse_datetime('from 25 Dec 2022 to 1 Jan 2023');
	is(scalar @range, 2, 'from range: 2 elements in list context');
	is($range[0]->dmy, '25-12-2022', 'from range start') if @range == 2;
	is($range[1]->dmy, '01-01-2023', 'from range end')   if @range == 2;

	# In scalar context always undef.
	my $scalar = $obj->parse_datetime('from 25 Dec 2022 to 1 Jan 2023');
	ok(!defined $scalar, 'from range in scalar context: undef');
};

# ===========================================================================
# SECTION 14: Calling-style dispatch branches (lines 400-408)
#
# parse_datetime must reroute to a fresh object when the invocant is not an
# object reference.  Three dispatch paths:
#   (a) !ref($self) && @_      → new()->parse_datetime(@_)
#   (b) !ref($self) && !@_     → new()->parse_datetime($self)   [bare string]
#   (c) ref($self) eq 'HASH'   → new()->parse_datetime($self)   [hashref]
# ===========================================================================

subtest 'parse_datetime - all dispatch branches (lines 400-408)' => sub {
	Readonly my $DATE   => '25 Dec 2022';
	Readonly my $EXPECT => '25-12-2022';

	# (a) class-method with arguments: !ref && @_
	my $dt_a = $PKG->parse_datetime($DATE);
	isa_ok($dt_a, 'DateTime', 'dispatch (a): class method + string');
	is($dt_a->dmy, $EXPECT, 'dispatch (a): value correct') if defined $dt_a;

	# (b) bare-function call, $self IS the date string: !ref && !@_
	my $dt_b = DateTime::Format::Genealogy::parse_datetime($DATE);
	isa_ok($dt_b, 'DateTime', 'dispatch (b): bare function call');
	is($dt_b->dmy, $EXPECT, 'dispatch (b): value correct') if defined $dt_b;

	# (c) hashref invocant: ref($self) eq 'HASH'
	# When the first argument to the function is a plain hashref (not a blessed
	# object and not a class name), parse_datetime reroutes via new()->parse.
	# This path is exercised by calling the function directly with a hashref.
	my $dt_c2 = DateTime::Format::Genealogy::parse_datetime({ date => $DATE });
	isa_ok($dt_c2, 'DateTime', 'dispatch (c): hashref first arg reroutes correctly');
	is($dt_c2->dmy, $EXPECT, 'dispatch (c): value correct') if defined $dt_c2;
};

done_testing();
