#!/usr/bin/env perl

# White-box function tests for Date::Cmp.
#
# Strategy: drive every branch in datecmp() — input normalisation,
# each fast-path, BEF/AFT handling, approximate-prefix stripping, month-
# range stripping, "or" and dash/BET ranges on both sides, DFG parse paths
# (success and failure), and the final ref/non-ref comparisons.
#
# External DFG calls are isolated via a drop-in MockDFG that replaces the
# $Date::Cmp::dfg singleton under "local", so real network/FS access is
# never needed. Term::ANSIColor::colored is mocked globally to keep test
# output free of ANSI escape sequences.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock unmock spy restore_all);
use Test::Returns     qw(returns_ok);
use Test::Memory::Cycle;
use Readonly;
use File::Spec;

use Date::Cmp qw(datecmp);

# -------------------------------------------------------------------------
# Named constants — avoid magic numbers throughout tests
# -------------------------------------------------------------------------
Readonly my $EQ  =>  0;
Readonly my $LT  => -1;
Readonly my $GT  =>  1;

# -------------------------------------------------------------------------
# Suppress ANSI colour codes that datecmp emits on STDERR error paths so
# test output remains readable.  This mock persists for the whole file.
# -------------------------------------------------------------------------
mock 'Term::ANSIColor::colored' => sub { $_[0] };

# -------------------------------------------------------------------------
# Redirect STDERR to the null device for blocks that intentionally trigger
# datecmp's internal error-reporting (print STDERR / die).
# We assert only on the return value or the die message, not STDERR text.
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

# -------------------------------------------------------------------------
# Fake DateTime-like object returned by MockDFG.
# Overloads <=> so the final "return $left <=> $right" path works without
# a real DateTime.  Also overloads "" so that after $left is set to this
# object, the fallback regex branches in datecmp stringify it predictably
# to the year string (e.g. "1900") rather than a raw ref address.
# -------------------------------------------------------------------------
{
	package Fake::DateTime;
	use overload
		'<=>' => \&_cmp,
		'""'  => sub { $_[0]->{year} },
		fallback => 1;

	sub new  { my ($class, %a) = @_; bless { year => $a{year} }, $class }
	sub year { $_[0]->{year} }
	sub _cmp {
		my ($a, $b, $swap) = @_;
		my $b_year = ref($b) ? $b->year() : $b;
		return $swap ? $b_year <=> $a->year() : $a->year() <=> $b_year;
	}
}

# -------------------------------------------------------------------------
# MockDFG replaces $Date::Cmp::dfg under "local $Date::Cmp::dfg = ..."
# Configure with enqueue([$dt, ...]) before calling datecmp; each call to
# parse_datetime dequeues the next result.  An empty queue means failure.
# call_count() returns the total number of parse_datetime invocations.
# -------------------------------------------------------------------------
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

# -------------------------------------------------------------------------
# Fake object that implements ->date() for the blessed-object unwrap path
# -------------------------------------------------------------------------
{
	package Fake::DateObj;
	sub new  { my ($class, $str) = @_; bless { date => $str }, $class }
	sub date { $_[0]->{date} }
}

# =========================================================================
# 1. Module loads and exports
# =========================================================================
subtest 'module exports datecmp on request' => sub {
	ok(Date::Cmp->can('datecmp'), 'datecmp is defined in Date::Cmp namespace');
	ok(defined &datecmp,          'datecmp is importable into test namespace');
};

# =========================================================================
# 2. Undef inputs — both sides
# datecmp treats undef as a recoverable error: prints to STDERR and
# returns 0 rather than dying, so callers do not need eval{} guards.
# =========================================================================
subtest 'undef inputs return 0 without dying' => sub {
	is(silence_stderr { datecmp(undef, '1900') }, $EQ, 'undef left  => 0');
	is(silence_stderr { datecmp('1900', undef)  }, $EQ, 'undef right => 0');
	is(silence_stderr { datecmp(undef, undef)   }, $EQ, 'both undef  => 0');
};

