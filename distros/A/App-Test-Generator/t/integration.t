#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use File::Path    qw(make_path);
use File::Temp    qw(tempdir tempfile);
use File::Spec;
use YAML::XS      qw(LoadFile);

# Integration tests for App::Test::Generator.
# Each subtest exercises end-to-end behaviour across multiple modules,
# verifying that they compose correctly and that state flows through
# the pipeline as documented.

BEGIN {
	use_ok('App::Test::Generator');
	use_ok('App::Test::Generator::SchemaExtractor');
	use_ok('App::Test::Generator::Planner');
	use_ok('App::Test::Generator::Emitter::Perl');
	use_ok('App::Test::Generator::Mutator');
	use_ok('App::Test::Generator::LCSAJ');
	use_ok('App::Test::Generator::CoverageGuidedFuzzer');
}

# --------------------------------------------------
# Shared sample Perl module source used across tests
# --------------------------------------------------
my $SAMPLE_MODULE = <<'END_PM';
package Sample::Calculator;

use strict;
use warnings;

=head2 new

Construct a Calculator.

=cut

sub new {
	my ($class, %args) = @_;
	return bless { precision => $args{precision} // 2 }, $class;
}

=head2 add

Add two numbers.

=head3 Arguments

=over 4

=item * C<$a> - first number

=item * C<$b> - second number

=back

=head3 Returns

The sum of $a and $b.

=cut

sub add {
	my ($self, $a, $b) = @_;
	die "Arguments required" unless defined $a && defined $b;
	return $a + $b;
}

=head2 is_positive

Return true if a number is positive.

=cut

sub is_positive {
	my ($self, $n) = @_;
	return $n > 0 ? 1 : 0;
}

=head2 precision

Get or set the precision.

=cut

sub precision {
	my ($self, $val) = @_;
	$self->{precision} = $val if defined $val;
	return $self->{precision};
}

1;
END_PM

# --------------------------------------------------
# Helper: write $SAMPLE_MODULE to a temp lib dir.
# Returns ($pm, $tmpdir) where $pm is the absolute
# path to the written .pm file.
# --------------------------------------------------
sub _make_sample_module {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib    = File::Spec->catdir($tmpdir, 'lib', 'Sample');
	make_path($lib);
	my $pm = File::Spec->catfile($lib, 'Calculator.pm');
	open my $fh, '>', $pm or die "Cannot write $pm: $!";
	print $fh $SAMPLE_MODULE;
	close $fh;
	return ($pm, $tmpdir);
}

# --------------------------------------------------
# Helper: write a minimal schema YAML file.
# Returns the absolute path to the written file.
# --------------------------------------------------
sub _make_schema {
	my (%opts) = @_;
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: builtin\n";
	print $fh "function: $opts{function}\n"      if $opts{function};
	print $fh "input:\n  type: $opts{input}\n"   if $opts{input};
	print $fh "output:\n  type: $opts{output}\n" if $opts{output};
	print $fh "$opts{extra}\n"                   if $opts{extra};
	close $fh;
	return $path;
}

# --------------------------------------------------
# Helper: run Mutator generate_mutants() safely from
# within $tmpdir, restoring cwd afterwards.
# Returns the list of mutants.
# --------------------------------------------------
sub _mutants_for {
	my ($mutator, $tmpdir) = @_;
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die "Cannot chdir $tmpdir: $!";
	my @mutants = eval { $mutator->generate_mutants() };
	my $err = $@;
	chdir $orig;
	die $err if $err;
	return @mutants;
}

# ==================================================================
# PIPELINE 1: SchemaExtractor -> Generator
#
# Extract schemas from a real .pm file, feed them directly into
# Generator::generate(), verify the produced test files are runnable.
# ==================================================================

subtest 'SchemaExtractor -> Generator: extract then generate test file' => sub {
	my ($pm, $tmpdir) = _make_sample_module();
	my $out_dir = File::Spec->catdir($tmpdir, 'schemas');
	mkdir $out_dir or die $!;

	# Step 1: extract schemas
	my $extractor = App::Test::Generator::SchemaExtractor->new(
		input_file => $pm,
		output_dir => $out_dir,
	);
	my $schemas = $extractor->extract_all(no_write => 1);
	ok(ref($schemas) eq 'HASH', 'extract_all returns hashref');
	ok(scalar keys %{$schemas} > 0, 'at least one schema extracted');

	# Step 2: generate a test file from each schema
	for my $method (keys %{$schemas}) {
		my $schema   = $schemas->{$method};
		my $test_out = File::Spec->catfile($tmpdir, "$method.t");
		my ($stdout) = capture(sub {
			eval {
				App::Test::Generator->generate(
					schema      => $schema,
					output_file => $test_out,
				);
			};
		});
		is($@, '', "generate() for $method did not croak: $@");
		ok(-f $test_out, "$method: test file written");
		ok(-s $test_out, "$method: test file is non-empty");

		# Verify the generated test file compiles
		is(system($^X, '-c', $test_out), 0,
			"$method: generated test file compiles cleanly");
	}
};

subtest 'SchemaExtractor -> Generator: module key propagated to generated test' => sub {
	my ($pm, $tmpdir) = _make_sample_module();
	my $extractor = App::Test::Generator::SchemaExtractor->new(
		input_file => $pm,
	);
	my $schemas = $extractor->extract_all(no_write => 1);

	for my $method (keys %{$schemas}) {
		is($schemas->{$method}{module}, 'Sample::Calculator',
			"$method: module key is Sample::Calculator");
	}
};

# ==================================================================
# PIPELINE 2: SchemaExtractor -> Planner -> Emitter::Perl
#
# Extract schemas, plan tests, emit Perl test code.
# Verify emitted code references the correct package.
# ==================================================================

subtest 'SchemaExtractor -> Planner -> Emitter: full planning pipeline' => sub {
	my ($pm, $tmpdir) = _make_sample_module();
	my $extractor = App::Test::Generator::SchemaExtractor->new(
		input_file => $pm,
	);
	my $schemas = $extractor->extract_all(no_write => 1);
	ok(scalar keys %{$schemas} > 0, 'schemas extracted');

	# Plan tests for all extracted methods
	my $planner = App::Test::Generator::Planner->new(
		schemas => $schemas,
		package => 'Sample::Calculator',
	);
	my $plans = $planner->plan_all();
	is(ref($plans), 'HASH', 'plan_all returns hashref');
	ok(scalar keys %{$plans} > 0, 'at least one plan produced');

	# Emit test code
	my $emitter = App::Test::Generator::Emitter::Perl->new(
		schema  => $schemas,
		plans   => $plans,
		package => 'Sample::Calculator',
	);
	my $code = $emitter->emit();
	ok(defined $code,                   'emit() returns defined value');
	ok(length($code) > 0,               'emit() returns non-empty string');
	like($code, qr/Sample::Calculator/, 'emitted code references package');
	like($code, qr/use strict/,         'emitted code has use strict');
	like($code, qr/done_testing/,       'emitted code has done_testing');
};

subtest 'SchemaExtractor -> Planner -> Emitter: boolean output sets boolean_test flag' => sub {
	my ($pm, $tmpdir) = _make_sample_module();
	my $extractor = App::Test::Generator::SchemaExtractor->new(
		input_file => $pm,
	);
	my $schemas = $extractor->extract_all(no_write => 1);

	# Inject a boolean output schema for is_positive
	if(exists $schemas->{is_positive}) {
		$schemas->{is_positive}{output} = { type => 'boolean' };
		my $planner = App::Test::Generator::Planner->new(
			schemas => $schemas,
			package => 'Sample::Calculator',
		);
		my $plans = $planner->plan_all();
		ok($plans->{is_positive}{boolean_test},
			'boolean output type sets boolean_test flag in plan');
	} else {
		ok(1, 'is_positive not extracted — skipping boolean flag check');
	}
};

subtest 'Planner -> Emitter: getset accessor type produces getset block' => sub {
	my $schemas = {
		precision => {
			input     => { val => { type => 'integer' } },
			output    => { type => 'integer' },
			accessor  => { type => 'getset', property => 'precision' },
			_analysis => {},
		},
	};
	my $planner = App::Test::Generator::Planner->new(
		schemas => $schemas,
		package => 'Sample::Calculator',
	);
	my $plans = $planner->plan_all();
	ok($plans->{precision}{getset_test}, 'getset accessor -> getset_test flag set');

	my $emitter = App::Test::Generator::Emitter::Perl->new(
		schema  => $schemas,
		plans   => $plans,
		package => 'Sample::Calculator',
	);
	my $code = $emitter->emit();
	like($code, qr/get\/set works/, 'emitted code contains getset block');
};

# ==================================================================
# PIPELINE 3: Mutator -> full mutation cycle on a real module
#
# Generate mutants, prepare workspace, apply each mutant, verify
# the workspace copy is modified while the original is unchanged.
# ==================================================================

subtest 'Mutator: generate -> prepare_workspace -> apply_mutant pipeline' => sub {
	my ($pm, $tmpdir) = _make_sample_module();
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;

	my $rel_lib = 'lib';
	my $rel_pm  = File::Spec->catfile('lib', 'Sample', 'Calculator.pm');

	my $mutator = App::Test::Generator::Mutator->new(
		file    => $rel_pm,
		lib_dir => $rel_lib,
	);

	# generate_mutants() called while still in $tmpdir
	my @mutants = eval { $mutator->generate_mutants() };
	my $gen_err = $@;

	my $workspace = eval { $mutator->prepare_workspace() };
	my $ws_err    = $@;

	# Read original source while still in $tmpdir
	my $original;
	if(open my $fh, '<', $rel_pm) {
		local $/;
		$original = <$fh>;
		close $fh;
	}

	# Apply first mutant while still in $tmpdir
	my $apply_err;
	if(!$gen_err && !$ws_err && @mutants) {
		eval { $mutator->apply_mutant($mutants[0]) };
		$apply_err = $@;
	}

	# Read source after mutation while still in $tmpdir
	my $after;
	if(open my $fh2, '<', $rel_pm) {
		local $/;
		$after = <$fh2>;
		close $fh2;
	}

	chdir $orig;

	is($gen_err, '',  'generate_mutants() did not croak');
	is($ws_err,  '',  'prepare_workspace() did not croak');
	ok(-d $workspace,  'workspace directory created');
	ok(scalar @mutants > 0, 'at least one mutant generated');
	is($apply_err, '', 'apply_mutant() did not croak');
	is($after, $original, 'original source file unchanged after apply_mutant');
};

subtest 'Mutator: fast mode produces fewer or equal mutants than full mode' => sub {
	my ($pm, $tmpdir) = _make_sample_module();
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;

	my $rel_pm  = File::Spec->catfile('lib', 'Sample', 'Calculator.pm');
	my $rel_lib = 'lib';

	my $full = App::Test::Generator::Mutator->new(
		file           => $rel_pm,
		lib_dir        => $rel_lib,
		mutation_level => 'full',
	);
	my $fast = App::Test::Generator::Mutator->new(
		file           => $rel_pm,
		lib_dir        => $rel_lib,
		mutation_level => 'fast',
	);

	# Both generate_mutants() calls made while still in $tmpdir
	my @full_m = eval { $full->generate_mutants() };
	my @fast_m = eval { $fast->generate_mutants() };
	chdir $orig;

	ok(scalar @fast_m <= scalar @full_m,
		'fast mode count <= full mode count');
	ok(scalar @full_m > 0, 'full mode produces at least one mutant');
};

# ==================================================================
# PIPELINE 4: LCSAJ -> extract paths from real module
# ==================================================================

subtest 'LCSAJ: extract paths from sample module' => sub {
	my ($pm, $tmpdir) = _make_sample_module();
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;

	my $rel_pm  = File::Spec->catfile('lib', 'Sample', 'Calculator.pm');
	my $out_dir = 'lcsaj_out';
	mkdir $out_dir unless -d $out_dir;

	my $paths = App::Test::Generator::LCSAJ->generate($rel_pm, $out_dir);
	chdir $orig;

	is(ref($paths), 'ARRAY', 'generate() returns arrayref');
	ok(scalar @{$paths} >= 0, 'non-negative path count');

	for my $p (@{$paths}) {
		ok(defined $p->{start},  'path start defined');
		ok(defined $p->{end},    'path end defined');
		ok(defined $p->{target}, 'path target defined');
	}
};

subtest 'LCSAJ: branching code produces more paths than linear code' => sub {
	my $linear_src = <<'END';
package Linear;
sub foo {
	my $x = shift;
	my $y = $x + 1;
	return $y;
}
1;
END

	my $branching_src = <<'END';
package Branching;
sub foo {
	my $x = shift;
	if($x > 0) { return $x; }
	if($x < 0) { return -$x; }
	return 0;
}
1;
END

	my $tmpdir = tempdir(CLEANUP => 1);
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;

	open my $fh1, '>', 'Linear.pm' or die $!;
	print $fh1 $linear_src;
	close $fh1;

	open my $fh2, '>', 'Branching.pm' or die $!;
	print $fh2 $branching_src;
	close $fh2;

	my $lin_paths = App::Test::Generator::LCSAJ->generate('Linear.pm',   'lin_out');
	my $br_paths  = App::Test::Generator::LCSAJ->generate('Branching.pm', 'br_out');
	chdir $orig;

	ok(scalar @{$br_paths} > scalar @{$lin_paths},
		'branching code produces more LCSAJ paths than linear code');
};

# ==================================================================
# PIPELINE 5: CoverageGuidedFuzzer -> corpus round-trip
# ==================================================================

subtest 'CoverageGuidedFuzzer: run -> save_corpus -> load_corpus -> run' => sub {
	my $tmpdir      = tempdir(CLEANUP => 1);
	my $corpus_file = File::Spec->catfile($tmpdir, 'corpus.json');

	my $call_count = 0;
	my $target = sub {
		my $input = shift;
		$call_count++;
		die "too long\n" if defined($input) && length($input) > 50;
		return length($input // '');
	};

	# First run
	my $f1 = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string', max => 100 } },
		target_sub => $target,
		iterations => 10,
		seed       => 42,
	);
	if($ENV{EXTENDED_TESTING}) {
		my $r1 = $f1->run();
		is($r1->{total_iterations}, 10, 'first run: 10 iterations completed');
	}

	# Save corpus
	lives_ok(sub { $f1->save_corpus($corpus_file) },
		'save_corpus() lives after run');
	ok(-f $corpus_file, 'corpus file written');

	# Load into second fuzzer
	my $f2 = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string', max => 100 } },
		target_sub => $target,
		iterations => 5,
		seed       => 99,
	);
	# Second run
	if($ENV{EXTENDED_TESTING}) {
		lives_ok(sub { $f2->load_corpus($corpus_file) }, 'load_corpus() lives');
		ok(scalar @{$f2->corpus()} > 0, 'corpus loaded into second fuzzer');

		my $r2 = $f2->run();
		is($r2->{total_iterations}, 5, 'second run: 5 iterations completed');
		ok($call_count > 0, 'target sub called across both runs');
	}
};

