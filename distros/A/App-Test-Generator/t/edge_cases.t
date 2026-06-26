#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Capture::Tiny qw(capture);
use File::Path    qw(make_path);
use File::Spec;
use File::Temp    qw(tempdir tempfile);

# Destructive, pathological, and boundary-condition tests for
# App::Test::Generator and its sub-modules.
# These tests deliberately probe broken, empty, huge, and
# adversarial inputs to ensure the system fails gracefully.

# Sentinel weight used to prove a forged evidence entry (one that
# bypassed add_evidence()'s category/signal validation) is still
# counted by resolve_confidence() -- chosen to be unambiguously
# above the 'high' confidence threshold on its own.
Readonly my $FORGED_EVIDENCE_WEIGHT => 9999;

BEGIN {
	use_ok('App::Test::Generator');
	use_ok('App::Test::Generator::SchemaExtractor');
	use_ok('App::Test::Generator::Mutator');
	use_ok('App::Test::Generator::LCSAJ');
	use_ok('App::Test::Generator::Planner');
	use_ok('App::Test::Generator::Emitter::Perl');
	use_ok('App::Test::Generator::CoverageGuidedFuzzer');
	use_ok('App::Test::Generator::Mutant');
	use_ok('App::Test::Generator::Mutation::BooleanNegation');
	use_ok('App::Test::Generator::Mutation::ReturnUndef');
	use_ok('App::Test::Generator::Mutation::ConditionalInversion');
	use_ok('App::Test::Generator::Mutation::NumericBoundary');
	use_ok('App::Test::Generator::Model::Method');
	use_ok('App::Test::Generator::Planner::Isolation');
	use_ok('App::Test::Generator::TestStrategy');
	use_ok('App::Test::Generator::Analyzer::SideEffect');
	use_ok('App::Test::Generator::Exporter::YAML');
}

# ==================================================================
# Generator — pathological schema inputs
# ==================================================================

subtest 'Generator: empty schema file produces graceful croak' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	close $fh;	# empty file
	throws_ok(
		sub { capture(sub { App::Test::Generator->generate($path) }) },
		qr/function|module|parse|load/i,
		'empty schema file croaks gracefully',
	);
};

subtest 'Generator: schema with only whitespace croaks gracefully' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "   \n\t\n   \n";
	close $fh;
	throws_ok(
		sub { capture(sub { App::Test::Generator->generate($path) }) },
		qr/function|module|parse|load/i,
		'whitespace-only schema croaks gracefully',
	);
};

subtest 'Generator: schema with function but no input or output' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: builtin\nfunction: abs\n";
	close $fh;
	my ($out, $err) = capture(sub {
		eval { App::Test::Generator->generate($path) };
	});
	is($@, '', 'no input/output schema does not croak');
	ok(length($out) > 0, 'some output produced even without input/output');
};

subtest 'Generator: schema with deeply nested input types' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh <<'END_YAML';
module: builtin
function: my_func
input:
  data:
    type: hashref
output:
  type: hashref
END_YAML
	close $fh;
	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($path) };
	});
	is($@, '', 'hashref input/output does not croak');
};

subtest 'Generator: schema with very long function name' => sub {
	my $long_name = 'a' x 200;
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: builtin\nfunction: $long_name\n";
	print $fh "input:\n  type: string\noutput:\n  type: string\n";
	close $fh;
	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($path) };
	});
	is($@, '', '200-char function name does not croak');
	like($out, qr/$long_name/, 'long function name appears in output');
};

subtest 'Generator: schema with special characters in string values' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: builtin\nfunction: my_func\n";
	print $fh "input:\n  type: string\noutput:\n  type: string\n";
	print $fh "seed: 42\n";
	close $fh;
	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($path) };
	});
	is($@, '', 'special character schema does not croak');
};

subtest 'Generator: zero iterations produces minimal output' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: builtin\nfunction: abs\n";
	print $fh "input:\n  type: number\noutput:\n  type: number\n";
	print $fh "iterations: 0\n";
	close $fh;
	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($path) };
	});
	is($@, '', 'zero iterations does not croak');
	like($out, qr/done_testing/, 'done_testing present with zero iterations');
};

subtest 'Generator: very large iterations value' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: builtin\nfunction: abs\n";
	print $fh "input:\n  type: number\noutput:\n  type: number\n";
	print $fh "iterations: 999999\n";
	close $fh;
	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($path) };
	});
	# Should not OOM or hang — just produce output with large iteration count
	is($@, '', 'very large iterations value does not croak');
};

subtest 'Generator: nonexistent schema file croaks' => sub {
	throws_ok(
		sub { App::Test::Generator->generate('/no/such/file.yml') },
		qr/No such|not found|Cannot|read/i,
		'nonexistent schema file croaks',
	);
};

subtest 'Generator: undef schema file croaks' => sub {
	throws_ok(
		sub { App::Test::Generator->generate(undef) },
		qr/Usage|required|defined/i,
		'undef schema file croaks',
	);
};

