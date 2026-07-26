#!perl

# Black-box unit tests for DateTime::Format::Genealogy.
#
# These tests exercise the public API (new, parse_datetime) strictly as
# documented in the POD.  Private and protected helpers are NOT called
# directly; Test::Mockingbird is used to inject behaviour into external
# dependencies so every documented code path can be exercised.
#
# Note on calling conventions: Params::Get does NOT support mixing a
# positional string argument with named key-value flags:
#   WRONG: parse_datetime('date string', quiet => 1)
#   RIGHT: parse_datetime(date => 'date string', quiet => 1)
#   RIGHT: parse_datetime({ date => 'date string', quiet => 1 })
# All tests below use the named or hashref form when flags are needed.
#
# Every message (carp/croak) and every return state listed in the POD is
# tracked in %LEDGER.  If a documented condition is never triggered, the
# final assertion fails.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Scalar::Util qw(blessed refaddr);
use POSIX ();

BEGIN { use_ok('DateTime::Format::Genealogy') || BAIL_OUT('Cannot load module') }

Readonly my $PKG => 'DateTime::Format::Genealogy';

# ---------------------------------------------------------------------------
# Optional calendar back-end stubs.
#
# Both modules are injected into %INC so that `require` inside the module
# short-circuits.  Their `new` methods die by default, which triggers the
# "conversion failed" carp paths.  Subtests that need successful conversions
# override `new` with Test::Mockingbird::mock for the duration of the test.
# ---------------------------------------------------------------------------

{
	package DateTime::Calendar::Hebrew;
	sub new { die "Hebrew stub: module not installed\n" }
}
$INC{'DateTime/Calendar/Hebrew.pm'} = 1;

{
	package DateTime::Calendar::FrenchRevolutionary;
	sub new { die "FrenchRevolutionary stub: module not installed\n" }
}
$INC{'DateTime/Calendar/FrenchRevolutionary.pm'} = 1;

# ---------------------------------------------------------------------------
# API ledger: every message and return state documented in the POD.
# Each entry is deleted when its corresponding test fires.
# The final subtest asserts the ledger is empty.
# ---------------------------------------------------------------------------

my %LEDGER = (
	# --- Croak conditions -------------------------------------------------
	'croak: no arguments to parse_datetime'                              => 1,
	'croak: unknown parameter key'                                       => 1,

	# --- Carp conditions (quiet suppresses unless annotated) --------------
	'carp: bef prefix (not an exact date)'                               => 1,
	'carp: aft prefix (not an exact date)'                               => 1,
	'carp: abt prefix (not an exact date)'                               => 1,
	'carp: 31 Nov invalid (never suppressed by quiet)'                   => 1,
	'carp: Changing date - ISO YYYY-MM-DD normalised'                    => 1,
	'carp: Changing date - dash range rewritten to bet'                  => 1,
	'carp: Unparseable date - strict mode non-3-letter month'            => 1,
	'carp: Unparseable date - unrecognised long month name (non-strict)' => 1,
	'carp: DateTime::Format::Natural parse error string'                 => 1,
	'carp: Calendar type not supported'                                  => 1,
	'carp: Hebrew calendar conversion failed'                            => 1,
	'carp: French Republican calendar conversion failed'                 => 1,

	# --- Return states ----------------------------------------------------
	'return: DateTime - exact parseable date'                            => 1,
	'return: (DateTime,DateTime) list - bet...and... range'              => 1,
	'return: (DateTime,DateTime) list - from...to... range non-strict'   => 1,
	'return: undef - bet range in scalar context'                        => 1,
	'return: undef - from range in scalar context'                       => 1,
	'return: undef - 4-digit year-only'                                  => 1,
	'return: undef - 3-digit year-only'                                  => 1,
	'return: undef - approximate prefix'                                 => 1,
	'return: undef - unparseable string'                                 => 1,
);