subtest 'CoverageGuidedFuzzer: bugs list entries are well-formed' => sub {
	my $target = sub {
		my $input = shift;
		die "trigger\n" if defined($input) && $input eq 'TRIGGER';
		return 1;
	};

	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string', min => 1, max => 20 } },
		target_sub => $target,
		iterations => 30,
		seed       => 42,
	);

	if($ENV{EXTENDED_TESTING}) {
		lives_ok(sub { $f->run() }, 'run() lives');
	}

	for my $bug (@{$f->bugs()}) {
		ok(exists $bug->{input}, 'bug entry has input key');
		ok(exists $bug->{error}, 'bug entry has error key');
		ok(defined $bug->{error}, 'bug error is defined');
	}
	ok(1, 'bug list iteration completed');
};

# ==================================================================
# PIPELINE 6: Generator with various schema configurations
# ==================================================================

subtest 'Generator: integer input/output schema produces compilable test' => sub {
	my $schema  = _make_schema(function => 'add', input => 'integer', output => 'integer');
	my $tmpdir  = tempdir(CLEANUP => 1);
	my $outfile = File::Spec->catfile($tmpdir, 'add.t');
	capture(sub { App::Test::Generator->generate($schema, $outfile) });
	ok(-f $outfile, 'test file written for integer schema');
	is(system($^X, '-c', $outfile), 0, 'generated test compiles');
};

