#!perl

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util qw(blessed refaddr);

# Allow white-box tests to call private/protected subroutines directly.
# Under prove/make test HARNESS_ACTIVE is set and Sub::Private skips its
# enforcer automatically; this covers direct 'perl t/function.t' runs.
$Sub::Private::BYPASS = 1;

BEGIN {
	use_ok('DateTime::Format::Genealogy') || BAIL_OUT('Cannot load module');
}

Readonly my $PKG => 'DateTime::Format::Genealogy';

# -----------------------------------------------------------------------
# Inject lightweight stubs for the two optional calendar back-ends so
# the _convert_calendar tests can exercise the real conversion paths
# without requiring the optional distributions to be installed.
# We set %INC entries so that "require DateTime::Calendar::*" inside
# _convert_calendar short-circuits immediately instead of searching @INC.
# -----------------------------------------------------------------------
{
	package DateTime::Calendar::Hebrew;
	sub new {
		my ($class, %args) = @_;
		return bless { year => $args{year}, month => $args{month}, day => $args{day} }, $class;
	}
}
$INC{'DateTime/Calendar/Hebrew.pm'} = 1;

{
	package DateTime::Calendar::FrenchRevolutionary;
	sub new {
		my ($class, %args) = @_;
		return bless { year => $args{year}, month => $args{month}, day => $args{day} }, $class;
	}
}
$INC{'DateTime/Calendar/FrenchRevolutionary.pm'} = 1;

# =======================================================================
# SECTION 1: _julian_to_gregorian_offset
#
# Pure arithmetic helper with four fixed tiers.  We test every boundary
# year (the first and last year of each tier) plus a representative
# interior value.
# =======================================================================

subtest '_julian_to_gregorian_offset' => sub {
	my $fn = \&{"${PKG}::_julian_to_gregorian_offset"};

	# tier => [ boundary_years that belong to it ]
	Readonly my %TIER => (
		10 => [1400, 1699],
		11 => [1700, 1799],
		12 => [1800, 1899],
		13 => [1900, 1920, 2025],
	);

	while (my ($expected_offset, $years) = each %TIER) {
		for my $year (@{$years}) {
			is($fn->($year), $expected_offset,
				"year $year maps to offset $expected_offset");
		}
	}

	diag('_julian_to_gregorian_offset spot-checks passed') if $ENV{TEST_VERBOSE};
};

# =======================================================================
# SECTION 2: new()
#
# Verify every calling style, flag propagation, and that the object graph
# is free of circular references.
#
# Note: parse_datetime first checks its own call-time parameters for "quiet"
# and "strict", then falls back to the object's stored attributes set at
# construction time.  Per-call values always take precedence.
# =======================================================================

subtest 'new() - construction' => sub {
	# Bare class-method call
	my $obj = $PKG->new();
	ok(defined $obj,  'new() returns a defined value');
	ok(blessed($obj), 'new() returns a blessed reference');
	isa_ok($obj, $PKG);
	memory_cycle_ok($obj, 'bare new() object is cycle-free');

	# Hash arguments are stored as object attributes
	my $obj_h = $PKG->new(quiet => 1, strict => 1);
	ok($obj_h->{quiet},  'new(hash) stores quiet flag');
	ok($obj_h->{strict}, 'new(hash) stores strict flag');
	returns_ok($obj_h, { type => 'object', isa => $PKG }, 'new(hash) returns correct type');

	# Hashref argument
	my $obj_r = $PKG->new({ quiet => 1 });
	ok($obj_r->{quiet}, 'new(hashref) stores quiet flag');

	# Clone with overrides merges new values on top of the original
	my $clone = $obj_h->new(strict => 0);
	isa_ok($clone, $PKG, 'clone is correct type');
	ok($clone->{quiet},   'clone inherits quiet from original');
	ok(!$clone->{strict}, 'clone overrides strict to 0');
	memory_cycle_ok($clone, 'cloned object is cycle-free');

	# Bare clone (no overrides) must be a *distinct* object, not the original
	my $bare_clone = $obj_h->new();
	isa_ok($bare_clone, $PKG, 'bare clone is correct type');
	isnt(refaddr($bare_clone), refaddr($obj_h),
		'bare clone is a new object, not the original reference');
	ok($bare_clone->{quiet},  'bare clone retains quiet');
	ok($bare_clone->{strict}, 'bare clone retains strict');

	diag('Object keys after new(hash): ' . join(', ', sort keys %{$obj_h}))
		if $ENV{TEST_VERBOSE};
};

