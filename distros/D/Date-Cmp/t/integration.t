#!/usr/bin/env perl

# End-to-end, black-box integration tests for Date::Cmp.
#
# Strategy: test *workflows* — sorting, genealogy life-event validation,
# stateful multi-call sequences, mixed input types — rather than individual
# branches.  Heavy mocking is avoided; we use Spy to verify that external
# routines are called (or deliberately skipped) with the right arguments.
#
# Sections
#  1. Module loading
#  2. Chronological sort workflow
#  3. Genealogy life-event validation
#  4. $dfg singleton stability across many calls
#  5. Complain-callback batch accumulation
#  6. Cross-format transitivity chain
#  7. Mixed-type sort (objects, hashrefs, strings)
#  8. Spy: DFG called only for complex dates; ordering with blessed()
#  9. Fast-path isolation: DFG must NOT be called for simple inputs
# 10. Test::Without::Module: Date::Cmp cannot load without required dep
# 11. Return-value schema validation across format types
# 12. Concurrency-style: independent parallel comparison sequences
# 13. Cleanup / call-log teardown

use strict;
use warnings;

use FindBin;
use Test::Most;
use Test::Returns;
use Test::Mockingbird;
use Test::Without::Module ();    # imported on demand inside tests
use Readonly;

use File::Spec;

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

Readonly my $LT => -1;
Readonly my $EQ =>  0;
Readonly my $GT =>  1;

# Genealogy date fixtures used across multiple subtests
Readonly my %DATE => (
	birth_plain     => '1842',
	birth_approx    => 'Abt. 1842',
	birth_ca        => 'ca. 1842',
	birth_question  => '1842 ?',
	marriage_bet    => 'BET 1865 AND 1870',
	marriage_dash   => '1865-1870',
	marriage_exact  => '1867-04-12',
	death_iso       => '1902-11-23',
	death_plain     => '1902',
	event_1         => '30 SEP 1943',
	event_2         => '4 AUG 1955',
	complex_1       => '1 Jan 1900',
	complex_2       => '1 Feb 1900',
	range_start     => '1830',
	range_mid       => '1831',
	range_end       => '1832',
	range_dash      => '1830-1832',
	range_bet       => 'BET 1830 AND 1832',
);

# ---------------------------------------------------------------------------
# Helper: silence STDERR (error paths print diagnostic output)
# ---------------------------------------------------------------------------

sub silence_stderr (&) {
	my ($code) = @_;
	my $devnull = File::Spec->devnull();
	open(my $saved, '>&STDERR') or die "dup STDERR: $!";
	open(STDERR, '>', $devnull) or die "redirect STDERR: $!";
	my ($result, $err);
	eval { $result = $code->() };
	$err = $@;
	open(STDERR, '>&', $saved) or die "restore STDERR: $!";
	close $saved;
	die $err if $err;
	return $result;
}

# Suppress ANSIColor so diagnostic STDERR is plain text in all tests below.
mock 'Term::ANSIColor::colored' => sub { $_[0] };

# ============================================================
# SECTION 1 — Module loading
# ============================================================

# Verify the module is loadable via use_ok and exports the right symbol.
# This also serves as a bail-out guard: if the module doesn't load, all
# subsequent tests are meaningless.
use_ok('Date::Cmp', 'datecmp') or BAIL_OUT('Date::Cmp failed to load');

use Date::Cmp qw(datecmp);

subtest 'module exports and singleton are present' => sub {
	can_ok('Date::Cmp', 'datecmp');
	ok(grep({ $_ eq 'datecmp' } @Date::Cmp::EXPORT_OK),
		'datecmp is listed in @EXPORT_OK');
	ok(defined $Date::Cmp::dfg,
		'$dfg singleton is defined after module load');
	ok($Date::Cmp::dfg->isa('DateTime::Format::Genealogy'),
		'$dfg is a DateTime::Format::Genealogy object');
};

# ============================================================
# SECTION 2 — Chronological sort workflow
# ============================================================

# Realistic genealogy workflow: a user imports records from multiple
# sources, each using a different date format, and needs them in order.
# datecmp is used as the sort comparator.

