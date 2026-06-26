#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird;
use File::Temp qw(tempdir);
use File::Spec;

# Black-box unit tests for App::Test::Generator::Mutator.
# Tests each public function according to its POD API specification.
# External dependencies (PPI, dircopy, prove) are mocked where needed.

BEGIN { use_ok('App::Test::Generator::Mutator') }

# --------------------------------------------------
# Helper: write a minimal .pm file and return its path
# --------------------------------------------------
sub _make_pm {
	my $src    = shift // "package TestModule;\nsub foo { return 1; }\n1;\n";
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib    = File::Spec->catdir($tmpdir, 'lib');
	mkdir $lib or die "Cannot mkdir $lib: $!";
	my $pm = File::Spec->catfile($lib, 'TestModule.pm');
	open my $fh, '>', $pm or die $!;
	print $fh $src;
	close $fh;
	return ($pm, $lib, $tmpdir);
}

# ==================================================================
# new()
#
# POD spec:
#   Required: file (must exist on disk)
#   Optional: lib_dir (default 'lib'), mutation_level (default 'full')
#   Returns:  blessed hashref
#   Croaks:   when file is missing or does not exist
# ==================================================================

subtest 'new() returns a blessed Mutator object' => sub {
	my ($pm, $lib) = _make_pm();
	my $m = App::Test::Generator::Mutator->new(file => $pm, lib_dir => $lib);
	isa_ok($m, 'App::Test::Generator::Mutator');
};

subtest 'new() croaks when file argument is missing' => sub {
	throws_ok(
		sub { App::Test::Generator::Mutator->new() },
		qr/file required/,
		'missing file croaks',
	);
};

subtest 'new() croaks when file does not exist on disk' => sub {
	throws_ok(
		sub { App::Test::Generator::Mutator->new(file => '/no/such/file.pm') },
		qr/file not found/,
		'nonexistent file croaks',
	);
};

subtest 'new() defaults lib_dir to "lib"' => sub {
	my ($pm) = _make_pm();
	my $m = App::Test::Generator::Mutator->new(file => $pm);
	is($m->{lib_dir}, 'lib', 'lib_dir defaults to "lib"');
};

subtest 'new() defaults mutation_level to "full"' => sub {
	my ($pm) = _make_pm();
	my $m = App::Test::Generator::Mutator->new(file => $pm);
	is($m->{mutation_level}, 'full', 'mutation_level defaults to "full"');
};

subtest 'new() stores supplied lib_dir' => sub {
	my ($pm, $lib) = _make_pm();
	my $m = App::Test::Generator::Mutator->new(file => $pm, lib_dir => $lib);
	is($m->{lib_dir}, $lib, 'supplied lib_dir stored');
};

subtest 'new() stores supplied mutation_level' => sub {
	my ($pm, $lib) = _make_pm();
	my $m = App::Test::Generator::Mutator->new(
		file           => $pm,
		lib_dir        => $lib,
		mutation_level => 'fast',
	);
	is($m->{mutation_level}, 'fast', 'fast mutation_level stored');
};

subtest 'new() registers four mutation strategies' => sub {
	my ($pm, $lib) = _make_pm();
	my $m = App::Test::Generator::Mutator->new(file => $pm, lib_dir => $lib);
	is(scalar @{$m->{mutations}}, 4, 'four mutation strategies registered');
	for my $strategy (@{$m->{mutations}}) {
		isa_ok($strategy, 'App::Test::Generator::Mutation::Base',
			ref($strategy) . ' inherits from Base');
	}
};

subtest 'new() each call returns a distinct object' => sub {
	my ($pm, $lib) = _make_pm();
	my $m1 = App::Test::Generator::Mutator->new(file => $pm, lib_dir => $lib);
	my $m2 = App::Test::Generator::Mutator->new(file => $pm, lib_dir => $lib);
	isnt($m1, $m2, 'distinct objects returned');
};

# ==================================================================
# generate_mutants()
#
# POD spec:
#   Returns a list of Mutant objects.
#   In 'fast' mode, redundant/duplicate mutants are removed first.
#   Uses registered mutation strategies against the parsed document.
# ==================================================================

subtest 'generate_mutants() returns a list' => sub {
	my ($pm, $lib) = _make_pm();
	my $m = App::Test::Generator::Mutator->new(file => $pm, lib_dir => $lib);
	my @mutants;
	lives_ok(sub { @mutants = $m->generate_mutants() }, 'generate_mutants lives');
	ok(ref(\@mutants) eq 'ARRAY', 'returns a list');
};

subtest 'generate_mutants() returns Mutant objects' => sub {
	my ($pm, $lib) = _make_pm(
		"package TestModule;\nsub foo { if(\$x > 0) { return 1; } return 0; }\n1;\n"
	);
	my $m = App::Test::Generator::Mutator->new(file => $pm, lib_dir => $lib);
	my @mutants = $m->generate_mutants();
	for my $mutant (@mutants) {
		isa_ok($mutant, 'App::Test::Generator::Mutant');
		ok(defined $mutant->description, 'mutant has description');
		is(ref($mutant->transform), 'CODE', 'mutant has CODE transform');
	}
};

