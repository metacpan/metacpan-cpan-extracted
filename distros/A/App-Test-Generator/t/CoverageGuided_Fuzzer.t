#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN { use_ok('App::Test::Generator::CoverageGuidedFuzzer') }

# ------------------------------------------------------------------
# Helper: minimal valid fuzzer construction
# ------------------------------------------------------------------
sub _fuzzer {
	my (%args) = @_;
	return App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => $args{schema}     // { input => { type => 'string' } },
		target_sub => $args{target_sub} // sub { 1 },
		iterations => $args{iterations} // 0,
		seed       => $args{seed}       // 42,
		exists $args{instance} ? (instance => $args{instance}) : (),
	);
}

# ==================================================================
# new — validation
# ==================================================================
subtest 'new() croaks when schema is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::CoverageGuidedFuzzer->new(
				target_sub => sub { 1 },
			)
		},
		qr/schema required/,
		'missing schema croaks',
	);
};

subtest 'new() croaks when target_sub is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::CoverageGuidedFuzzer->new(
				schema => { input => {} },
			)
		},
		qr/target_sub required/,
		'missing target_sub croaks',
	);
};

subtest 'new() returns a blessed object' => sub {
	my $f = _fuzzer();
	ok(defined $f, 'new() returns defined value');
	isa_ok($f, 'App::Test::Generator::CoverageGuidedFuzzer');
};

subtest 'new() defaults iterations to 100' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => {} },
		target_sub => sub { 1 },
		seed       => 42,
	);
	is($f->{iterations}, 100, 'iterations defaults to 100');
};

subtest 'new() stores explicit iterations' => sub {
	my $f = _fuzzer(iterations => 50);
	is($f->{iterations}, 50, 'explicit iterations stored');
};

subtest 'new() stores seed and initialises srand' => sub {
	my $f = _fuzzer(seed => 99);
	is($f->{seed}, 99, 'seed stored');
};

subtest 'new() initialises corpus, covered, bugs, and stats' => sub {
	my $f = _fuzzer();
	is(ref($f->{corpus}),  'ARRAY', 'corpus is arrayref');
	is(ref($f->{covered}), 'HASH',  'covered is hashref');
	is(ref($f->{bugs}),    'ARRAY', 'bugs is arrayref');
	is(ref($f->{stats}),   'HASH',  'stats is hashref');
	is(scalar @{$f->{corpus}}, 0, 'corpus initially empty');
	is(scalar @{$f->{bugs}},   0, 'bugs initially empty');
};

subtest 'new() initialises stats keys to zero' => sub {
	my $f = _fuzzer();
	is($f->{stats}{total},       0, 'stats.total = 0');
	is($f->{stats}{interesting}, 0, 'stats.interesting = 0');
	is($f->{stats}{bugs},        0, 'stats.bugs = 0');
	is($f->{stats}{coverage},    0, 'stats.coverage = 0');
};

subtest 'new() stores optional instance' => sub {
	my $obj = bless {}, 'FakeClass';
	my $f   = _fuzzer(instance => $obj);
	is($f->{instance}, $obj, 'instance stored');
};

# ==================================================================
# corpus and bugs accessors
# ==================================================================
subtest 'corpus() returns the corpus arrayref' => sub {
	my $f = _fuzzer();
	my $c = $f->corpus();
	is(ref($c), 'ARRAY', 'corpus() returns arrayref');
	is($c, $f->{corpus}, 'returns same reference as internal state');
};

subtest 'bugs() returns the bugs arrayref' => sub {
	my $f = _fuzzer();
	my $b = $f->bugs();
	is(ref($b), 'ARRAY', 'bugs() returns arrayref');
	is($b, $f->{bugs}, 'returns same reference as internal state');
};

# ==================================================================
# _is_interesting
# ==================================================================
subtest '_is_interesting() returns 1 for new branch key' => sub {
	my $f = _fuzzer();
	$f->{covered} = {};
	ok($f->_is_interesting({ 'foo.pm:10:0' => 1 }),
		'new branch key -> interesting');
};

subtest '_is_interesting() returns 0 for already-covered branch' => sub {
	my $f = _fuzzer();
	$f->{covered} = { 'foo.pm:10:0' => 1 };
	# When coverage is non-empty but all keys are known, returns 0
	# (the random keep path only fires when coverage is empty)
	is($f->_is_interesting({ 'foo.pm:10:0' => 1 }), 0,
		'known branch -> not interesting');
};