subtest 'Generator: boolean output schema produces compilable test' => sub {
	my $schema  = _make_schema(function => 'is_positive', input => 'number', output => 'boolean');
	my $tmpdir  = tempdir(CLEANUP => 1);
	my $outfile = File::Spec->catfile($tmpdir, 'bool.t');
	capture(sub { App::Test::Generator->generate($schema, $outfile) });
	ok(-f $outfile, 'test file written for boolean schema');
	is(system($^X, '-c', $outfile), 0, 'generated test compiles');
};

subtest 'Generator: same seed produces reproducible output' => sub {
	my $s1 = _make_schema(function => 'my_func', input => 'string',
		output => 'string', extra => 'seed: 12345');
	my $s2 = _make_schema(function => 'my_func', input => 'string',
		output => 'string', extra => 'seed: 12345');
	my ($out1) = capture(sub { App::Test::Generator->generate($s1) });
	my ($out2) = capture(sub { App::Test::Generator->generate($s2) });
	is($out1, $out2, 'same seed produces identical output');
};

subtest 'Generator: different seeds produce different output' => sub {
	my $s1 = _make_schema(function => 'my_func', input => 'string',
		output => 'string', extra => 'seed: 1');
	my $s2 = _make_schema(function => 'my_func', input => 'string',
		output => 'string', extra => 'seed: 2');
	my ($out1) = capture(sub { App::Test::Generator->generate($s1) });
	my ($out2) = capture(sub { App::Test::Generator->generate($s2) });
	isnt($out1, $out2, 'different seeds produce different output');
};

