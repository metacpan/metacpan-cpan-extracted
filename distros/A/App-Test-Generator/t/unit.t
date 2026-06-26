#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird 0.10;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use Capture::Tiny qw(capture);

# CORE::GLOBAL::system overrides are resolved when the *calling* code is
# compiled, not dispatched dynamically -- a "local *CORE::GLOBAL::system"
# set at runtime inside a subtest has no effect on Mutator::run_tests(),
# because Mutator.pm is already compiled by the time that subtest runs.
# This override must therefore be installed in a BEGIN block before
# App::Test::Generator::Mutator is use'd below, with the actual mock
# behaviour supplied per-subtest via $REAL_SYSTEM_HOOK so the default
# (no active subtest) passes through to the real builtin.
our $REAL_SYSTEM_HOOK;
BEGIN {
	no warnings 'redefine';
	*CORE::GLOBAL::system = sub {
		return $REAL_SYSTEM_HOOK ? $REAL_SYSTEM_HOOK->(@_) : CORE::system(@_);
	};
}

BEGIN {
	use_ok('App::Test::Generator');
	use_ok('App::Test::Generator::Mutator');
	use_ok('App::Test::Generator::Mutant');
}

# --------------------------------------------------
# Shared minimal Perl source file used across
# multiple subtests
# --------------------------------------------------
my ($src_fh, $src_file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
print {$src_fh} <<'PERL';
package Foo;
sub bar {
	my $x = shift;
	if($x > 0) {
		return 1;
	}
	return 0;
}
1;
PERL
close $src_fh;

# --------------------------------------------------
# Source file rooted under a lib/ directory, needed
# for prepare_workspace and apply_mutant tests where
# the relative path stripping must work correctly
# --------------------------------------------------
my $ws_tmpdir = tempdir(CLEANUP => 1);
my $ws_lib    = File::Spec->catdir($ws_tmpdir, 'lib');
File::Path::make_path($ws_lib);
my $ws_src    = File::Spec->catfile($ws_lib, 'Foo.pm');
open my $ws_fh, '>', $ws_src or die "Cannot write $ws_src: $!";
print {$ws_fh} <<'PERL';
package Foo;
sub bar { return 1; }
1;
PERL
close $ws_fh;

# --------------------------------------------------
# Helper: build a minimal no-op Mutant object
# --------------------------------------------------
sub _stub_mutant {
	my (%args) = @_;
	return App::Test::Generator::Mutant->new(
		id          => $args{id}          // 'TEST_1',
		file        => $args{file}        // $src_file,
		line        => $args{line}        // 1,
		description => $args{description} // 'stub mutant',
		original    => $args{original}    // '',
		transform   => $args{transform}   // sub {},
	);
}

# --------------------------------------------------
# Stub mutant factory for use in mocked strategy calls
# --------------------------------------------------
sub _make_stub_mutant {
	my ($line) = @_;
	return App::Test::Generator::Mutant->new(
		id          => "STUB_$line",
		file        => $src_file,
		line        => $line,
		description => 'stub',
		original    => 'x',
		transform   => sub {},
	);
}

# ==================================================================
# new()
# POD: croaks if file is missing or does not exist; returns a
# blessed App::Test::Generator::Mutator on success.
# ==================================================================
subtest 'Mutator::new - croaks when file argument omitted' => sub {
	# POD states file is required — omitting it must croak
	throws_ok {
		App::Test::Generator::Mutator->new()
	} qr/file required/, 'croaks with no file argument';

	done_testing();
};

subtest 'Mutator::new - croaks for non-existent file' => sub {
	throws_ok {
		App::Test::Generator::Mutator->new(file => '/no/such/file.pm')
	} qr/file not found/, 'croaks for missing file';

	done_testing();
};

subtest 'Mutator::new - returns blessed object for valid file' => sub {
	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	isa_ok($m, 'App::Test::Generator::Mutator');

	done_testing();
};

subtest 'Mutator::new - lib_dir defaults to lib' => sub {
	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	is($m->{lib_dir}, 'lib', 'lib_dir defaults to lib');

	done_testing();
};

subtest 'Mutator::new - mutation_level defaults to full' => sub {
	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	is($m->{mutation_level}, 'full', 'mutation_level defaults to full');

	done_testing();
};

subtest 'Mutator::new - accepts custom lib_dir' => sub {
	my $m = App::Test::Generator::Mutator->new(
		file    => $src_file,
		lib_dir => 'src',
	);
	is($m->{lib_dir}, 'src', 'custom lib_dir accepted');

	done_testing();
};

subtest 'Mutator::new - accepts fast mutation_level' => sub {
	my $m = App::Test::Generator::Mutator->new(
		file           => $src_file,
		mutation_level => 'fast',
	);
	is($m->{mutation_level}, 'fast', 'fast mutation_level accepted');

	done_testing();
};

# ==================================================================
# generate_mutants()
# POD: returns a list of Mutant objects; lines within
# MUTANT_SKIP_BEGIN/END blocks are excluded; skip_lines
# hashref is populated after call; mismatched markers croak.
# ==================================================================
subtest 'Mutator::generate_mutants - returns list of mutants' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	my @mutants = $m->generate_mutants();

	ok(scalar(@mutants) > 0, 'at least one mutant generated');
	for my $mutant (@mutants) {
		isa_ok($mutant, 'App::Test::Generator::Mutant');
	}

	done_testing();
};