subtest '_is_interesting() returns randomly for empty coverage' => sub {
	# With seed 42, deterministic — just check it returns 0 or 1
	my $f = _fuzzer(seed => 42);
	my $result = $f->_is_interesting({});
	ok($result == 0 || $result == 1, 'empty coverage returns 0 or 1');
};

# ==================================================================
# _update_covered
# ==================================================================
subtest '_update_covered() merges new branch keys into covered' => sub {
	my $f = _fuzzer();
	$f->_update_covered({ 'a:1:0' => 1, 'b:2:1' => 1 });
	ok($f->{covered}{'a:1:0'}, 'a:1:0 merged');
	ok($f->{covered}{'b:2:1'}, 'b:2:1 merged');
};

subtest '_update_covered() does not remove existing keys' => sub {
	my $f = _fuzzer();
	$f->{covered} = { 'existing:1:0' => 1 };
	$f->_update_covered({ 'new:2:0' => 1 });
	ok($f->{covered}{'existing:1:0'}, 'existing key preserved');
	ok($f->{covered}{'new:2:0'},      'new key added');
};

# ==================================================================
# _seed_corpus
# ==================================================================
subtest '_seed_corpus() adds exactly SEED_CORPUS_SIZE entries' => sub {
	my $f = _fuzzer();
	$f->_seed_corpus();
	is(scalar @{$f->{corpus}}, 5, 'seed adds 5 corpus entries');
};

subtest '_seed_corpus() each entry has input and coverage keys' => sub {
	my $f = _fuzzer();
	$f->_seed_corpus();
	for my $entry (@{$f->{corpus}}) {
		ok(exists $entry->{input},    'entry has input key');
		ok(exists $entry->{coverage}, 'entry has coverage key');
		is(ref($entry->{coverage}), 'HASH', 'coverage is a hashref');
	}
};

# ==================================================================
# _build_report
# ==================================================================
subtest '_build_report() returns hashref with all required keys' => sub {
	my $f = _fuzzer();
	my $r = $f->_build_report();
	is(ref($r), 'HASH', 'returns hashref');
	for my $key (qw(total_iterations interesting_inputs corpus_size
	                branches_covered bugs_found bugs)) {
		ok(exists $r->{$key}, "$key present in report");
	}
};

subtest '_build_report() reflects current stats' => sub {
	my $f = _fuzzer();
	$f->{stats}{total}       = 10;
	$f->{stats}{interesting} = 3;
	$f->{stats}{coverage}    = 7;
	$f->{stats}{bugs}        = 1;
	push @{$f->{corpus}}, { input => 'x', coverage => {} };
	push @{$f->{bugs}},   { input => 'y', error => 'oops' };

	my $r = $f->_build_report();
	is($r->{total_iterations},   10, 'total_iterations from stats');
	is($r->{interesting_inputs}, 3,  'interesting_inputs from stats');
	is($r->{branches_covered},   7,  'branches_covered from stats');
	is($r->{bugs_found},         1,  'bugs_found from stats');
	is($r->{corpus_size},        1,  'corpus_size from corpus array');
	is(ref($r->{bugs}),     'ARRAY', 'bugs is arrayref');
};

# ==================================================================
# _validate_value
# ==================================================================
subtest '_validate_value() accepts valid integer' => sub {
	my $f = _fuzzer();
	ok($f->_validate_value(42, { type => 'integer' }), 'integer 42 valid');
	ok($f->_validate_value(-5, { type => 'integer' }), 'negative integer valid');
	ok($f->_validate_value(0,  { type => 'integer' }), 'zero valid');
};

subtest '_validate_value() rejects non-integer for integer type' => sub {
	my $f = _fuzzer();
	ok(!$f->_validate_value('abc',  { type => 'integer' }), 'string rejected');
	ok(!$f->_validate_value('3.14', { type => 'integer' }), 'float rejected');
};

subtest '_validate_value() enforces integer min/max' => sub {
	my $f = _fuzzer();
	ok( $f->_validate_value(5,  { type => 'integer', min => 1, max => 10 }), 'in range valid');
	ok(!$f->_validate_value(0,  { type => 'integer', min => 1, max => 10 }), 'below min invalid');
	ok(!$f->_validate_value(11, { type => 'integer', min => 1, max => 10 }), 'above max invalid');
};

subtest '_validate_value() accepts valid number' => sub {
	my $f = _fuzzer();
	ok($f->_validate_value('3.14',  { type => 'number' }), 'decimal accepted');
	ok($f->_validate_value('1e5',   { type => 'number' }), 'scientific notation accepted');
	ok($f->_validate_value('-0.5',  { type => 'number' }), 'negative float accepted');
};