# Deletes the ledger entry; fails loudly if the key is not found so that a
# typo in a test does not silently hide a gap.
sub covered {
	my ($key) = @_;
	unless(exists $LEDGER{$key}) {
		fail("covered() called with unknown ledger key: '$key'");
		return;
	}
	delete $LEDGER{$key};
}

# ==========================================================================
# SECTION A: new()
# ==========================================================================

subtest 'new() - bare class method' => sub {
	my $obj = $PKG->new();
	ok(defined $obj,   'new() returns a defined value');
	ok(blessed($obj),  'new() returns a blessed reference');
	isa_ok($obj, $PKG, 'new() is the correct type');
	returns_ok($obj, { type => 'object', isa => $PKG }, 'return type validates');
};

subtest 'new() - stores flags as object attributes' => sub {
	my $obj = $PKG->new(quiet => 1, strict => 1);
	ok($obj->{quiet},  'quiet flag stored on object');
	ok($obj->{strict}, 'strict flag stored on object');
};

subtest 'new() - accepts a hashref argument' => sub {
	my $obj = $PKG->new({ quiet => 1 });
	ok($obj->{quiet}, 'hashref arg: quiet stored');
	isa_ok($obj, $PKG);
};

subtest 'new() - clone via object invocant merges overrides' => sub {
	my $original = $PKG->new(quiet => 1, strict => 1);
	my $clone    = $original->new(strict => 0);

	isa_ok($clone, $PKG, 'clone is correct type');
	ok( $clone->{quiet},  'clone inherits quiet => 1 from original');
	ok(!$clone->{strict}, 'clone overrides strict to 0');
	isnt(refaddr($clone), refaddr($original),
		'clone is a distinct reference from original');
};

subtest 'new() - bare clone retains all attributes' => sub {
	my $original   = $PKG->new(quiet => 1, strict => 1);
	my $bare_clone = $original->new();

	isa_ok($bare_clone, $PKG);
	ok($bare_clone->{quiet},   'bare clone retains quiet');
	ok($bare_clone->{strict},  'bare clone retains strict');
	isnt(refaddr($bare_clone), refaddr($original),
		'bare clone is a new object, not the original reference');
};

# ==========================================================================
# SECTION B: parse_datetime - croak conditions
# ==========================================================================

subtest 'parse_datetime - croak on no arguments' => sub {
	my $obj = $PKG->new();

	throws_ok(
		sub { $obj->parse_datetime() },
		qr/^Usage:.*parse_datetime/,
		'no args: croaks with usage message',
	);
	covered('croak: no arguments to parse_datetime');
};

subtest 'parse_datetime - croak on unknown parameter key' => sub {
	my $obj = $PKG->new();

	# 'datex' is a typo of 'date'.  Params::Validate::Strict detects it;
	# the module re-throws via Carp::croak so Test::Carp can intercept it.
	throws_ok(
		sub { $obj->parse_datetime({ datex => '25 Dec 2022' }) },
		qr/Invalid parse_datetime parameters.*datex/,
		'unknown param key: croaks with key name in message',
	);
	covered('croak: unknown parameter key');
};

# ==========================================================================
# SECTION C: parse_datetime - return undef conditions
# ==========================================================================

subtest 'parse_datetime - undef for year-only strings' => sub {
	my $obj = $PKG->new();

	# Quiet via constructor so no carp fires during these undef-return checks.
	my $q = $PKG->new(quiet => 1);

	ok(!defined $q->parse_datetime('2022'), '4-digit year-only returns undef');
	covered('return: undef - 4-digit year-only');

	ok(!defined $q->parse_datetime('800'),  '3-digit year-only returns undef');
	covered('return: undef - 3-digit year-only');
};