# =========================================================================
# 3. Blessed object unwrapping via ->date()
# When a blessed object that implements date() is passed, the string
# returned by ->date() must be used for all subsequent comparisons.
# =========================================================================
subtest 'blessed objects with ->date() are unwrapped transparently' => sub {
	my $obj1900 = Fake::DateObj->new('1900');
	my $obj1901 = Fake::DateObj->new('1901');

	cmp_ok(datecmp($obj1900, $obj1901), '<', $EQ, 'obj(1900) < obj(1901)');
	cmp_ok(datecmp($obj1901, $obj1900), '>', $EQ, 'obj(1901) > obj(1900)');
	is(datecmp($obj1900, $obj1900),     $EQ,       'same obj == 0');
	cmp_ok(datecmp($obj1900, '1901'),   '<', $EQ, 'obj LHS  < string RHS');
	cmp_ok(datecmp('1901',   $obj1900), '>', $EQ, 'string LHS > obj RHS');
};

# =========================================================================
# 4. Hashref unwrapping via the 'date' key
# =========================================================================
subtest 'unblessed hashrefs are unwrapped via the date key' => sub {
	my $h1900 = { date => '1900' };
	my $h1901 = { date => '1901' };

	cmp_ok(datecmp($h1900, $h1901), '<', $EQ, 'hash(1900) < hash(1901)');
	is(datecmp($h1900, $h1900),     $EQ,       'same hash  == 0');
	cmp_ok(datecmp($h1901, '1900'), '>', $EQ, 'hash LHS  > string RHS');
	cmp_ok(datecmp('1900', $h1901), '<', $EQ, 'string LHS < hash RHS');
};

# =========================================================================
# 5. Identity fast-path (eq short-circuit)
# Strings that are character-for-character identical must return 0 before
# any parsing is attempted.
# =========================================================================
subtest 'identical strings short-circuit to 0' => sub {
	is(datecmp('1900',            '1900'),            $EQ, 'plain years');
	is(datecmp('BET 1830 AND 1832', 'BET 1830 AND 1832'), $EQ, 'BET strings');
	is(datecmp('Abt. 1900',       'Abt. 1900'),       $EQ, 'approximate strings');
};

# =========================================================================
# 6. Input validation — strings starting with illegal characters die
# After unwrapping, the first character must match [A-S0-9] (case-
# insensitive).  Inputs starting outside this range (e.g. '?', 'Z') die
# with "Date parse failure".
# =========================================================================
subtest 'illegal starting characters die with Date parse failure' => sub {
	throws_ok { silence_stderr { datecmp('??', '1900') } }
		qr/Date parse failure.*left/,
		'"??" on LHS dies (not in [A-S0-9])';

	throws_ok { silence_stderr { datecmp('1900', '?invalid') } }
		qr/Date parse failure.*right/,
		'"?invalid" on RHS dies';

	throws_ok { silence_stderr { datecmp('1900', 'Zzz 1900') } }
		qr/Date parse failure.*right/,
		'"Z" initial char on RHS dies (Z > S in [A-S])';
};

# =========================================================================
# 7. Fast path 1 — different 4-digit years anywhere in non-range strings
# When neither side is a BET/dash-range and both contain a 4-digit year
# the function returns immediately after a numeric year comparison.
# =========================================================================
subtest 'fast path: 4-digit years in non-range strings' => sub {
	is(datecmp('1899', '1900'), $LT, '1899 < 1900');
	is(datecmp('1900', '1899'), $GT, '1900 > 1899');
	# Approximate prefix does not block the 4-digit fast path
	cmp_ok(datecmp('ca 1880', '1900'), '<', $EQ, 'ca 1880 < 1900 via fast path');

	diag 'fast-path 4-digit comparison verified' if $ENV{TEST_VERBOSE};
};

# =========================================================================
# 8. ISO time suffix stripping
# A trailing T00:00:00 timestamp must be removed before year comparison.
# =========================================================================
subtest 'ISO T-timestamp suffix is stripped from left side' => sub {
	# '26 Aug 1744' vs '1673-02-22T00:00:00': after stripping the T suffix
	# the right side becomes '1673-02-22' and the fast-path year comparison
	# sees 1744 > 1673.
	cmp_ok(datecmp('26 Aug 1744', '1673-02-22T00:00:00'), '>', $EQ,
		'1744 > 1673 after T-suffix stripped');
};