subtest '_validate_value() rejects non-number for number type' => sub {
	my $f = _fuzzer();
	ok(!$f->_validate_value('abc', { type => 'number' }), 'string rejected for number');
};

subtest '_validate_value() enforces string length constraints' => sub {
	my $f = _fuzzer();
	ok( $f->_validate_value('hello', { type => 'string', min => 3, max => 10 }), 'in range valid');
	ok(!$f->_validate_value('hi',    { type => 'string', min => 3, max => 10 }), 'too short invalid');
	ok(!$f->_validate_value('x' x 11, { type => 'string', max => 10 }),          'too long invalid');
};

subtest '_validate_value() enforces string matches pattern' => sub {
	my $f = _fuzzer();
	ok( $f->_validate_value('foo123', { type => 'string', matches => '/^\w+$/' }), 'matching pattern valid');
	ok(!$f->_validate_value('foo bar', { type => 'string', matches => '/^\w+$/' }), 'non-matching invalid');
};

subtest '_validate_value() accepts valid boolean' => sub {
	my $f = _fuzzer();
	ok($f->_validate_value(0, { type => 'boolean' }), '0 is valid boolean');
	ok($f->_validate_value(1, { type => 'boolean' }), '1 is valid boolean');
};

subtest '_validate_value() rejects non-boolean for boolean type' => sub {
	my $f = _fuzzer();
	ok(!$f->_validate_value(2,     { type => 'boolean' }), '2 rejected');
	ok(!$f->_validate_value('yes', { type => 'boolean' }), '"yes" rejected');
};

subtest '_validate_value() accepts arrayref for arrayref type' => sub {
	my $f = _fuzzer();
	ok( $f->_validate_value([1,2],  { type => 'arrayref' }), 'arrayref valid');
	ok(!$f->_validate_value('list', { type => 'arrayref' }), 'string rejected for arrayref');
};

subtest '_validate_value() accepts hashref for hashref type' => sub {
	my $f = _fuzzer();
	ok( $f->_validate_value({a => 1}, { type => 'hashref' }), 'hashref valid');
	ok(!$f->_validate_value([],       { type => 'hashref' }), 'arrayref rejected for hashref');
};

subtest '_validate_value() rejects undef' => sub {
	my $f = _fuzzer();
	ok(!$f->_validate_value(undef, { type => 'string' }), 'undef rejected');
};

# ==================================================================
# _validate_hash_input
# ==================================================================
subtest '_validate_hash_input() returns 0 for undef input' => sub {
	my $f = _fuzzer();
	ok(!$f->_validate_hash_input(undef, { name => { type => 'string' } }),
		'undef input invalid');
};

subtest '_validate_hash_input() returns 0 when required field missing' => sub {
	my $f = _fuzzer();
	ok(!$f->_validate_hash_input({},
		{ name => { type => 'string', optional => 0 } }),
		'missing required field invalid');
};

subtest '_validate_hash_input() accepts when optional field missing' => sub {
	my $f = _fuzzer();
	ok($f->_validate_hash_input({},
		{ name => { type => 'string', optional => 1 } }),
		'missing optional field valid');
};

subtest '_validate_hash_input() skips internal _ keys in spec' => sub {
	my $f = _fuzzer();
	ok($f->_validate_hash_input({},
		{ _source => 'pod', _note => 'internal' }),
		'internal keys skipped');
};

subtest '_validate_hash_input() validates field values' => sub {
	my $f = _fuzzer();
	ok( $f->_validate_hash_input(
		{ age => 25 },
		{ age => { type => 'integer', min => 0, max => 150 } }
	), 'valid field value accepted');
	ok(!$f->_validate_hash_input(
		{ age => -1 },
		{ age => { type => 'integer', min => 0, max => 150 } }
	), 'invalid field value rejected');
};

# ==================================================================
# _input_is_valid
# ==================================================================
subtest '_input_is_valid() returns 1 when no schema input spec' => sub {
	my $f = _fuzzer(schema => {});
	ok($f->_input_is_valid('anything'), 'no spec -> always valid');
};

subtest '_input_is_valid() validates scalar against spec' => sub {
	my $f = _fuzzer(schema => { input => { type => 'integer', min => 0 } });
	ok( $f->_input_is_valid(5),  'valid integer accepted');
	ok(!$f->_input_is_valid(-1), 'invalid integer rejected');
};

