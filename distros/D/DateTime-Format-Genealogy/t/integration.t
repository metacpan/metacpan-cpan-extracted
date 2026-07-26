#!perl

# Black-box integration tests for DateTime::Format::Genealogy.
#
# These tests exercise stateful, cross-method workflows: constructor flags
# flowing into parse_datetime, per-object cache isolation, cloning chains,
# optional-dependency fallbacks, and concurrent independent instances.
#
# Calling convention: Params::Get does NOT support mixing a positional scalar
# with named key-value flags.  All parse_datetime calls that pass flags use
# the named (date => '...', quiet => 1) or hashref form.

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Readonly;
use Scalar::Util qw(blessed refaddr);

# Test::Without::Module blocks require() at load time; import it before the
# module under test so we can selectively hide optional back-ends.
use Test::Without::Module ();

BEGIN { use_ok('DateTime::Format::Genealogy') || BAIL_OUT('Cannot load module') }

Readonly my $PKG => 'DateTime::Format::Genealogy';

# ---------------------------------------------------------------------------
# Lightweight stubs for optional calendar back-ends.
#
# Neither DateTime::Calendar::Hebrew nor DateTime::Calendar::FrenchRevolutionary
# is installed in this environment, so we inject stubs that behave like the
# real modules.  %INC entries prevent require() from searching @INC.
#
# The stubs record how they are constructed so spy-style assertions can verify
# that _convert_calendar passes the right coordinates.
# ---------------------------------------------------------------------------

my @hebrew_new_calls;
my @french_new_calls;

{
	package DateTime::Calendar::Hebrew;
	sub new {
		my ($class, %args) = @_;
		push @hebrew_new_calls, \%args;
		return bless { %args }, $class;
	}
}
$INC{'DateTime/Calendar/Hebrew.pm'} = 1;

{
	package DateTime::Calendar::FrenchRevolutionary;
	sub new {
		my ($class, %args) = @_;
		push @french_new_calls, \%args;
		return bless { %args }, $class;
	}
}
$INC{'DateTime/Calendar/FrenchRevolutionary.pm'} = 1;

# ===========================================================================
# SECTION 1: Multi-instance isolation
#
# Two independent objects must not share mutable state (the all_dates cache
# or the internal DFN/date_parser lazy singletons).
# ===========================================================================

subtest 'two independent objects do not share cache state' => sub {
	my $obj_a = $PKG->new();
	my $obj_b = $PKG->new();

	isnt(refaddr($obj_a), refaddr($obj_b), 'objects are distinct references');

	# Populate obj_a's cache.
	$obj_a->parse_datetime('25 Dec 2022');
	my $cache_a = $obj_a->{all_dates} // {};

	# obj_b must have an empty cache (or at least not share obj_a's hashref).
	my $cache_b = $obj_b->{all_dates} // {};

	isnt(refaddr($cache_a), refaddr($cache_b),
		'per-object caches are distinct hashrefs')
		if %{$cache_a} && %{$cache_b};

	ok(!exists $cache_b->{'25 Dec 2022'},
		"obj_b cache does not contain obj_a's parsed entry");

	diag('obj_a cache keys: ' . join(', ', keys %{$cache_a}))
		if $ENV{TEST_VERBOSE};
};

subtest 'concurrent instances with different flags do not interfere' => sub {
	# quiet_obj silences carps; loud_obj emits them; they must not share flags.
	my $quiet_obj = $PKG->new(quiet => 1);
	my $loud_obj  = $PKG->new();

	# quiet_obj must not emit a carp for an approximate date.
	warnings_are(
		sub { $quiet_obj->parse_datetime('bef 1 Jan 2000') },
		[],
		'quiet_obj suppresses bef carp',
	);

	# loud_obj must still emit the carp (its quiet is not set).
	warning_like(
		sub { $loud_obj->parse_datetime('bef 1 Jan 2000') },
		qr/is invalid.*need an exact date/,
		'loud_obj emits bef carp independently',
	);
};