# =======================================================================
# SECTION 3: _date_parser_cached
#
# This private method wraps Genealogy::Gedcom::Date and memoises results
# to avoid re-parsing identical strings.  We verify: the croak contract,
# the structure of a successful parse, cache identity on a repeat call,
# and undef on unparseable input.
# =======================================================================

subtest '_date_parser_cached - croak on undef date' => sub {
	my $obj = $PKG->new();

	# The croak must fire when the date value is explicitly undef, giving
	# callers a clear usage message rather than a cryptic deep exception.
	# _date_parser_cached now takes a plain positional arg (no Params::Get).
	throws_ok(
		sub { $obj->_date_parser_cached(undef) },
		qr/Usage: _date_parser_cached/,
		'croaks with a usage message when date is undef',
	);
};

subtest '_date_parser_cached - successful parse' => sub {
	my $obj = $PKG->new();

	Readonly my $DATE_STR => '25 Dec 2022';

	my $result = $obj->_date_parser_cached($DATE_STR);
	returns_ok($result, { type => 'hashref' }, 'returns a hashref on success');

	# The hashref must carry the keys that parse_datetime relies on
	is($result->{canonical}, $DATE_STR, 'canonical key matches input');
	is($result->{day},       '25',      'day key correct');
	is($result->{month},     'Dec',     'month key correct');
	is($result->{year},      '2022',    'year key correct');

	diag('Parsed result: ' . join(', ', map { "$_ => $result->{$_}" } sort keys %{$result}))
		if $ENV{TEST_VERBOSE};
};

subtest '_date_parser_cached - result is memoised' => sub {
	my $obj = $PKG->new();

	Readonly my $DATE_STR => '29 Sep 1939';

	my $first  = $obj->_date_parser_cached($DATE_STR);
	my $second = $obj->_date_parser_cached($DATE_STR);

	# Both calls must return the *identical* reference, proving the
	# Genealogy::Gedcom::Date parser was not invoked a second time.
	is(refaddr($first), refaddr($second),
		'second call returns the same cached reference');

	memory_cycle_ok($obj, 'object with populated cache is cycle-free');
};

subtest '_date_parser_cached - undef on unparseable input' => sub {
	my $obj = $PKG->new(quiet => 1);

	# The quiet attribute on $self suppresses the internal carp here.
	# Failures are now cached as undef so repeated calls are O(1).
	my $result = $obj->_date_parser_cached('not a date xyzzy 99999');
	ok(!defined $result, 'returns undef for garbage input');
};

# =======================================================================
# SECTION 4: _convert_calendar
#
# This private function dispatches on a calendar-type string.  We test
# each branch: Julian offset arithmetic, Hebrew and French Revolutionary
# stub conversions, and the unknown-type carp path.
#
# BUG NOTE: the original code used "return ..." inside eval{} for the
# Hebrew and French Republican branches.  In Perl, "return" inside
# eval{} exits the eval block rather than the enclosing sub, so the
# converted DateTime was silently discarded and the original $dt was
# returned.  The tests below assert the *intended* behaviour (return the
# converted DateTime); the corresponding fix is applied to the module.
# =======================================================================