# =========================================================================
# 9. BEF/AFT qualifier on the left side
# =========================================================================
subtest 'BEF qualifier on left side' => sub {
	# When the year in the BEF expression is strictly less than the right
	# year the function can confidently return -1.
	is(datecmp('bef 1965', 1969),          $LT, 'bef 1965 < 1969');
	is(datecmp('bef 1 Jun 1965', 1969),    $LT, 'bef full-date < later year');

	# BEF against an ISO date: left year 1932 < right year 2005 → -1
	is(silence_stderr { datecmp('BEF. 1932', '2005-06-16') }, $LT,
		'BEF. 1932 < 2005-06-16');

	# Cases the code explicitly cannot handle fall back to 0 without dying
	is(silence_stderr { datecmp('aft 1900', 'BET 1890 AND 1910') }, $EQ,
		'unhandled aft/BET combo returns 0');
};

# =========================================================================
# 10. Approximate prefix stripping — left side
# "Abt.", "Abt", "ca.", "ca", and trailing "?" must all be stripped to
# expose the underlying year for numeric comparison.
# =========================================================================
subtest 'approximate prefix stripping on left side' => sub {
	is(datecmp('Abt. 1900', '1900'), $EQ, 'Abt. 1900 == 1900');
	is(datecmp('Abt 1900',  '1900'), $EQ, 'Abt (no dot) == 1900');
	is(datecmp('ca. 1900',  '1900'), $EQ, 'ca. 1900 == 1900');
	is(datecmp('ca 1900',   '1900'), $EQ, 'ca 1900 == 1900');
	is(datecmp('1900 ?',    '1900'), $EQ, 'trailing ? stripped');

	cmp_ok(datecmp('Abt. 1899', '1900'), '<', $EQ, 'Abt. 1899 < 1900');
	cmp_ok(datecmp('ca 1901',   '1900'), '>', $EQ, 'ca 1901 > 1900');
};

# =========================================================================
# 11. Month-range stripping — left side
# "Oct/Nov/Dec YYYY" and similar slash-separated month lists must be
# reduced to the year component before comparison.
# =========================================================================
subtest 'month range stripped to year on left side' => sub {
	is(datecmp('Oct/Nov/Dec 1950', '1950'),  $EQ, 'Oct/Nov/Dec 1950 == 1950');
	cmp_ok(datecmp('Oct/Nov/Dec 1949', '1950'), '<', $EQ,
		'Oct/Nov/Dec 1949 < 1950');
};

# =========================================================================
# 12. Left-side "or" range
# "1802 or 1803" uses the first (start) year.  If both years are the same
# the optional complain callback must be invoked.
# =========================================================================
subtest 'left-side "or" range uses start year and fires complain when equal' => sub {
	cmp_ok(datecmp('1802 or 1803', '1801'), '>', $EQ, '1802 or 1803 > 1801');
	cmp_ok(datecmp('1802 or 1803', '1804'), '<', $EQ, '1802 or 1803 < 1804');

	# The RHS must share the same year as the "or" range so the fast-path
	# year comparison ties and falls through to the "or" branch.  Using a
	# different RHS year (e.g. 1803) would cause the fast path to return
	# immediately and the complain callback would never be reached.
	my $complaint;
	datecmp('1802 or 1802', '1802', sub { $complaint = $_[0] });
	like($complaint, qr/the years are the same/, 'complain fires for same-year "or"');
};