subtest 'concurrent instances with different strict settings' => sub {
	my $strict_obj     = $PKG->new(strict => 1, quiet => 1);
	my $nonstrict_obj  = $PKG->new(quiet  => 1);

	# strict_obj rejects long month names; nonstrict_obj accepts them.
	ok(!defined $strict_obj->parse_datetime('12 June 2020'),
		'strict_obj rejects long month name');

	my $dt = $nonstrict_obj->parse_datetime('12 June 2020');
	isa_ok($dt, 'DateTime', 'nonstrict_obj accepts long month name');
	is($dt->dmy, '12-06-2020', 'nonstrict_obj parses long month correctly');

	# Cross-check: nonstrict_obj must not have been polluted by strict_obj.
	my $dt2 = $nonstrict_obj->parse_datetime('21 Mai 1681');
	is($dt2->dmy, '21-05-1681', 'nonstrict_obj still handles French month after concurrent strict use');
};

# ===========================================================================
# SECTION 2: Constructor-flag → parse_datetime pipeline
#
# Flags set on the constructor must flow through to every subsequent call.
# Per-call values must override them in both directions.
# ===========================================================================

subtest 'quiet set at construction silences all qualifying carps' => sub {
	my $obj = $PKG->new(quiet => 1);

	Readonly my @QUIET_DATES => (
		'bef 1 Jan 2000',
		'aft 1 Jan 2000',
		'abt 1 Jan 2000',
		'xyzzy',
		'1517-06-04',          # triggers Changing date carp
		'1 Jan 2000 - 31 Dec 2000',  # triggers Changing date carp
	);

	for my $date (@QUIET_DATES) {
		warnings_are(
			sub { $obj->parse_datetime($date) },
			[],
			"quiet obj: '$date' emits no warnings",
		);
	}
};

subtest 'per-call quiet => 0 restores carps on a quiet-by-default object' => sub {
	my $obj = $PKG->new(quiet => 1);

	# Per-call quiet => 0 must unmute the carp.
	warning_like(
		sub { $obj->parse_datetime(date => 'bef 1 Jan 2000', quiet => 0) },
		qr/is invalid.*need an exact date/,
		'per-call quiet => 0 restores bef carp on quiet object',
	);
	warning_like(
		sub { $obj->parse_datetime(date => 'xyzzy', quiet => 0) },
		qr/does not parse/,
		'per-call quiet => 0 restores DFN error carp',
	);
};

subtest 'strict set at construction flows through multiple calls' => sub {
	my $obj = $PKG->new(strict => 1, quiet => 1);

	# Multiple calls across different date forms — strict must apply each time.
	ok(!defined $obj->parse_datetime('12 June 2020'),  'June rejected');
	ok(!defined $obj->parse_datetime('1 January 2020'), 'January rejected');
	ok(!defined $obj->parse_datetime('21 Mai 1681'),    'Mai rejected');

	# Valid 3-letter forms must still parse.
	is($obj->parse_datetime('29 Sep 1939')->dmy, '29-09-1939', 'Sep accepted');
	is($obj->parse_datetime('25 Dec 2022')->dmy, '25-12-2022', 'Dec accepted');

	# Per-call strict => 0 must allow long names again.
	my $dt = $obj->parse_datetime(date => '12 June 2020', strict => 0);
	isa_ok($dt, 'DateTime', 'per-call strict => 0 overrides object strict');
};

# ===========================================================================
# SECTION 3: Clone chain
#
# A clone inherits flags from its source but is otherwise independent.
# Mutations on the clone must not bleed back to the original.
# ===========================================================================

subtest 'clone inherits flags and parses independently' => sub {
	my $original = $PKG->new(quiet => 1, strict => 1);
	my $clone    = $original->new(strict => 0);

	# Clone picks up quiet => 1 from original.
	warnings_are(
		sub { $clone->parse_datetime('bef 1 Jan 2000') },
		[],
		'clone inherits quiet => 1: bef carp suppressed',
	);

	# Clone overrides strict => 0: long month names are now accepted.
	my $dt = $clone->parse_datetime('12 June 2020');
	isa_ok($dt, 'DateTime', 'clone with strict => 0 accepts long month name');

	# Original is still strict — must still reject long month names.
	ok(!defined $original->parse_datetime('12 June 2020'),
		'original remains strict after clone is created');

	# Caches are isolated: populate clone's cache and verify original is unaffected.
	$clone->parse_datetime('1 Aug 1800');
	ok(!exists($original->{all_dates}{'1 Aug 1800'}),
		"clone's cache entry did not propagate to original");
};

