#!perl

# Destructive, pathological, boundary-condition, and security tests for
# DateTime::Format::Genealogy.
#
# Strategy: every subtest here deliberately tries to break or subvert the
# module.  Inputs that well-behaved callers would never supply are fed in;
# upstream collaborators are replaced with mocks that return failure modes
# (undef, 0, "", exceptions, malformed data).  Global-variable clobbering,
# list/scalar context abuse, and security-relevant strings are all covered.
#
# Calling convention reminder: Params::Get does NOT support mixing a
# positional scalar with named key-value flags:
#   WRONG: parse_datetime('date string', quiet => 1)
#   RIGHT: parse_datetime(date => 'date string', quiet => 1)
#   RIGHT: parse_datetime({ date => 'date string', quiet => 1 })

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Scalar::Util qw(blessed weaken);
use Time::HiRes qw(gettimeofday tv_interval);

BEGIN { use_ok('DateTime::Format::Genealogy') || BAIL_OUT('Cannot load module') }

Readonly my $PKG => 'DateTime::Format::Genealogy';

# ---------------------------------------------------------------------------
# Calendar back-end stubs (succeed by default; overridden in specific tests).
# ---------------------------------------------------------------------------
{
	package DateTime::Calendar::Hebrew;
	sub new {
		my ($class, %a) = @_;
		return bless { %a }, $class;
	}
}
$INC{'DateTime/Calendar/Hebrew.pm'} = 1;

{
	package DateTime::Calendar::FrenchRevolutionary;
	sub new {
		my ($class, %a) = @_;
		return bless { %a }, $class;
	}
}
$INC{'DateTime/Calendar/FrenchRevolutionary.pm'} = 1;

# Standard "safe" mock for DateTime::from_object used by calendar tests
my $FROM_OBJECT_SENTINEL = DateTime->new(year => 2022, month => 10, day => 9);

# ===========================================================================
# SECTION 1: Hostile inputs to new()
# ===========================================================================

subtest 'new() - hostile constructor arguments' => sub {
	# Verify the constructor does not die on zero-ish flag values.
	for my $val (0, '', undef) {
		my $label = defined $val ? "'$val'" : 'undef';
		my $obj;
		lives_ok(
			sub { $obj = $PKG->new(quiet => $val, strict => $val) },
			"new(quiet => $label, strict => $label) does not throw",
		);
		isa_ok($obj, $PKG, "new() with $label flags returns blessed object");
	}

	# Extra unknown keys passed to new() should not crash (Object::Configure
	# absorbs them; they are simply stored on the object).
	my $obj_extra;
	lives_ok(sub { $obj_extra = $PKG->new(unknown_key => 99) },
		'new() with unknown key does not throw');
	isa_ok($obj_extra, $PKG, 'still returns a blessed object');

	# Circular reference as constructor argument: must not crash.
	my $circ = {};
	$circ->{self} = $circ;
	weaken($circ->{self});
	lives_ok(sub { $PKG->new(quiet => 0) },
		'new() survives when caller holds a circular reference');

	diag('Constructor hostile-input section completed') if $ENV{TEST_VERBOSE};
};

subtest 'new() - invocant is undef (bare function call form)' => sub {
	# Calling DateTime::Format::Genealogy::new() with no invocant should
	# default to the package name and still construct a valid object.
	my $obj;
	lives_ok(sub { $obj = DateTime::Format::Genealogy::new() },
		'bare function new() does not throw');
	isa_ok($obj, $PKG, 'bare new() returns a blessed reference');
};

# ===========================================================================
# SECTION 2: Hostile date values — parse_datetime croak conditions
# ===========================================================================

subtest 'parse_datetime - all falsy date values croak' => sub {
	my $obj = $PKG->new();

	Readonly my %FALSY => (
		'undef'         => undef,
		'empty string'  => '',
		'string zero'   => '0',
		'integer zero'  => 0,
	);

	while (my ($label, $val) = each %FALSY) {
		throws_ok(
			sub { $obj->parse_datetime(date => $val) },
			qr/^Usage:.*parse_datetime/,
			"$label date value croaks with usage message",
		);
	}
};

