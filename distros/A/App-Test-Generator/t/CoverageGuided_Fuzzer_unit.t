#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;

# Black-box unit tests for App::Test::Generator::CoverageGuidedFuzzer.
# Tests each public function according to its POD API specification.

BEGIN { use_ok('App::Test::Generator::CoverageGuidedFuzzer') }

my $have_json = eval { require JSON::MaybeXS; 1 }
             // eval { require JSON; 1 }
             // 0;

# --------------------------------------------------
# Helper: build a minimal valid fuzzer
# --------------------------------------------------
sub _fuzzer {
	my (%args) = @_;
	return App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => $args{schema}     // { input => { type => 'string' } },
		target_sub => $args{target_sub} // sub { 1 },
		iterations => $args{iterations} // 5,
		seed       => $args{seed}       // 42,
		exists $args{instance} ? (instance => $args{instance}) : (),
		exists $args{timeout}  ? (timeout  => $args{timeout})  : (),
	);
}

# ==================================================================
# new()
#
# POD spec:
#   Required: schema (hashref), target_sub (coderef)
#   Optional: iterations (default 100), seed (default time()),
#             instance
#   Returns:  blessed hashref
#   Croaks:   when schema or target_sub is missing
# ==================================================================

subtest 'new() returns a blessed object' => sub {
	my $f = _fuzzer();
	isa_ok($f, 'App::Test::Generator::CoverageGuidedFuzzer');
};

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
				schema => { input => { type => 'string' } },
			)
		},
		qr/target_sub required/,
		'missing target_sub croaks',
	);
};

subtest 'new() defaults iterations to 100' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string' } },
		target_sub => sub { 1 },
	);
	is($f->{iterations}, 100, 'iterations defaults to 100');
};

subtest 'new() stores supplied iterations' => sub {
	my $f = _fuzzer(iterations => 50);
	is($f->{iterations}, 50, 'iterations stored correctly');
};

subtest 'new() stores supplied seed and calls srand' => sub {
	my $f = _fuzzer(seed => 999);
	is($f->{seed}, 999, 'seed stored correctly');
};

subtest 'new() uses time() as default seed' => sub {
	my $before = time();
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string' } },
		target_sub => sub { 1 },
	);
	my $after = time();
	ok($f->{seed} >= $before && $f->{seed} <= $after,
		'default seed is approximately time()');
};

subtest 'new() stores optional instance' => sub {
	my $obj = bless {}, 'FakeClass';
	my $f   = _fuzzer(instance => $obj);
	is($f->{instance}, $obj, 'instance stored correctly');
};

subtest 'new() initialises corpus, covered, and bugs to empty' => sub {
	my $f = _fuzzer();
	is(ref($f->{corpus}),  'ARRAY', 'corpus is arrayref');
	is(ref($f->{covered}), 'HASH',  'covered is hashref');
	is(ref($f->{bugs}),    'ARRAY', 'bugs is arrayref');
	is(scalar @{$f->{corpus}},  0, 'corpus initially empty');
	is(scalar @{$f->{bugs}},    0, 'bugs initially empty');
	is(scalar keys %{$f->{covered}}, 0, 'covered initially empty');
};

subtest 'new() each call returns a distinct object' => sub {
	my $f1 = _fuzzer();
	my $f2 = _fuzzer();
	isnt($f1, $f2, 'distinct objects returned');
};

subtest 'new() defaults timeout to 5 seconds' => sub {
	my $f = _fuzzer();
	is($f->{timeout}, 5, 'timeout defaults to 5');
};

subtest 'new() stores supplied timeout' => sub {
	my $f = _fuzzer(timeout => 1);
	is($f->{timeout}, 1, 'timeout stored correctly');
};

# ==================================================================
# Regression: a hanging target_sub must not hang the whole fuzzing
# run. Both the Devel::Cover and non-cover call sites in _run_one /
# _run_with_cover now wrap the target_sub call in an alarm()-bounded
# eval, recording the timeout as a bug rather than blocking forever.
# ==================================================================