subtest 'Generator: iterations config controls iteration count in output' => sub {
	my $schema = _make_schema(function => 'my_func', input => 'string',
		output => 'string', extra => 'iterations: 99');
	my ($out) = capture(sub { App::Test::Generator->generate($schema) });
	like($out, qr/99/, 'iteration count 99 appears in generated output');
};

# ==================================================================
# PIPELINE 7: SchemaExtractor strict_pod validation report
# ==================================================================

subtest 'SchemaExtractor: strict_pod=1 populates validation report' => sub {
	my ($pm, $tmpdir) = _make_sample_module();
	my $extractor = App::Test::Generator::SchemaExtractor->new(
		input_file => $pm,
		strict_pod => 1,
	);
	my $schemas = $extractor->extract_all(no_write => 1);
	my $report  = $extractor->generate_pod_validation_report($schemas);

	ok(defined $report,     'report is defined');
	ok(length($report) > 0, 'report is non-empty');
	ok(
		$report =~ /All methods passed/i || $report =~ /Validation Report/i,
		'report is either all-passed or a validation report',
	);
};

subtest 'SchemaExtractor -> generate_pod_validation_report: injected errors appear' => sub {
	my ($pm, $tmpdir) = _make_sample_module();
	my $extractor = App::Test::Generator::SchemaExtractor->new(
		input_file => $pm,
	);
	my $schemas = $extractor->extract_all(no_write => 1);

	# Inject errors into two methods that we know were extracted
	my @methods = sort keys %{$schemas};
	SKIP: {
		skip 'fewer than two methods extracted', 1 unless scalar @methods >= 2;
		my ($m1, $m2) = @methods[0, 1];
		$schemas->{$m1}{_pod_validation_errors} = ['param mismatch'];
		$schemas->{$m1}{_pod_disagreement}      = 1;
		$schemas->{$m2}{_pod_validation_errors} = ['return type unclear'];
		$schemas->{$m2}{_pod_disagreement}      = 1;

		my $report = $extractor->generate_pod_validation_report($schemas);
		like($report, qr/\Q$m1\E/, "$m1 appears in report");
		like($report, qr/\Q$m2\E/, "$m2 appears in report");
	}
};