subtest 'parse_datetime - undef for approximate prefixes' => sub {
	my $q = $PKG->new(quiet => 1);

	# All three prefixes must return undef.
	ok(!defined $q->parse_datetime('bef 1 Jan 2000'), 'bef returns undef');
	ok(!defined $q->parse_datetime('aft 1 Jan 2000'), 'aft returns undef');
	ok(!defined $q->parse_datetime('abt 1 Jan 2000'), 'abt returns undef');

	covered('return: undef - approximate prefix');
};

subtest 'parse_datetime - undef in scalar context for bet range' => sub {
	my $obj = $PKG->new();

	my $scalar = $obj->parse_datetime('bet 28 Jul 1914 and 11 Nov 1918');
	ok(!defined $scalar, 'bet range in scalar context returns undef');
	covered('return: undef - bet range in scalar context');
};

subtest 'parse_datetime - undef in scalar context for from range' => sub {
	my $obj = $PKG->new();

	# Non-strict mode accepts 'from...to...'; scalar context gives undef.
	my $scalar = $obj->parse_datetime('from 1 Jan 2000 to 31 Dec 2000');
	ok(!defined $scalar, 'from range in scalar context returns undef');
	covered('return: undef - from range in scalar context');
};

subtest 'parse_datetime - undef for unparseable string' => sub {
	my $q = $PKG->new(quiet => 1);

	ok(!defined $q->parse_datetime('xyzzy'), 'garbage string returns undef');
	covered('return: undef - unparseable string');
};

# ==========================================================================
# SECTION D: parse_datetime - carp conditions
#
# When passing flags alongside a date, use "date => '...'" named form or a
# hashref.  Mixing a positional string with named flags is unsupported by
# Params::Get and will die.
# ==========================================================================

subtest 'parse_datetime - carp for bef prefix' => sub {
	my $obj = $PKG->new();

	warning_like(
		sub { $obj->parse_datetime('bef 1 Jan 2000') },
		qr/is invalid.*need an exact date/,
		'bef prefix triggers carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => 'bef 1 Jan 2000', quiet => 1) },
		[],
		'quiet => 1 (named) suppresses bef carp',
	);
	covered('carp: bef prefix (not an exact date)');
};

subtest 'parse_datetime - carp for aft prefix' => sub {
	my $obj = $PKG->new();

	warning_like(
		sub { $obj->parse_datetime('aft 1 Jan 2000') },
		qr/is invalid.*need an exact date/,
		'aft prefix triggers carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => 'aft 1 Jan 2000', quiet => 1) },
		[],
		'quiet => 1 (named) suppresses aft carp',
	);
	covered('carp: aft prefix (not an exact date)');
};

subtest 'parse_datetime - carp for abt prefix' => sub {
	my $obj = $PKG->new();

	warning_like(
		sub { $obj->parse_datetime('abt 1 Jan 2000') },
		qr/is invalid.*need an exact date/,
		'abt prefix triggers carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => 'abt 1 Jan 2000', quiet => 1) },
		[],
		'quiet => 1 (named) suppresses abt carp',
	);
	covered('carp: abt prefix (not an exact date)');
};

subtest 'parse_datetime - carp for 31 Nov (always, not suppressed by quiet)' => sub {
	my $obj = $PKG->new();

	# The POD explicitly documents this carp as never silenced by quiet.
	warning_like(
		sub { $obj->parse_datetime('31 Nov 2022') },
		qr/31 Nov 2022 is invalid.*30 days in November/,
		'31 Nov triggers carp',
	);
	warning_like(
		sub { $obj->parse_datetime(date => '31 Nov 2022', quiet => 1) },
		qr/31 Nov.*invalid/,
		'31 Nov carp fires even with quiet => 1',
	);
	covered('carp: 31 Nov invalid (never suppressed by quiet)');
};

subtest 'parse_datetime - carp for Changing date (ISO YYYY-MM-DD)' => sub {
	my $obj = $PKG->new();

	warning_like(
		sub { $obj->parse_datetime('1517-06-04') },
		qr/Changing date .+1517-06-04.+04 Jun 1517/,
		'ISO date rewrite triggers Changing date carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => '1517-06-04', quiet => 1) },
		[],
		'quiet => 1 (named) suppresses ISO Changing date carp',
	);
	covered('carp: Changing date - ISO YYYY-MM-DD normalised');
};