subtest '_convert_calendar - DJULIAN' => sub {
	my $fn = \&{"${PKG}::_convert_calendar"};

	# 15 Mar 1620 Julian = 25 Mar 1620 Gregorian (pre-1700 offset = 10 days)
	my $julian_dt = DateTime->new(year => 1620, month => 3, day => 15);
	my $gregorian  = $fn->($julian_dt, 'DJULIAN', 0);

	isa_ok($gregorian, 'DateTime', 'DJULIAN returns a DateTime');
	is($gregorian->year,  1620, 'DJULIAN: year unchanged');
	is($gregorian->month,    3, 'DJULIAN: month unchanged');
	is($gregorian->day,     25, 'DJULIAN: day advanced by 10-day offset');

	# Verify the offset helper is called with the correct year
	my $spy = spy("${PKG}::_julian_to_gregorian_offset");
	$fn->($julian_dt, 'DJULIAN', 0);
	my @calls = $spy->();
	is(scalar @calls, 1, '_julian_to_gregorian_offset called exactly once');
	is($calls[0][1], 1620, 'offset helper receives the correct year');
	restore_all();

	diag('DJULIAN result: ' . $gregorian->dmy) if $ENV{TEST_VERBOSE};
};

subtest '_convert_calendar - DHEBREW returns converted DateTime' => sub {
	my $fn = \&{"${PKG}::_convert_calendar"};

	# Stub DateTime->from_object with a sentinel year so we can distinguish
	# "returned the converted object" from "returned the original $dt".
	Readonly my $CONVERTED_YEAR => 5783;
	mock 'DateTime::from_object' => sub {
		return DateTime->new(year => $CONVERTED_YEAR, month => 10, day => 1);
	};

	my $original = DateTime->new(year => 2022, month => 10, day => 9);
	my $result   = $fn->($original, 'DHEBREW', 0);

	isa_ok($result, 'DateTime', 'DHEBREW returns a DateTime');
	is($result->year, $CONVERTED_YEAR,
		'DHEBREW returns the converted DateTime, not the original');

	restore_all();

	diag('DHEBREW converted year: ' . $result->year) if $ENV{TEST_VERBOSE};
};

subtest '_convert_calendar - DFRENCH R returns converted DateTime' => sub {
	my $fn = \&{"${PKG}::_convert_calendar"};

	# Sentinel: any year that differs from the input year proves conversion ran
	Readonly my $SENTINEL_YEAR => 2000;
	mock 'DateTime::from_object' => sub {
		return DateTime->new(year => $SENTINEL_YEAR, month => 9, day => 22);
	};

	my $original = DateTime->new(year => 1792, month => 9, day => 22);
	my $result   = $fn->($original, 'DFRENCH R', 0);

	isa_ok($result, 'DateTime', 'DFRENCH R returns a DateTime');
	is($result->year, $SENTINEL_YEAR,
		'DFRENCH R returns the converted DateTime, not the original');

	restore_all();
};

subtest '_convert_calendar - unknown type carps and passes through' => sub {
	my $fn = \&{"${PKG}::_convert_calendar"};

	my $dt = DateTime->new(year => 2000, month => 6, day => 15);

	# An unrecognised calendar type should carp but return $dt unchanged
	my $result;
	warning_like(
		sub { $result = $fn->($dt, 'DROMAN', 0) },
		qr/Calendar type DROMAN not supported/,
		'unknown calendar type emits a carp',
	);
	is($result, $dt, 'unknown calendar: original DateTime returned unchanged');

	# With quiet set, the carp must be suppressed entirely
	my $quiet_result;
	warnings_are(
		sub { $quiet_result = $fn->($dt, 'DROMAN', 1) },
		[],
		'quiet flag suppresses carp for unknown calendar',
	);
	is($quiet_result, $dt, 'quiet + unknown calendar: original DateTime still returned');
};

# =======================================================================
# SECTION 5: parse_datetime - calling conventions
#
# parse_datetime must accept a plain string, a key-value pair, a hashref,
# and work when called as a class method or a bare function.
# =======================================================================