subtest 'Mutator::generate_mutants - populates skip_lines hashref' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	$m->generate_mutants();

	# POD states skip_lines is always set after the call
	is(ref($m->{skip_lines}), 'HASH', 'skip_lines is a hashref after call');

	done_testing();
};

subtest 'Mutator::generate_mutants - skip block excludes lines from mutants' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my ($fh, $file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} <<'PERL';
package Skip;
sub safe {
	if(my $x > 0) { return 1; }
	return 0;
}
sub risky {
	## MUTANT_SKIP_BEGIN
	kill 'HUP', $$;
	waitpid $$, 0;
	## MUTANT_SKIP_END
	return 1;
}
1;
PERL
	close $fh;

	my $m = App::Test::Generator::Mutator->new(file => $file);
	my @mutants = $m->generate_mutants();

	# No mutant should reference a line inside the skip block
	my %skip = %{$m->{skip_lines}};
	for my $mutant (@mutants) {
		ok(!$skip{$mutant->line},
			'mutant line ' . $mutant->line . ' is not in skip block');
	}

	done_testing();
};

subtest 'Mutator::generate_mutants - unclosed MUTANT_SKIP_BEGIN croaks' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my ($fh, $file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} <<'PERL';
package Bad;
sub x {
	## MUTANT_SKIP_BEGIN
	return 1;
}
1;
PERL
	close $fh;

	my $m = App::Test::Generator::Mutator->new(file => $file);
	throws_ok {
		$m->generate_mutants()
	} qr/MUTANT_SKIP_BEGIN/, 'unclosed MUTANT_SKIP_BEGIN croaks';

	done_testing();
};

subtest 'Mutator::generate_mutants - unmatched MUTANT_SKIP_END croaks' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my ($fh, $file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} <<'PERL';
package Bad2;
sub x {
	return 1;
	## MUTANT_SKIP_END
}
1;
PERL
	close $fh;

	my $m = App::Test::Generator::Mutator->new(file => $file);
	throws_ok {
		$m->generate_mutants()
	} qr/MUTANT_SKIP_END/, 'unmatched MUTANT_SKIP_END croaks';

	done_testing();
};

subtest 'Mutator::generate_mutants - fast mode returns mutants' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my $m = App::Test::Generator::Mutator->new(
		file           => $src_file,
		mutation_level => 'fast',
	);
	my @mutants = $m->generate_mutants();

	# fast mode must still return Mutant objects
	for my $mutant (@mutants) {
		isa_ok($mutant, 'App::Test::Generator::Mutant');
	}

	done_testing();
};

subtest 'Mutator::generate_mutants - fast mode no more mutants than full' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my $fast = App::Test::Generator::Mutator->new(
		file           => $src_file,
		mutation_level => 'fast',
	);
	my $full = App::Test::Generator::Mutator->new(file => $src_file);

	my @fast_mutants = $fast->generate_mutants();
	my @full_mutants = $full->generate_mutants();

	ok(scalar(@fast_mutants) <= scalar(@full_mutants),
		'fast mode produces no more mutants than full mode');

	done_testing();
};

# ==================================================================
# prepare_workspace()
# POD: returns absolute path to temp directory; sets
# $self->{workspace} and $self->{relative}; croaks if dircopy fails.
# ==================================================================
subtest 'Mutator::prepare_workspace - returns a directory path' => sub {
	# Mock dircopy so we do not touch the real filesystem
	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	my $path = $m->prepare_workspace();

	ok(defined $path, 'prepare_workspace returns a path');
	ok(-d $path,      'returned path is a directory');

	done_testing();
};

subtest 'Mutator::prepare_workspace - sets workspace on object' => sub {
	my $guard = mock_scoped(
		'File::Copy::Recursive::dircopy' => sub { 1 }
	);

	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	my $path = $m->prepare_workspace();

	is($m->{workspace}, $path, 'workspace stored on object matches return value');

	done_testing();
};

subtest 'Mutator::prepare_workspace - sets relative path on object' => sub {
	my $guard = mock_scoped(
		'File::Copy::Recursive::dircopy' => sub { 1 }
	);

	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	$m->prepare_workspace();

	ok(defined $m->{relative}, 'relative path set on object');

	done_testing();
};

subtest 'Mutator::prepare_workspace - croaks when dircopy fails' => sub {
	my $guard = mock_scoped(
		'App::Test::Generator::Mutator::dircopy' => sub { 0 }
	);

	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	throws_ok {
		$m->prepare_workspace()
	} qr/dircopy failed/, 'croaks when dircopy fails';

	done_testing();
};