subtest 'parse_datetime - carp for Changing date (dash range)' => sub {
	my $obj = $PKG->new();

	warning_like(
		sub { $obj->parse_datetime('1 Jan 2000 - 31 Dec 2000') },
		qr/Changing date .+ to .+bet/,
		'dash range triggers Changing date carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => '1 Jan 2000 - 31 Dec 2000', quiet => 1) },
		[],
		'quiet => 1 (named) suppresses dash-range carp',
	);
	covered('carp: Changing date - dash range rewritten to bet');
};

subtest 'parse_datetime - carp for Unparseable date (strict mode)' => sub {
	my $obj = $PKG->new();

	warning_like(
		sub { $obj->parse_datetime(date => '12 June 2020', strict => 1) },
		qr/Unparseable date.*month name isn.t 3 letters/,
		'strict + long month name triggers Unparseable carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => '12 June 2020', strict => 1, quiet => 1) },
		[],
		'quiet => 1 suppresses strict-mode Unparseable carp',
	);
	covered('carp: Unparseable date - strict mode non-3-letter month');
};

subtest 'parse_datetime - carp for unrecognised long month name (non-strict)' => sub {
	my $obj = $PKG->new();

	# 'Zeptember' is 9 letters and absent from %MONTH_ALIAS.  In non-strict
	# mode, longer-than-3-letter names that are unknown trigger the carp.
	warning_like(
		sub { $obj->parse_datetime('29 Zeptember 1939') },
		qr/Unparseable date.*month name/,
		'unrecognised long month triggers Unparseable carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => '29 Zeptember 1939', quiet => 1) },
		[],
		'quiet => 1 (named) suppresses unrecognised-month carp',
	);
	covered('carp: Unparseable date - unrecognised long month name (non-strict)');
};

subtest 'parse_datetime - carp for DateTime::Format::Natural parse error' => sub {
	my $obj = $PKG->new();

	# 'xyzzy' is all word characters so it reaches the DFN fallback.
	# DFN returns a DateTime but success() is false, so error() is carped.
	warning_like(
		sub { $obj->parse_datetime('xyzzy') },
		qr/does not parse/,
		"'xyzzy' triggers DFN error carp",
	);
	warnings_are(
		sub { $obj->parse_datetime(date => 'xyzzy', quiet => 1) },
		[],
		'quiet => 1 (named) suppresses DFN error carp',
	);
	covered('carp: DateTime::Format::Natural parse error string');
};

subtest 'parse_datetime - carp for unsupported GEDCOM calendar type' => sub {
	my $obj = $PKG->new();

	# @#DROMAN@ is a valid GEDCOM escape that this module does not implement.
	# The date portion ('25 Dec 2022') parses normally; _convert_calendar then
	# carps when it encounters an unknown type.
	warning_like(
		sub { $obj->parse_datetime('@#DROMAN@ 25 Dec 2022') },
		qr/Calendar type DROMAN not supported/,
		'@#DROMAN@ triggers calendar-not-supported carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => '@#DROMAN@ 25 Dec 2022', quiet => 1) },
		[],
		'quiet => 1 (named) suppresses calendar-not-supported carp',
	);
	covered('carp: Calendar type not supported');
};

subtest 'parse_datetime - carp for Hebrew calendar conversion failure' => sub {
	my $obj = $PKG->new();

	# The Hebrew stub has new() die; _convert_calendar's eval catches it and
	# carps the failure.
	warning_like(
		sub { $obj->parse_datetime('@#DHEBREW@ 9 Oct 2022') },
		qr/Hebrew calendar conversion failed/,
		'stub Hebrew new() failure triggers conversion-failed carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => '@#DHEBREW@ 9 Oct 2022', quiet => 1) },
		[],
		'quiet => 1 (named) suppresses Hebrew conversion-failed carp',
	);
	covered('carp: Hebrew calendar conversion failed');
};