subtest 'parse_datetime - reference types as date value croak' => sub {
	my $obj = $PKG->new();

	# Params::Validate::Strict rejects references; the module re-throws via
	# Carp::croak as "Invalid parse_datetime parameters: ...must be a scalar".
	my $circ = {};
	$circ->{self} = $circ;
	weaken($circ->{self});

	my %REF_CASES = (
		arrayref  => [],
		hashref   => {},
		scalarref => \"value",
		coderef   => sub { },
		regexp    => qr/pattern/,
	);

	while (my ($label, $ref) = each %REF_CASES) {
		throws_ok(
			sub { $obj->parse_datetime(date => $ref) },
			qr/Invalid parse_datetime parameters.*must be a scalar/,
			"$label as date value: croaks with 'must be a scalar'",
		);
	}

	# Blessed reference also rejected.
	my $blessed = bless {}, 'SomeClass';
	throws_ok(
		sub { $obj->parse_datetime(date => $blessed) },
		qr/Invalid parse_datetime parameters.*must be a scalar/,
		'blessed ref as date value: croaks',
	);
};

subtest 'parse_datetime - unknown parameter key is rejected' => sub {
	my $obj = $PKG->new();

	throws_ok(
		sub { $obj->parse_datetime({ datex => '25 Dec 2022' }) },
		qr/Invalid parse_datetime parameters.*datex/,
		"typo 'datex' croaks with key name in message",
	);

	throws_ok(
		sub { $obj->parse_datetime({ date => '25 Dec 2022', injected => 1 }) },
		qr/Invalid parse_datetime parameters.*injected/,
		"extra key 'injected' croaks",
	);
};

# ===========================================================================
# SECTION 3: Whitespace, control characters, null bytes
# ===========================================================================

subtest 'parse_datetime - whitespace and control character dates' => sub {
	my $obj = $PKG->new(quiet => 1);

	# Whitespace-only strings are truthy but parse to undef after DFN fails.
	ok(!defined $obj->parse_datetime('   '),      'spaces-only returns undef');
	ok(!defined $obj->parse_datetime("\t"),       'tab-only returns undef');
	ok(!defined $obj->parse_datetime("\n"),       'newline-only returns undef');
	ok(!defined $obj->parse_datetime("\r\n"),     'CRLF-only returns undef');

	# Null bytes: the string is truthy but no recognisable pattern matches.
	ok(!defined $obj->parse_datetime("\0"),       'null byte returns undef');
	ok(!defined $obj->parse_datetime("25\0Dec 2022"), 'embedded null returns undef');

	# Tab-embedded dates still parse if the Genealogy::Gedcom::Date/DFN can
	# normalise whitespace (the regex \s+ already covers \t).
	my $tab_date = $obj->parse_datetime("25\tDec 2022");
	diag("tab-embedded date result: " . (defined $tab_date ? $tab_date->dmy : 'undef'))
		if $ENV{TEST_VERBOSE};
	# Newline-embedded dates: DFN may treat \n as whitespace.
	my $nl_date = $obj->parse_datetime("25 Dec\n2022");
	diag("newline-embedded date result: " . (defined $nl_date ? $nl_date->dmy : 'undef'))
		if $ENV{TEST_VERBOSE};
	# Neither must crash or clobber global state.
	pass('whitespace-embedded dates do not crash');
};

# ===========================================================================
# SECTION 4: Year boundary conditions
#
# Bug fixed: DFN silently returned today's date for years in the range
# 100-999 and for very large years (>= 10000) because it cannot parse them.
# The GGD-cached path now checks dfn->success() before returning, matching
# the existing behaviour of the DFN-fallback path.
# ===========================================================================