# =========================================================================
# 13. Left-side date range (dash and BET forms)
# A range [from, to] on the LHS is compared with a scalar year on the RHS.
# - year < from  → range returns +1  (range is later)
# - year in [from,to] → 0
# - year > to    → range returns -1  (range is earlier)
# An inverted range (from > to) triggers the complain callback and returns 0.
# Equal endpoints collapse to a single year and also fire complain.
# =========================================================================
subtest 'left-side date range comparison (dash and BET forms)' => sub {
	# Dash form
	is(datecmp('1900-1902', '1899'), $GT,  'dash range > year before start');
	is(datecmp('1900-1902', '1900'), $EQ,  'dash range == start year');
	is(datecmp('1900-1902', '1901'), $EQ,  'dash range == mid year');
	is(datecmp('1900-1902', '1902'), $EQ,  'dash range == end year');
	is(datecmp('1900-1902', '1903'), $LT,  'dash range < year after end');

	# BET … AND … form must be equivalent for every case
	is(datecmp('BET 1900 AND 1902', '1899'), $GT,  'BET > year before');
	is(datecmp('BET 1900 AND 1902', '1901'), $EQ,  'BET == mid year');
	is(datecmp('BET 1900 AND 1902', '1903'), $LT,  'BET < year after');

	is(datecmp('1830-1832', '1831'),
	   datecmp('BET 1830 AND 1832', '1831'),
	   'dash and BET forms give identical results');

	# Inverted range (from > to): complain, return 0
	my $inv_complaint;
	is(silence_stderr { datecmp('1902-1900', '1901', sub { $inv_complaint = $_[0] }) },
		$EQ, 'inverted dash range returns 0');
	like($inv_complaint, qr/\d+ > \d+/, 'inverted range fires complain');

	# Same endpoints: collapse to that year, fire complain
	my $eq_complaint;
	is(datecmp('1900-1900', '1900', sub { $eq_complaint = $_[0] }),
		$EQ, 'same-endpoint range == that year');
	like($eq_complaint, qr/from == to/, 'same-endpoint range fires complain');
};

# =========================================================================
# 14. BEF qualifier on right side
# =========================================================================
subtest 'BEF qualifier on right side' => sub {
	# Plain integer LHS < bef-year on RHS → -1
	is(datecmp(1939, 'bef 1 Jun 1965'), $LT, '1939 < bef 1 Jun 1965');

	# The "Before not handled" fallback only fires when $left is not a plain
	# integer (i.e. it is a DateTime ref after DFG parsing), because the code
	# first checks "$left =~ /^\d+$/" and a ref does not satisfy that.
	# Using the same year forces all fast-path ties so DFG is reached.
	is(silence_stderr { datecmp('1 Jan 1900', 'bef 1900') }, $EQ,
		'unhandled BEF on RHS with DateTime LHS returns 0');
};

# =========================================================================
# 15. Approximate prefix stripping — right side
# =========================================================================
subtest 'approximate prefix stripping on right side' => sub {
	is(datecmp('1900', 'Abt. 1900'), $EQ, 'Abt. stripped on RHS');
	is(datecmp('1900', 'ca. 1900'),  $EQ, 'ca. stripped on RHS');
	is(datecmp('1900', 'ca 1900'),   $EQ, 'ca (no dot) stripped on RHS');
	is(datecmp('1900', '1900 ?'),    $EQ, 'trailing ? stripped on RHS');
	cmp_ok(datecmp('1901', 'ca 1900'), '>', $EQ, '1901 > ca 1900 after strip');
};

# =========================================================================
# 16. Month-range stripping — right side
# =========================================================================
subtest 'month range stripped to year on right side' => sub {
	is(datecmp('1892', 'Oct/Nov/Dec 1892'),     $EQ, 'RHS month range == year');
	cmp_ok(datecmp('1891', 'Oct/Nov/Dec 1892'), '<', $EQ,
		'year < RHS month-range year');
};

# =========================================================================
# 17. Right-side date range (dash and BET forms)
# Same semantics as section 13 but with the range on the RHS.
# =========================================================================
subtest 'right-side date range comparison (dash and BET forms)' => sub {
	is(datecmp(1899, 'BET 1900 AND 1902'), $LT,  'year before range < range');
	is(datecmp(1900, 'BET 1900 AND 1902'), $EQ,  'start year == range');
	is(datecmp(1901, 'BET 1900 AND 1902'), $EQ,  'mid year == range');
	is(datecmp(1902, 'BET 1900 AND 1902'), $EQ,  'end year == range');
	is(datecmp(1903, 'BET 1900 AND 1902'), $GT,  'year after range > range');

	is(datecmp(1831, '1830-1832'), $EQ,  'mid year == dash range');
	is(datecmp(1829, '1830-1832'), $LT,  'year before dash range');
	is(datecmp(1833, '1830-1832'), $GT,  'year after dash range');

	is(datecmp(1831, '1830-1832'),
	   datecmp(1831, 'BET 1830 AND 1832'),
	   'RHS dash and BET forms are equivalent');

	# Equal endpoints collapse to a single year and fire complain
	my $complaint;
	is(datecmp(1900, '1900-1900', sub { $complaint = $_[0] }),
		$EQ, 'same-endpoint RHS range == that year');
	like($complaint, qr/from == to/, 'same-endpoint RHS range fires complain');
};