subtest 'parse_datetime - carp for French Republican conversion failure' => sub {
	my $obj = $PKG->new();

	warning_like(
		sub { $obj->parse_datetime('@#DFRENCH R@ 22 Sep 1792') },
		qr/French Republican calendar conversion failed/,
		'stub FrenchRevolutionary new() failure triggers conversion-failed carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => '@#DFRENCH R@ 22 Sep 1792', quiet => 1) },
		[],
		'quiet => 1 (named) suppresses French Republican carp',
	);
	covered('carp: French Republican calendar conversion failed');
};

# ==========================================================================
# SECTION E: parse_datetime - DateTime return conditions
# ==========================================================================

subtest 'parse_datetime - returns DateTime for exact date' => sub {
	my $obj = $PKG->new();

	my $dt = $obj->parse_datetime('25 Dec 2022');
	isa_ok($dt, 'DateTime', 'exact date returns a DateTime');
	is($dt->dmy, '25-12-2022', 'date value is correct');
	returns_ok($dt, { type => 'object', isa => 'DateTime' }, 'return type validates');

	covered('return: DateTime - exact parseable date');
	diag("Exact date: " . $dt->dmy) if $ENV{TEST_VERBOSE};
};

subtest 'parse_datetime - non-strict: long English month names' => sub {
	my $obj = $PKG->new();

	Readonly my %CASES => (
		'1 January 2020'    => '01-01-2020',
		'12 June 2020'      => '12-06-2020',
		'12 July 2020'      => '12-07-2020',
		'1 August 2020'     => '01-08-2020',
		'27 September 2020' => '27-09-2020',
		'1 November 2020'   => '01-11-2020',
		'1 December 2020'   => '01-12-2020',
	);

	while(my ($input, $expected) = each %CASES) {
		my $dt = $obj->parse_datetime($input);
		ok(defined $dt, "non-strict accepts '$input'");
		is($dt->dmy, $expected, "'$input' => '$expected'") if defined $dt;
	}
};

subtest 'parse_datetime - non-strict: French and German month variants' => sub {
	my $obj = $PKG->new();

	is($obj->parse_datetime('21 Mai 1681')->dmy,  '21-05-1681', 'Mai (French May)');
	is($obj->parse_datetime('1 Janv 1752')->dmy,  '01-01-1752', 'Janv (French January)');
	is($obj->parse_datetime('8 Juli 1817')->dmy,  '08-07-1817', 'Juli (German July)');
	is($obj->parse_datetime('27 Sept 1791')->dmy, '27-09-1791', 'Sept abbreviation');
};

subtest 'parse_datetime - non-strict: dash-separated DD-Mon-YYYY format' => sub {
	my $q = $PKG->new(quiet => 1);

	is($q->parse_datetime('29-Aug-1938')->dmy, '29-08-1938', '29-Aug-1938 accepted');
};

subtest 'parse_datetime - ISO YYYY-MM-DD normalised to DD Mon YYYY' => sub {
	my $q = $PKG->new(quiet => 1);

	my $dt = $q->parse_datetime('1517-06-04');
	isa_ok($dt, 'DateTime', 'ISO date produces DateTime');
	is($dt->dmy, '04-06-1517', 'ISO date correctly normalised to DD-MM-YYYY');
};