subtest 'double clone chain: grandchild inherits root flags' => sub {
	my $root   = $PKG->new(quiet => 1);
	my $child  = $root->new(strict => 1);
	my $grand  = $child->new();

	ok($grand->{quiet},  'grandchild retains quiet from root');
	ok($grand->{strict}, 'grandchild retains strict from child');

	warnings_are(
		sub { $grand->parse_datetime('bef 1 Jan 2000') },
		[],
		'grandchild quiet suppresses carp',
	);
	ok(!defined $grand->parse_datetime('12 June 2020'),
		'grandchild strict rejects long month name');
};

# ===========================================================================
# SECTION 4: End-to-end date rewrite → parse pipeline
#
# ISO and dash-range rewrites happen inside parse_datetime and then
# recursively feed the rewritten string back through the parser.
# ===========================================================================

subtest 'ISO YYYY-MM-DD rewrite feeds the parser correctly' => sub {
	my $obj = $PKG->new(quiet => 1);

	Readonly my %ISO_CASES => (
		'1517-06-04' => '04-06-1517',
		'1800-01-01' => '01-01-1800',
		'2000-12-31' => '31-12-2000',
		'1941-08-02' => '02-08-1941',
	);

	while (my ($iso, $expected) = each %ISO_CASES) {
		my $dt = $obj->parse_datetime($iso);
		isa_ok($dt, 'DateTime', "'$iso' parses to a DateTime");
		is($dt->dmy, $expected, "'$iso' => '$expected'") if defined $dt;
	}
};

subtest 'dash-separated range rewrite feeds bet...and... recursively' => sub {
	my $obj = $PKG->new(quiet => 1);

	# "A - B" is rewritten to "bet A and B" which is then parsed as a range.
	my @range = $obj->parse_datetime('28 Jul 1914 - 11 Nov 1918');
	is(scalar @range, 2,           'dash range yields 2-element list');
	isa_ok($range[0], 'DateTime',  'first is DateTime');
	isa_ok($range[1], 'DateTime',  'second is DateTime');
	is($range[0]->dmy, '28-07-1914', 'dash range start correct');
	is($range[1]->dmy, '11-11-1918', 'dash range end correct');
};

subtest 'bet...and... range recursion produces two independent DateTimes' => sub {
	my $obj = $PKG->new();

	my @range = $obj->parse_datetime('bet 1 Sep 1939 and 2 Sep 1945');
	is(scalar @range, 2, 'bet range yields 2 elements');

	isa_ok($range[0], 'DateTime', 'start is DateTime');
	isa_ok($range[1], 'DateTime', 'end is DateTime');

	# The two DateTimes must be independent objects.
	isnt(refaddr($range[0]), refaddr($range[1]),
		'range DateTimes are distinct references');

	is($range[0]->dmy, '01-09-1939', 'range start value');
	is($range[1]->dmy, '02-09-1945', 'range end value');

	# Scalar context must return undef, not raise an exception.
	my $scalar = $obj->parse_datetime('bet 1 Sep 1939 and 2 Sep 1945');
	ok(!defined $scalar, 'bet range in scalar context returns undef');
};

subtest 'from...to... range: non-strict accepts, strict ignores' => sub {
	my $ns = $PKG->new();
	my $st = $PKG->new(strict => 1, quiet => 1);

	my @ns_range = $ns->parse_datetime('from 1 Jan 2000 to 31 Dec 2000');
	is(scalar @ns_range, 2, 'non-strict: from...to... yields 2 elements');
	is($ns_range[0]->dmy, '01-01-2000', 'from start correct');
	is($ns_range[1]->dmy, '31-12-2000', 'from end correct');

	# Strict treats "from ... to ..." as unparseable, returns empty list.
	my @st_range = $st->parse_datetime('from 1 Jan 2000 to 31 Dec 2000');
	is(scalar @st_range, 0, 'strict: from...to... yields empty list');
};

# ===========================================================================
# SECTION 5: Per-object cache behaviour
#
# The all_dates cache must accelerate repeated identical calls on the same
# object but must not prevent correct parsing of different date strings.
# ===========================================================================