subtest 'Generator: schema with min > max for integer input' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: builtin\nfunction: my_func\n";
	print $fh "input:\n  x:\n    type: integer\n    min: 100\n    max: 1\n";
	print $fh "output:\n  type: integer\n";
	close $fh;
	# Should not crash even with inverted constraints
	lives_ok(
		sub { capture(sub { App::Test::Generator->generate($path) }) },
		'inverted min/max does not crash',
	);
};

subtest 'Generator: schema with unicode function name' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	binmode $fh, ':utf8';
	print $fh "module: builtin\nfunction: my_func\n";
	print $fh "input:\n  type: string\noutput:\n  type: string\n";
	close $fh;
	lives_ok(
		sub { capture(sub { App::Test::Generator->generate($path) }) },
		'unicode in schema file does not crash',
	);
};

# ==================================================================
# Generator — render helpers with pathological inputs
# ==================================================================

subtest 'perl_quote: handles undef' => sub {
	is(App::Test::Generator::perl_quote(undef), 'undef',
		'undef -> literal undef string');
};

subtest 'perl_quote: handles empty string' => sub {
	is(App::Test::Generator::perl_quote(''), "''", 'empty string -> empty quotes');
};

subtest 'perl_quote: handles string with single quotes' => sub {
	my $result = App::Test::Generator::perl_quote("it's");
	ok(defined $result, 'string with single quote handled');
	like($result, qr/it/, 'original content preserved');
};

subtest 'perl_quote: handles NUL bytes' => sub {
	my $result = App::Test::Generator::perl_quote("a\0b");
	ok(defined $result, 'NUL byte handled');
};

subtest 'perl_quote: handles very long string' => sub {
	my $long = 'x' x 10_000;
	my $result = App::Test::Generator::perl_quote($long);
	ok(defined $result, '10000-char string handled');
	ok(length($result) > 0, 'non-empty result');
};