subtest 'parse_datetime - all calling conventions produce the same result' => sub {
	Readonly my $DATE_STR => '29 Sep 1939';
	Readonly my $EXPECTED => '29-09-1939';

	my $obj = $PKG->new();

	is($obj->parse_datetime($DATE_STR)->dmy,              $EXPECTED, 'object + plain string');
	is($obj->parse_datetime(date => $DATE_STR)->dmy,      $EXPECTED, 'object + key-value pair');
	is($obj->parse_datetime({ date => $DATE_STR })->dmy,  $EXPECTED, 'object + hashref');
	is($PKG->parse_datetime($DATE_STR)->dmy,              $EXPECTED, 'class method + string');
	is($PKG->parse_datetime({ date => $DATE_STR })->dmy,  $EXPECTED, 'class method + hashref');
	is(DateTime::Format::Genealogy::parse_datetime($DATE_STR)->dmy, $EXPECTED, 'bare function call');

	# Return type validation
	my $dt = $obj->parse_datetime($DATE_STR);
	returns_ok($dt, { type => 'object', isa => 'DateTime' }, 'returns a DateTime object');

	diag("Parsed '$DATE_STR' => " . $dt->dmy) if $ENV{TEST_VERBOSE};
};

# =======================================================================
# SECTION 6: parse_datetime - croak contract
# =======================================================================

subtest 'parse_datetime - croaks on missing or undef date' => sub {
	my $obj = $PKG->new();

	# No arguments at all: our guard must fire before Params::Get gets a chance
	# to croak with its own message (which Test::Carp cannot intercept because
	# Params::Get uses a compile-time-imported croak symbol).
	throws_ok(
		sub { $obj->parse_datetime() },
		qr/^Usage:.*parse_datetime/,
		'no args: croaks with module usage message',
	);

	throws_ok(
		sub { $obj->parse_datetime(date => undef) },
		qr/^Usage:.*parse_datetime/,
		'explicit undef date: croaks with module usage message',
	);
};

# =======================================================================
# SECTION 7: parse_datetime - dates that must return undef
# =======================================================================

subtest 'parse_datetime - returns undef for rejected date forms' => sub {
	my $obj = $PKG->new();

	# Year-only strings carry no day/month precision for genealogical use.
	# quiet => 1 is passed per-call because parse_datetime reads it from
	# call parameters, not from the object's stored attributes.
	ok(!defined $obj->parse_datetime(date => '2022', quiet => 1),
		'year-only string returns undef');
	ok(!defined $obj->parse_datetime(date => '800', quiet => 1),
		'3-digit year-only string returns undef');

	# Approximate and boundary prefixes
	Readonly my @APPROX_PREFIXES => qw(bef aft abt Bef Aft Abt);
	for my $prefix (@APPROX_PREFIXES) {
		ok(!defined $obj->parse_datetime(date => "$prefix 1 Jan 2000", quiet => 1),
			"prefix '$prefix' returns undef");
	}

	# Scalar context for a range must return undef (the range is ambiguous)
	my $scalar = $obj->parse_datetime(date => 'bet 1 Jan 2000 and 31 Dec 2000');
	ok(!defined $scalar, 'bet...and... in scalar context returns undef');
};

# =======================================================================
# SECTION 8: parse_datetime - carp behaviour and quiet flag
#
# The quiet flag must be passed as a call-time parameter; the object
# attribute of the same name is used only by internal helpers.
# =======================================================================