subtest 'mixed-format date list sorts to correct chronological order' => sub {
	my @unsorted = (
		$DATE{range_bet},       # BET 1830 AND 1832
		'1805',
		$DATE{birth_approx},    # Abt. 1842
		'1785-03-15',
		'ca. 1810',
		'Oct/Nov/Dec 1821',
	);

	my @sorted = sort { datecmp($a, $b) } @unsorted;

	my @expected = (
		'1785-03-15',
		'1805',
		'ca. 1810',
		'Oct/Nov/Dec 1821',
		$DATE{range_bet},
		$DATE{birth_approx},
	);

	is_deeply(\@sorted, \@expected, 'six mixed-format dates sort correctly');
	diag('Sorted: ' . join(', ', @sorted)) if $ENV{TEST_VERBOSE};
};

# ============================================================
# SECTION 3 — Genealogy life-event validation workflow
# ============================================================

# An end-to-end genealogy use case: validate that a person's life events
# are in chronological order regardless of the format each was recorded in.

subtest 'life events are in chronological order (birth < marriage < death)' => sub {
	# Test with multiple equivalent representations of the same events.
	my @birth_variants    = ($DATE{birth_approx}, $DATE{birth_ca}, $DATE{birth_question}, $DATE{birth_plain});
	my @marriage_variants = ($DATE{marriage_bet}, $DATE{marriage_dash}, $DATE{marriage_exact});
	my @death_variants    = ($DATE{death_iso}, $DATE{death_plain});

	for my $birth (@birth_variants) {
		for my $death (@death_variants) {
			cmp_ok(datecmp($birth, $death), '==', $LT,
				"'$birth' < '$death' (birth before death)");
		}
	}

	for my $marriage (@marriage_variants) {
		for my $death (@death_variants) {
			cmp_ok(datecmp($marriage, $death), '==', $LT,
				"'$marriage' < '$death' (marriage before death)");
		}
	}

	# Transitivity spot-check: birth < marriage < death
	cmp_ok(datecmp($DATE{birth_approx}, $DATE{marriage_exact}), '==', $LT,
		'birth (Abt. 1842) before marriage (1867-04-12)');
	cmp_ok(datecmp($DATE{marriage_exact}, $DATE{death_iso}), '==', $LT,
		'marriage (1867-04-12) before death (1902-11-23)');

	diag("Birth variants: @birth_variants") if $ENV{TEST_VERBOSE};
};

# ============================================================
# SECTION 4 — $dfg singleton stability across many calls
# ============================================================

# The module-level $dfg object is reused for every call.  Verify that
# exercising many different code paths does not corrupt the singleton
# and that all comparisons remain correct after repeated use.

subtest '$dfg singleton is the same object before and after many calls' => sub {
	my $dfg_identity_before = $Date::Cmp::dfg;

	# Drive calls through many distinct paths: fast-path years, approx
	# prefixes, DFG-parsed complex dates, BET ranges, and BEF qualifiers.
	datecmp('1900',              '1950');
	datecmp('Abt. 1850',        '1860');
	datecmp($DATE{complex_1},   $DATE{complex_2});
	datecmp($DATE{range_bet},   $DATE{range_mid});
	datecmp('bef 1 Jun 1965',   '1969');
	datecmp($DATE{event_1},     $DATE{event_2});
	datecmp('1929/06/26',       '1939');

	my $dfg_identity_after = $Date::Cmp::dfg;
	is($dfg_identity_before, $dfg_identity_after,
		'$dfg is the identical object after many varied calls');

	# Sanity: results are still correct after many prior calls.
	cmp_ok(datecmp('1800', '1900'), '==', $LT, 'comparison still correct after prior calls');
	cmp_ok(datecmp('1900', '1900'), '==', $EQ, 'equality still correct after prior calls');
	cmp_ok(datecmp('1900', '1800'), '==', $GT, 'reverse still correct after prior calls');
};

# ============================================================
# SECTION 5 — Complain-callback batch accumulation
# ============================================================

# In a batch-processing genealogy workflow a user collects all ambiguous-date
# warnings by passing the same callback to multiple datecmp calls.  Verify
# that callbacks from independent calls do not interfere with each other.