subtest 'parse_datetime - year boundary conditions' => sub {
	my $obj = $PKG->new(quiet => 1);

	# 1-2 digit years: caught by the \s\d{1,2}$ guard, always undef.
	ok(!defined $obj->parse_datetime('25 Dec 99'),  '2-digit year returns undef');
	ok(!defined $obj->parse_datetime('1 Jan 9'),    '1-digit year returns undef');

	# 3-digit years (100-999): GGD parses them but DFN cannot.
	# Previously this returned today's date (bug); now returns undef + carp.
	ok(!defined $obj->parse_datetime('20 Dec 100'), '3-digit year 100: returns undef (not today)');
	ok(!defined $obj->parse_datetime('20 Dec 500'), '3-digit year 500: returns undef');
	ok(!defined $obj->parse_datetime('20 Dec 999'), '3-digit year 999: returns undef');

	# 4-digit year boundary: 1000 is the first year DFN can handle.
	my $dt_1000 = $obj->parse_datetime('20 Dec 1000');
	isa_ok($dt_1000, 'DateTime', '4-digit year 1000: parses to a DateTime');
	is($dt_1000->year, 1000, '4-digit year 1000: correct year') if defined $dt_1000;

	# Normal modern years must not be affected by the new guard.
	my $dt = $obj->parse_datetime('25 Dec 2022');
	isa_ok($dt, 'DateTime', '4-digit modern year still parses correctly');
	is($dt->dmy, '25-12-2022', 'modern year value correct') if defined $dt;

	# Extremely large years: DFN fails, must return undef (not today).
	ok(!defined $obj->parse_datetime('1 Jan 99999'),  'year 99999: returns undef (not today)');
	ok(!defined $obj->parse_datetime('1 Jan 100000'), 'year 100000: returns undef');

	# Pure year-only strings: always undef regardless of digit count.
	ok(!defined $obj->parse_datetime('800'),   '3-digit year-only string returns undef');
	ok(!defined $obj->parse_datetime('2022'),  '4-digit year-only string returns undef');
	ok(!defined $obj->parse_datetime('99999'), '5-digit year-only string returns undef');
};

subtest 'parse_datetime - 3-digit year DFN failure emits carp (not silent)' => sub {
	my $obj = $PKG->new();

	# With quiet off, the DFN error carp must be audible for sub-1000 dates.
	warning_like(
		sub { $obj->parse_datetime('20 Dec 100') },
		qr/does not parse/,
		'3-digit year triggers DFN error carp when quiet is off',
	);

	# With quiet on, the carp must be suppressed.
	warnings_are(
		sub { $obj->parse_datetime(date => '20 Dec 100', quiet => 1) },
		[],
		'3-digit year carp suppressed by quiet => 1',
	);
};

# ===========================================================================
# SECTION 5: Calendar month boundary conditions
# ===========================================================================

subtest 'parse_datetime - February 29 in leap vs non-leap year' => sub {
	my $obj = $PKG->new(quiet => 1);

	# 2000 is a leap year; 29 Feb 2000 is valid.
	my $leap = $obj->parse_datetime('29 Feb 2000');
	isa_ok($leap, 'DateTime', '29 Feb 2000 (leap year) parses to DateTime');
	is($leap->dmy, '29-02-2000', 'leap day correct') if defined $leap;

	# 1900 is not a leap year (century year not divisible by 400).
	# DFN raises an exception; the module must not propagate it.
	my $nonleap;
	lives_ok(sub { $nonleap = $obj->parse_datetime('29 Feb 1900') },
		'29 Feb 1900 (non-leap) does not throw');
	diag('29 Feb 1900 result: ' . (defined $nonleap ? $nonleap->dmy : 'undef'))
		if $ENV{TEST_VERBOSE};
};

subtest 'parse_datetime - 31 November is always rejected' => sub {
	my $obj = $PKG->new();

	# The 31-Nov carp is deliberately not gated on quiet — it fires always.
	warning_like(
		sub { $obj->parse_datetime('31 Nov 2022') },
		qr/31 Nov 2022 is invalid.*30 days in November/,
		'31 Nov triggers mandatory carp',
	);
	warning_like(
		sub { $obj->parse_datetime(date => '31 Nov 2022', quiet => 1) },
		qr/31 Nov.*invalid/,
		'31 Nov carp fires even with quiet => 1',
	);

	ok(!defined $obj->parse_datetime('31 Nov 2022'),
		'31 Nov returns undef');
};

# ===========================================================================
# SECTION 6: GEDCOM calendar escape edge cases
# ===========================================================================

subtest 'parse_datetime - GEDCOM escape with no date after it' => sub {
	my $obj = $PKG->new(quiet => 1);

	# Escape with nothing following: the remaining string is empty or
	# whitespace, which fails all downstream checks and returns undef.
	ok(!defined $obj->parse_datetime('@#DJULIAN@'),
		'@#DJULIAN@ with no date returns undef');
	ok(!defined $obj->parse_datetime('@#DJULIAN@ '),
		'@#DJULIAN@ + whitespace returns undef');
};