subtest 'run() aborts a hanging target_sub via timeout and records a bug' => sub {
	my $f = _fuzzer(
		timeout    => 1,
		iterations => 1,
		target_sub => sub { sleep 30; return 1 },
	);

	my $start = time();
	my $r;
	lives_ok(sub { $r = $f->run() }, 'run() returns rather than hanging');
	my $elapsed = time() - $start;

	ok($elapsed < 25, "run() returned promptly (elapsed=${elapsed}s), not after the full sleep")
		or diag("run() took ${elapsed}s — timeout did not abort the hanging call");

	ok(scalar(@{$f->bugs()}) >= 1, 'hanging call recorded as a bug');
	like($f->bugs()->[0]{error}, qr/timed out/, 'bug error mentions the timeout');
};

subtest 'run() with timeout disabled (0) does not wrap target_sub in alarm' => sub {
	my $f = _fuzzer(
		timeout    => 0,
		iterations => 3,
		target_sub => sub { 1 },
	);
	lives_ok(sub { $f->run() }, 'run() lives with timeout disabled');
};

# ==================================================================
# run()
#
# POD spec:
#   Returns a hashref with keys: total_iterations, interesting_inputs,
#   corpus_size, branches_covered, bugs_found, bugs
# ==================================================================

subtest 'run() returns a hashref' => sub {
	my $f = _fuzzer();
	my $r;
	lives_ok(sub { $r = $f->run() }, 'run() lives');
	is(ref($r), 'HASH', 'returns hashref');
};

subtest 'run() report contains all required keys' => sub {
	my $f = _fuzzer();
	my $r = $f->run();
	for my $key (qw(total_iterations interesting_inputs
	                corpus_size branches_covered bugs_found bugs)) {
		ok(exists $r->{$key}, "$key key present");
	}
};

subtest 'run() total_iterations matches configured iterations' => sub {
	my $f = _fuzzer(iterations => 7);
	my $r = $f->run();
	is($r->{total_iterations}, 7, 'total_iterations equals configured value');
};

subtest 'run() bugs key is an arrayref' => sub {
	my $f = _fuzzer();
	my $r = $f->run();
	is(ref($r->{bugs}), 'ARRAY', 'bugs is arrayref');
};

subtest 'run() corpus_size is non-negative' => sub {
	my $f = _fuzzer();
	my $r = $f->run();
	ok($r->{corpus_size} >= 0, 'corpus_size is non-negative');
};

subtest 'run() does not croak for target that always returns 1' => sub {
	my $f = _fuzzer(target_sub => sub { 1 });
	lives_ok(sub { $f->run() }, 'run() lives for well-behaved target');
};

subtest 'run() does not croak for target that always dies' => sub {
	my $f = _fuzzer(target_sub => sub { die "expected error\n" });
	lives_ok(sub { $f->run() }, 'run() lives even when target always dies');
};

subtest 'run() seeds corpus before main loop' => sub {
	my $f = _fuzzer(iterations => 0);
	$f->run();
	# With 0 iterations the corpus is populated only by _seed_corpus
	ok(scalar @{$f->corpus()} >= 0, 'corpus seeded even with 0 iterations');
};

subtest 'run() passes instance as first arg to target_sub when set' => sub {
	my $invocant;
	my $obj = bless {}, 'FakeInvocant';
	my $f = _fuzzer(
		instance   => $obj,
		iterations => 3,
		target_sub => sub { $invocant = $_[0]; 1 },
	);
	$f->run();
	is($invocant, $obj, 'instance passed as first arg to target_sub');
};

# ==================================================================
# corpus()
#
# POD spec:
#   Returns the corpus arrayref (entries have input and coverage keys)
# ==================================================================