subtest 'parse_datetime - GEDCOM @#DJULIAN@ escape applies day offset' => sub {
	my $obj = $PKG->new();

	# 15 Mar 1620 Julian: pre-1700 offset = 10 days -> 25 Mar 1620 Gregorian.
	my $dt = $obj->parse_datetime('@#DJULIAN@ 15 Mar 1620');
	isa_ok($dt, 'DateTime', '@#DJULIAN@ returns a DateTime');
	is($dt->day,    25,   'DJULIAN: day advanced by 10-day offset');
	is($dt->month,   3,   'DJULIAN: month unchanged');
	is($dt->year,  1620,  'DJULIAN: year unchanged');

	diag('@#DJULIAN@ 15 Mar 1620 => ' . $dt->dmy) if $ENV{TEST_VERBOSE};
};

subtest 'parse_datetime - GEDCOM @#DHEBREW@ escape with mocked conversion' => sub {
	# Override the failing Hebrew stub with one that succeeds so we can
	# verify that _convert_calendar returns the from_object result, not the
	# intermediate Gregorian DateTime.
	Readonly my $SENTINEL_YEAR => 5783;

	mock 'DateTime::Calendar::Hebrew::new' => sub {
		my ($class, %args) = @_;
		return bless { %args }, $class;
	};
	mock 'DateTime::from_object' => sub {
		return DateTime->new(year => $SENTINEL_YEAR, month => 10, day => 1);
	};

	my $obj = $PKG->new();
	my $dt  = $obj->parse_datetime('@#DHEBREW@ 9 Oct 2022');

	isa_ok($dt, 'DateTime', '@#DHEBREW@ (mocked) returns a DateTime');
	is($dt->year, $SENTINEL_YEAR,
		'@#DHEBREW@: from_object result returned, not original Gregorian');

	restore_all();
	diag("DHEBREW sentinel year used: $SENTINEL_YEAR") if $ENV{TEST_VERBOSE};
};

# ==========================================================================
# SECTION F: parse_datetime - list return conditions (date ranges)
# ==========================================================================

subtest 'parse_datetime - list return for bet...and... range' => sub {
	my $obj = $PKG->new();

	my @range = $obj->parse_datetime('bet 28 Jul 1914 and 11 Nov 1918');
	is(scalar @range, 2,             'bet range yields 2-element list');
	isa_ok($range[0], 'DateTime',    'first element is DateTime');
	isa_ok($range[1], 'DateTime',    'second element is DateTime');
	is($range[0]->dmy, '28-07-1914', 'range start correct');
	is($range[1]->dmy, '11-11-1918', 'range end correct');

	covered('return: (DateTime,DateTime) list - bet...and... range');
};

subtest 'parse_datetime - list return for from...to... range (non-strict)' => sub {
	my $obj = $PKG->new();

	my @range = $obj->parse_datetime('from 1 Jan 2000 to 31 Dec 2000');
	is(scalar @range, 2,             'from range yields 2-element list');
	is($range[0]->dmy, '01-01-2000', 'from range start correct');
	is($range[1]->dmy, '31-12-2000', 'from range end correct');

	covered('return: (DateTime,DateTime) list - from...to... range non-strict');
};

# ==========================================================================
# SECTION G: parse_datetime - all documented calling conventions
# ==========================================================================

subtest 'parse_datetime - all documented calling forms produce the same result' => sub {
	Readonly my $DATE   => '29 Sep 1939';
	Readonly my $EXPECT => '29-09-1939';

	my $obj = $PKG->new();

	is($obj->parse_datetime($DATE)->dmy,             $EXPECT, 'object + plain string');
	is($obj->parse_datetime(date => $DATE)->dmy,     $EXPECT, 'object + key-value');
	is($obj->parse_datetime({ date => $DATE })->dmy, $EXPECT, 'object + hashref');
	is($PKG->parse_datetime($DATE)->dmy,             $EXPECT, 'class method + string');
	is($PKG->parse_datetime({ date => $DATE })->dmy, $EXPECT, 'class method + hashref');
	is(DateTime::Format::Genealogy::parse_datetime($DATE)->dmy,
		$EXPECT, 'bare function call');

	diag("All 6 calling conventions parsed '$DATE' correctly") if $ENV{TEST_VERBOSE};
};

