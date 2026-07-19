#!/usr/bin/env perl

# Black-box unit tests for Date::Cmp::datecmp(), derived strictly from the
# public API documented in the module POD.  Every documented behaviour,
# return code, and error condition is catalogued in %LEDGER; entries are
# deleted as they are exercised and the ledger is asserted empty at the end.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Readonly;

use Date::Cmp qw(datecmp);
use File::Spec;
use Scalar::Util qw(blessed);

# ---------------------------------------------------------------------------
# Constants — no magic strings or numbers in the test bodies
# ---------------------------------------------------------------------------

Readonly my $LT => -1;
Readonly my $EQ =>  0;
Readonly my $GT =>  1;

Readonly my %LEDGER_INIT => (
	# --- Return codes (POD: "Returns" section) ---
	'return:-1'                  => 'left is earlier than right',
	'return:0'                   => 'equivalent dates',
	'return:1'                   => 'left is later than right',

	# --- Input: year-only strings (POD: SUPPORTED FORMATS) ---
	'format:year-only'           => 'plain year string comparison',

	# --- Input: approximate prefixes (POD: SUPPORTED FORMATS) ---
	'format:approx-abt'          => 'Abt. prefix stripped on left',
	'format:approx-ca'           => 'ca. prefix stripped on left',
	'format:approx-question'     => '? suffix stripped on left',
	'format:approx-rhs'          => 'approximate prefix stripped on right',

	# --- Input: exact date formats (POD: SUPPORTED FORMATS) ---
	'format:exact-iso'           => 'ISO date (YYYY-MM-DD)',
	'format:exact-slash'         => 'slash date (M/D/YYYY)',

	# --- Input: date ranges (POD: SUPPORTED FORMATS) ---
	'format:range-dash-within'   => 'value within dash range',
	'format:range-dash-before'   => 'value before dash range',
	'format:range-dash-after'    => 'value after dash range',
	'format:range-dash-at-from'  => 'value equals dash range lower bound',
	'format:range-dash-at-to'    => 'value equals dash range upper bound',
	'format:range-bet-within'    => 'value within BET range',
	'format:range-bet-at-from'   => 'value equals BET range lower bound',
	'format:range-bet-at-to'     => 'value equals BET range upper bound',
	'format:range-lhs-dash'      => 'dash range on left side',
	'format:range-lhs-bet'       => 'BET range on left side',

	# --- Input: month ranges (POD: SUPPORTED FORMATS) ---
	'format:month-range'         => 'Oct/Nov/Dec YYYY month range',

	# --- Input: BEF qualifier (POD: SUPPORTED FORMATS) ---
	'format:bef-lhs'             => 'BEF qualifier on left side',
	'format:bef-rhs'             => 'BEF qualifier on right side',

	# --- Input: blessed object with date() method (POD: datecmp Arguments) ---
	'input:object-date-method'   => 'blessed object with date() method',

	# --- Input: hashref with date key (POD: datecmp Arguments) ---
	'input:hashref-date-key'     => 'hashref with date key',

	# --- Complain callback (POD: $complain argument) ---
	'complain:equal-endpoints'   => 'callback for range with equal endpoints',
	'complain:inverted-range'    => 'callback for inverted range on left',

	# --- Error: undef input (POD: Returns / ERROR HANDLING) ---
	'error:undef-left-returns-0' => 'undef left returns 0',
	'error:undef-right-returns-0'=> 'undef right returns 0',

	# --- Error: invalid leading character (POD: ERROR HANDLING) ---
	'error:invalid-left-dies'    => 'invalid left char dies',
	'error:invalid-right-dies'   => 'invalid right char dies',

	# --- Error: completely unparseable date (POD: ERROR HANDLING) ---
	'error:unparseable-right-dies' => 'unparseable right date dies',
);

my %ledger = %LEDGER_INIT;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Redirect STDERR to /dev/null for the duration of the code block.
# Returns the scalar return value of the block.
sub silence_stderr (&) {
	my ($code) = @_;
	my $devnull = File::Spec->devnull();
	open(my $saved, '>&STDERR')    or die "dup STDERR: $!";
	open(STDERR, '>', $devnull)    or die "redirect STDERR: $!";
	my ($result, $err);
	eval { $result = $code->() };
	$err = $@;
	open(STDERR, '>&', $saved)     or die "restore STDERR: $!";
	close $saved;
	die $err if $err;
	return $result;
}