subtest 'complain callbacks accumulate correctly across multiple calls' => sub {
	my @diagnostics;
	my $collector = sub { push @diagnostics, @_ };

	# First ambiguous call: equal-endpoint range on RHS.
	my $r1 = silence_stderr { datecmp('1900', '1900-1900', $collector) };
	my $count_after_first = scalar @diagnostics;
	ok($count_after_first > 0, 'first ambiguous call invokes callback');

	# Clean call: must NOT add to the diagnostic list.
	my $r2 = datecmp('1800', '1900');
	is(scalar @diagnostics, $count_after_first,
		'clean call does not grow the diagnostic list');

	# Second ambiguous call: another equal-endpoint range.
	my $r3 = silence_stderr { datecmp('1850', '1850-1850', $collector) };
	ok(scalar @diagnostics > $count_after_first,
		'second ambiguous call adds more diagnostics');

	# Third ambiguous call: inverted left-side range.
	my $r4 = silence_stderr { datecmp('1832-1830', '1831', $collector) };
	ok(scalar @diagnostics > 0, 'total diagnostic count is positive');

	# All results must be integers.
	returns_is($r1, { type => 'integer' }, 'r1 (equal-endpoint) returns integer');
	returns_is($r2, { type => 'integer' }, 'r2 (clean)          returns integer');
	returns_is($r3, { type => 'integer' }, 'r3 (equal-endpoint) returns integer');
	returns_is($r4, { type => 'integer' }, 'r4 (inverted range) returns integer');

	diag('Diagnostics: ' . join('; ', @diagnostics)) if $ENV{TEST_VERBOSE};
};

# ============================================================
# SECTION 6 — Cross-format transitivity chain
# ============================================================

# For any three dates a, b, c: if a < b and b < c then a < c, regardless
# of the input format used for each.  This verifies that format normalisation
# is consistent across the boundary between different parsers.

subtest 'cross-format comparison chain satisfies transitivity' => sub {
	my @chain = (
		'1673-07-01',           # ISO date (16th/17th century)
		'26 Aug 1744',          # day-month-year string -> DFG
		$DATE{range_bet},       # BET 1830 AND 1832
		'Abt. 1880',            # approximate prefix
		'1902-11-23',           # ISO date
	);

	# Verify every consecutive pair is strictly increasing.
	for my $i (0 .. $#chain - 1) {
		cmp_ok(
			datecmp($chain[$i], $chain[$i + 1]),
			'==', $LT,
			"chain[$i] < chain[${\($i+1)}]: '$chain[$i]' < '$chain[$i+1]'",
		);
	}

	# Verify first < last (long-range transitivity).
	cmp_ok(datecmp($chain[0], $chain[-1]), '==', $LT,
		'first element is before last element (transitivity)');

	# Verify the reverse direction is consistently $GT.
	cmp_ok(datecmp($chain[-1], $chain[0]), '==', $GT,
		'last element is after first element (reverse transitivity)');
};

# ============================================================
# SECTION 7 — Mixed-type sort (objects, hashrefs, strings)
# ============================================================

# A real genealogy application may provide dates from heterogeneous sources:
# a model object from an ORM, a raw hashref from JSON, and a plain string
# from user input.  All three must sort together correctly.

{
	package GedcomRecord;
	sub new  { bless { date => $_[1] }, $_[0] }
	sub date { $_[0]->{date} }
}

subtest 'objects, hashrefs, and strings interoperate in a sort workflow' => sub {
	my @sources = (
		GedcomRecord->new('1 Jan 1802'),     # blessed object
		{ date => 'BET 1820 AND 1825' },     # hashref
		'1835',                              # plain string
		GedcomRecord->new('Abt. 1860'),      # blessed object, approx
		{ date => '1900-06-15' },            # hashref, ISO date
	);

	my @sorted = sort { datecmp($a, $b) } @sources;

	# Extract the first four-digit year from each element in sorted order.
	my @years = map {
		my $d = ref($_) eq 'GedcomRecord' ? $_->date()
		      : ref($_) eq 'HASH'         ? $_->{date}
		      :                             "$_";
		$d =~ /(\d{3,4})/;
		$1 + 0;
	} @sorted;

	is_deeply(\@years, [1802, 1820, 1835, 1860, 1900],
		'mixed-type inputs sort to correct year sequence');

	diag('Sorted years: ' . join(', ', @years)) if $ENV{TEST_VERBOSE};
};

# ============================================================
# SECTION 8 — Spy: DFG called for complex dates; call ordering
# ============================================================

# Verify the internal contract: DFG is called for complex dates (where
# fast-path year comparisons cannot determine the result) and is NOT called
# for simple year-only comparisons.  Also verify that Scalar::Util::blessed()
# is invoked before DFG when the inputs are blessed objects.