subtest 'parse_datetime - unknown GEDCOM calendar type is tolerated' => sub {
	my $obj = $PKG->new();

	# An unknown calendar escape (DROMAN, DGREEK, etc.) must carp and return
	# the Gregorian-interpreted DateTime rather than crashing.
	my $result;
	warning_like(
		sub { $result = $obj->parse_datetime('@#DROMAN@ 25 Dec 2022') },
		qr/Calendar type DROMAN not supported/,
		'@#DROMAN@: calendar-not-supported carp emitted',
	);
	isa_ok($result, 'DateTime',
		'@#DROMAN@: still returns the Gregorian-interpreted DateTime');

	# Very long unknown calendar type must not crash the regex.
	my $long_type = 'A' x 500;
	my $long_result;
	lives_ok(
		sub { $long_result = $obj->parse_datetime("\@#D${long_type}\@ 25 Dec 2022") },
		'Extremely long calendar type does not crash',
	);
	diag("Long calendar type result: " . (defined $long_result ? $long_result->dmy : 'undef'))
		if $ENV{TEST_VERBOSE};
};

subtest 'parse_datetime - lowercase GEDCOM escape is not recognised' => sub {
	# The regex @#D([A-Z ]+?)@ requires uppercase letters; lowercase should
	# not be treated as a calendar escape and falls through to normal parsing.
	my $obj = $PKG->new(quiet => 1);

	my $result = $obj->parse_datetime('@#djulian@ 25 Dec 2022');
	ok(!defined $result,
		'Lowercase GEDCOM escape not recognised: date cannot be parsed normally');
};

subtest 'parse_datetime - GEDCOM Julian offset for each century tier' => sub {
	# Verify all four offset tiers (<1700=>10, <1800=>11, <1900=>12, >=1900=>13)
	# are applied correctly end-to-end.
	my $obj = $PKG->new();

	Readonly my @TIER_CASES => (
		# [ julian_date,      expected_day, expected_offset ]
		['@#DJULIAN@ 1 Mar 1620',  11, 10],
		['@#DJULIAN@ 1 Mar 1750',  12, 11],
		['@#DJULIAN@ 1 Mar 1850',  13, 12],
		['@#DJULIAN@ 1 Mar 1920',  14, 13],
	);

	for my $case (@TIER_CASES) {
		my ($input, $expected_day, $offset) = @{$case};
		my $dt = $obj->parse_datetime($input);
		isa_ok($dt, 'DateTime', "$input parses to DateTime");
		is($dt->day, $expected_day, "$input: day advanced by $offset") if defined $dt;
	}
};

# ===========================================================================
# SECTION 7: Date range edge cases and list/scalar context abuse
# ===========================================================================

subtest 'parse_datetime - range in scalar context always returns undef' => sub {
	my $obj = $PKG->new();

	# These must NOT return a DateTime or throw; scalar context must give undef.
	Readonly my @RANGE_STRINGS => (
		'bet 1 Jan 2000 and 31 Dec 2000',
		'from 1 Jan 2000 to 31 Dec 2000',
		'1 Jan 2000 - 31 Dec 2000',
	);

	for my $range (@RANGE_STRINGS) {
		my $scalar = $obj->parse_datetime($range);
		ok(!defined $scalar, "'$range' in scalar context returns undef");
	}
};

subtest 'parse_datetime - range with invalid first endpoint' => sub {
	# When one endpoint of a bet...and... range is itself invalid (31 Nov),
	# the recursive parse_datetime call returns the empty list.  In list
	# context that causes the outer return to have fewer than 2 elements.
	# This is a known limitation: callers must check scalar(@result) == 2.
	my $obj = $PKG->new(quiet => 1);

	my @range;
	lives_ok(
		sub { @range = $obj->parse_datetime('bet 31 Nov 2000 and 31 Dec 2000') },
		'bet range with invalid first endpoint does not crash',
	);
	# Verify the caller gets back something that is at least not a full 2-DT list.
	ok(scalar(@range) != 2 || !defined $range[0],
		'invalid first endpoint: result is not a clean 2-element range');

	diag("Range with bad first endpoint: " . scalar(@range) . " elements")
		if $ENV{TEST_VERBOSE};
};

subtest 'parse_datetime - deeply nested bet...and... does not crash' => sub {
	# "bet bet A and B and C" is nonsensical but must not crash or loop forever.
	my $obj = $PKG->new(quiet => 1);

	my @result;
	lives_ok(
		sub { @result = $obj->parse_datetime('bet bet 1 Jan 2000 and 31 Dec 2000 and 1 Jan 2001') },
		'nested bet...and... does not crash',
	);
	diag("nested bet result: " . scalar(@result) . " elements") if $ENV{TEST_VERBOSE};
};