subtest 'parse_datetime - carps for invalid inputs (and quiet suppresses them)' => sub {
	my $obj = $PKG->new();

	# bef/aft/abt dates are invalid for exact DateTime creation
	warning_like(
		sub { $obj->parse_datetime(date => 'bef 1 Jan 2000') },
		qr/is invalid.*need an exact date/,
		'bef prefix triggers carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => 'bef 1 Jan 2000', quiet => 1) },
		[],
		'quiet param suppresses bef carp',
	);

	# November has only 30 days - 31 Nov is always invalid
	warning_like(
		sub { $obj->parse_datetime(date => '31 Nov 2022') },
		qr/31 Nov 2022 is invalid/,
		'31 Nov triggers carp',
	);
	# The 31 Nov carp is intentionally NOT gated on quiet (it fires unconditionally)

	# Completely unparseable string
	warning_like(
		sub { $obj->parse_datetime(date => 'xyzzy') },
		qr/does not parse/,
		'garbage string triggers carp',
	);
	warnings_are(
		sub { $obj->parse_datetime(date => 'xyzzy', quiet => 1) },
		[],
		'quiet param suppresses garbage-string carp',
	);
};

# =======================================================================
# SECTION 9: parse_datetime - ISO YYYY-MM-DD normalisation
#
# Dates in ISO format are automatically rewritten to "DD Mon YYYY" before
# parsing.  The rewrite always emits a carp (unless quiet).
# =======================================================================

subtest 'parse_datetime - ISO YYYY-MM-DD normalisation' => sub {
	my $obj = $PKG->new();

	my $dt = $obj->parse_datetime(date => '1517-06-04', quiet => 1);
	isa_ok($dt, 'DateTime', 'ISO date parses to a DateTime');
	is($dt->dmy, '04-06-1517', 'ISO date correctly normalised');

	# Rewriting fires the Changing date carp when quiet is off
	warning_like(
		sub { $obj->parse_datetime(date => '1941-08-02') },
		qr/Changing date/,
		'ISO date rewrite emits Changing date carp',
	);
};

# =======================================================================
# SECTION 10: parse_datetime - date ranges
# =======================================================================

subtest 'parse_datetime - bet...and... range' => sub {
	my $obj = $PKG->new();

	# List context must return exactly two DateTime objects
	my @range = $obj->parse_datetime(date => 'bet 28 Jul 1914 and 11 Nov 1918');
	is(scalar @range, 2,           'bet...and... yields 2-element list');
	isa_ok($range[0], 'DateTime',  'first element is a DateTime');
	isa_ok($range[1], 'DateTime',  'second element is a DateTime');
	is($range[0]->dmy, '28-07-1914', 'range start is correct');
	is($range[1]->dmy, '11-11-1918', 'range end is correct');

	# Scalar context must return undef (range is ambiguous as a single point)
	my $scalar = $obj->parse_datetime(date => 'bet 28 Jul 1914 and 11 Nov 1918');
	ok(!defined $scalar, 'bet...and... in scalar context returns undef');
};

subtest 'parse_datetime - from...to... range (non-strict only)' => sub {
	my $obj = $PKG->new();

	# Non-strict: from...to... is accepted as a range
	my @range = $obj->parse_datetime(date => 'from 1 Jan 2000 to 31 Dec 2000');
	is(scalar @range, 2,           'from...to... yields 2-element list (non-strict)');
	is($range[0]->dmy, '01-01-2000', 'from...to... start correct');
	is($range[1]->dmy, '31-12-2000', 'from...to... end correct');

	# Strict mode: from...to... is not a valid GEDCOM range, must be rejected.
	# strict is a call-time parameter - the object attribute alone is not enough.
	my @strict = $obj->parse_datetime(date => 'from 1 Jan 2000 to 31 Dec 2000',
		strict => 1, quiet => 1);
	is(scalar @strict, 0, 'from...to... is ignored when strict => 1 is passed');
};

subtest 'parse_datetime - dash-separated range normalisation' => sub {
	my $obj = $PKG->new();

	# "date1 - date2" is normalised to "bet date1 and date2"
	my @range = $obj->parse_datetime(date => '28 Jul 1914 - 11 Nov 1918', quiet => 1);
	is(scalar @range, 2,           'dash range yields 2 elements');
	is($range[0]->dmy, '28-07-1914', 'dash range start correct');
	is($range[1]->dmy, '11-11-1918', 'dash range end correct');
};