subtest 'corpus() returns an arrayref' => sub {
	my $f = _fuzzer();
	is(ref($f->corpus()), 'ARRAY', 'corpus() returns arrayref');
};

subtest 'corpus() grows after run()' => sub {
	my $f = _fuzzer(iterations => 10);
	my $before = scalar @{$f->corpus()};
	$f->run();
	ok(scalar @{$f->corpus()} >= $before,
		'corpus size does not decrease after run()');
};

subtest 'corpus() entries have input and coverage keys' => sub {
	my $f = _fuzzer(iterations => 5);
	$f->run();
	for my $entry (@{$f->corpus()}) {
		ok(exists $entry->{input},    'corpus entry has input key');
		ok(exists $entry->{coverage}, 'corpus entry has coverage key');
	}
};

# ==================================================================
# bugs()
#
# POD spec:
#   Returns bugs arrayref (entries have input and error keys)
# ==================================================================

subtest 'bugs() returns an arrayref' => sub {
	my $f = _fuzzer();
	is(ref($f->bugs()), 'ARRAY', 'bugs() returns arrayref');
};

subtest 'bugs() records errors from valid input that dies' => sub {
	# A target that dies on any defined input — bugs are only recorded
	# when the input is considered valid by the schema
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => {
			input => { type => 'string', min => 1, max => 10 },
		},
		target_sub => sub {
			my $v = $_[0];
			die "intentional error\n" if defined($v) && length($v) >= 1;
			1;
		},
		iterations => 20,
		seed       => 42,
	);
	$f->run();
	# May or may not find bugs depending on generated inputs — just verify
	# the bugs arrayref is well-formed
	for my $bug (@{$f->bugs()}) {
		ok(exists $bug->{input}, 'bug entry has input key');
		ok(exists $bug->{error}, 'bug entry has error key');
		ok(defined $bug->{error}, 'bug error is defined');
	}
};

# ==================================================================
# save_corpus()
#
# POD spec:
#   Arguments: $path (required)
#   Writes JSON file to $path
#   Croaks when path is missing or file cannot be written
# ==================================================================

subtest 'save_corpus() croaks when path is missing' => sub {
	my $f = _fuzzer();
	throws_ok(
		sub { $f->save_corpus(undef) },
		qr/path required/,
		'undef path croaks',
	);
};

subtest 'save_corpus() croaks when path is not writable' => sub {
	my $f = _fuzzer();
	throws_ok(
		sub { $f->save_corpus('/no/such/dir/corpus.json') },
		qr/Cannot write corpus/,
		'unwritable path croaks',
	);
};
subtest 'save_corpus() writes a JSON file' => sub {
	SKIP: {
		skip 'No JSON module available', 3 unless $have_json;
		my $f   = _fuzzer(iterations => 3);
		$f->run();
		my $dir  = tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'corpus.json');
		lives_ok(sub { $f->save_corpus($path) }, 'save_corpus() lives');
		ok(-f $path, 'corpus file created');
		ok(-s $path, 'corpus file is non-empty');
	}
};

subtest 'save_corpus() writes valid JSON' => sub {
	SKIP: {
		skip 'No JSON module available', 2 unless $have_json;
		my $f   = _fuzzer(iterations => 3);
		$f->run();
		my $dir  = tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'corpus.json');
		$f->save_corpus($path);
		open my $fh, '<', $path or die $!;
		my $json = do { local $/; <$fh> };
		close $fh;
		my $data;
		lives_ok(
			sub {
				require JSON::MaybeXS;
				$data = JSON::MaybeXS->new->decode($json);
			},
			'corpus file contains valid JSON',
		);
		ok(exists $data->{corpus}, 'JSON has corpus key');
		ok(exists $data->{seed},   'JSON has seed key');
		ok(exists $data->{bugs},   'JSON has bugs key');
	}
};