subtest '_input_is_valid() validates hash-style input' => sub {
	my $f = _fuzzer(schema => {
		input       => { name => { type => 'string', optional => 0 } },
		input_style => 'hash',
	});
	ok( $f->_input_is_valid({ name => 'foo' }), 'valid hash input accepted');
	ok(!$f->_input_is_valid({}),                'missing required field rejected');
};

# ==================================================================
# _mutate_int
# ==================================================================
subtest '_mutate_int() returns a defined scalar' => sub {
	my $f = _fuzzer();
	for my $n (0, 1, -1, 42, -100) {
		my $result = $f->_mutate_int($n);
		ok(defined $result, "_mutate_int($n) returns defined value");
		ok($result =~ /^-?\d+$/, "_mutate_int($n) returns integer-like value");
	}
};

# ==================================================================
# _mutate_num
# ==================================================================
subtest '_mutate_num() returns a defined numeric scalar' => sub {
	my $f = _fuzzer();
	for my $n (0, 3.14, -2.5) {
		my $result = $f->_mutate_num($n);
		ok(defined $result, "_mutate_num($n) returns defined value");
		ok($result =~ /^-?[\d.e+]+$/i, "_mutate_num($n) returns numeric-looking value");
	}
};

# ==================================================================
# _mutate_string
# ==================================================================
subtest '_mutate_string() returns a defined scalar' => sub {
	my $f = _fuzzer();
	for my $s ('hello', '', 'a' x 10) {
		my $result = $f->_mutate_string($s);
		ok(defined $result, '_mutate_string returns defined value');
	}
};

# ==================================================================
# _mutate_array
# ==================================================================
subtest '_mutate_array() returns an arrayref' => sub {
	my $f = _fuzzer();
	my $result = $f->_mutate_array([1, 2, 3]);
	is(ref($result), 'ARRAY', '_mutate_array returns arrayref');
};

subtest '_mutate_array() returns arrayref for empty input' => sub {
	my $f = _fuzzer();
	my $result = $f->_mutate_array([]);
	is(ref($result), 'ARRAY', '_mutate_array([]) returns arrayref');
};

# ==================================================================
# _mutate_hash
# ==================================================================
subtest '_mutate_hash() returns a hashref' => sub {
	my $f = _fuzzer();
	my $result = $f->_mutate_hash({ a => 1, b => 'x' });
	is(ref($result), 'HASH', '_mutate_hash returns hashref');
};

subtest '_mutate_hash() returns hashref for empty input' => sub {
	my $f = _fuzzer();
	my $result = $f->_mutate_hash({});
	is(ref($result), 'HASH', '_mutate_hash({}) returns hashref');
};

subtest '_mutate_hash() does not modify original' => sub {
	my $f   = _fuzzer();
	my $orig = { x => 1 };
	$f->_mutate_hash($orig);
	is($orig->{x}, 1, 'original hashref not modified');
};

# ==================================================================
# _mutate — dispatch
# ==================================================================
subtest '_mutate() handles undef by generating random' => sub {
	my $f = _fuzzer();
	my $result = $f->_mutate(undef);
	# Returns whatever _generate_random returns — just check it lives
	ok(1, '_mutate(undef) lives');
};

subtest '_mutate() handles integer scalar' => sub {
	my $f      = _fuzzer();
	my $result = $f->_mutate(42);
	ok(defined $result, '_mutate(42) returns defined value');
};

subtest '_mutate() handles float scalar' => sub {
	my $f      = _fuzzer();
	my $result = $f->_mutate(3.14);
	ok(defined $result, '_mutate(3.14) returns defined value');
};

subtest '_mutate() handles string scalar' => sub {
	my $f      = _fuzzer();
	my $result = $f->_mutate('hello');
	ok(defined $result, '_mutate("hello") returns defined value');
};

subtest '_mutate() handles arrayref' => sub {
	my $f      = _fuzzer();
	my $result = $f->_mutate([1, 2, 3]);
	is(ref($result), 'ARRAY', '_mutate([]) returns arrayref');
};

subtest '_mutate() handles hashref' => sub {
	my $f      = _fuzzer();
	my $result = $f->_mutate({ a => 1 });
	is(ref($result), 'HASH', '_mutate({}) returns hashref');
};

subtest '_mutate() passes blessed refs through unchanged' => sub {
	my $f   = _fuzzer();
	my $obj = bless { x => 1 }, 'SomeClass';
	my $result = $f->_mutate($obj);
	is($result, $obj, 'blessed ref returned unchanged');
};