# ==================================================================
# apply_mutant()
# POD: croaks if workspace not prepared; overwrites workspace
# copy of target file with mutated version.
# ==================================================================
subtest 'Mutator::apply_mutant - croaks without prepare_workspace' => sub {
	my $m = App::Test::Generator::Mutator->new(file => $ws_src, lib_dir => $ws_lib);
	my $mutant = _stub_mutant();

	throws_ok {
		$m->apply_mutant($mutant)
	} qr/Workspace not prepared/, 'croaks when workspace not prepared';

	done_testing();
};

subtest 'Mutator::apply_mutant - applies transform to workspace file' => sub {
	my $guard = mock_scoped(
		'App::Test::Generator::Mutator::dircopy' => sub { 1 }
	);
	my $m = App::Test::Generator::Mutator->new(file => $ws_src, lib_dir => $ws_lib);
	$m->prepare_workspace();

	# Write the source file into the workspace at the expected path
	my $ws_lib_dir = File::Spec->catfile($m->{workspace}, 'lib');
	File::Path::make_path($ws_lib_dir);
	my $ws_file = File::Spec->catfile($ws_lib_dir, $m->{relative});
	File::Copy::copy($src_file, $ws_file);

	# Transform that marks the file with a known string
	my $transform_called = 0;
	my $mutant = _stub_mutant(
		transform => sub { $transform_called = 1 },
	);
	lives_ok {
		$m->apply_mutant($mutant)
	} 'apply_mutant lives with prepared workspace';
	ok($transform_called, 'transform coderef was called');
	done_testing();
};

# ==================================================================
# App::Test::Generator (Generator.pm)
#
# t/Generator.t and t/Generator_unit.t already give thorough black-box
# coverage of generate(), perl_quote(), render_fallback(), render_hash(),
# render_args_hash() and render_arrayref_map() against their POD. The
# subtests below cover the specific POD-documented branches those files
# leave untested: perl_quote()'s hashref/blessed-object fallthrough to
# render_fallback(), render_hash()'s carp-and-skip path for a scalar
# value that is not a recognised type string, and generate()'s
# documented-but-not-yet-implemented quiet flag.
# ==================================================================
sub _unit_schema_file {
	my (%opts) = @_;
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	my $module   = $opts{module}   // 'builtin';
	my $function = $opts{function} // 'my_func';
	my $input    = $opts{input}    // "input:\n  type: string";
	my $output   = $opts{output}   // "output:\n  type: string";
	print {$fh} "module: $module\nfunction: $function\n$input\n$output\n";
	close $fh;
	return $path;
}

subtest 'Generator::perl_quote - hashref falls through to render_fallback' => sub {
	# POD: "anything else (including hashrefs and blessed objects) falls
	# through to render_fallback" — a bare hashref is not ARRAY/Regexp,
	# so it must take the render_fallback branch rather than stringify
	# as a ref address.
	my $result = App::Test::Generator::perl_quote({ a => 1 });
	is($result, App::Test::Generator::render_fallback({ a => 1 }),
		'hashref renders identically to a direct render_fallback() call');

	done_testing();
};

subtest 'Generator::perl_quote - blessed object falls through to render_fallback' => sub {
	my $obj = bless { x => 1 }, 'Some::Fake::Class';
	my $result = App::Test::Generator::perl_quote($obj);
	is($result, App::Test::Generator::render_fallback($obj),
		'blessed object renders identically to a direct render_fallback() call');

	done_testing();
};

subtest 'Generator::render_hash - carps and skips key whose scalar value is not a recognised type' => sub {
	# POD: "A scalar value that is a recognised type string is expanded
	# ... Any other non-hashref value is skipped with a warning." This
	# distinguishes the valid-type-shorthand branch (already covered in
	# t/Generator.t) from the invalid-scalar-value branch, which is not
	# tested anywhere else.
	my $warning;
	local $SIG{__WARN__} = sub { $warning = $_[0] };

	my $result = App::Test::Generator::render_hash({ arg1 => 'not_a_real_type' });

	is($result, '', 'key with unrecognised scalar value contributes nothing to the output');
	like($warning, qr/skipping key 'arg1'/, 'carp warns about the skipped key');

	done_testing();
};

subtest 'Generator::generate - quiet flag is accepted but documented as not yet implemented' => sub {
	# POD now states quiet is "accepted but not yet implemented; has no
	# effect". Pass it both ways and confirm generate() neither croaks
	# nor changes its output, matching the documented current behaviour.
	my $schema = _unit_schema_file();

	my ($out_quiet) = capture(sub { App::Test::Generator->generate($schema, undef) });
	my ($out_noisy) = capture(sub {
		App::Test::Generator->generate({ schema_file => $schema, quiet => 1 });
	});

	ok(defined $out_quiet, 'generate() without quiet produces output');
	ok(defined $out_noisy, 'generate() with quiet => 1 does not croak');
	is($out_noisy, $out_quiet, 'quiet => 1 does not change generated output');

	done_testing();
};