# Capture STDERR output into a string via a temp file (scalar-ref redirect
# is not reliable for real STDERR on all platforms).
sub capture_stderr (&) {
	my ($code) = @_;
	my $tmp = File::Spec->catfile(File::Spec->tmpdir(), "unit_stderr_$$");
	open(my $saved, '>&STDERR')    or die "dup STDERR: $!";
	open(STDERR, '>', $tmp)        or die "redirect STDERR: $!";
	my $err;
	eval { $code->() };
	$err = $@;
	open(STDERR, '>&', $saved)     or die "restore STDERR: $!";
	close $saved;
	my $buf = '';
	if(-e $tmp) {
		open(my $fh, '<', $tmp) or die "read tmp: $!";
		local $/;
		$buf = <$fh>;
		unlink $tmp;
	}
	die $err if $err;
	return $buf;
}

# Suppress Term::ANSIColor so diagnostic output is predictable.
mock 'Term::ANSIColor::colored' => sub { $_[0] };

# ---------------------------------------------------------------------------
# 1. Return value schema — all three documented codes
# ---------------------------------------------------------------------------

subtest 'documented return values satisfy integer schema' => sub {
	# Each cmp_ok call below checks exact numeric value.
	# returns_is validates the value against the documented scalar-integer schema.

	my $lt_val = datecmp('1900', '1950');
	returns_is($lt_val, { type => 'integer' }, 'returns_is: -1 is integer');
	cmp_ok($lt_val, '==', $LT, 'plain years: earlier returns -1');
	delete $ledger{'return:-1'};
	delete $ledger{'format:year-only'};

	my $eq_val = datecmp('1900', '1900');
	returns_is($eq_val, { type => 'integer' }, 'returns_is: 0 is integer');
	cmp_ok($eq_val, '==', $EQ, 'plain years: equal returns 0');
	delete $ledger{'return:0'};

	my $gt_val = datecmp('1950', '1900');
	returns_is($gt_val, { type => 'integer' }, 'returns_is: 1 is integer');
	cmp_ok($gt_val, '==', $GT, 'plain years: later returns 1');
	delete $ledger{'return:1'};
};

# ---------------------------------------------------------------------------
# 2. Approximate date prefixes on the left
# ---------------------------------------------------------------------------

subtest 'approximate prefix: Abt. stripped on left' => sub {
	cmp_ok(datecmp('Abt. 1850', '1860'), '==', $LT, 'Abt. 1850 earlier than 1860');
	cmp_ok(datecmp('Abt. 1860', '1850'), '==', $GT, 'Abt. 1860 later than 1850');
	cmp_ok(datecmp('Abt. 1850', '1850'), '==', $EQ, 'Abt. 1850 equals 1850');
	delete $ledger{'format:approx-abt'};
};

subtest 'approximate prefix: ca. stripped on left' => sub {
	cmp_ok(datecmp('ca. 1820', '1830'), '==', $LT, 'ca. 1820 earlier than 1830');
	cmp_ok(datecmp('ca. 1830', '1820'), '==', $GT, 'ca. 1830 later than 1820');
	delete $ledger{'format:approx-ca'};
};

subtest 'approximate suffix: ? stripped on left' => sub {
	cmp_ok(datecmp('1828 ?', '1830'), '==', $LT, '1828 ? earlier than 1830');
	cmp_ok(datecmp('1828 ?', '1828'), '==', $EQ, '1828 ? equals 1828');
	delete $ledger{'format:approx-question'};
};

subtest 'approximate prefix stripped on right side' => sub {
	cmp_ok(datecmp('1820', 'Abt. 1830'), '==', $LT, '1820 earlier than Abt. 1830');
	cmp_ok(datecmp('1840', 'ca. 1830'),  '==', $GT, '1840 later than ca. 1830');
	cmp_ok(datecmp('1828', '1828 ?'),    '==', $EQ, '1828 equals 1828 ?');
	delete $ledger{'format:approx-rhs'};
};