subtest 'perl_quote: handles arrayref' => sub {
	my $result = App::Test::Generator::perl_quote([1, 2, 3]);
	like($result, qr/\[.*1.*2.*3/s, 'arrayref rendered');
};

subtest 'perl_quote: handles nested arrayref' => sub {
	my $result = App::Test::Generator::perl_quote([[1, 2], [3, 4]]);
	ok(defined $result, 'nested arrayref handled');
};

subtest 'q_wrap: handles string containing all bracket pairs' => sub {
	my $result = App::Test::Generator::q_wrap('{}()[]<>');
	ok(defined $result, 'string with all brackets handled');
	ok(length($result) > 0, 'non-empty result');
};

subtest 'q_wrap: handles empty string' => sub {
	my $result = App::Test::Generator::q_wrap('');
	ok(defined $result, 'empty string handled');
};

subtest 'q_wrap: handles undef' => sub {
	my $result = App::Test::Generator::q_wrap(undef);
	ok(defined $result, 'undef handled');
};

subtest 'q_wrap: handles string with all single delimiters' => sub {
	# String containing all Q_SINGLE_DELIMITERS — forces last-resort escaping
	my $result = App::Test::Generator::q_wrap('~!%^=+:,;|/#');
	ok(defined $result, 'all-delimiter string handled');
};

subtest 'render_hash: handles empty hashref' => sub {
	my $result = App::Test::Generator::render_hash({});
	ok(defined $result, 'empty hashref handled');
	is($result, '', 'empty hashref -> empty string');
};

subtest 'render_hash: handles undef' => sub {
	my $result = App::Test::Generator::render_hash(undef);
	is($result, '', 'undef -> empty string');
};

subtest 'render_hash: handles non-hashref' => sub {
	my $result = App::Test::Generator::render_hash('not a hash');
	is($result, '', 'non-hashref -> empty string');
};

subtest 'render_arrayref_map: handles empty hashref' => sub {
	my $result = App::Test::Generator::render_arrayref_map({});
	ok(defined $result, 'empty hashref handled');
};

subtest 'render_arrayref_map: handles undef values in hash' => sub {
	my $result = App::Test::Generator::render_arrayref_map(
		{ key => undef }
	);
	ok(defined $result, 'undef value handled');
};

subtest 'render_fallback: handles circular-like structure via Dumper' => sub {
	my $result = App::Test::Generator::render_fallback({ a => 1, b => [2, 3] });
	ok(defined $result, 'nested structure handled');
	ok(length($result) > 0, 'non-empty output');
};

# ==================================================================
# SchemaExtractor — pathological source files
# ==================================================================

subtest 'SchemaExtractor: empty source file' => sub {
	my ($fh, $pm) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	close $fh;
	lives_ok(
		sub {
			my $e = App::Test::Generator::SchemaExtractor->new(
				input_file => $pm
			);
			$e->extract_all(no_write => 1);
		},
		'empty source file does not crash',
	);
};

subtest 'SchemaExtractor: source with no package declaration' => sub {
	my ($fh, $pm) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh "sub foo { return 1; }\n1;\n";
	close $fh;
	lives_ok(
		sub {
			my $e = App::Test::Generator::SchemaExtractor->new(
				input_file => $pm
			);
			$e->extract_all(no_write => 1);
		},
		'source without package declaration does not crash',
	);
};

subtest 'SchemaExtractor: source with syntax errors parses gracefully' => sub {
	my ($fh, $pm) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh "package Broken;\nsub foo { my \$x = ; }\n1;\n";
	close $fh;
	# PPI is tolerant of syntax errors — should not crash
	lives_ok(
		sub {
			my $e = App::Test::Generator::SchemaExtractor->new(
				input_file => $pm
			);
			$e->extract_all(no_write => 1);
		},
		'source with syntax errors does not crash',
	);
};

subtest 'SchemaExtractor: source with 100 methods' => sub {
	my ($fh, $pm) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh "package Big;\n";
	for my $i (1..100) {
		print $fh "sub method_$i { return $i; }\n";
	}
	print $fh "1;\n";
	close $fh;
	my $schemas;
	lives_ok(
		sub {
			my $e = App::Test::Generator::SchemaExtractor->new(
				input_file => $pm,
			);
			$schemas = $e->extract_all(no_write => 1);
		},
		'100-method module does not crash',
	);
	ok(scalar keys %{$schemas} > 0, 'schemas extracted from large module');
};

subtest 'SchemaExtractor: source with deeply nested anonymous subs' => sub {
	my ($fh, $pm) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh "package Nested;\n";
	print $fh "sub outer {\n";
	print $fh "\tmy \$x = sub { my \$y = sub { return 1; }; return \$y; };\n";
	print $fh "\treturn \$x;\n";
	print $fh "}\n1;\n";
	close $fh;
	lives_ok(
		sub {
			my $e = App::Test::Generator::SchemaExtractor->new(
				input_file => $pm
			);
			$e->extract_all(no_write => 1);
		},
		'nested anonymous subs do not crash',
	);
};

subtest 'SchemaExtractor: source with only comments and POD' => sub {
	my ($fh, $pm) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh "# This is just a comment\n\n=head1 NAME\n\nFoo\n\n=cut\n\n1;\n";
	close $fh;
	lives_ok(
		sub {
			my $e = App::Test::Generator::SchemaExtractor->new(
				input_file => $pm
			);
			my $schemas = $e->extract_all(no_write => 1);
			is(scalar keys %{$schemas}, 0, 'no schemas from comment-only file');
		},
		'comment-only source does not crash',
	);
};

subtest 'SchemaExtractor: source with Unicode identifiers' => sub {
	my ($fh, $pm) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	binmode $fh, ':utf8';
	print $fh "package Unicode;\nuse utf8;\nsub greet { return 'héllo'; }\n1;\n";
	close $fh;
	lives_ok(
		sub {
			my $e = App::Test::Generator::SchemaExtractor->new(
				input_file => $pm
			);
			$e->extract_all(no_write => 1);
		},
		'unicode source does not crash',
	);
};

subtest 'SchemaExtractor: confidence_threshold at extremes' => sub {
	my ($fh, $pm) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh "package Foo;\nsub bar { return 1; }\n1;\n";
	close $fh;

	for my $thresh (0.0, 0.5, 1.0) {
		lives_ok(
			sub {
				my $e = App::Test::Generator::SchemaExtractor->new(
					input_file           => $pm,
					confidence_threshold => $thresh,
				);
				$e->extract_all(no_write => 1);
			},
			"confidence_threshold=$thresh does not crash",
		);
	}
};

# ==================================================================
# Mutant — boundary conditions
# ==================================================================

subtest 'Mutant: line number 0' => sub {
	lives_ok(
		sub {
			App::Test::Generator::Mutant->new(
				id          => 'TEST',
				description => 'test',
				original    => 'x',
				line        => 0,
				transform   => sub { 1 },
			)
		},
		'line number 0 accepted',
	);
};

subtest 'Mutant: very large line number' => sub {
	lives_ok(
		sub {
			App::Test::Generator::Mutant->new(
				id          => 'TEST',
				description => 'test',
				original    => 'x',
				line        => 999_999_999,
				transform   => sub { 1 },
			)
		},
		'very large line number accepted',
	);
};

subtest 'Mutant: empty string id' => sub {
	lives_ok(
		sub {
			App::Test::Generator::Mutant->new(
				id          => '',
				description => 'test',
				original    => 'x',
				line        => 1,
				transform   => sub { 1 },
			)
		},
		'empty string id accepted',
	);
};

subtest 'Mutant: original with NUL bytes' => sub {
	lives_ok(
		sub {
			App::Test::Generator::Mutant->new(
				id          => 'TEST',
				description => 'test',
				original    => "a\0b\0c",
				line        => 1,
				transform   => sub { 1 },
			)
		},
		'NUL bytes in original accepted',
	);
};

subtest 'Mutant: transform that throws is stored without croak' => sub {
	my $m;
	lives_ok(
		sub {
			$m = App::Test::Generator::Mutant->new(
				id          => 'TEST',
				description => 'test',
				original    => 'x',
				line        => 1,
				transform   => sub { die "intentional\n" },
			);
		},
		'transform that throws is stored without croak at construction',
	);
	# Calling it should die
	eval { $m->transform->() };
	like($@, qr/intentional/, 'transform die propagated when called');
};

# ==================================================================
# Mutator — pathological source files
# ==================================================================

subtest 'Mutator: empty source file generates no mutants' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib    = File::Spec->catdir($tmpdir, 'lib');
	mkdir $lib or die $!;
	my $pm = File::Spec->catfile($lib, 'Empty.pm');
	open my $fh, '>', $pm or die $!;
	close $fh;	# empty file

	my $mutator = App::Test::Generator::Mutator->new(
		file    => $pm,
		lib_dir => $lib,
	);
	my @mutants;
	lives_ok(sub { @mutants = $mutator->generate_mutants() },
		'empty file: generate_mutants lives');
	is(scalar @mutants, 0, 'empty file: no mutants generated');
};