# ==================================================================
# App::Test::Generator::Analyzer::Complexity
#
# t/Analyzer-Complexity.t already gives analyze() exhaustive black-box
# POD-driven coverage. One documented behaviour is untested anywhere:
# the Notes section states nesting_depth is "naive brace counting and
# will be inaccurate if the source contains braces inside strings or
# regexes" — unlike the keyword/operator counts (which strip strings
# and comments first via _strip_strings_and_comments), nesting_depth
# scans $body directly and so DOES still count braces inside a string
# literal. This documents that the limitation is real, not a typo.
# ==================================================================
subtest 'Analyzer::Complexity::analyze - documented limitation: braces inside string literals inflate nesting_depth' => sub {
	require App::Test::Generator::Analyzer::Complexity;
	my $analyser = App::Test::Generator::Analyzer::Complexity->new;

	# A brace pair that exists only inside a string literal, with no
	# real brace nesting in the surrounding code at all
	my $report = $analyser->analyze({ body => q{return "{not real code}";} });

	is($report->{nesting_depth}, 1,
		'brace characters inside a string literal are still counted, per the documented limitation');

	done_testing();
};

# ==================================================================
# App::Test::Generator::Analyzer::Return
#
# t/Analyzer-Return.t already gives analyze() exhaustive black-box
# coverage when called with a Model::Method-shaped mock object (one
# exposing both source() and add_evidence()). The POD now documents
# a second, defensive code path — a plain hashref with a source/body
# key and no add_evidence method — that is untested anywhere: the
# analyser must read the source without dying and silently no-op
# rather than recording evidence, since there is nowhere to record it.
# ==================================================================
subtest 'Analyzer::Return::analyze - tolerates a raw hashref with no add_evidence method' => sub {
	require App::Test::Generator::Analyzer::Return;
	my $analyser = App::Test::Generator::Analyzer::Return->new;

	my $result;
	lives_ok {
		$result = $analyser->analyze({ source => 'sub foo { return $self->{name}; } ' });
	} 'analyze() does not die on a plain hashref with no add_evidence method';
	is($result, undef, 'analyze() still returns undef for a plain hashref');

	# 'body' key is also accepted, per the documented fallback order
	lives_ok {
		$analyser->analyze({ body => 'sub foo { return 1; }' });
	} 'analyze() also tolerates the body key fallback';

	done_testing();
};

# ==================================================================
# App::Test::Generator::Analyzer::SideEffect
#
# t/Analyzer-SideEffect.t already has a dedicated subtest proving
# performs_io/calls_external ignore keywords inside string literals
# and comments. mutates_self and mutates_globals had no equivalent
# protection: they matched against the raw $body instead of the
# string/comment-stripped $code_only, so a docstring merely
# mentioning "$self->{name} = ..." or "%ENV" falsely set those flags.
# This was a real bug (verified to misfire before the fix), not just
# a documentation gap, and has been corrected in the production code
# to match the same $code_only convention IO_PATTERN/EXEC_PATTERN
# already used.
# ==================================================================
subtest 'Analyzer::SideEffect::analyze - mutates_self ignores field-assignment text inside a string literal' => sub {
	require App::Test::Generator::Analyzer::SideEffect;
	my $analyser = App::Test::Generator::Analyzer::SideEffect->new;

	my $report = $analyser->analyze({
		body => q{sub foo { return "use $self->{name} = x in docs"; }},
	});
	is($report->{mutates_self}, 0,
		'field-assignment text inside a string literal does not set mutates_self');
	is_deeply($report->{mutation_fields}, [],
		'no mutation_fields captured from the string literal');

	done_testing();
};

subtest 'Analyzer::SideEffect::analyze - mutates_globals ignores global-variable text inside a string literal' => sub {
	require App::Test::Generator::Analyzer::SideEffect;
	my $analyser = App::Test::Generator::Analyzer::SideEffect->new;

	my $report = $analyser->analyze({
		body => q{sub foo { return "Set %ENV manually"; }},
	});
	is($report->{mutates_globals}, 0,
		'global-variable text inside a string literal does not set mutates_globals');

	done_testing();
};

# ==================================================================
# App::Test::Generator::CoverageGuidedFuzzer
#
# t/CoverageGuided_Fuzzer_unit.t already exhaustively covers new(),
# run(), corpus(), bugs(), save_corpus(), and load_corpus() against
# their documented API. The one POD-documented behaviour with no
# existing regression coverage is run()'s bug-filtering rule: a
# target_sub die is only recorded in bugs() when the input that
# triggered it is schema-valid (see run()'s POD Notes, added this
# session). Verify both halves of that rule with a deterministic
# seed: a target that always dies, fed integers constrained to
# [100,200], must record only in-range inputs as bugs even though
# some generated inputs (the int-boundary bias picks 0/-1/1) fall
# outside that range and are correctly discarded as expected failures.
# ==================================================================
subtest 'CoverageGuidedFuzzer::run - only records bugs for schema-valid input' => sub {
	require App::Test::Generator::CoverageGuidedFuzzer;

	my $fuzzer = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'integer', min => 100, max => 200 } },
		target_sub => sub { die "boom\n" },
		iterations => 30,
		seed       => 42,
	);
	$fuzzer->run();

	my @bugs = @{ $fuzzer->bugs() };
	ok(scalar(@bugs) > 0, 'at least one in-range die was recorded as a bug');
	ok(scalar(@bugs) < 30,
		'at least one out-of-range die was correctly NOT recorded as a bug');
	ok((!grep { $_->{input} < 100 || $_->{input} > 200 } @bugs),
		'every recorded bug input falls within the schema-declared min/max');

	done_testing();
};