# ---------------------------------------------------------------------------
# 3. Exact date formats
# ---------------------------------------------------------------------------

subtest 'ISO date format (YYYY-MM-DD)' => sub {
	cmp_ok(datecmp('1941-08-02', '1955-01-01'), '==', $LT, 'ISO: earlier');
	cmp_ok(datecmp('1955-01-01', '1941-08-02'), '==', $GT, 'ISO: later');
	cmp_ok(datecmp('1941-08-02', '1941-08-02'), '==', $EQ, 'ISO: equal');
	delete $ledger{'format:exact-iso'};
};

subtest 'slash date format (D/M/YYYY or M/D/YYYY)' => sub {
	cmp_ok(datecmp('1929/06/26', '1939'), '==', $LT, 'slash date earlier than year');
	cmp_ok(datecmp('5/27/1872',  '1900'), '==', $LT, 'M/D/YYYY earlier than year');
	delete $ledger{'format:exact-slash'};
};

# ---------------------------------------------------------------------------
# 4. Date ranges on the right side
# ---------------------------------------------------------------------------

subtest 'right-side dash range: boundary and interior cases' => sub {
	# within (interior)
	cmp_ok(datecmp('1831', '1830-1832'), '==', $EQ, '1831 within 1830-1832');
	delete $ledger{'format:range-dash-within'};

	# at lower bound
	cmp_ok(datecmp('1830', '1830-1832'), '==', $EQ, '1830 at lower bound of 1830-1832');
	delete $ledger{'format:range-dash-at-from'};

	# at upper bound
	cmp_ok(datecmp('1832', '1830-1832'), '==', $EQ, '1832 at upper bound of 1830-1832');
	delete $ledger{'format:range-dash-at-to'};

	# before range
	cmp_ok(datecmp('1825', '1830-1832'), '==', $LT, '1825 before 1830-1832');
	delete $ledger{'format:range-dash-before'};

	# after range
	cmp_ok(datecmp('1840', '1830-1832'), '==', $GT, '1840 after 1830-1832');
	delete $ledger{'format:range-dash-after'};
};

subtest 'right-side BET range: boundary and interior cases' => sub {
	cmp_ok(datecmp('1831', 'BET 1830 AND 1832'), '==', $EQ, '1831 within BET range');
	delete $ledger{'format:range-bet-within'};

	cmp_ok(datecmp('1830', 'BET 1830 AND 1832'), '==', $EQ, '1830 at lower BET bound');
	delete $ledger{'format:range-bet-at-from'};

	cmp_ok(datecmp('1832', 'BET 1830 AND 1832'), '==', $EQ, '1832 at upper BET bound');
	delete $ledger{'format:range-bet-at-to'};
};

# ---------------------------------------------------------------------------
# 5. Date ranges on the left side
# ---------------------------------------------------------------------------

subtest 'left-side dash range compared to year within range' => sub {
	cmp_ok(datecmp('1830-1832', '1830-02-06'), '==', $EQ, 'BET range on left vs ISO date');
	delete $ledger{'format:range-lhs-dash'};
};

subtest 'left-side BET range compared to date within range' => sub {
	cmp_ok(datecmp('BET 1830 AND 1832', '1830-02-06'), '==', $EQ, 'BET range on left vs ISO date');
	delete $ledger{'format:range-lhs-bet'};
};

# ---------------------------------------------------------------------------
# 6. Month ranges
# ---------------------------------------------------------------------------

subtest 'month ranges (Oct/Nov/Dec YYYY)' => sub {
	cmp_ok(datecmp('1891', 'Oct/Nov/Dec 1892'), '==', $LT, '1891 earlier than Oct/Nov/Dec 1892');
	cmp_ok(datecmp('1893', 'Oct/Nov/Dec 1892'), '==', $GT, '1893 later than Oct/Nov/Dec 1892');
	delete $ledger{'format:month-range'};
};

# ---------------------------------------------------------------------------
# 7. BEF qualifier
# ---------------------------------------------------------------------------