# =========================================================================
# 18. Regression — DateTime object on LHS must be unwrapped before the
# right-side range comparison.
#
# Root cause: '1 Jan 1996' has its first \d{3,4} sequence as '1996',
# which equals the range start so the early-exit fast path does NOT fire.
# The string then falls through to DFG parsing and $left becomes a
# DateTime object.  The range handler's "$left == $to" comparison must
# unwrap $left first, or DateTime's overloaded == dies on a plain integer.
# =========================================================================
subtest 'DateTime LHS does not crash when compared against a year range' => sub {
	is(datecmp('1 Jan 1996', '1996-2000'),         $EQ, 'DateTime LHS within dash range');
	is(datecmp('1 Jan 1996', 'BET 1996 AND 2000'), $EQ, 'DateTime LHS within BET range');
	cmp_ok(datecmp('1 Jan 1994', '1996-2000'), '<', $EQ, 'DateTime LHS before dash range');
	cmp_ok(datecmp('1 Jan 2001', '1996-2000'), '>', $EQ, 'DateTime LHS after dash range');
};

# =========================================================================
# 19. DFG parsing path — controlled via mocked $dfg singleton
#
# We replace $Date::Cmp::dfg with a fresh MockDFG for each sub-case so
# queue state never leaks between assertions.
#
# Call-count verification uses MockDFG's built-in counter rather than
# Test::Mockingbird's spy(), which does not reliably intercept OO dispatch
# when the invocant is a non-DFG class installed via "local".
#
# For the failure paths we use Test::Mockingbird's mock() to override
# DateTime::Format::Genealogy::parse_datetime globally (and restore it
# with unmock() afterwards) so the real $dfg singleton returns nothing.
# =========================================================================
subtest 'DFG parsing paths (mocked $dfg)' => sub {
	# --- Left side parsed by DFG, right is a plain year ---
	# '1 Jan 1900' falls through all fast paths because its first \d{3,4}
	# match is 1900, which ties with the plain '1900' on the right; DFG
	# is therefore called for the left side and the returned year is used.
	{
		my $mock = MockDFG->new();
		local $Date::Cmp::dfg = $mock;
		$mock->enqueue([ Fake::DateTime->new(year => 1900) ]);
		is(datecmp('1 Jan 1900', '1900'), $EQ, 'DFG LHS year 1900 == plain 1900');
	}
	{
		my $mock = MockDFG->new();
		local $Date::Cmp::dfg = $mock;
		$mock->enqueue([ Fake::DateTime->new(year => 1899) ]);
		is(datecmp('1 Jan 1899', '1900'), $LT, 'DFG LHS year 1899 < plain 1900');
	}

	# --- Both sides parsed by DFG → final $left <=> $right via overloading ---
	# '1 Jan 1900' and '1 Feb 1900' share the same embedded year so every
	# fast-path numeric tie falls through.  After the left is replaced by a
	# Fake::DateTime that stringifies to "1900", the right-side fallback also
	# sees a tie and sends '1 Feb 1900' to DFG.  The mock returns a later
	# year for the right side; MockDFG.call_count() tracks invocations.
	{
		my $mock = MockDFG->new();
		local $Date::Cmp::dfg = $mock;
		$mock->enqueue([ Fake::DateTime->new(year => 1900) ]);
		$mock->enqueue([ Fake::DateTime->new(year => 1901) ]);

		my $result = datecmp('1 Jan 1900', '1 Feb 1900');
		cmp_ok($result, '<', $EQ, 'DFG both sides: 1900 < 1901 via overloaded <=>');
		is($mock->call_count(), 2, 'parse_datetime called exactly twice (once per side)');
		diag 'MockDFG call count: ' . $mock->call_count() if $ENV{TEST_VERBOSE};
	}

	# --- DFG fails to parse left side → die ---
	# Test::Mockingbird's mock() overrides the real DFG method globally so
	# we do not need a fake singleton here.
	mock 'DateTime::Format::Genealogy::parse_datetime' => sub { () };
	throws_ok { silence_stderr { datecmp('1 Jan 1900', '1900') } }
		qr/Date parse failure.*left/,
		'mocked DFG failure on left side dies';
	unmock 'DateTime::Format::Genealogy::parse_datetime';

	# --- DFG fails to parse right side → die ---
	# Left '1900' is a plain year resolved without DFG; right '1 Feb 1900'
	# falls through to DFG which the mock makes return nothing.
	mock 'DateTime::Format::Genealogy::parse_datetime' => sub { () };
	throws_ok { silence_stderr { datecmp('1900', '1 Feb 1900') } }
		qr/Date parse failure.*right/,
		'mocked DFG failure on right side dies';
	unmock 'DateTime::Format::Genealogy::parse_datetime';
};