subtest 'cache accelerates repeated calls and yields equal DateTime values' => sub {
	my $obj = $PKG->new();

	Readonly my $DATE => '5 Jan 2019';

	my $first  = $obj->parse_datetime($DATE);
	my $second = $obj->parse_datetime($DATE);
	my $third  = $obj->parse_datetime($DATE);

	isa_ok($first, 'DateTime', 'first parse returns DateTime');
	is($first->dmy,  $second->dmy, 'second parse value matches first');
	is($second->dmy, $third->dmy,  'third parse value matches second');

	# Cache must contain exactly one entry for the key.
	my $cache = $obj->{all_dates} // {};
	ok(exists $cache->{$DATE}, 'date string is in the cache after first parse');
	is(scalar keys %{$cache}, 1, 'only one entry in cache after three identical calls')
		if scalar keys %{$cache} > 0;

	diag("Cache entry key: '$DATE'") if $ENV{TEST_VERBOSE};
};

subtest 'different date strings each get their own cache entry' => sub {
	my $obj = $PKG->new();

	Readonly my @DATES => ('25 Dec 2022', '5 Jan 2019', '29 Sep 1939');

	for my $date (@DATES) {
		$obj->parse_datetime($date);
	}

	my $cache = $obj->{all_dates} // {};
	for my $date (@DATES) {
		ok(exists $cache->{$date}, "cache contains entry for '$date'");
	}

	diag('Cache entries: ' . join(', ', sort keys %{$cache}))
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 6: GEDCOM calendar escapes — end-to-end with stubs installed
# ===========================================================================

subtest '@#DJULIAN@ escape applies correct offset for each century tier' => sub {
	my $obj = $PKG->new();

	# Offset tiers: <1700 => 10, <1800 => 11, <1900 => 12, >= 1900 => 13
	Readonly my %JULIAN_CASES => (
		# [ input_day, month, year ] => expected_gregorian_day (same month/year)
		'15 Mar 1620' => { day => 25, offset => 10 },
		'1 Mar 1750'  => { day => 12, offset => 11 },
		'1 Mar 1850'  => { day => 13, offset => 12 },
		'1 Mar 1920'  => { day => 14, offset => 13 },
	);

	while (my ($date_str, $expected) = each %JULIAN_CASES) {
		my $dt = $obj->parse_datetime("@#DJULIAN@ $date_str");
		isa_ok($dt, 'DateTime', "@#DJULIAN@ $date_str parses to DateTime");
		if (defined $dt) {
			is($dt->day, $expected->{day},
				"$date_str: day advanced by $expected->{offset} days");
		}
	}
};

subtest '@#DHEBREW@ escape delegates to Hebrew stub and returns converted DateTime' => sub {
	# Reset the spy array so only calls from this subtest are counted.
	@hebrew_new_calls = ();

	# Override DateTime->from_object to return a sentinel year that proves
	# _convert_calendar returned the converted object and not the original.
	Readonly my $SENTINEL_YEAR => 5783;
	no warnings 'redefine';
	local *DateTime::from_object = sub {
		return DateTime->new(year => $SENTINEL_YEAR, month => 10, day => 1);
	};

	my $obj = $PKG->new();
	my $dt  = $obj->parse_datetime('@#DHEBREW@ 9 Oct 2022');

	isa_ok($dt, 'DateTime', '@#DHEBREW@ returns a DateTime');
	is($dt->year, $SENTINEL_YEAR,
		'@#DHEBREW@: from_object result returned, not original Gregorian');

	# The stub must have been called with Gregorian coordinates from the
	# date string so that _convert_calendar passed the right year/month/day.
	is(scalar @hebrew_new_calls, 1, 'Hebrew::new called exactly once');
	is($hebrew_new_calls[0]{year},  2022, 'Hebrew::new passed correct year');
	is($hebrew_new_calls[0]{month},   10, 'Hebrew::new passed correct month');
	is($hebrew_new_calls[0]{day},      9, 'Hebrew::new passed correct day');

	diag("Hebrew stub called with: " . join(', ', map { "$_=$hebrew_new_calls[0]{$_}" } qw(year month day)))
		if $ENV{TEST_VERBOSE};
};

subtest '@#DFRENCH R@ escape delegates to FrenchRevolutionary stub' => sub {
	@french_new_calls = ();

	Readonly my $SENTINEL_YEAR => 1792;
	no warnings 'redefine';
	local *DateTime::from_object = sub {
		return DateTime->new(year => $SENTINEL_YEAR, month => 9, day => 22);
	};

	my $obj = $PKG->new();
	my $dt  = $obj->parse_datetime('@#DFRENCH R@ 22 Sep 1792');

	isa_ok($dt, 'DateTime', '@#DFRENCH R@ returns a DateTime');
	is($dt->year, $SENTINEL_YEAR,
		'@#DFRENCH R@: from_object result returned');

	is(scalar @french_new_calls, 1, 'FrenchRevolutionary::new called exactly once');

	diag("French stub called with year=$french_new_calls[0]{year}")
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 7: Optional-dependency fallbacks with Test::Without::Module
#
# When DateTime::Calendar::Hebrew or DateTime::Calendar::FrenchRevolutionary
# is absent, the module must gracefully degrade: carp (unless quiet) and
# return undef rather than dying.
#
# Test::Without::Module removes modules from %INC and blocks their loading,
# so we must run these tests before the stubs registered above could be
# re-used.  We localise %INC inside the block to undo the stub injection
# for the duration of each Without::Module scope.
# ===========================================================================

subtest 'graceful degradation without DateTime::Calendar::Hebrew' => sub {
	# Temporarily unregister the Hebrew stub so require() fails as if the
	# real module is absent.
	local %INC = %INC;
	delete $INC{'DateTime/Calendar/Hebrew.pm'};

	Test::Without::Module->import('DateTime::Calendar::Hebrew');

	my $obj = $PKG->new();

	# Must carp about conversion failure (not die).
	warning_like(
		sub { $obj->parse_datetime('@#DHEBREW@ 9 Oct 2022') },
		qr/Hebrew calendar conversion failed/,
		'missing Hebrew module: parse_datetime carps',
	);

	# With quiet => 1 the carp must be suppressed and undef returned.
	warnings_are(
		sub {
			my $rc = $obj->parse_datetime(date => '@#DHEBREW@ 9 Oct 2022', quiet => 1);
			ok(!defined $rc, 'missing Hebrew module + quiet: returns undef');
		},
		[],
		'missing Hebrew module + quiet: no warnings',
	);

	Test::Without::Module->unimport('DateTime::Calendar::Hebrew');

	# Re-register the stub so later tests can still use it.
	$INC{'DateTime/Calendar/Hebrew.pm'} = 1;
};

subtest 'graceful degradation without DateTime::Calendar::FrenchRevolutionary' => sub {
	local %INC = %INC;
	delete $INC{'DateTime/Calendar/FrenchRevolutionary.pm'};

	Test::Without::Module->import('DateTime::Calendar::FrenchRevolutionary');

	my $obj = $PKG->new();

	warning_like(
		sub { $obj->parse_datetime('@#DFRENCH R@ 22 Sep 1792') },
		qr/French Republican calendar conversion failed/,
		'missing FrenchRevolutionary module: parse_datetime carps',
	);

	warnings_are(
		sub {
			my $rc = $obj->parse_datetime(date => '@#DFRENCH R@ 22 Sep 1792', quiet => 1);
			ok(!defined $rc, 'missing FrenchRevolutionary + quiet: returns undef');
		},
		[],
		'missing FrenchRevolutionary + quiet: no warnings',
	);

	Test::Without::Module->unimport('DateTime::Calendar::FrenchRevolutionary');
	$INC{'DateTime/Calendar/FrenchRevolutionary.pm'} = 1;
};

subtest 'graceful degradation with both optional calendar modules absent' => sub {
	local %INC = %INC;
	delete $INC{'DateTime/Calendar/Hebrew.pm'};
	delete $INC{'DateTime/Calendar/FrenchRevolutionary.pm'};

	Test::Without::Module->import(
		'DateTime::Calendar::Hebrew',
		'DateTime::Calendar::FrenchRevolutionary',
	);

	my $obj = $PKG->new(quiet => 1);

	# Core functionality must be completely unaffected.
	my $dt = $obj->parse_datetime('25 Dec 2022');
	isa_ok($dt, 'DateTime', 'core parse works without optional calendar modules');
	is($dt->dmy, '25-12-2022', 'correct date value');

	my $julian = $obj->parse_datetime('@#DJULIAN@ 15 Mar 1620');
	isa_ok($julian, 'DateTime', 'DJULIAN works without optional calendar modules');
	is($julian->day, 25, 'Julian offset still applied');

	# Both optional escapes must degrade gracefully (no die, no exception).
	my $h = $obj->parse_datetime('@#DHEBREW@ 9 Oct 2022');
	ok(!defined $h, 'DHEBREW with both absent returns undef (quiet)');

	my $f = $obj->parse_datetime('@#DFRENCH R@ 22 Sep 1792');
	ok(!defined $f, 'DFRENCH R with both absent returns undef (quiet)');

	Test::Without::Module->unimport(
		'DateTime::Calendar::Hebrew',
		'DateTime::Calendar::FrenchRevolutionary',
	);
	$INC{'DateTime/Calendar/Hebrew.pm'}             = 1;
	$INC{'DateTime/Calendar/FrenchRevolutionary.pm'} = 1;
};

# ===========================================================================
# SECTION 8: Class-method and bare-function calling forms
#
# All documented invocation styles must produce the same result regardless
# of whether a constructor was called first.
# ===========================================================================

subtest 'all documented calling forms produce consistent results' => sub {
	Readonly my $DATE   => '29 Sep 1939';
	Readonly my $EXPECT => '29-09-1939';

	my $obj = $PKG->new();

	my @forms = (
		[ sub { $obj->parse_datetime($DATE)->dmy },               'object + plain string'    ],
		[ sub { $obj->parse_datetime(date => $DATE)->dmy },       'object + named arg'       ],
		[ sub { $obj->parse_datetime({ date => $DATE })->dmy },   'object + hashref'         ],
		[ sub { $PKG->parse_datetime($DATE)->dmy },               'class method + string'    ],
		[ sub { $PKG->parse_datetime({ date => $DATE })->dmy },   'class method + hashref'   ],
		[ sub { DateTime::Format::Genealogy::parse_datetime($DATE)->dmy }, 'bare function'   ],
	);

	for my $pair (@forms) {
		my ($code, $label) = @{$pair};
		is($code->(), $EXPECT, $label);
	}
};

# ===========================================================================
# SECTION 9: Global state integrity across multiple calls
#
# parse_datetime must not clobber $_, $!, or $@ between calls.
# ===========================================================================

subtest 'parse_datetime does not clobber global variables across multiple calls' => sub {
	my $obj = $PKG->new(quiet => 1);

	# Prime $_ so a clobber would be detectable.
	local $_ = 'sentinel';

	$obj->parse_datetime('25 Dec 2022');
	is($_, 'sentinel', '$_ intact after successful parse');

	$obj->parse_datetime('xyzzy');
	is($_, 'sentinel', '$_ intact after failed parse');

	$obj->parse_datetime('bef 1 Jan 2000');
	is($_, 'sentinel', '$_ intact after approximate-date parse');

	$obj->parse_datetime('bet 1 Jan 2000 and 31 Dec 2000');
	is($_, 'sentinel', '$_ intact after range parse (scalar context)');

	# Check $@ is not left in an error state.
	eval { 1 };
	my $pre_at = $@;
	$obj->parse_datetime('25 Dec 2022');
	is($@, $pre_at, '$@ not clobbered after successful parse');
};

# ===========================================================================
# SECTION 10: Non-standard month names — end-to-end alias table coverage
#
# Every entry in %MONTH_ALIAS (non-strict mode) must round-trip correctly
# through a full parse_datetime call.
# ===========================================================================

subtest 'every MONTH_ALIAS entry parses correctly end-to-end' => sub {
	my $obj = $PKG->new();

	# month_input => expected DMY
	Readonly my %ALIAS_CASES => (
		'1 January 2020'    => '01-01-2020',
		'1 February 2020'   => '01-02-2020',
		'1 March 2020'      => '01-03-2020',
		'1 April 2020'      => '01-04-2020',
		'12 June 2020'      => '12-06-2020',
		'8 July 2020'       => '08-07-2020',
		'1 August 2020'     => '01-08-2020',
		'27 September 2020' => '27-09-2020',
		'1 October 2020'    => '01-10-2020',
		'1 November 2020'   => '01-11-2020',
		'1 December 2020'   => '01-12-2020',
		# Common abbreviation variant
		'27 Sept 1791'      => '27-09-1791',
		# French/German variants
		'1 Janv 1752'       => '01-01-1752',
		'8 Juli 1817'       => '08-07-1817',
		'21 Mai 1681'       => '21-05-1681',
		# Dash-separated single-date format
		'29-Aug-1938'       => '29-08-1938',
	);

	while (my ($input, $expected) = each %ALIAS_CASES) {
		my $dt = $obj->parse_datetime($input);
		ok(defined $dt, "MONTH_ALIAS: '$input' is accepted in non-strict mode");
		is($dt->dmy, $expected, "'$input' => '$expected'") if defined $dt;
	}
};

done_testing();