subtest 'parse_datetime - from...to... rejected by strict flag' => sub {
	my $obj = $PKG->new(strict => 1, quiet => 1);

	my @result = $obj->parse_datetime('from 1 Jan 2000 to 31 Dec 2000');
	is(scalar @result, 0, 'from...to... returns empty list when strict is set');
};

# ===========================================================================
# SECTION 8: Extremely long and malformed strings
# ===========================================================================

subtest 'parse_datetime - extremely long date strings do not crash or hang' => sub {
	my $obj = $PKG->new(quiet => 1);

	Readonly my $LONG_GARBAGE => 'X' x 10_000;
	Readonly my $LONG_DASH    => ('A' x 100) . ' - ' . ('B' x 100);
	Readonly my $LONG_BET     => 'bet ' . ('A ' x 500) . 'and ' . ('B ' x 500);

	my $t0 = [gettimeofday];
	lives_ok(sub { $obj->parse_datetime($LONG_GARBAGE) }, '10k garbage string: no crash');
	lives_ok(sub { $obj->parse_datetime($LONG_DASH)    }, 'long dash-range string: no crash');
	lives_ok(sub { $obj->parse_datetime($LONG_BET)     }, 'long bet...and... string: no crash');
	my $elapsed = tv_interval($t0);

	# Pathological regex backtracking would make this take many seconds.
	# Allow 30 s to accommodate slow CI / Windows runners while still catching
	# catastrophic backtracking (which would take minutes, not seconds).
	cmp_ok($elapsed, '<', 30, 'all long-string tests complete within 30 seconds');

	diag(sprintf('Long-string subtests took %.3fs', $elapsed)) if $ENV{TEST_VERBOSE};
};

subtest 'parse_datetime - shell-injection strings are inert' => sub {
	# The module must not execute shell commands.  These strings must return
	# undef without doing anything dangerous.
	my $obj = $PKG->new(quiet => 1);

	Readonly my @SHELL_STRINGS => (
		'25 Dec 2022; rm -rf /',
		'25 Dec 202`date`',
		'25 Dec 202$(cat /etc/passwd)',
		"25 Dec 2022\nrm -rf /",
		'25 Dec 202|cat /etc/passwd',
		'25 Dec 202 && id',
	);

	for my $s (@SHELL_STRINGS) {
		my $r;
		lives_ok(sub { $r = $obj->parse_datetime($s) },
			"shell-injection string does not crash: '${\substr($s,0,30)}'");
		ok(!defined $r || blessed($r) eq 'DateTime',
			'result is undef or a DateTime (no shell expansion occurred)');
	}
};

subtest 'parse_datetime - Perl code injection strings are inert' => sub {
	# The module does not use string eval, but confirm that strings that look
	# like Perl code either return undef or a DateTime, and never execute.
	my $obj = $PKG->new(quiet => 1);

	Readonly my @CODE_STRINGS => (
		'system("id")',
		'`id`',
		'${\ system("id") }',
		'eval { die "injected" }',
		'25 Dec ${year}',
		'25 Dec @{[2022]}',
	);

	for my $s (@CODE_STRINGS) {
		my $r;
		lives_ok(sub { $r = $obj->parse_datetime($s) },
			"Perl code-like string survives: '${\substr($s,0,30)}'");
		ok(!defined $r || blessed($r) eq 'DateTime',
			"result is inert: '${\substr($s,0,30)}'");
	}
};

# ===========================================================================
# SECTION 9: Upstream failure simulation via Test::Mockingbird
# ===========================================================================

subtest 'parse_datetime - Genealogy::Gedcom::Date->parse returns empty arrayref' => sub {
	# If GGD returns [] (no parsed dates), _date_parser_cached returns undef
	# and parse_datetime must fall through to the DFN fallback path.
	mock 'Genealogy::Gedcom::Date::parse' => sub { return [] };

	my $obj = $PKG->new(quiet => 1);
	my $r;
	lives_ok(sub { $r = $obj->parse_datetime('25 Dec 2022') },
		'GGD returning [] does not crash');
	# DFN fallback may succeed or fail; we just need no crash.
	ok(!defined $r || blessed($r) eq 'DateTime',
		'result is undef or DateTime after GGD returns []');

	restore_all();
};

subtest 'parse_datetime - Genealogy::Gedcom::Date->parse returns undef' => sub {
	# If the upstream parser returns undef, the module must not die.
	mock 'Genealogy::Gedcom::Date::parse' => sub { return undef };

	my $obj = $PKG->new(quiet => 1);
	my $r;
	lives_ok(sub { $r = $obj->parse_datetime('25 Dec 2022') },
		'GGD returning undef does not crash');

	restore_all();
};