subtest 'generate_mutants() full mode returns all mutants' => sub {
	my ($pm, $lib) = _make_pm(
		"package TestModule;\nsub foo { if(\$x > 0) { return 1; } return 0; }\n1;\n"
	);
	my $full = App::Test::Generator::Mutator->new(
		file           => $pm,
		lib_dir        => $lib,
		mutation_level => 'full',
	);
	my $fast = App::Test::Generator::Mutator->new(
		file           => $pm,
		lib_dir        => $lib,
		mutation_level => 'fast',
	);
	my @full_mutants = $full->generate_mutants();
	my @fast_mutants = $fast->generate_mutants();
	ok(scalar @fast_mutants <= scalar @full_mutants,
		'fast mode count <= full mode count');
};

subtest 'generate_mutants() does not croak for bare module with no targets' => sub {
	my ($pm, $lib) = _make_pm(
		"package TestModule;\nsub foo { return 'hello'; }\n1;\n"
	);
	my $m = App::Test::Generator::Mutator->new(file => $pm, lib_dir => $lib);
	lives_ok(sub { $m->generate_mutants() },
		'no croak for module with no mutation targets');
};

# ==================================================================
# Regression: generate_mutants() never called applies_to() on any
# registered strategy before calling mutate() -- the pre-filter
# documented in Mutation::Base's POD was dead code. mutate() must
# now be skipped entirely for a strategy whose applies_to() says the
# document has nothing to mutate.
# ==================================================================
subtest 'generate_mutants() skips mutate() when applies_to() returns false' => sub {
	my ($pm, $lib) = _make_pm(
		"package TestModule;\nsub foo { if(\$x > 0) { return 1; } return 0; }\n1;\n"
	);
	my $m = App::Test::Generator::Mutator->new(file => $pm, lib_dir => $lib);

	my $mutate_called = 0;
	Test::Mockingbird::mock(
		'App::Test::Generator::Mutation::NumericBoundary',
		'applies_to',
		sub { return 0 },
	);
	Test::Mockingbird::mock(
		'App::Test::Generator::Mutation::NumericBoundary',
		'mutate',
		sub { $mutate_called++; return () },
	);

	$m->generate_mutants();
	is($mutate_called, 0, 'mutate() never called when applies_to() returns false');

	Test::Mockingbird::unmock('App::Test::Generator::Mutation::NumericBoundary', 'applies_to');
	Test::Mockingbird::unmock('App::Test::Generator::Mutation::NumericBoundary', 'mutate');
};

subtest 'generate_mutants() still calls mutate() when applies_to() returns true' => sub {
	my ($pm, $lib) = _make_pm(
		"package TestModule;\nsub foo { if(\$x > 0) { return 1; } return 0; }\n1;\n"
	);
	my $m = App::Test::Generator::Mutator->new(file => $pm, lib_dir => $lib);

	my $mutate_called = 0;
	Test::Mockingbird::mock(
		'App::Test::Generator::Mutation::NumericBoundary',
		'mutate',
		sub { $mutate_called++; return () },
	);

	$m->generate_mutants();
	ok($mutate_called > 0, 'mutate() called when applies_to() returns true');

	Test::Mockingbird::unmock('App::Test::Generator::Mutation::NumericBoundary', 'mutate');
};

# ==================================================================
# Regression: none of the four concrete Mutation::* strategies ever
# populated the context/line_content fields that
# Mutator::_is_redundant_mutation's fast-mode dedup checks depend on,
# so those checks were dead code for real, production-generated
# mutants. Each strategy must now set both fields.
# ==================================================================
subtest 'generate_mutants() populates context and line_content on real mutants' => sub {
	my ($pm, $lib) = _make_pm(
		"package TestModule;\nsub foo {\n\tif(\$x > 0) {\n\t\treturn 1;\n\t}\n\treturn 0;\n}\n1;\n"
	);
	my $m = App::Test::Generator::Mutator->new(file => $pm, lib_dir => $lib);
	my @mutants = $m->generate_mutants();

	ok(scalar(@mutants) > 0, 'mutants were generated for the fixture');

	for my $mutant (@mutants) {
		ok(defined $mutant->context, $mutant->id . ': context is defined');
		ok(defined $mutant->line_content, $mutant->id . ': line_content is defined');
		like($mutant->line_content, qr/\S/, $mutant->id . ': line_content is non-blank');
	}

	my @conditional = grep { $_->context eq 'conditional' } @mutants;
	ok(scalar(@conditional) > 0,
		'at least one mutant is correctly classified as context => conditional');
};