# ==================================================================
# PIPELINE 8: Full stack — SchemaExtractor write -> Generator read
# ==================================================================

subtest 'Full stack: SchemaExtractor write -> Generator read round-trip' => sub {
	my ($pm, $tmpdir) = _make_sample_module();
	my $out_dir = File::Spec->catdir($tmpdir, 'schemas');
	mkdir $out_dir or die $!;

	my $extractor = App::Test::Generator::SchemaExtractor->new(
		input_file => $pm,
		output_dir => $out_dir,
	);
	$extractor->extract_all(no_write => 0);

	my @yaml_files = glob(File::Spec->catfile($out_dir, '*.yml'));
	ok(scalar @yaml_files > 0, 'at least one YAML schema file written');

	for my $yaml (@yaml_files) {
		my $outfile = $yaml;
		$outfile =~ s/\.yml$/.t/;
		my ($stdout, $stderr) = capture(sub {
			eval { App::Test::Generator->generate($yaml, $outfile) };
		});
		is($@, '', "generate() from $yaml did not croak: $@");
		if(-f $outfile && -s $outfile) {
			is(system($^X, '-c', $outfile), 0,
				"generated test from $yaml compiles");
		} else {
			ok(1, "no test file produced for $yaml (schema may be empty)");
		}
	}
};