subtest 'spy: DFG is called for complex dates and skipped for fast-path years' => sub {
	clear_call_log();
	my $spy_dfg = spy 'DateTime::Format::Genealogy::parse_datetime';

	# Fast-path case: plain integers with different years.
	# The fast-path exits before DFG is reached.
	datecmp('1900', '1950');
	my @fast_calls = $spy_dfg->();
	is(scalar @fast_calls, 0,
		'DFG not called when fast-path fires for plain years (1900 vs 1950)');

	# Complex case: same-year day-month-year strings.
	# Fast-path ties on year 1900 and falls through to DFG for both sides.
	datecmp($DATE{complex_1}, $DATE{complex_2});    # '1 Jan 1900' vs '1 Feb 1900'
	my @complex_calls = $spy_dfg->();
	ok(scalar @complex_calls >= 2,
		'DFG called at least twice for same-year complex dates');

	# Verify argument shape: each call must pass a hashref with date and quiet keys.
	for my $call (@complex_calls) {
		my (undef, $args_hashref) = @{$call}[1, 2];    # [$method, $self, $hashref]
		next unless ref($args_hashref) eq 'HASH';
		ok(exists $args_hashref->{date},  'DFG call has "date" key in args hashref');
		ok(exists $args_hashref->{quiet}, 'DFG call has "quiet" key in args hashref');
		ok($args_hashref->{quiet},        '"quiet" flag is true');
	}

	diag('DFG complex calls: ' . scalar(@complex_calls)) if $ENV{TEST_VERBOSE};

	restore_all('DateTime::Format::Genealogy');
};

subtest 'spy: object date() method called before DFG in parsing workflow' => sub {
	# Scalar::Util::blessed is an XS function that may be inlined into the
	# optree at compile time, making it impossible to intercept via symbol-table
	# replacement.  Instead we spy on GedcomRecord::date (a pure-Perl sub) to
	# verify the object-extraction step runs before DFG is invoked.
	clear_call_log();
	my $spy_date = spy 'GedcomRecord::date';
	my $spy_dfg  = spy 'DateTime::Format::Genealogy::parse_datetime';

	# Same-year complex dates: fast-path ties so DFG must be invoked.
	datecmp(GedcomRecord->new($DATE{complex_1}), $DATE{complex_2});

	my @date_calls = $spy_date->();
	my @dfg_calls  = $spy_dfg->();

	ok(scalar(@date_calls) > 0, 'GedcomRecord::date() was called for object input');
	ok(scalar(@dfg_calls) > 0,  'DFG was called for complex date resolution');

	# date() must be called before DFG: we need the string before we can parse it.
	assert_call_order(
		'GedcomRecord::date',
		'DateTime::Format::Genealogy::parse_datetime',
	);

	restore_all('GedcomRecord');
	restore_all('DateTime::Format::Genealogy');
};

# ============================================================
# SECTION 9 — Fast-path isolation: DFG must NOT be called
# ============================================================

# Prove that the documented fast-path inputs truly bypass DFG.
# We mock DFG to die if called; any fast-path input must survive.

subtest 'documented fast-path inputs do not invoke DFG' => sub {
	mock 'DateTime::Format::Genealogy::parse_datetime'
		=> sub { die 'DFG must not be called for fast-path inputs' };

	# All of these must complete without triggering the mock.
	lives_ok { datecmp('1900',         '1950')       } 'plain years: no DFG';
	lives_ok { datecmp('Abt. 1850',   '1860')        } 'Abt. prefix: no DFG';
	lives_ok { datecmp('ca. 1850',    '1860')        } 'ca. prefix: no DFG';
	lives_ok { datecmp('1828 ?',      '1830')        } '? suffix: no DFG';
	lives_ok { datecmp('1900',        'Abt. 1950')   } 'Abt. on right: no DFG';
	lives_ok { datecmp($DATE{range_mid}, $DATE{range_dash}) }
		'integer vs right-side dash range: no DFG';
	lives_ok { datecmp($DATE{range_mid}, $DATE{range_bet}) }
		'integer vs right-side BET range: no DFG';

	unmock 'DateTime::Format::Genealogy::parse_datetime';
};

# ============================================================
# SECTION 10 — Test::Without::Module: required dep loading
# ============================================================

# Verify that Date::Cmp correctly signals a hard failure when its required
# dependency DateTime::Format::Genealogy is absent at load time.
# We manipulate %INC to force a re-require inside the eval.