# ==================================================================
# App::Test::Generator::Emitter::Perl
#
# TestStrategy.pm sets $plan{boundary_tests} when a method's schema
# carries non-empty _yamltest_hints, but _emit_method_tests() had no
# dispatch branch for that flag at all -- a $TEST_BOUNDARY constant
# was defined but never read. Methods planned for boundary testing
# silently got zero generated test code for it. Fixed by adding the
# dispatch line plus a new _emit_boundary_test() that emits one
# smoke-test block per boundary_values/invalid_inputs hint value.
# ==================================================================
subtest 'Emitter::Perl::emit - boundary_tests flag emits one block per hint value' => sub {
	require App::Test::Generator::Emitter::Perl;

	my $emitter = App::Test::Generator::Emitter::Perl->new(
		schema => {
			clamp => {
				_yamltest_hints => {
					boundary_values => [0, 255],
					invalid_inputs  => [-1],
				},
			},
		},
		plans   => { clamp => { boundary_tests => 1 } },
		package => 'My::Module',
	);
	my $code = $emitter->emit;

	like($code, qr/\$obj->clamp\(0\)/, 'boundary value 0 emitted');
	like($code, qr/\$obj->clamp\(255\)/, 'boundary value 255 emitted');
	like($code, qr/\$obj->clamp\(-1\)/, 'invalid_inputs value -1 emitted');

	done_testing();
};

subtest 'Emitter::Perl::emit - boundary_tests flag with no hint values emits nothing' => sub {
	require App::Test::Generator::Emitter::Perl;

	my $emitter = App::Test::Generator::Emitter::Perl->new(
		schema  => { clamp => { _yamltest_hints => {} } },
		plans   => { clamp => { boundary_tests => 1 } },
		package => 'My::Module',
	);
	my $code = $emitter->emit;

	unlike($code, qr/survives boundary input/,
		'no boundary block emitted when hints carry no concrete values');

	done_testing();
};

# ==================================================================
# App::Test::Generator::Exporter::YAML
#
# t/Exporter-YAML.t already covers the documented "non-hashref plan"
# and "missing/empty file" failure modes (including the
# Params::Validate::Strict undef-vs-absent quirk noted in CLAUDE.md).
# Two genuine gaps remain: an entirely undef (not merely wrong-type)
# plan, and a DumpFile-level write failure (bad directory) that
# propagates as YAML::XS's own die rather than a validate_strict error.
# ==================================================================
subtest 'Exporter::YAML::export - undef plan croaks as a missing required parameter' => sub {
	require App::Test::Generator::Exporter::YAML;
	my $exporter = bless {}, 'App::Test::Generator::Exporter::YAML';

	throws_ok { $exporter->export(undef, '/tmp/atg-unit-test-exporter.yaml') }
		qr/plan' is missing/,
		'undef plan croaks distinctly from a wrong-type plan';
};

subtest 'Exporter::YAML::export - unwritable directory propagates the DumpFile error' => sub {
	require App::Test::Generator::Exporter::YAML;
	my $exporter = bless {}, 'App::Test::Generator::Exporter::YAML';

	throws_ok { $exporter->export({ a => 1 }, '/no/such/dir/atg-unit-test.yaml') }
		qr/Can't open|No such file/,
		'write failure to a non-existent directory croaks with the underlying I/O error';
};

# ==================================================================
# App::Test::Generator::LCSAJ::Coverage
#
# t/LCSAJ-Coverage.t (white-box) covers the covered/not-covered
# annotation logic and the three "argument is missing" croaks, but
# never exercises the POD-documented "Croaks if any file cannot be
# read or written" failure mode for a file that is defined but does
# not actually exist/is not writable -- a behaviourally distinct
# path through _slurp()/the disabled-autodie open() in merge().
# ==================================================================
subtest 'LCSAJ::Coverage::merge - croaks when lcsaj_file does not exist on disk' => sub {
	require App::Test::Generator::LCSAJ::Coverage;

	throws_ok {
		App::Test::Generator::LCSAJ::Coverage::merge(
			'/no/such/lcsaj.json', '/no/such/hits.json', '/tmp/atg-unit-test-out.json',
		)
	}
		qr/Cannot read \/no\/such\/lcsaj\.json/,
		'nonexistent lcsaj_file croaks with the underlying read error';
};

subtest 'LCSAJ::Coverage::merge - croaks when out_file directory does not exist' => sub {
	require App::Test::Generator::LCSAJ::Coverage;
	require File::Temp;
	require File::Spec;
	require JSON::MaybeXS;

	my $dir   = File::Temp::tempdir(CLEANUP => 1);
	my $lcsaj = File::Spec->catfile($dir, 'l.json');
	my $hits  = File::Spec->catfile($dir, 'h.json');
	open my $lfh, '>', $lcsaj or die $!;
	print $lfh JSON::MaybeXS::encode_json([ { start => 1, end => 2 } ]);
	close $lfh;
	open my $hfh, '>', $hits or die $!;
	print $hfh JSON::MaybeXS::encode_json({});
	close $hfh;

	throws_ok {
		App::Test::Generator::LCSAJ::Coverage::merge($lcsaj, $hits, '/no/such/dir/out.json')
	}
		qr/Cannot write coverage output/,
		'unwritable out_file directory croaks with the underlying write error';
};