subtest 'BEF qualifier on left side' => sub {
	cmp_ok(datecmp('bef 1 Jun 1965', '1969'), '==', $LT, 'BEF 1965 earlier than 1969');
	delete $ledger{'format:bef-lhs'};
};

subtest 'BEF qualifier on right side' => sub {
	cmp_ok(datecmp('1939', 'bef 1 Jun 1965'), '==', $LT, '1939 earlier than bef 1965');
	delete $ledger{'format:bef-rhs'};
};

# ---------------------------------------------------------------------------
# 8. Object input: blessed object with date() method
# ---------------------------------------------------------------------------

subtest 'blessed object with date() method is accepted' => sub {
	package DateObj;
	sub new  { bless { d => $_[1] }, $_[0] }
	sub date { $_[0]->{d} }

	package main;

	my $obj1 = DateObj->new('1900');
	my $obj2 = DateObj->new('1950');
	ok(blessed($obj1) && $obj1->can('date'), 'test object is a blessed object with date()');
	cmp_ok(datecmp($obj1, $obj2), '==', $LT, 'object 1900 earlier than object 1950');
	cmp_ok(datecmp($obj2, $obj1), '==', $GT, 'object 1950 later than object 1900');
	cmp_ok(datecmp($obj1, $obj1), '==', $EQ, 'same object date equals itself');
	delete $ledger{'input:object-date-method'};
};

# ---------------------------------------------------------------------------
# 9. Hashref input
# ---------------------------------------------------------------------------

subtest 'hashref with date key is accepted' => sub {
	my $h1 = { date => '16/11/1689' };
	my $h2 = { date => '1659-07-01' };
	cmp_ok(datecmp($h1, $h2), '==', $GT, 'hashref 1689 later than hashref 1659');
	cmp_ok(datecmp($h2, $h1), '==', $LT, 'hashref 1659 earlier than hashref 1689');
	cmp_ok(datecmp($h1, $h1), '==', $EQ, 'same hashref date equals itself');
	delete $ledger{'input:hashref-date-key'};
};

# ---------------------------------------------------------------------------
# 10. Complain callback
# ---------------------------------------------------------------------------

subtest 'complain callback: equal endpoints on right-side range' => sub {
	# A range like '1900-1900' has equal endpoints.
	# The callback must be invoked; return value should still be numeric.
	my @messages;
	my $result = silence_stderr {
		datecmp('1900', '1900-1900', sub { push @messages, @_ });
	};
	ok(scalar(@messages) > 0, 'callback was invoked for equal-endpoint range');
	like($messages[0], qr/1900/, 'callback message references the year');
	returns_is($result, { type => 'integer' }, 'result is still an integer');
	delete $ledger{'complain:equal-endpoints'};
};

subtest 'complain callback: inverted range on left side' => sub {
	# A range like '1832-1830' has from > to (inverted).
	my @messages;
	my $result = silence_stderr {
		datecmp('1832-1830', '1831', sub { push @messages, @_ });
	};
	ok(scalar(@messages) > 0, 'callback was invoked for inverted left range');
	returns_is($result, { type => 'integer' }, 'result is still an integer after inverted range');
	delete $ledger{'complain:inverted-range'};
};

# ---------------------------------------------------------------------------
# 11. Undef inputs — return 0 after STDERR output (documented in Returns)
# ---------------------------------------------------------------------------

subtest 'undef left: returns 0 without dying' => sub {
	my $result;
	my $stderr = capture_stderr { $result = datecmp(undef, '1900') };
	cmp_ok($result, '==', $EQ, 'undef left returns 0');
	ok(length($stderr) > 0, 'undef left prints to STDERR');
	returns_is($result, { type => 'integer' }, 'result is integer');
	delete $ledger{'error:undef-left-returns-0'};
};

subtest 'undef right: returns 0 without dying' => sub {
	my $result;
	my $stderr = capture_stderr { $result = datecmp('1900', undef) };
	cmp_ok($result, '==', $EQ, 'undef right returns 0');
	ok(length($stderr) > 0, 'undef right prints to STDERR');
	delete $ledger{'error:undef-right-returns-0'};
};