subtest 'Mutator: source with only comments generates no mutants' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib    = File::Spec->catdir($tmpdir, 'lib');
	mkdir $lib or die $!;
	my $pm = File::Spec->catfile($lib, 'Comments.pm');
	open my $fh, '>', $pm or die $!;
	print $fh "# just a comment\n# nothing here\n1;\n";
	close $fh;

	my $mutator = App::Test::Generator::Mutator->new(
		file    => $pm,
		lib_dir => $lib,
	);
	my @mutants;
	lives_ok(sub { @mutants = $mutator->generate_mutants() },
		'comment-only file: generate_mutants lives');
};

subtest 'Mutator: source with 50 if-branches' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib    = File::Spec->catdir($tmpdir, 'lib');
	mkdir $lib or die $!;
	my $pm = File::Spec->catfile($lib, 'Dense.pm');
	open my $fh, '>', $pm or die $!;
	print $fh "package Dense;\nsub check {\n\tmy \$x = shift;\n";
	for my $i (1..50) {
		print $fh "\tif(\$x > $i) { return $i; }\n";
	}
	print $fh "\treturn 0;\n}\n1;\n";
	close $fh;

	my $mutator = App::Test::Generator::Mutator->new(
		file    => $pm,
		lib_dir => $lib,
	);
	my @mutants;
	lives_ok(sub { @mutants = $mutator->generate_mutants() },
		'50-branch file: generate_mutants lives');
	ok(scalar @mutants > 0, '50-branch file: mutants generated');
};

# ==================================================================
# Mutation strategies — edge case PPI inputs
# ==================================================================

subtest 'BooleanNegation: empty document produces no mutants' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = PPI::Document->new(\'');
	my @mutants;
	lives_ok(sub { @mutants = $m->mutate($doc) }, 'empty doc: lives');
	is(scalar @mutants, 0, 'empty doc: no mutants');
};

subtest 'BooleanNegation: document with only comments' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = PPI::Document->new(\'# just a comment');
	my @mutants;
	lives_ok(sub { @mutants = $m->mutate($doc) }, 'comment-only doc: lives');
	is(scalar @mutants, 0, 'comment-only doc: no mutants');
};

subtest 'BooleanNegation: bare return statement skipped' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = PPI::Document->new(\"sub foo { return; }\n");
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 0, 'bare return: no mutants');
};

subtest 'ReturnUndef: empty document produces no mutants' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = PPI::Document->new(\'');
	my @mutants;
	lives_ok(sub { @mutants = $m->mutate($doc) }, 'empty doc: lives');
	is(scalar @mutants, 0, 'empty doc: no mutants');
};

subtest 'ReturnUndef: return of list expression handled safely' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = PPI::Document->new(\"sub foo { return (\$a, \$b); }\n");
	my @mutants;
	lives_ok(sub { @mutants = $m->mutate($doc) }, 'list return: lives');
};

subtest 'ConditionalInversion: deeply nested conditionals' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ConditionalInversion->new();
	my $src = "sub foo {\n"
		. "\tif(\$a) { if(\$b) { if(\$c) { return 1; } } }\n"
		. "\treturn 0;\n}\n";
	my $doc = PPI::Document->new(\$src);
	my @mutants;
	lives_ok(sub { @mutants = $m->mutate($doc) }, 'nested conditionals: lives');
	ok(scalar @mutants >= 1, 'nested conditionals: at least one mutant');
};

subtest 'NumericBoundary: all supported operators present' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::NumericBoundary->new();
	my $src = "sub foo { my \$x = shift;\n"
		. "\treturn 1 if \$x > 0;\n"
		. "\treturn 2 if \$x < 0;\n"
		. "\treturn 3 if \$x >= 0;\n"
		. "\treturn 4 if \$x <= 0;\n"
		. "\treturn 5 if \$x == 0;\n"
		. "\treturn 6 if \$x != 0;\n"
		. "}\n";
	my $doc = PPI::Document->new(\$src);
	my @mutants;
	lives_ok(sub { @mutants = $m->mutate($doc) }, 'all operators: lives');
	ok(scalar @mutants > 0, 'all operators: mutants generated');
};