subtest 'Model::Method::add_evidence - returns undef, not the push count' => sub {
	require App::Test::Generator::Model::Method;
	my $m = App::Test::Generator::Model::Method->new(
		name => 'test_method', source => 'sub test_method { return 1; }',
	);
	my $ret = $m->add_evidence(category => 'return', signal => 'returns_self');
	is($ret, undef, 'add_evidence returns undef in scalar context');
	done_testing();
};

subtest 'Model::Method::resolve_return_type - alphabetical tie-break with no evidence is constant' => sub {
	require App::Test::Generator::Model::Method;
	my $m = App::Test::Generator::Model::Method->new(
		name => 'test_method', source => 'sub test_method { return 1; }',
	);
	is($m->resolve_return_type, 'constant',
		"3-way tie at weight 0 breaks alphabetically: 'constant' < 'object' < 'property'");
	done_testing();
};

subtest 'Mutant::context and Mutant::line_content - stored and returned correctly' => sub {
	require App::Test::Generator::Mutant;
	my $mutant = App::Test::Generator::Mutant->new(
		id           => 'TEST_1_1_x',
		description  => 'Test mutation',
		original     => '>',
		line         => 10,
		transform    => sub { 1 },
		context      => 'conditional',
		line_content => 'if ($x > 0) { ... }',
	);
	is($mutant->context,      'conditional',          'context returned correctly');
	is($mutant->line_content, 'if ($x > 0) { ... }',  'line_content returned correctly');
	done_testing();
};

subtest 'Mutant::context and Mutant::line_content - default to undef when not supplied' => sub {
	require App::Test::Generator::Mutant;
	my $mutant = App::Test::Generator::Mutant->new(
		id          => 'TEST_1_1_x',
		description => 'Test mutation',
		original    => '>',
		line        => 10,
		transform   => sub { 1 },
	);
	is($mutant->context,      undef, 'context undef when not supplied');
	is($mutant->line_content, undef, 'line_content undef when not supplied');
	done_testing();
};

require App::Test::Generator::Mutation::BooleanNegation;
require App::Test::Generator::Mutation::ReturnUndef;

for my $class (qw(
	App::Test::Generator::Mutation::BooleanNegation
	App::Test::Generator::Mutation::ReturnUndef
)) {
	subtest "${class}::mutate - sets context to 'statement' for a top-level return" => sub {
		require PPI;
		my $m   = $class->new;
		my $doc = PPI::Document->new(\"sub foo {\n\treturn \$x;\n}\n");
		my @mutants = $m->mutate($doc);
		is(scalar(@mutants), 1, 'one mutant produced');
		is($mutants[0]->context, 'statement', 'context is statement for a top-level return');
		done_testing();
	};

	subtest "${class}::mutate - sets context to 'conditional' for a return inside if" => sub {
		require PPI;
		my $m   = $class->new;
		my $doc = PPI::Document->new(\"sub foo {\n\tif(\$x) { return \$y; }\n}\n");
		my @mutants = $m->mutate($doc);
		is(scalar(@mutants), 1, 'one mutant produced');
		is($mutants[0]->context, 'conditional', 'context is conditional for a return inside if');
		done_testing();
	};

	subtest "${class}::mutate - sets line_content to the raw source text of the mutated line" => sub {
		require PPI;
		my $m   = $class->new;
		my $doc = PPI::Document->new(\"sub foo {\n\treturn \$x;\n}\n");
		my @mutants = $m->mutate($doc);
		is(scalar(@mutants), 1, 'one mutant produced');
		is($mutants[0]->line_content, "\treturn \$x;", 'line_content matches the source line verbatim');
		done_testing();
	};
}

require App::Test::Generator::Mutation::ConditionalInversion;

subtest 'Mutation::ConditionalInversion::mutate - context is always conditional, line_content matches the source line' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ConditionalInversion->new;
	my $doc = PPI::Document->new(\"sub foo {\n\tif(\$x) { return 1; }\n}\n");
	my @mutants = $m->mutate($doc);
	is(scalar(@mutants), 1, 'one mutant produced');
	is($mutants[0]->context, 'conditional', 'context is always conditional');
	is($mutants[0]->line_content, "\tif(\$x) { return 1; }", 'line_content matches the source line verbatim');
	done_testing();
};

require App::Test::Generator::Mutation::NumericBoundary;

subtest 'Mutation::NumericBoundary::mutate - context is conditional for an operator inside if' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::NumericBoundary->new;
	my $doc = PPI::Document->new(\"sub foo {\n\tif(\$x > 0) { return 1; }\n}\n");
	my @mutants = $m->mutate($doc);
	is(scalar(@mutants), 3, 'three mutants produced for the > operator');
	is($mutants[0]->context, 'conditional', 'context is conditional for an operator inside if');
	is($mutants[0]->line_content, "\tif(\$x > 0) { return 1; }", 'line_content matches the source line verbatim');
	done_testing();
};