# =======================================================================
# SECTION 11: parse_datetime - month name leniency (non-strict mode)
#
# Without strict, the module accepts long English month names, several
# common abbreviation variants, and a handful of French month names.
# =======================================================================

subtest 'parse_datetime - non-strict month name acceptance' => sub {
	my $obj = $PKG->new();

	Readonly my %CASES => (
		'12 June 2020'  => '12-06-2020',
		'12 July 2020'  => '12-07-2020',
		'1 January 2020'=> '01-01-2020',
		'1 August 2020' => '01-08-2020',
		'27 Sept 1791'  => '27-09-1791',
		'27 Sept. 1791' => '27-09-1791',
		'21 Mai 1681'   => '21-05-1681',
		'1 Janv 1752'   => '01-01-1752',
		'8 Juli 1817'   => '08-07-1817',
		'29-Aug-1938'   => '29-08-1938',
	);

	while (my ($input, $expected) = each %CASES) {
		my $dt = $obj->parse_datetime(date => $input);
		ok(defined $dt, "non-strict accepts '$input'");
		is($dt->dmy, $expected, "'$input' normalised to '$expected'") if defined $dt;
	}
};

subtest 'parse_datetime - strict mode enforces 3-letter months' => sub {
	my $obj = $PKG->new();

	# A valid 3-letter abbreviation must succeed in strict mode
	my $dt = $obj->parse_datetime(date => '29 Sep 1939', strict => 1);
	isa_ok($dt, 'DateTime', 'strict mode accepts valid 3-letter abbreviation');
	is($dt->dmy, '29-09-1939', 'strict: date value correct');

	# Long month names are not valid GEDCOM and must be rejected.
	# strict and quiet are passed per-call (not inherited from the object).
	ok(!defined $obj->parse_datetime(date => '12 June 2020', strict => 1, quiet => 1),
		'strict: long month name returns undef');
	ok(!defined $obj->parse_datetime(date => '29 Sept. 1939', strict => 1, quiet => 1),
		'strict: Sept. abbreviation rejected');
};

# =======================================================================
# SECTION 12: parse_datetime - GEDCOM calendar escapes
# =======================================================================

subtest 'parse_datetime - @#DJULIAN@ escape' => sub {
	my $obj = $PKG->new();

	# 15 Mar 1620 Julian = 25 Mar 1620 Gregorian (pre-1700, offset = 10)
	my $dt = $obj->parse_datetime(date => '@#DJULIAN@ 15 Mar 1620');
	isa_ok($dt, 'DateTime', '@#DJULIAN@ produces a DateTime');
	is($dt->day,    25,   'DJULIAN: day advanced by offset');
	is($dt->month,   3,   'DJULIAN: month unchanged');
	is($dt->year,  1620,  'DJULIAN: year unchanged');

	diag('@#DJULIAN@ 15 Mar 1620 => ' . $dt->dmy) if $ENV{TEST_VERBOSE};
};

subtest 'parse_datetime - @#DHEBREW@ escape reaches _convert_calendar' => sub {
	# Genealogy::Gedcom::Date cannot parse Hebrew month names such as "Tishri",
	# so we mock _date_parser_cached to return a plausible Gregorian parse
	# result.  That lets parse_datetime reach the _convert_calendar call for
	# DHEBREW, which we then verify returns the from_object sentinel rather
	# than the intermediate Gregorian DateTime.
	Readonly my $SENTINEL_YEAR => 5783;

	mock "${PKG}::_date_parser_cached" => sub {
		return {
			canonical => '9 Oct 2022',
			day       => '9',
			month     => 'Oct',
			year      => '2022',
			kind      => 'Date',
			type      => 'Gregorian',
		};
	};
	mock 'DateTime::from_object' => sub {
		return DateTime->new(year => $SENTINEL_YEAR, month => 10, day => 1);
	};

	my $obj = $PKG->new();
	my $dt  = $obj->parse_datetime(date => '@#DHEBREW@ 9 Oct 2022');

	isa_ok($dt, 'DateTime', '@#DHEBREW@ produces a DateTime');
	is($dt->year, $SENTINEL_YEAR,
		'@#DHEBREW@: from_object result returned (not the intermediate Gregorian)');

	restore_all();

	diag("DHEBREW result year: $SENTINEL_YEAR") if $ENV{TEST_VERBOSE};
};