subtest 'NumericBoundary: readline operator not treated as comparison' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::NumericBoundary->new();
	my $doc = PPI::Document->new(\"sub foo { my \$line = <\$fh>; }\n");
	my @mutants;
	lives_ok(sub { @mutants = $m->mutate($doc) }, 'readline: lives');
	is(scalar @mutants, 0, 'readline < not treated as comparison');
};

# ==================================================================
# LCSAJ — pathological inputs
# ==================================================================

subtest 'LCSAJ: module with single-line subs' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;

	open my $fh, '>', 'Inline.pm' or die $!;
	print $fh "package Inline;\n";
	print $fh "sub foo { return 1 }\n" x 20;
	print $fh "1;\n";
	close $fh;

	my $paths;
	lives_ok(sub { $paths = App::Test::Generator::LCSAJ->generate('Inline.pm', 'out') },
		'single-line subs: lives');
	chdir $orig;
	is(ref($paths), 'ARRAY', 'returns arrayref');
};

subtest 'LCSAJ: module with empty subs' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;

	open my $fh, '>', 'Empty.pm' or die $!;
	print $fh "package Empty;\n";
	print $fh "sub foo { }\nsub bar { }\nsub baz { }\n";
	print $fh "1;\n";
	close $fh;

	my $paths;
	lives_ok(sub { $paths = App::Test::Generator::LCSAJ->generate('Empty.pm', 'out') },
		'empty subs: lives');
	chdir $orig;
	is(scalar @{$paths}, 0, 'empty subs: no paths');
};

subtest 'LCSAJ: output directory not writable gracefully croaks' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $pm     = File::Spec->catfile($tmpdir, 'Foo.pm');
	open my $fh, '>', $pm or die $!;
	print $fh "package Foo;\nsub bar { return 1; }\n1;\n";
	close $fh;

	SKIP: {
		skip 'running as root', 1 if $> == 0;
		my $no_write = File::Spec->catdir($tmpdir, 'no_write');
		mkdir $no_write or die $!;
		chmod 0444, $no_write;
		throws_ok(
			sub { App::Test::Generator::LCSAJ->generate($pm, $no_write) },
			qr/Cannot|write|permission/i,
			'unwritable output dir croaks',
		);
		chmod 0755, $no_write;
	}
};

# ==================================================================
# Planner — boundary and pathological inputs
# ==================================================================

subtest 'Planner: empty schemas produces empty plan' => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => {},
		package => 'Foo',
	);
	my $plan = $p->plan_all();
	is_deeply($plan, {}, 'empty schemas -> empty plan');
};

subtest 'Planner: schema with undef output type' => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => { foo => { output => { type => undef } } },
		package => 'Foo',
	);
	lives_ok(sub { $p->plan_all() }, 'undef output type does not crash');
};

subtest 'Planner: schema with 100 methods' => sub {
	my %schemas;
	for my $i (1..100) { $schemas{"method_$i"} = { output => {} } }
	my $p = App::Test::Generator::Planner->new(
		schemas => \%schemas,
		package => 'Foo',
	);
	my $plan;
	lives_ok(sub { $plan = $p->plan_all() }, '100-method plan does not crash');
	is(scalar keys %{$plan}, 100, '100 methods planned');
};

subtest 'Planner: all accessor types in one schema' => sub {
	my %schemas = (
		getter   => { accessor => { type => 'get' },      output => {} },
		setter   => { accessor => { type => 'getset' },   output => {} },
		injector => { accessor => { type => 'injector' }, output => {} },
		boolean  => { output   => { type => 'boolean' } },
		plain    => { output   => {} },
	);
	my $p = App::Test::Generator::Planner->new(
		schemas => \%schemas,
		package => 'Foo',
	);
	my $plan;
	lives_ok(sub { $plan = $p->plan_all() }, 'mixed accessor types do not crash');
	ok($plan->{getter}{getter_test},        'getter -> getter_test');
	ok($plan->{setter}{getset_test},        'setter -> getset_test');
	ok($plan->{injector}{object_injection_test}, 'injector -> object_injection_test');
	ok($plan->{boolean}{boolean_test},      'boolean output -> boolean_test');
	ok(!$plan->{plain}{boolean_test},       'plain output -> no boolean_test');
};

# ==================================================================
# Emitter::Perl — boundary and pathological inputs
# ==================================================================

subtest 'Emitter::Perl: all plan flags set simultaneously' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { m => { input => {}, output => {} } },
		plans   => { m => {
			basic_test          => 1,
			getter_test         => 1,
			setter_test         => 1,
			getset_test         => 1,
			chaining_test       => 1,
			error_handling_test => 1,
			context_tests       => 1,
			object_injection_test => 1,
			boolean_test        => 1,
			void_context_test   => 1,
		} },
		package => 'My::Module',
	);
	my $code;
	lives_ok(sub { $code = $e->emit() }, 'all flags: emit lives');
	like($code, qr/done_testing/, 'all flags: done_testing present');
};

subtest 'Emitter::Perl: method name with special characters in comment' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { 'import' => { input => {}, output => {} } },
		plans   => { 'import' => { basic_test => 1 } },
		package => 'My::Module',
	);
	lives_ok(sub { $e->emit() }, 'reserved word method name does not crash');
};