subtest 'Mutation::NumericBoundary::mutate - context is expression for a top-level comparison' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::NumericBoundary->new;
	my $doc = PPI::Document->new(\"sub foo {\n\t\$x > 0;\n}\n");
	my @mutants = $m->mutate($doc);
	is(scalar(@mutants), 3, 'three mutants produced for the > operator');
	is($mutants[0]->context, 'expression', 'context is expression outside any conditional');
	done_testing();
};

# Black-box per the POD: run_tests() returns 1 if all tests passed
# (mutant survived), 0 if any test failed (mutant killed).
subtest 'Mutator::run_tests - returns true/false per the underlying test run exit status' => sub {
	my ($fh, $src_file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} "package RunTestsUnitTarget;\nsub f { return 1; }\n1;\n";
	close $fh;

	my $m = App::Test::Generator::Mutator->new(file => $src_file);

	local $REAL_SYSTEM_HOOK = sub { return 0 };
	ok($m->run_tests(), 'run_tests() returns true (mutant survived) when the test run exits 0');

	$REAL_SYSTEM_HOOK = sub { return 256 };
	ok(!$m->run_tests(), 'run_tests() returns false (mutant killed) when the test run exits non-zero');

	done_testing();
};

require App::Test::Generator::Planner;

subtest 'Planner::new - croaks when schemas argument is missing' => sub {
	throws_ok(
		sub { App::Test::Generator::Planner->new(package => 'Foo') },
		qr/schemas required/,
		'new() croaks with the documented message when schemas is missing',
	);
	done_testing();
};

subtest 'Planner::new - croaks when package argument is missing' => sub {
	throws_ok(
		sub { App::Test::Generator::Planner->new(schemas => {}) },
		qr/package required/,
		'new() croaks with the documented message when package is missing',
	);
	done_testing();
};

require App::Test::Generator::SchemaExtractor;

# ==================================================================
# SchemaExtractor::extract_all - documented "always included"
# override for _new/_init/_build-prefixed private methods. The POD
# describes this as a prefix match (not an exact-name match), since
# it exists to catch Moose-style builder/initializer methods such as
# _build_attribute or _init_logger, not just the literal names
# _new/_init/_build.
# ==================================================================
subtest 'SchemaExtractor::extract_all - _new/_init/_build-prefixed methods are always included' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $src = File::Spec->catfile($dir, 'AlwaysIncluded.pm');
	open(my $fh, '>', $src) or die "Cannot write $src: $!";
	print {$fh} <<'PERL';
package AlwaysIncluded;

=head2 _build_widget

=cut

sub _build_widget { return 1; }

=head2 _other_private

=cut

sub _other_private { return 1; }

1;
PERL
	close $fh;

	my $extractor = App::Test::Generator::SchemaExtractor->new(input_file => $src);
	my $schemas   = $extractor->extract_all(no_write => 1);

	ok(exists $schemas->{_build_widget},
		'_build_widget is included even though include_private is off, via the _build prefix override');
	ok(!exists $schemas->{_other_private},
		'_other_private (no qualifying prefix) is excluded when include_private is off');

	done_testing();
};

# ==================================================================
# SchemaExtractor::extract_all - duplicate method name handling.
# The second definition of a method overwrites neither the schema
# nor a stale entry -- it is dropped, with a warning logged under
# verbose mode, per _find_methods' documented dedup behaviour.
# ==================================================================
subtest 'SchemaExtractor::extract_all - duplicate method definitions are deduplicated with a verbose warning' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $src = File::Spec->catfile($dir, 'DupMethod.pm');
	open(my $fh, '>', $src) or die "Cannot write $src: $!";
	print {$fh} <<'PERL';
package DupMethod;

=head2 thing

=cut

sub thing { return 1; }

sub thing { return 2; }

1;
PERL
	close $fh;

	my $extractor = App::Test::Generator::SchemaExtractor->new(input_file => $src, verbose => 1);
	my $schemas;
	my $stdout = capture { $schemas = $extractor->extract_all(no_write => 1) };

	is_deeply([keys %$schemas], ['thing'], 'duplicate method name appears only once in the result');
	like($stdout, qr/WARNING: duplicate method 'thing' ignored/,
		'verbose mode logs the documented duplicate-method warning');

	done_testing();
};

# ==================================================================
# SchemaExtractor::extract_all - strict_pod enforcement against a
# real POD/code disagreement (not the synthetic hashes used by the
# white-box _validate_pod_code_agreement tests elsewhere): fatal mode
# croaks, warn mode only carps and continues, off mode does neither.
# ==================================================================
subtest 'SchemaExtractor::extract_all - strict_pod=2 (fatal) croaks on a real POD/code disagreement' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $src = File::Spec->catfile($dir, 'PodDisagreeFatal.pm');
	open(my $fh, '>', $src) or die "Cannot write $src: $!";
	print {$fh} <<'PERL';
package PodDisagreeFatal;