# =======================================================================
# SECTION 13: parse_datetime - caching and memory
# =======================================================================

subtest 'parse_datetime - repeated calls use the internal cache' => sub {
	my $obj = $PKG->new();

	Readonly my $DATE_STR => '5 Jan 2019';

	my $first  = $obj->parse_datetime(date => $DATE_STR);
	my $second = $obj->parse_datetime(date => $DATE_STR);

	isa_ok($first,  'DateTime', 'first parse returns DateTime');
	isa_ok($second, 'DateTime', 'second parse returns DateTime');
	is($first->dmy, $second->dmy, 'repeated parse yields identical date value');

	memory_cycle_ok($obj, 'object with cache populated is cycle-free');

	diag('Cache size after repeated parse: ' . scalar(keys %{$obj->{all_dates}}) . ' entries')
		if $ENV{TEST_VERBOSE};
};

# =======================================================================
# SECTION 14: parse_datetime - quiet/strict inherited from object
#
# Flags set at construction time are picked up by subsequent calls to
# parse_datetime without needing to pass them per-call.  Per-call values
# override object-level defaults.
# =======================================================================

subtest 'parse_datetime - quiet inherited from constructor' => sub {
	# Build an object with quiet permanently on; parse_datetime should
	# suppress all carps without needing quiet => 1 on each call.
	my $obj = $PKG->new(quiet => 1);

	# These would normally carp - silence proves the object flag was read.
	my $nw1;
	warnings_are(
		sub { $nw1 = $obj->parse_datetime(date => 'bef 1 Jan 2000') },
		[],
		'bef prefix: object-level quiet suppresses carp',
	);
	ok(!defined $nw1, 'bef prefix still returns undef with quiet on object');

	my $nw2;
	warnings_are(
		sub { $nw2 = $obj->parse_datetime(date => 'xyzzy') },
		[],
		'garbage date: object-level quiet suppresses carp',
	);
	ok(!defined $nw2, 'garbage date still returns undef with quiet on object');

	# Per-call quiet => 0 must override the object attribute, restoring carps.
	warning_like(
		sub { $obj->parse_datetime(date => 'bef 1 Jan 2000', quiet => 0) },
		qr/is invalid.*need an exact date/,
		'per-call quiet => 0 overrides object-level quiet => 1',
	);
};

subtest 'parse_datetime - strict inherited from constructor' => sub {
	my $obj_strict = $PKG->new(strict => 1, quiet => 1);

	# Long month name must be rejected without passing strict per-call.
	ok(!defined $obj_strict->parse_datetime(date => '12 June 2020'),
		'object-level strict rejects long month name');

	# Valid 3-letter month must still work under object-level strict.
	my $dt = $obj_strict->parse_datetime(date => '29 Sep 1939');
	isa_ok($dt, 'DateTime', 'object-level strict accepts 3-letter month');
	is($dt->dmy, '29-09-1939', 'date value correct under object-level strict');

	# Per-call strict => 0 must override the object attribute.
	my $dt2 = $obj_strict->parse_datetime(date => '12 June 2020', strict => 0);
	isa_ok($dt2, 'DateTime', 'per-call strict => 0 overrides object-level strict');
	is($dt2->dmy, '12-06-2020', 'date value correct after per-call strict override');
};

done_testing();