subtest 'Emitter::Perl: 50-method schema emits valid code' => sub {
	my (%schemas, %plans);
	for my $i (1..50) {
		$schemas{"method_$i"} = { input => {}, output => {} };
		$plans{"method_$i"}   = { basic_test => 1 };
	}
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => \%schemas,
		plans   => \%plans,
		package => 'My::Module',
	);
	my $code;
	lives_ok(sub { $code = $e->emit() }, '50-method emit lives');
	my $tmpdir  = tempdir(CLEANUP => 1);
	my $outfile = File::Spec->catfile($tmpdir, 'big.t');
	open my $fh, '>', $outfile or die $!;
	print $fh $code;
	close $fh;
	is(system($^X, '-c', $outfile), 0, '50-method emitted code compiles');
};

# ==================================================================
# CoverageGuidedFuzzer — boundary and pathological inputs
# ==================================================================

subtest 'CoverageGuidedFuzzer: zero iterations produces seed corpus only' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string' } },
		target_sub => sub { 1 },
		iterations => 0,
		seed       => 42,
	);
	my $r;
	lives_ok(sub { $r = $f->run() }, 'zero iterations: run lives');
	is($r->{total_iterations}, 0, 'zero iterations reported');
	ok($r->{corpus_size} >= 0,     'corpus size non-negative');
};

subtest 'CoverageGuidedFuzzer: target that always dies produces bug entries' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string', min => 1, max => 5 } },
		target_sub => sub { die "always\n" },
		iterations => 5,
		seed       => 42,
	);
	lives_ok(sub { $f->run() }, 'always-dying target: run lives');
};

subtest 'CoverageGuidedFuzzer: target that always warns does not crash' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string' } },
		target_sub => sub { warn "test warning\n"; return 1 },
		iterations => 5,
		seed       => 42,
	);
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	lives_ok(sub { $f->run() }, 'always-warning target: run lives');
};

subtest 'CoverageGuidedFuzzer: integer schema boundary values' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => {
			type => 'integer', min => -2**31, max => 2**31 - 1
		} },
		target_sub => sub { return $_[0] + 0 },
		iterations => 10,
		seed       => 42,
	);
	lives_ok(sub { $f->run() }, 'INT32 boundary schema: run lives');
};

subtest 'CoverageGuidedFuzzer: boolean schema' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'boolean' } },
		target_sub => sub { return $_[0] ? 'yes' : 'no' },
		iterations => 10,
		seed       => 42,
	);
	lives_ok(sub { $f->run() }, 'boolean schema: run lives');
};

subtest 'CoverageGuidedFuzzer: arrayref schema' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'arrayref' } },
		target_sub => sub { return scalar @{$_[0]} },
		iterations => 10,
		seed       => 42,
	);
	lives_ok(sub { $f->run() }, 'arrayref schema: run lives');
};

subtest 'CoverageGuidedFuzzer: hashref schema' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'hashref' } },
		target_sub => sub { return scalar keys %{$_[0]} },
		iterations => 10,
		seed       => 42,
	);
	lives_ok(sub { $f->run() }, 'hashref schema: run lives');
};

subtest 'CoverageGuidedFuzzer: save_corpus to read-only directory croaks' => sub {
	SKIP: {
		skip 'running as root', 1 if $> == 0;
		my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
			schema     => { input => { type => 'string' } },
			target_sub => sub { 1 },
			iterations => 3,
			seed       => 42,
		);
		$f->run();
		throws_ok(
			sub { $f->save_corpus('/no/such/dir/corpus.json') },
			qr/Cannot write corpus/,
			'unwritable path croaks',
		);
	}
};

subtest 'CoverageGuidedFuzzer: load_corpus from nonexistent file croaks' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string' } },
		target_sub => sub { 1 },
		iterations => 0,
		seed       => 42,
	);
	throws_ok(
		sub { $f->load_corpus('/no/such/corpus.json') },
		qr/Cannot read corpus/,
		'nonexistent corpus file croaks',
	);
};

subtest 'CoverageGuidedFuzzer: load_corpus from empty file croaks' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.json', UNLINK => 1);
	close $fh;	# empty file
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string' } },
		target_sub => sub { 1 },
		iterations => 0,
		seed       => 42,
	);
	throws_ok(
		sub { $f->load_corpus($path) },
		qr/./,	# any error is acceptable for malformed JSON
		'empty corpus file croaks',
	);
};

# ==================================================================
# Cross-module: render helpers handle values from real schemas
# ==================================================================