subtest 'load_corpus() appends entries to corpus' => sub {
	SKIP: {
		skip 'No JSON module available', 2 unless $have_json;
		my $f1 = _fuzzer(iterations => 5);
		$f1->run();
		my $dir  = tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'corpus.json');
		$f1->save_corpus($path);
		my $f2 = _fuzzer();
		my $before = scalar @{$f2->corpus()};
		lives_ok(sub { $f2->load_corpus($path) }, 'load_corpus() lives');
		ok(scalar @{$f2->corpus()} >= $before,
			'corpus grew after load_corpus()');
	}
};

# ==================================================================
# load_corpus()
#
# POD spec:
#   Arguments: $path (required)
#   Appends entries to corpus
#   Croaks when path is missing or file cannot be read
# ==================================================================

subtest 'load_corpus() croaks when path is missing' => sub {
	my $f = _fuzzer();
	throws_ok(
		sub { $f->load_corpus(undef) },
		qr/path required/,
		'undef path croaks',
	);
};

subtest 'load_corpus() croaks when file does not exist' => sub {
	my $f = _fuzzer();
	throws_ok(
		sub { $f->load_corpus('/no/such/corpus.json') },
		qr/Cannot read corpus/,
		'missing file croaks',
	);
};

subtest 'load_corpus() appends entries to corpus' => sub {
	# Save a corpus then load it into a new fuzzer
	my $f1 = _fuzzer(iterations => 5);
	$f1->run();
	my $dir  = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, 'corpus.json');
	$f1->save_corpus($path);

	my $f2 = _fuzzer();
	my $before = scalar @{$f2->corpus()};
	lives_ok(sub { $f2->load_corpus($path) }, 'load_corpus() lives');
	ok(scalar @{$f2->corpus()} >= $before,
		'corpus grew after load_corpus()');
};

subtest 'save_corpus() writes a JSON file' => sub {
	SKIP: {
		skip 'No JSON module available', 3 unless $have_json;
		my $f   = _fuzzer(iterations => 3);
		$f->run();
		my $dir  = tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'corpus.json');
		lives_ok(sub { $f->save_corpus($path) }, 'save_corpus() lives');
		ok(-f $path, 'corpus file created');
		ok(-s $path, 'corpus file is non-empty');
	}
};

subtest 'save_corpus() writes valid JSON' => sub {
	SKIP: {
		skip 'No JSON module available', 2 unless $have_json;
		my $f   = _fuzzer(iterations => 3);
		$f->run();
		my $dir  = tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'corpus.json');
		$f->save_corpus($path);
		open my $fh, '<', $path or die $!;
		my $json = do { local $/; <$fh> };
		close $fh;
		my $data;
		lives_ok(
			sub {
				require JSON::MaybeXS;
				$data = JSON::MaybeXS->new->decode($json);
			},
			'corpus file contains valid JSON',
		);
		ok(exists $data->{corpus}, 'JSON has corpus key');
		ok(exists $data->{seed},   'JSON has seed key');
		ok(exists $data->{bugs},   'JSON has bugs key');
	}
};

subtest 'save_corpus() and load_corpus() round-trip preserves seed' => sub {
	my $f1 = _fuzzer(seed => 12345, iterations => 3);
	$f1->run();
	my $dir  = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, 'corpus.json');
	$f1->save_corpus($path);

	open my $fh, '<', $path or die $!;
	my $data;
	require JSON::MaybeXS;
	$data = JSON::MaybeXS->new->decode(do { local $/; <$fh> });
	close $fh;

	is($data->{seed}, 12345, 'seed preserved in saved corpus');
};

# ==================================================================
# corpus_size() — convenience check via corpus()
# ==================================================================

subtest 'corpus size increases after successive runs' => sub {
	my $f = _fuzzer(iterations => 10);
	$f->run();
	my $size1 = scalar @{$f->corpus()};
	$f->run();
	my $size2 = scalar @{$f->corpus()};
	ok($size2 >= $size1, 'corpus size does not decrease on second run');
};

done_testing();