=head2 method_one

=head3 Arguments

=over 4

=item * C<$undocumented_in_code>

=back

=cut

sub method_one {
	my ($self, $foo) = @_;
	return $foo;
}

1;
PERL
	close $fh;

	my $extractor = App::Test::Generator::SchemaExtractor->new(input_file => $src, strict_pod => 2);
	throws_ok(
		sub { $extractor->extract_all(no_write => 1) },
		qr/\[POD STRICT\] POD\/Code disagreement in method 'method_one'/,
		'strict_pod=2 croaks immediately with the documented [POD STRICT] message',
	);

	done_testing();
};

subtest 'SchemaExtractor::extract_all - strict_pod=1 (warn) carps but still returns a populated schema' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $src = File::Spec->catfile($dir, 'PodDisagreeWarn.pm');
	open(my $fh, '>', $src) or die "Cannot write $src: $!";
	print {$fh} <<'PERL';
package PodDisagreeWarn;

=head2 method_one

=head3 Arguments

=over 4

=item * C<$undocumented_in_code>

=back

=cut

sub method_one {
	my ($self, $foo) = @_;
	return $foo;
}

1;
PERL
	close $fh;

	my $extractor = App::Test::Generator::SchemaExtractor->new(input_file => $src, strict_pod => 1);
	my $schemas;
	warning_like(
		sub { $schemas = $extractor->extract_all(no_write => 1) },
		qr/\[POD STRICT\] POD\/Code disagreement in method 'method_one'/,
		'strict_pod=1 carps with the documented [POD STRICT] message instead of croaking',
	);

	ok(exists $schemas->{method_one}, 'extraction completes and returns the method despite the disagreement');
	is($schemas->{method_one}{_pod_disagreement}, 1,
		'_pod_disagreement is set on the schema, per the documented Notes');

	done_testing();
};

# ==================================================================
# SchemaExtractor::extract_all - output_dir is created on demand
# when writing is enabled (the documented Side Effects behaviour),
# rather than requiring the caller to pre-create it.
# ==================================================================
subtest 'SchemaExtractor::extract_all - creates output_dir if it does not exist' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $src = File::Spec->catfile($dir, 'CreatesOutputDir.pm');
	open(my $fh, '>', $src) or die "Cannot write $src: $!";
	print {$fh} <<'PERL';
package CreatesOutputDir;

=head2 thing

=cut

sub thing { return 1; }

1;
PERL
	close $fh;

	my $output_dir = File::Spec->catdir($dir, 'does', 'not', 'exist', 'yet');
	ok(!-d $output_dir, 'output_dir does not exist before extract_all is called');

	my $extractor = App::Test::Generator::SchemaExtractor->new(input_file => $src, output_dir => $output_dir);
	$extractor->extract_all();

	ok(-d $output_dir, 'output_dir is created automatically when writing is enabled');
	ok(-f File::Spec->catfile($output_dir, 'thing.yml'), 'schema file is written into the newly created output_dir');

	done_testing();
};

# ==================================================================
# SchemaExtractor::generate_pod_validation_report - exact documented
# format: a "Method: $name" header, a "Severity:" line whose value
# is driven by _pod_disagreement (warning when truthy, fatal
# otherwise), and each error indented with "    - $error".
# ==================================================================
subtest 'SchemaExtractor::generate_pod_validation_report - exact Severity and indentation format' => sub {
	my $extractor = App::Test::Generator::SchemaExtractor->new(
		input_file => $0,	# any real file -- not parsed by this method
	);

	my $fatal_report = $extractor->generate_pod_validation_report({
		broken_method => {
			_pod_validation_errors => ["Parameter '\$x' documented in POD but not found in code signature"],
			# _pod_disagreement intentionally absent/false -- fatal mode never sets it
		},
	});
	like($fatal_report, qr/^Method: broken_method$/m, 'report includes the "Method: " header line');
	like($fatal_report, qr/^  Severity: fatal$/m,
		'Severity is "fatal" when _pod_disagreement is falsy, per the documented branching');
	like($fatal_report, qr/^    - Parameter '\$x' documented in POD but not found in code signature$/m,
		'each error is indented with exactly four spaces, a hyphen, and a space');

	my $warn_report = $extractor->generate_pod_validation_report({
		warned_method => {
			_pod_validation_errors => ['some disagreement'],
			_pod_disagreement      => 1,
		},
	});
	like($warn_report, qr/^  Severity: warning$/m,
		'Severity is "warning" when _pod_disagreement is truthy');

	done_testing();
};

subtest 'SchemaExtractor::generate_pod_validation_report - multiple methods are sorted by name' => sub {
	my $extractor = App::Test::Generator::SchemaExtractor->new(input_file => $0);

	my $report = $extractor->generate_pod_validation_report({
		zebra_method => { _pod_validation_errors => ['z error'] },
		alpha_method => { _pod_validation_errors => ['a error'] },
	});

	ok(index($report, 'Method: alpha_method') < index($report, 'Method: zebra_method'),
		'methods are reported in sorted (alpha before zebra) order, per the sort keys implementation');

	done_testing();
};

done_testing();