subtest 'Date::Cmp fails to load without DateTime::Format::Genealogy' => sub {
	# Manipulating %INC inside a running test process is fragile because
	# Test::Without::Module may tie the hash, making assignments to previously
	# absent keys fail.  Use a subprocess instead: a fresh perl that has never
	# loaded Date::Cmp, with the required dep blocked, will report cleanly.
	my $lib = File::Spec->catdir($FindBin::Bin, '..', 'lib');
	my $tmp = File::Spec->catfile(File::Spec->tmpdir(), "date_cmp_load_$$\.pl");

	open(my $fh, '>', $tmp) or do {
		skip "Cannot write temp file: $!", 1;
		return;
	};
	print $fh <<'PERL';
use Test::Without::Module qw(DateTime::Format::Genealogy);
eval { require Date::Cmp };
print $@ =~ /DateTime|Genealogy|locate/i ? "FAIL_OK\n" : "LOADED_UNEXPECTEDLY\n";
PERL
	close $fh;

	my $devnull = File::Spec->devnull();
	my $out = `"$^X" "-I$lib" "$tmp" 2>"$devnull"`;
	unlink $tmp;

	like($out, qr/FAIL_OK/,
		'Date::Cmp emits a load error when DateTime::Format::Genealogy is absent');

	# Verify the current process's module is unaffected.
	cmp_ok(datecmp('1900', '1950'), '==', $LT,
		'datecmp still works in the current process after subprocess test');
};

# ============================================================
# SECTION 11 — Return-value schema validation
# ============================================================

# Validate that the documented integer return type (-1, 0, 1) holds for
# every format category listed in the POD.

subtest 'return value is always a documented integer (-1, 0, 1)' => sub {
	my @cases = (
		['plain years: earlier',      '1900',               '1950'],
		['plain years: equal',        '1900',               '1900'],
		['plain years: later',        '1950',               '1900'],
		['approx Abt. earlier',       'Abt. 1900',          '1950'],
		['ISO date earlier',          '1900-01-01',         '1950-01-01'],
		['slash date earlier',        '1929/06/26',         '1939'       ],
		['right dash range within',   '1831',               '1830-1832'  ],
		['right BET range within',    '1831',               'BET 1830 AND 1832'],
		['left dash range eq',        '1830-1832',          '1830-02-06' ],
		['month range earlier',       '1891',               'Oct/Nov/Dec 1892'],
		['BEF qualifier on left',     'bef 1 Jun 1965',     '1969'       ],
		['BEF qualifier on right',    '1939',               'bef 1 Jun 1965'],
	);

	for my $case (@cases) {
		my ($label, $left, $right) = @{$case};
		my $result = datecmp($left, $right);
		returns_is($result, { type => 'integer' }, "$label: returns integer");
		ok(grep({ $result == $_ } $LT, $EQ, $GT),
			"$label: return value is -1, 0, or 1 (got $result)");
	}
};

# ============================================================
# SECTION 12 — Concurrency-style: independent call sequences
# ============================================================

# Although Date::Cmp has no per-instance state (it is a function module),
# verify that interleaved calls with different formats do not corrupt results.
# This simulates concurrent usage patterns (e.g. sort callbacks from different
# sort operations running in sequence in the same process).

subtest 'interleaved calls from two independent sort sequences do not interfere' => sub {
	my @seq_a = ('1785', '1810', '1842', '1867', '1902');
	my @seq_b = ('BET 1830 AND 1832', 'Abt. 1850', '1 Jan 1900');

	# Interleave comparisons from both sequences.
	my @results_a;
	my @results_b;
	for my $i (0 .. $#seq_a - 1) {
		push @results_a, datecmp($seq_a[$i], $seq_a[$i + 1]);

		if($i < $#seq_b - 1) {
			push @results_b, datecmp($seq_b[$i], $seq_b[$i + 1]);
		}
	}

	# Sequence A is strictly ascending — every comparison must be $LT.
	for my $i (0 .. $#results_a) {
		cmp_ok($results_a[$i], '==', $LT,
			"seq_a[$i] vs seq_a[${\($i+1)}]: strictly earlier");
	}

	# Sequence B is also strictly ascending.
	for my $i (0 .. $#results_b) {
		cmp_ok($results_b[$i], '==', $LT,
			"seq_b[$i] vs seq_b[${\($i+1)}]: strictly earlier");
	}

	diag('Seq A results: @results_a') if $ENV{TEST_VERBOSE};
	diag('Seq B results: @results_b') if $ENV{TEST_VERBOSE};
};

# ============================================================
# SECTION 13 — Cleanup
# ============================================================

restore_all();

done_testing();