# ==================================================================
# prepare_workspace()
#
# POD spec:
#   Returns absolute path to a temporary directory.
#   Copies lib_dir tree into workspace.
#   Sets $self->{workspace} and $self->{relative}.
#   Croaks if dircopy fails.
# ==================================================================

subtest 'prepare_workspace() returns a path to an existing directory' => sub {
	my ($pm, $lib, $tmpdir) = _make_pm();
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;
	my $m = App::Test::Generator::Mutator->new(
		file    => File::Spec->catfile('lib', 'TestModule.pm'),
		lib_dir => 'lib',
	);
	my $workspace;
	eval { $workspace = $m->prepare_workspace() };
	my $err = $@;
	chdir $orig;
	is($err, '', 'prepare_workspace lives');
	ok(-d $workspace, 'returned path is an existing directory');
};

subtest 'prepare_workspace() sets $self->{workspace} and $self->{relative}' => sub {
	my ($pm, $lib, $tmpdir) = _make_pm();
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;
	my $m = App::Test::Generator::Mutator->new(
		file    => File::Spec->catfile('lib', 'TestModule.pm'),
		lib_dir => 'lib',
	);
	eval { $m->prepare_workspace() };
	chdir $orig;
	ok(defined $m->{workspace}, '$self->{workspace} set');
	ok(defined $m->{relative},  '$self->{relative} set');
};

subtest 'prepare_workspace() copies lib tree into workspace' => sub {
	my ($pm, $lib, $tmpdir) = _make_pm();
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;
	my $m = App::Test::Generator::Mutator->new(
		file    => File::Spec->catfile('lib', 'TestModule.pm'),
		lib_dir => 'lib',
	);
	my $workspace;
	eval { $workspace = $m->prepare_workspace() };
	chdir $orig;
	my $copied_lib = File::Spec->catdir($workspace, 'lib');
	ok(-d $copied_lib, 'lib dir copied into workspace');
	my $copied_pm = File::Spec->catfile($copied_lib, 'TestModule.pm');
	ok(-f $copied_pm, 'module file present in workspace');
};

# ==================================================================
# apply_mutant()
#
# POD spec:
#   Arguments: $mutant (Mutant object)
#   Returns:   nothing
#   Croaks:    when workspace not prepared
#   Side effect: overwrites target file in workspace
# ==================================================================

subtest 'apply_mutant() croaks when workspace not prepared' => sub {
	my ($pm, $lib) = _make_pm();
	my $m = App::Test::Generator::Mutator->new(file => $pm, lib_dir => $lib);
	my $stub = { description => 'stub', transform => sub {} };
	throws_ok(
		sub { $m->apply_mutant($stub) },
		qr/Workspace not prepared/,
		'croaks when workspace not prepared',
	);
};

subtest 'apply_mutant() modifies workspace copy not original' => sub {
	my ($pm, $lib, $tmpdir) = _make_pm();
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;
	my $rel_pm = File::Spec->catfile('lib', 'TestModule.pm');
	my $m = App::Test::Generator::Mutator->new(
		file    => $rel_pm,
		lib_dir => 'lib',
	);
	eval { $m->prepare_workspace() };

	# Read original source before mutation
	open my $fh, '<', $rel_pm or die $!;
	my $before = do { local $/; <$fh> };
	close $fh;

	require PPI;
	my $marker  = '# MUTATED';
	my $mutant  = App::Test::Generator::Mutant->new(
		id          => 'TEST_1',
		description => 'append marker',
		original    => '',
		line        => 1,
		transform   => sub {
			my ($doc) = @_;
			$doc->add_element(PPI::Token::Comment->new("$marker\n"));
		},
	);
	lives_ok(sub { $m->apply_mutant($mutant) }, 'apply_mutant lives');

	# Original file must be unchanged
	open my $after_fh, '<', $rel_pm or die $!;
	my $after = do { local $/; <$after_fh> };
	close $after_fh;
	chdir $orig;

	is($after, $before, 'original source file unchanged after apply_mutant');
};

subtest 'apply_mutant() transform is called with a PPI::Document' => sub {
	my ($pm, $lib, $tmpdir) = _make_pm();
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;
	my $rel_pm = File::Spec->catfile('lib', 'TestModule.pm');
	my $m = App::Test::Generator::Mutator->new(
		file    => $rel_pm,
		lib_dir => 'lib',
	);
	eval { $m->prepare_workspace() };

	my $received_doc;
	require PPI;
	my $mutant = App::Test::Generator::Mutant->new(
		id          => 'TEST_2',
		description => 'capture doc',
		original    => '',
		line        => 1,
		transform   => sub { $received_doc = $_[0] },
	);
	eval { $m->apply_mutant($mutant) };
	chdir $orig;

	ok(defined $received_doc, 'transform received a document');
	isa_ok($received_doc, 'PPI::Document', 'document is a PPI::Document');
};

done_testing();