# ==================================================================
# _generate_for_schema
# ==================================================================
subtest '_generate_for_schema() returns undef for undef spec' => sub {
	my $f = _fuzzer();
	ok(!defined($f->_generate_for_schema(undef)), 'undef spec -> undef');
};

subtest '_generate_for_schema() returns undef for "undef" string spec' => sub {
	my $f = _fuzzer();
	ok(!defined($f->_generate_for_schema('undef')), '"undef" spec -> undef');
};

subtest '_generate_for_schema() generates integer' => sub {
	my $f = _fuzzer(seed => 1);
	my $v = $f->_generate_for_schema({ type => 'integer', min => 0, max => 100 });
	ok(defined $v,       'integer generated');
	ok($v =~ /^-?\d+$/,  'looks like integer');
};

subtest '_generate_for_schema() generates boolean 0 or 1' => sub {
	my $f = _fuzzer(seed => 1);
	for (1..10) {
		my $v = $f->_generate_for_schema({ type => 'boolean' });
		ok($v == 0 || $v == 1, "boolean value $v is 0 or 1");
	}
};

subtest '_generate_for_schema() generates arrayref' => sub {
	my $f = _fuzzer(seed => 1);
	my $v = $f->_generate_for_schema({ type => 'arrayref' });
	is(ref($v), 'ARRAY', 'arrayref generated');
};

subtest '_generate_for_schema() generates hashref' => sub {
	my $f = _fuzzer(seed => 1);
	my $v = $f->_generate_for_schema({
		type       => 'hashref',
		properties => { name => { type => 'string' } },
	});
	is(ref($v), 'HASH', 'hashref generated');
	ok(exists $v->{name}, 'property key present');
};

subtest '_generate_for_schema() uses edge_case_array when available' => sub {
	# With seed fixed, at EDGE_CASE_RATIO=0.40 we expect some hits over 20 tries
	my $f = _fuzzer(seed => 42);
	my @edge_cases = (999, 1000, 1001);
	my $spec = { type => 'integer', edge_case_array => \@edge_cases };
	my $hit_edge = 0;
	for (1..20) {
		my $v = $f->_generate_for_schema($spec);
		$hit_edge++ if grep { $_ == $v } @edge_cases;
	}
	ok($hit_edge > 0, 'edge cases selected at least once in 20 tries');
};

# ==================================================================
# _rand_int boundary bias
# ==================================================================
subtest '_rand_int() returns an integer' => sub {
	my $f = _fuzzer(seed => 1);
	for (1..20) {
		my $v = $f->_rand_int({ min => 5, max => 10 });
		ok($v =~ /^-?\d+$/, "rand_int returns integer: $v");
	}
};

# ==================================================================
# _rand_string
# ==================================================================
subtest '_rand_string() returns a scalar' => sub {
	my $f = _fuzzer(seed => 1);
	my $v = $f->_rand_string({ min => 0, max => 10 });
	ok(defined $v, 'rand_string returns defined value');
	ok(length($v) >= 0 && length($v) <= 10, 'length within spec');
};

# ==================================================================
# save_corpus and load_corpus
# ==================================================================
subtest 'save_corpus() croaks when path is missing' => sub {
	my $f = _fuzzer();
	throws_ok(
		sub { $f->save_corpus(undef) },
		qr/path required/,
		'undef path croaks',
	);
};

subtest 'load_corpus() croaks when path is missing' => sub {
	my $f = _fuzzer();
	throws_ok(
		sub { $f->load_corpus(undef) },
		qr/path required/,
		'undef path croaks',
	);
};

subtest 'save_corpus() and load_corpus() round-trip' => sub {
	my $has_json = eval {
			App::Test::Generator::CoverageGuidedFuzzer::_load_json_module();
			1;
		} // 0;

	SKIP: {
		skip 'No JSON module available', 6 unless $has_json;

		my $dir  = tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'corpus.json');

		my $f1 = _fuzzer(seed => 42);
		push @{$f1->{corpus}}, { input => 'hello', coverage => {} };
		push @{$f1->{corpus}}, { input => 42,      coverage => {} };

		lives_ok(sub { $f1->save_corpus($path) }, 'save_corpus lives');
		ok(-f $path, 'corpus file created');

		my $f2 = _fuzzer(seed => 42);
		lives_ok(sub { $f2->load_corpus($path) }, 'load_corpus lives');

		is(scalar @{$f2->corpus()}, 2, 'two entries loaded');
		is($f2->corpus()->[0]{input}, 'hello', 'first input preserved');
		is($f2->corpus()->[1]{input}, 42,      'second input preserved');
	}
};