# =========================================================================
# 20. Genuinely unparseable dates (real DFG, no mock)
# Strings that survive character validation but cannot be parsed must die.
# =========================================================================
subtest 'genuinely unparseable dates die' => sub {
	throws_ok { silence_stderr { datecmp('bad date', '1900') } }
		qr/Date parse failure/,
		'bad left date string dies';

	throws_ok { silence_stderr { datecmp('1900', 'not a date') } }
		qr/Date parse failure/,
		'bad right date string dies';
};

# =========================================================================
# 21. Return-value schema validation via Test::Returns
# datecmp must always return a defined integer value.
# =========================================================================
subtest 'return value is always a defined integer' => sub {
	my @cases = (
		[ '1900', '1901' ],
		[ '1901', '1900' ],
		[ '1900', '1900' ],
		[ 'Abt. 1900', '1901'          ],
		[ '1900',      'ca 1899'        ],
		[ 'BET 1900 AND 1902', '1901'   ],
		[ '1901', 'BET 1900 AND 1902'   ],
		[ '1901', '1900-1902'           ],
	);
	for my $pair (@cases) {
		my ($l, $r) = @$pair;
		returns_ok(datecmp($l, $r), { type => 'integer' },
			"datecmp('$l', '$r') returns an integer");
	}
};

# =========================================================================
# 22. Memory-cycle checks
#
# We check only the data structures owned by this module and its test
# helpers.  The real $Date::Cmp::dfg singleton is deliberately excluded:
# after its first parse_datetime call it lazily builds an internal parser
# (stored under $dfg->{date_parser}{recce} and $dfg->{dfn}) that contains
# GLOB and REGEXP refs — types Devel::Cycle cannot traverse.  Those refs
# are third-party internals (DateTime::Format::Genealogy / Marpa parser);
# we do not own them and cannot control their structure.  Passing $dfg to
# memory_cycle_ok produces harmless "Unhandled type: GLOB/REGEXP" noise on
# STDERR without providing any signal about our code's memory behaviour.
# =========================================================================
subtest 'no memory cycles in owned data structures' => sub {
	my $mock = MockDFG->new();
	$mock->enqueue([ Fake::DateTime->new(year => 1900) ]);
	memory_cycle_ok($mock, 'MockDFG holding Fake::DateTime has no cycles');

	my $dt = Fake::DateTime->new(year => 1900);
	memory_cycle_ok($dt, 'Fake::DateTime object has no cycles');

	# A populated MockDFG after dequeue (queue now empty) also has no cycles
	$mock->parse_datetime();
	memory_cycle_ok($mock, 'MockDFG after queue exhausted has no cycles');

	diag 'all memory cycle checks passed' if $ENV{TEST_VERBOSE};
};

restore_all();   # clean up Term::ANSIColor::colored mock

done_testing();