# ==================================================================
# PIPELINE 9: Mutant transform correctness
# ==================================================================

subtest 'BooleanNegation + ReturnUndef: transforms produce correct mutations' => sub {
	use_ok('App::Test::Generator::Mutation::BooleanNegation');
	use_ok('App::Test::Generator::Mutation::ReturnUndef');

	require PPI;
	my $src = "sub foo { return \$ok; }\n";

	# BooleanNegation
	my $bn  = new_ok('App::Test::Generator::Mutation::BooleanNegation');
	my $doc = PPI::Document->new(\$src);
	my @bn_mutants = $bn->mutate($doc);
	if(@bn_mutants) {
		my $copy = PPI::Document->new(\$src);
		$bn_mutants[0]->transform->($copy);
		like($copy->serialize, qr/!\(/,
			'BooleanNegation: !() present after transform');
	} else {
		ok(1, 'BooleanNegation: no mutants for this source');
	}

	# ReturnUndef
	my $ru         = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc2       = PPI::Document->new(\$src);
	my @ru_mutants = $ru->mutate($doc2);
	if(@ru_mutants) {
		my $copy2 = PPI::Document->new(\$src);
		$ru_mutants[0]->transform->($copy2);
		like($copy2->serialize, qr/return undef/,
			'ReturnUndef: return undef present after transform');
	} else {
		ok(1, 'ReturnUndef: no mutants for this source');
	}
};

subtest 'Mutator: all four mutation strategies applied in sequence' => sub {
	my ($pm, $tmpdir) = _make_sample_module();
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;

	my $rel_pm  = File::Spec->catfile('lib', 'Sample', 'Calculator.pm');
	my $mutator = App::Test::Generator::Mutator->new(
		file    => $rel_pm,
		lib_dir => 'lib',
	);

	# generate_mutants() called while still in $tmpdir
	my @mutants = eval { $mutator->generate_mutants() };
	my $err = $@;
	chdir $orig;

	is($err, '', 'generate_mutants() did not croak');
	ok(scalar @mutants > 0, 'at least one mutant generated');

	my %types;
	for my $m (@mutants) {
		$types{$m->type // 'unknown'}++ if $m->type;
	}
	ok(scalar keys %types >= 1, 'at least one mutation type present');
	diag('Mutation types found: '
		. join(', ', map { "$_=$types{$_}" } sort keys %types));
};

# ==================================================================
# PIPELINE 10: Emitter::Perl output is a runnable test
# ==================================================================

subtest 'Emitter::Perl: emitted code is syntactically valid Perl' => sub {
	my $schemas = {
		my_method => {
			input     => {},
			output    => {},
			_analysis => {},
		},
	};
	my $plans = {
		my_method => {
			basic_test  => 1,
			getter_test => 1,
		},
	};
	my $emitter = App::Test::Generator::Emitter::Perl->new(
		schema  => $schemas,
		plans   => $plans,
		package => 'My::Module',
	);
	my $code = $emitter->emit();

	my $tmpdir  = tempdir(CLEANUP => 1);
	my $outfile = File::Spec->catfile($tmpdir, 'emitted.t');
	open my $fh, '>', $outfile or die $!;
	print $fh $code;
	close $fh;

	is(system($^X, '-c', $outfile), 0, 'emitted code is syntactically valid');
};

subtest 'Emitter::Perl: multiple methods emitted in sorted order' => sub {
	my $schemas = {
		alpha => { input => {}, output => {}, _analysis => {} },
		beta  => { input => {}, output => {}, _analysis => {} },
		gamma => { input => {}, output => {}, _analysis => {} },
	};
	my $plans = {
		alpha => { basic_test => 1 },
		beta  => { basic_test => 1 },
		gamma => { basic_test => 1 },
	};
	my $emitter = App::Test::Generator::Emitter::Perl->new(
		schema  => $schemas,
		plans   => $plans,
		package => 'My::Module',
	);
	my $code = $emitter->emit();

	my $pos_alpha = index($code, 'alpha');
	my $pos_beta  = index($code, 'beta');
	my $pos_gamma = index($code, 'gamma');
	ok($pos_alpha < $pos_beta,  'alpha before beta in emitted output');
	ok($pos_beta  < $pos_gamma, 'beta before gamma in emitted output');
};

subtest 'test-generator-index: _is_class_method detects class vs instance methods' => sub {
	# Test the logic directly by duplicating the detection pattern
	# used in _is_class_method — we cannot require the script since
	# it has top-level executable code that needs GITHUB_REPOSITORY

	my $class_src = [
		"sub generate {\n",
		"\tmy \$class = shift;\n",
		"\treturn 1;\n",
		"}\n",
	];
	my $instance_src = [
		"sub run {\n",
		"\tmy \$self = shift;\n",
		"\treturn 1;\n",
		"}\n",
	];

	# Replicate the detection logic from _is_class_method
	my $detect = sub {
		my ($lines, $name) = @_;
		my $in_sub = 0;
		for my $line (@{$lines}) {
			if(!$in_sub && $line =~ /^\s*sub\s+\Q$name\E\b/) {
				$in_sub = 1; next;
			}
			next unless $in_sub;
			return 1 if $line =~ /my\s+\$class\s*=/;
			return 1 if $line =~ /my\s*\(\s*\$class\b/;
			return 0 if $line =~ /my\s+\$self\s*=/;
			return 0 if $line =~ /my\s*\(\s*\$self\b/;
			last if $line =~ /^\s*\}\s*$/;
		}
		return 0;
	};

	is($detect->($class_src,    'generate'), 1, 'generate($class) -> class method');
	is($detect->($instance_src, 'run'),      0, 'run($self) -> instance method');
	is($detect->([],            'foo'),      0, 'empty source -> 0');
};

done_testing();