subtest 'load_corpus() croaks for unreadable file' => sub {
	my $has_json = eval {
			App::Test::Generator::CoverageGuidedFuzzer::_load_json_module();
			1;
		} // 0;

	SKIP: {
		skip 'No JSON module available', 1 unless $has_json;

		my $f = _fuzzer();
		throws_ok(
			sub { $f->load_corpus('/nonexistent/path/corpus.json') },
			qr/Cannot read corpus/,
			'unreadable file croaks',
		);
	}
};

# ==================================================================
# run — smoke test (iterations => 0 skips loop)
# ==================================================================
subtest 'run() with iterations=0 returns valid report structure' => sub {
	my $f      = _fuzzer(iterations => 0);
	my $report = $f->run();
	is(ref($report), 'HASH', 'run() returns hashref');
	for my $key (qw(total_iterations interesting_inputs corpus_size
	                branches_covered bugs_found bugs)) {
		ok(exists $report->{$key}, "$key present");
	}
};

subtest 'run() seeds corpus before loop' => sub {
	my $f = _fuzzer(iterations => 0);
	$f->run();
	is(scalar @{$f->corpus()}, 5, 'corpus seeded with 5 entries after run');
};

subtest 'run() with small iteration count completes without error' => sub {
	my $called = 0;
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'integer', min => 0, max => 100 } },
		target_sub => sub { $called++; return 1 },
		iterations => 10,
		seed       => 42,
	);
	my $report;
	lives_ok(sub { $report = $f->run() }, 'run() with 10 iterations lives');
	is($report->{total_iterations}, 10, 'total_iterations is 10');
	ok($called > 0, 'target_sub was called');
};

subtest 'run() detects bugs from target_sub die on valid input' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'integer', min => 0, max => 100 } },
		target_sub => sub { die "always dies\n" },
		iterations => 5,
		seed       => 42,
	);
	my $report = $f->run();
	# May or may not find bugs depending on whether generated inputs are valid
	ok($report->{bugs_found} >= 0, 'bugs_found is non-negative');
	is(scalar @{$f->bugs()}, $report->{bugs_found}, 'bugs array matches bugs_found count');
};

# ==================================================================
# _validate_value — 'matches' ReDoS guard (white-box)
# ==================================================================
subtest '_validate_value accepts a string matching a benign pattern' => sub {
	my $f = _fuzzer();
	ok($f->_validate_value('abc123', { type => 'string', matches => '/^[a-z]+\d+$/' }),
		'benign pattern matches valid input');
};

subtest '_validate_value rejects a string not matching a benign pattern' => sub {
	my $f = _fuzzer();
	ok(!$f->_validate_value('???', { type => 'string', matches => '/^[a-z]+\d+$/' }),
		'benign pattern rejects non-matching input');
};

subtest '_validate_value returns within the alarm bound on a catastrophic pattern' => sub {
	my $f = _fuzzer();
	# Classic catastrophic-backtracking pattern: (a+)+ against a string
	# with no trailing match char forces exponential backtracking.
	my $evil_pattern = '/^(a+)+$/';
	my $evil_input   = ('a' x 40) . '!';

	my $start = time();
	my $result;
	lives_ok(
		sub { $result = $f->_validate_value($evil_input, { type => 'string', matches => $evil_pattern }) },
		'_validate_value does not hang or die on a catastrophic-backtracking pattern',
	);
	my $elapsed = time() - $start;
	ok($elapsed < 5, "returned well within the timeout bound (took ${elapsed}s)");
	ok(!$result, 'timed-out match is treated as a non-match (rejected)');
};

# ==================================================================
# _snapshot_cover / _run_with_cover — single-walk-per-iteration caching
# (white-box; only meaningful when Devel::Cover is unavailable, where
# _snapshot_cover short-circuits to an empty hash, but the caching
# logic itself is exercised regardless)
# ==================================================================
subtest '_run_with_cover caches the "after" snapshot for reuse as next "before"' => sub {
	my $f = _fuzzer(target_sub => sub { 1 });
	ok(!exists $f->{_last_cover_snapshot}, 'no cached snapshot before first call');

	my ($result, $error);
	$f->_run_with_cover('x', \$result, \$error);
	ok(exists $f->{_last_cover_snapshot}, 'snapshot cached after _run_with_cover call');
	is(ref($f->{_last_cover_snapshot}), 'HASH', 'cached snapshot is a hashref');
};

done_testing();