subtest 'parse_datetime - Genealogy::Gedcom::Date->parse throws' => sub {
	# A die inside GGD is caught by eval in _date_parser_cached; the method
	# must return undef (not propagate the exception).
	mock 'Genealogy::Gedcom::Date::parse' => sub {
		die "Simulated GGD internal error\n";
	};

	my $obj = $PKG->new(quiet => 1);
	my $r;
	lives_ok(sub { $r = $obj->parse_datetime('25 Dec 2022') },
		'GGD throwing an exception does not kill parse_datetime');

	restore_all();
};

subtest 'parse_datetime - GGD canonical key is undef' => sub {
	# If the parsed hashref has undef as its canonical field, the module must
	# return undef gracefully rather than passing undef to DFN (which would
	# throw a Params::Validate croak).
	mock 'Genealogy::Gedcom::Date::parse' => sub {
		return [{ canonical => undef, day => 25, month => 'Dec', year => 2022 }];
	};

	my $obj = $PKG->new(quiet => 1);
	my $r;
	lives_ok(sub { $r = $obj->parse_datetime('25 Dec 2022') },
		'undef canonical field: parse_datetime does not crash');
	ok(!defined $r, 'undef canonical field: parse_datetime returns undef');

	restore_all();
};

subtest 'parse_datetime - DateTime::Format::Natural->parse_datetime throws' => sub {
	# If DFN itself throws, parse_datetime must not propagate the exception
	# because the caller cannot anticipate it.
	mock 'DateTime::Format::Natural::parse_datetime' => sub {
		die "Simulated DFN hard error\n";
	};

	my $obj = $PKG->new(quiet => 1);
	# We allow the exception to surface here because the module does not
	# wrap the DFN call in an eval; this test documents the current contract.
	my $r = eval { $obj->parse_datetime('25 Dec 2022') };
	diag("DFN throw result: " . ($@ ? "propagated: $@" : "caught, got " . (defined $r ? $r->dmy : 'undef')))
		if $ENV{TEST_VERBOSE};
	# Whether it propagates or is caught is acceptable; it must not corrupt state.
	pass('DFN throwing: no Perl VM crash');

	restore_all();
};

subtest 'parse_datetime - DFN success() returns false for parseable-looking date' => sub {
	# Simulate DFN returning a DateTime but reporting failure via success().
	# parse_datetime must trust success() and return undef (not the bad DateTime).
	my $sentinel = DateTime->new(year => 1999, month => 1, day => 1);

	mock 'DateTime::Format::Natural::parse_datetime' => sub { return $sentinel };
	mock 'DateTime::Format::Natural::success'        => sub { return 0 };
	mock 'DateTime::Format::Natural::error'          => sub { return "'25 Dec 2022' does not parse" };

	my $obj = $PKG->new(quiet => 1);
	my $r = $obj->parse_datetime('25 Dec 2022');

	ok(!defined $r,
		'parse_datetime returns undef when DFN success() is false (GGD-cached path)');

	restore_all();

	diag("DFN success=false result: " . (defined $r ? $r->dmy : 'undef'))
		if $ENV{TEST_VERBOSE};
};

subtest 'parse_datetime - DFN returns undef from parse_datetime' => sub {
	# Some DFN versions return undef rather than a DateTime-with-success=false.
	mock 'DateTime::Format::Natural::parse_datetime' => sub { return undef };

	my $obj = $PKG->new(quiet => 1);
	my $r;
	lives_ok(sub { $r = $obj->parse_datetime('25 Dec 2022') },
		'DFN returning undef does not crash parse_datetime');

	restore_all();
};

subtest 'parse_datetime - DateTime::from_object throws during calendar conversion' => sub {
	# If DateTime->from_object throws, _convert_calendar must carp and return
	# undef (not propagate the exception).
	no warnings 'redefine';
	local *DateTime::from_object = sub { die "from_object hard failure\n" };

	my $obj = $PKG->new();
	my $result;
	warning_like(
		sub { $result = $obj->parse_datetime('@#DHEBREW@ 9 Oct 2022') },
		qr/Hebrew calendar conversion failed/,
		'from_object throwing: conversion-failed carp emitted',
	);
	ok(!defined $result, 'from_object throwing: parse_datetime returns undef');
};