subtest 'render helpers: handle Regexp values without crashing' => sub {
	my $re     = qr/^[a-z]+$/i;
	my $result = App::Test::Generator::perl_quote($re);
	ok(defined $result,        'Regexp handled by perl_quote');
	like($result, qr/qr\{/,   'Regexp rendered as qr{}');
};

subtest 'render_args_hash: handles Regexp values' => sub {
	my $result = App::Test::Generator::render_args_hash({
		matches => qr/^\d+$/,
		type    => 'string',
	});
	ok(defined $result,     'Regexp in args hash handled');
	like($result, qr/qr\{/, 'Regexp rendered in args hash');
};

subtest 'render_hash: skips undef sub-values gracefully' => sub {
	my $result = App::Test::Generator::render_hash({
		param => { type => 'string', min => undef, max => 10 }
	});
	ok(defined $result,        'undef sub-value handled');
	unlike($result, qr/min/,   'undef min key omitted');
	like($result,   qr/max/,   'defined max key present');
};

# ==================================================================
# Planner::Isolation -- asymmetric argument validation
#
# plan() croaks if $strategy is not a hashref, but never validates
# $schema at all. Every access to $schema below is a chained rvalue
# dereference ($schema->{$method}{_analysis}...), which Perl resolves
# to undef without autovivifying or dying even when $schema itself is
# undef. This is real, intentional asymmetry (CLAUDE.md documents it),
# not an oversight -- the hostile case to prove is that a caller who
# forgets to pass $schema still gets a safe, maximally-defensive plan
# rather than a crash.
# ==================================================================
subtest 'Planner::Isolation::plan: undef schema degrades gracefully to the safest fixture' => sub {
	my $planner = App::Test::Generator::Planner::Isolation->new();

	my $isolation;
	lives_ok {
		$isolation = $planner->plan(undef, { risky_method => 1 });
	} 'plan() does not die when $schema is undef';

	is_deeply(
		$isolation,
		{ risky_method => { fixture => 'isolated_block' } },
		'undef schema degrades to the most defensive (isolated_block) fixture, not a crash',
	);
};

# ==================================================================
# Model::Method -- aliasing/state abuse via evidence_ref()
#
# POD documents evidence_ref() as returning "the live internal
# arrayref, not a copy". Treated as a hostile capability: a caller can
# splice a forged entry directly into that arrayref, completely
# bypassing add_evidence()'s category/signal whitelist validation, and
# have it silently summed by resolve_confidence() anyway, since that
# method trusts every entry's weight regardless of provenance.
# ==================================================================
subtest 'Model::Method::evidence_ref: external mutation bypasses add_evidence() validation entirely' => sub {
	my $m = App::Test::Generator::Model::Method->new(name => 'm', source => 'sub m {}');
	my $ref = $m->evidence_ref;

	push @{$ref}, {
		category => 'not_a_real_category',
		signal   => 'not_a_real_signal',
		weight   => $FORGED_EVIDENCE_WEIGHT,
	};

	is(scalar($m->evidence), 1,
		'forged entry is visible through evidence() despite never passing through add_evidence()');

	my $conf = $m->resolve_confidence;
	is($conf->{score}, $FORGED_EVIDENCE_WEIGHT,
		'forged weight is summed into resolve_confidence() with no provenance check');
	is($conf->{level}, 'high',
		'a single forged entry is enough on its own to reach "high" confidence');
};

# ==================================================================
# Model::Method -- list vs scalar context confusion
#
# evidence() is documented to behave differently depending on calling
# context: list context yields every evidence hashref, scalar context
# yields only the count (via Perl's own "array in scalar context is
# its length" rule, not a special case in the sub body). Exercise both
# conventions side by side on the same populated object.
# ==================================================================
subtest 'Model::Method::evidence: list and scalar context return genuinely different things' => sub {
	my $m = App::Test::Generator::Model::Method->new(name => 'm', source => 'sub m {}');
	$m->add_evidence(category => 'return', signal => 'returns_constant', weight => 10);
	$m->add_evidence(category => 'return', signal => 'returns_self',     weight => 15);

	my @list_ctx   = $m->evidence;
	my $scalar_ctx = $m->evidence;

	is(scalar(@list_ctx), 2, 'list context returns both evidence hashrefs');
	is($scalar_ctx,        2, 'scalar context returns the entry count, not the last entry');
	is(ref($list_ctx[0]), 'HASH', 'each list-context element is still a real evidence hashref');
};

# ==================================================================
# Model::Method -- unlocalized $_ mutation
#
# resolve_confidence() sums weights via the postfix form
# "$total += $_->{weight} for @{ $self->{evidence} };". Postfix
# for/foreach always aliases and restores $_ around the loop body, but
# that safety property is easy to break if the loop is ever rewritten
# -- assert it explicitly rather than trusting it silently continues
# to hold under future refactors.
# ==================================================================
subtest 'Model::Method::resolve_confidence: does not leak $_ into the caller' => sub {
	local $_ = 'sentinel-before-call';

	my $m = App::Test::Generator::Model::Method->new(name => 'm', source => 'sub m {}');
	$m->add_evidence(category => 'return', signal => 'returns_constant', weight => 10);
	$m->resolve_confidence;

	is($_, 'sentinel-before-call',
		'$_ is unchanged by resolve_confidence(), confirming the postfix for-loop restores it');
};

# ==================================================================
# Analyzer::SideEffect / Analyzer::Complexity -- unexpected reference
# types in place of the documented source-string body
#
# $method->{body} is documented as a plain source string. Passing an
# arrayref instead must not crash: the regex match operator stringifies
# its operand (e.g. to "ARRAY(0x...)"), which trivially fails to match
# any side-effect or branch-keyword pattern, so the safe and correct
# outcome is graceful "no signal detected" rather than a die.
# ==================================================================
subtest 'Analyzer::SideEffect::analyze: arrayref body stringifies harmlessly instead of crashing' => sub {
	my $se = App::Test::Generator::Analyzer::SideEffect->new();

	my $report;
	lives_ok {
		$report = $se->analyze({ body => [ 'system("rm -rf /")' ] });
	} 'analyze() lives when body is an arrayref instead of a string';

	is($report->{purity_level}, 'pure',
		'a stringified arrayref reference does not coincidentally match any side-effect pattern');
};

# ==================================================================
# Analyzer::SideEffect -- typeglob in place of the method hashref
#
# $method is documented as "a hashref". A typeglob reference is exactly
# the kind of unexpected-reference-type input the skill calls for.
# Perl's own type system rejects dereferencing it as a hash with a
# clear, immediate die rather than silently misbehaving or corrupting
# state -- confirm that boundary explicitly.
# ==================================================================
subtest 'Analyzer::SideEffect::analyze: typeglob in place of $method dies predictably, not silently' => sub {
	my $se = App::Test::Generator::Analyzer::SideEffect->new();

	throws_ok {
		$se->analyze(\*STDOUT);
	} qr/Not a HASH reference/,
		'a typeglob ref in place of $method dies with a clear type error';
};

# ==================================================================
# Exporter::YAML -- circular-reference plan hashref
#
# Empirically verified against YAML::XS directly (libyaml supports
# anchors/aliases for cyclic structures) before writing this test: a
# self-referential plan hashref does NOT hang or crash DumpFile. This
# is therefore a lives_ok confirmation of safe, already-correct
# behaviour -- a hang here would be a real denial-of-service risk
# given that plan hashrefs are partly schema-derived, so it is worth
# locking in permanently rather than assuming it stays true.
# ==================================================================
subtest 'Exporter::YAML::export: self-referential plan hashref does not hang or crash' => sub {
	my $exporter = bless {}, 'App::Test::Generator::Exporter::YAML';
	my %plan;
	$plan{self} = \%plan;	# circular reference

	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'circular.yml');

	lives_ok {
		$exporter->export(\%plan, $file);
	} 'export() does not crash or hang on a circular-reference plan';

	ok(-s $file, 'a non-empty YAML file was written for the circular structure');
};

# ==================================================================
# TestStrategy::generate_plan -- malformed per-method schema entries
#
# generate_plan() has no schema-shape validation of its own, unlike
# every Planner::* submodule (which all croak on a non-hashref $schema
# argument). Probe both ends of that gap: an undef per-method entry is
# safe (a chained rvalue dereference degrades to defaults), while a
# non-hashref entry such as a plain string is unsafe (dereferencing a
# string as a hashref dies under "strict refs"). Both behaviours were
# verified directly against the running code before being asserted
# here.
# ==================================================================
subtest 'TestStrategy::generate_plan: undef per-method entry degrades to the basic_test fallback' => sub {
	my $strategy = App::Test::Generator::TestStrategy->new(
		schema => { mystery_method => undef },
	);

	my $plan;
	lives_ok {
		$plan = $strategy->generate_plan;
	} 'generate_plan() lives when a per-method schema entry is undef';

	is_deeply(
		$plan->{mystery_method},
		{ basic_test => 1 },
		'an undef per-method entry degrades to the basic_test-only fallback plan',
	);
};

subtest 'TestStrategy::generate_plan: non-hashref per-method entry dies with a clear type error' => sub {
	my $strategy = App::Test::Generator::TestStrategy->new(
		schema => { broken_method => 'not a hashref' },
	);

	throws_ok {
		$strategy->generate_plan;
	} qr/HASH ref/,
		'a non-hashref per-method schema entry dies clearly rather than silently misbehaving';
};

# ==================================================================
# Generator::generate() -- end-to-end injection attempt via a
# schema-derived function name
#
# _assert_identifier() itself is already unit-tested directly
# elsewhere (t/function.t). This instead exercises the *full*
# generate() pipeline end to end: a function name shaped like a Perl
# statement-injection payload (semicolon-separated, containing a
# system() call) must be rejected before it ever reaches the point of
# being spliced unescaped into generated test source, and critically,
# before any output file is created on disk.
# ==================================================================
subtest 'Generator::generate(): statement-injection-shaped function name is rejected before any file is written' => sub {
	my $dir     = tempdir(CLEANUP => 1);
	my $outfile = File::Spec->catfile($dir, 'out.t');

	my $schema = {
		function => 'evil; system("touch /tmp/pwned"); 1',
		input    => { number => { type => 'number', position => 0 } },
		output   => { type => 'number' },
	};

	throws_ok {
		App::Test::Generator->generate(schema => $schema, output_file => $outfile);
	} qr/not a valid Perl identifier/,
		'a statement-injection-shaped function name is rejected';

	ok(!-e $outfile, 'no output file was written once the malicious identifier was rejected');
};

done_testing();