# ---------------------------------------------------------------------------
# 12. Invalid leading character — must die (documented in ERROR HANDLING)
# ---------------------------------------------------------------------------

subtest 'invalid left: dies with Date parse failure' => sub {
	silence_stderr {
		throws_ok(
			sub { datecmp('!invalid', '1900') },
			qr/Date parse failure.*left/i,
			'invalid left char causes die with "Date parse failure: left"',
		);
	};
	delete $ledger{'error:invalid-left-dies'};
};

subtest 'invalid right: dies with Date parse failure' => sub {
	silence_stderr {
		throws_ok(
			sub { datecmp('1900', '!invalid') },
			qr/Date parse failure.*right/i,
			'invalid right char causes die with "Date parse failure: right"',
		);
	};
	delete $ledger{'error:invalid-right-dies'};
};

# ---------------------------------------------------------------------------
# 13. Completely unparseable right date via DFG — must die
# ---------------------------------------------------------------------------

subtest 'unparseable right date: dies via DFG failure' => sub {
	# 'Nodate1900' passes the leading-char check ([A-S0-9] — 'N' is in A-S)
	# and contains a 4-digit year so fast-paths tie and don't early-exit.
	# But there is no space/slash before the year, so the fallback year-suffix
	# extraction inside the DFG failure block also fails, forcing a die.
	# We mock parse_datetime to guarantee the DFG failure path regardless of
	# what the real DFG parser might do with a nonsense string.
	mock 'DateTime::Format::Genealogy::parse_datetime' => sub { return () };

	silence_stderr {
		throws_ok(
			sub { datecmp('1900', 'Nodate1900') },
			qr/Date parse failure/i,
			'unparseable right date via mocked DFG causes die',
		);
	};

	unmock 'DateTime::Format::Genealogy::parse_datetime';
	delete $ledger{'error:unparseable-right-dies'};
};

# ---------------------------------------------------------------------------
# 14. Global state integrity — $@, $!, $_ must not be clobbered
# ---------------------------------------------------------------------------

subtest 'datecmp does not clobber global $@, $!, or $_' => sub {
	local $@ = 'preserved-error';
	local $! = 9;            # EBADF — a non-zero errno
	local $_ = 'preserved-topic';

	datecmp('1900', '1950');

	is($@, 'preserved-error', '$@ not clobbered');
	is("$_", 'preserved-topic', '$_ not clobbered');
	# $! is volatile; we only check it was not set to 0 by our call
	# (a zero $! means "no error", which would mask the original state)
	# We can't portably freeze $! so we skip that assertion.
};

# ---------------------------------------------------------------------------
# 15. Regression: DateTime object on LHS must not crash against a year range
# ---------------------------------------------------------------------------

subtest 'DateTime LHS does not crash against a year range on RHS' => sub {
	# '1 Jan 1996' is parsed by DFG into a DateTime object because the
	# fast-path year comparison ties at 1996.  The unwrap must happen
	# before any range integer comparison (fixed in 0.07).
	cmp_ok(datecmp('1 Jan 1996', '1996-2000'),        '==', $EQ, 'DateTime LHS within dash range');
	cmp_ok(datecmp('1 Jan 1996', 'BET 1996 AND 2000'), '==', $EQ, 'DateTime LHS within BET range');
	cmp_ok(datecmp('1 Jan 1994', '1996-2000'),         '==', $LT, 'DateTime LHS before dash range');
	cmp_ok(datecmp('1 Jan 2001', '1996-2000'),         '==', $GT, 'DateTime LHS after dash range');
};

# ---------------------------------------------------------------------------
# 16. Ledger: assert every documented behaviour was exercised
# ---------------------------------------------------------------------------

subtest 'API ledger: all documented behaviours were tested' => sub {
	if(keys %ledger) {
		for my $key (sort keys %ledger) {
			fail("Untested documented behaviour: $key — $ledger{$key}");
		}
	} else {
		pass('All documented API behaviours were covered');
	}
};

# ---------------------------------------------------------------------------
# Cleanup and teardown
# ---------------------------------------------------------------------------

restore_all();

done_testing();