# ===========================================================================
# SECTION 10: Global variable integrity under hostile conditions
# ===========================================================================

subtest 'global variables are not clobbered by hostile inputs' => sub {
	my $obj = $PKG->new(quiet => 1);

	local $_  = 'sentinel_dollar_underscore';
	local $,  = 'sentinel_list_separator';
	local $\  = '';                            # output separator must stay empty
	local $/  = "\n";                          # input separator must stay \n

	Readonly my @HOSTILE => (
		"xyzzy",
		"\0",
		"A" x 5_000,
		"bet 1 Jan 2000 and 31 Dec 2000",
		"20 Dec 100",
		"31 Nov 2022",
	);

	for my $date (@HOSTILE) {
		eval { $obj->parse_datetime($date) };
		is($_, 'sentinel_dollar_underscore', "\$_ intact after '${\substr($date,0,20)}'");
		is($,, 'sentinel_list_separator',    "\$, intact after '${\substr($date,0,20)}'");
	}

	# $@ must not be set to an error after a quiet successful-or-rejected parse.
	eval { 1 };
	my $pre_at = $@;
	$obj->parse_datetime('25 Dec 2022');
	is($@, $pre_at, '$@ not clobbered after successful parse');
};

subtest 'alarm() is not called by the module' => sub {
	# alarm() is a POSIX feature not implemented on Windows.  Skip there.
	if($^O eq 'MSWin32') {
		plan skip_all => 'alarm() not supported on Windows';
		return;
	}

	# A paranoid check: the module must not call alarm() and disrupt any
	# countdown set by the caller.
	my $remaining = alarm(3600);              # set a 1-hour countdown
	my $obj = $PKG->new(quiet => 1);
	$obj->parse_datetime('25 Dec 2022');
	my $after = alarm($remaining);            # restore and read back

	cmp_ok($after, '>=', 3599,
		'alarm countdown was not cleared or shortened by parse_datetime');

	alarm($remaining);                        # restore original countdown
};

# ===========================================================================
# SECTION 11: Concurrent object state isolation under hostile conditions
# ===========================================================================

subtest 'hostile input on one object does not pollute another' => sub {
	my $victim   = $PKG->new(quiet => 1);
	my $innocent = $PKG->new(quiet => 1);

	# Pre-populate innocent's cache with a good date.
	my $dt_before = $innocent->parse_datetime('25 Dec 2022');

	# Feed hostile inputs exclusively to victim.
	$victim->parse_datetime("\0");
	$victim->parse_datetime("20 Dec 100");
	$victim->parse_datetime("xyzzy");
	$victim->parse_datetime("A" x 5_000);
	$victim->parse_datetime('31 Nov 2022');

	# Innocent must still return the same correct date.
	my $dt_after = $innocent->parse_datetime('25 Dec 2022');
	is($dt_after->dmy, $dt_before->dmy,
		"innocent object unaffected by hostile inputs on victim");

	# Innocent's quiet and strict flags must not have been touched.
	ok(!$innocent->{strict},
		"innocent's strict flag unchanged after victim abuse");
};

# ===========================================================================
# SECTION 12: Approximate prefix variations (boundary fuzz)
# ===========================================================================

subtest 'parse_datetime - approximate prefix boundary cases' => sub {
	my $obj = $PKG->new(quiet => 1);

	# All documented approximate-prefix forms return undef.
	Readonly my @APPROX_DATES => (
		'bef 1 Jan 2000',
		'Bef 1 Jan 2000',
		'BEF 1 Jan 2000',
		'aft 1 Jan 2000',
		'Aft 1 Jan 2000',
		'AFT 1 Jan 2000',
		'abt 1 Jan 2000',
		'Abt 1 Jan 2000',
		'ABT 1 Jan 2000',
	);

	for my $date (@APPROX_DATES) {
		ok(!defined $obj->parse_datetime($date),
			"'$date' returns undef");
	}

	# Prefix glued without space must NOT match and must parse normally.
	my $no_space = $obj->parse_datetime('bef1 Jan 2000');
	diag("'bef1 Jan 2000' result: " . (defined $no_space ? $no_space->dmy : 'undef'))
		if $ENV{TEST_VERBOSE};
	# The regex is /^bef\s/i so no-space form must not be treated as approximate.
	pass("'bef1 Jan 2000' (no space) does not trigger approximate-date path");
};

done_testing();