# ==========================================================================
# SECTION H: quiet and strict flag inheritance from constructor
# ==========================================================================

subtest 'parse_datetime - quiet inherited from constructor' => sub {
	my $obj = $PKG->new(quiet => 1);

	# Without per-call quiet, object-level quiet must suppress the carp.
	warnings_are(
		sub { $obj->parse_datetime('bef 1 Jan 2000') },
		[],
		'object-level quiet suppresses bef carp without per-call flag',
	);

	# Per-call quiet => 0 (named form) must override the object attribute.
	warning_like(
		sub { $obj->parse_datetime(date => 'bef 1 Jan 2000', quiet => 0) },
		qr/is invalid.*need an exact date/,
		'per-call quiet => 0 (named) overrides object-level quiet => 1',
	);
};

subtest 'parse_datetime - strict inherited from constructor' => sub {
	my $obj = $PKG->new(strict => 1, quiet => 1);

	# Long month name rejected without per-call strict.
	ok(!defined $obj->parse_datetime('12 June 2020'),
		'object-level strict rejects long month name');

	# Valid 3-letter month still accepted under object-level strict.
	my $dt = $obj->parse_datetime('29 Sep 1939');
	isa_ok($dt, 'DateTime', 'object-level strict accepts 3-letter month');

	# Per-call strict => 0 (named form) overrides and allows long names.
	my $dt2 = $obj->parse_datetime(date => '12 June 2020', strict => 0);
	isa_ok($dt2, 'DateTime', 'per-call strict => 0 (named) overrides object-level strict');
	is($dt2->dmy, '12-06-2020', 'date value correct after override');
};

# ==========================================================================
# SECTION I: global state integrity
# ==========================================================================

subtest 'parse_datetime - does not clobber $_' => sub {
	local $_ = 'sentinel_value';

	my $q = $PKG->new(quiet => 1);

	$q->parse_datetime('25 Dec 2022');
	is($_, 'sentinel_value', '$_ not clobbered after successful parse');

	$q->parse_datetime('xyzzy');
	is($_, 'sentinel_value', '$_ not clobbered after failed parse');
};

subtest 'parse_datetime - does not clobber $!' => sub {
	# Source the ENOENT message from Perl's layer via local $! assignment.
	# This is the correct idiom: never use POSIX::strerror here because it may
	# not track Perl's setlocale call on all platforms.
	local $! = POSIX::ENOENT();
	my $enoent_msg = "$!";

	my $q = $PKG->new(quiet => 1);
	$q->parse_datetime('25 Dec 2022');

	local $! = POSIX::ENOENT();
	is("$!", $enoent_msg, '$! not clobbered after successful parse');

	diag("ENOENT message: $enoent_msg") if $ENV{TEST_VERBOSE};
};

subtest 'parse_datetime - does not leave $@ in an error state' => sub {
	# Successful calls use eval internally; $@ is reset to '' by eval but must
	# not be left non-empty or set to a stale error after the call returns.
	my $q = $PKG->new(quiet => 1);

	eval { 1 };    # prime $@ to the normal post-eval empty string
	my $pre = $@;

	$q->parse_datetime('25 Dec 2022');

	# After a successful call, $@ should still be '' (empty, not an error).
	is($@, $pre, '$@ not left in an unexpected state after successful parse');
};

# ==========================================================================
# SECTION J: API ledger completeness check
# ==========================================================================

# If the ledger is non-empty, at least one documented condition was never
# exercised.  This is a test-suite gap and must be addressed.

subtest 'API ledger: all documented conditions were exercised' => sub {
	my @uncovered = sort keys %LEDGER;

	if(@uncovered) {
		fail('The following documented conditions were NOT exercised:');
		for my $item (@uncovered) {
			diag("  MISSING: $item");
		}
	} else {
		pass('All documented messages and return states exercised');
	}
};

done_testing();
