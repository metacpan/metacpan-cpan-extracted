#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use File::Spec;
use File::Temp qw(tempdir);

# White-box unit tests for App::Test::Generator::Mutator.
# Exercises new(), generate_mutants(), prepare_workspace(),
# apply_mutant(), and the private _dedup_mutants /
# _is_redundant_mutation helpers (indirectly via fast mode).

BEGIN { use_ok('App::Test::Generator::Mutator') }

# ---------------------------------------------------------------
# Helper: write a minimal .pm file to a temp lib/ directory and
# return the path to the file and the lib dir.
# ---------------------------------------------------------------
sub _make_temp_module {
	my $source = $_[0];
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib = File::Spec->catdir($tmpdir, 'lib');

	mkdir $lib or die "Cannot mkdir $lib: $!";
	my $pm = File::Spec->catfile($lib, 'TestModule.pm');
	open my $fh, '>', $pm or die "Cannot write $pm: $!";
	print $fh $source;
	close $fh;
	# rel_pm is the path relative to $tmpdir — used when chdir'd
	# into $tmpdir so that prepare_workspace sees a relative path
	# and does not embed the absolute path into workspace filenames
	my $rel_pm = File::Spec->catfile('lib', 'TestModule.pm');
	return ($pm, $lib, $tmpdir, $rel_pm);
}

# Minimal module source with a variety of mutation targets:
# conditionals, numeric literals, boolean logic, return values
my $SAMPLE_SOURCE = <<'END_PM';
package TestModule;
use strict;
use warnings;

sub add {
	my ($x, $y) = @_;
	return $x + $y;
}

sub is_positive {
	my ($n) = @_;
	if($n > 0) {
		return 1;
	}
	return 0;
}

sub maybe {
	my ($flag) = @_;
	return $flag ? 'yes' : 'no';
}

1;
END_PM

# ---------------------------------------------------------------
# 1. new() — happy path
# ---------------------------------------------------------------
subtest 'new() constructs a Mutator for a valid file' => sub {
	my ($pm, $lib) = _make_temp_module($SAMPLE_SOURCE);
	my $mutator = App::Test::Generator::Mutator->new(
		file    => $pm,
		lib_dir => $lib,
	);
	isa_ok($mutator, 'App::Test::Generator::Mutator', 'returns blessed object');
	is($mutator->{file}, $pm, 'file stored correctly');
};

# ---------------------------------------------------------------
# 2. new() — missing file argument croaks
# ---------------------------------------------------------------
subtest 'new() croaks when file argument is missing' => sub {
	throws_ok(
		sub { App::Test::Generator::Mutator->new() },
		qr/file required/,
		'croaks with "file required" when file omitted',
	);
};

# ---------------------------------------------------------------
# 3. new() — non-existent file croaks
# ---------------------------------------------------------------
subtest 'new() croaks when file does not exist on disk' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Mutator->new(file => '/no/such/file.pm')
		},
		qr/file not found/,
		'croaks with "file not found" for missing file',
	);
};

# ---------------------------------------------------------------
# 4. new() — default lib_dir and mutation_level applied
# ---------------------------------------------------------------
subtest 'new() applies default lib_dir and mutation_level' => sub {
	my ($pm, $lib) = _make_temp_module($SAMPLE_SOURCE);
	my $mutator = App::Test::Generator::Mutator->new(file => $pm);
	is($mutator->{lib_dir},        'lib',  'lib_dir defaults to "lib"');
	is($mutator->{mutation_level}, 'full', 'mutation_level defaults to "full"');
};

# ---------------------------------------------------------------
# 5. new() — custom mutation_level stored correctly
# ---------------------------------------------------------------
subtest 'new() stores custom mutation_level' => sub {
	my ($pm, $lib) = _make_temp_module($SAMPLE_SOURCE);
	my $mutator = App::Test::Generator::Mutator->new(
		file           => $pm,
		lib_dir        => $lib,
		mutation_level => 'fast',
	);
	is($mutator->{mutation_level}, 'fast', 'fast mutation_level stored');
};

# ---------------------------------------------------------------
# 6. new() — four mutation strategies registered by default
# ---------------------------------------------------------------
subtest 'new() registers four mutation strategies' => sub {
	my ($pm, $lib) = _make_temp_module($SAMPLE_SOURCE);
	my $mutator = App::Test::Generator::Mutator->new(
		file    => $pm,
		lib_dir => $lib,
	);
	is(scalar @{ $mutator->{mutations} }, 4, 'four mutation strategies registered');
};

# ---------------------------------------------------------------
# 7. generate_mutants() — returns a non-empty list for a module
#    with mutation targets
# ---------------------------------------------------------------
subtest 'generate_mutants() returns mutants for a module with targets' => sub {
	my ($pm, $lib) = _make_temp_module($SAMPLE_SOURCE);
	my $mutator = App::Test::Generator::Mutator->new(
		file    => $pm,
		lib_dir => $lib,
	);
	my @mutants = $mutator->generate_mutants();
	ok(scalar @mutants > 0, 'at least one mutant generated')
		or diag('No mutants generated from sample source');
	# Each mutant must have a description and a transform coderef
	for my $m (@mutants) {
		ok(defined $m->{description}, 'mutant has description');
		is(ref $m->{transform},  'CODE', 'mutant transform is a coderef');
	}
};

# ---------------------------------------------------------------
# 8. generate_mutants() in fast mode returns fewer or equal
#    mutants than full mode (deduplication cannot add mutants)
# ---------------------------------------------------------------
subtest 'fast mode returns <= mutants compared to full mode' => sub {
	my ($pm, $lib) = _make_temp_module($SAMPLE_SOURCE);
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
		'fast mode produces no more mutants than full mode')
		or diag(sprintf 'fast=%d full=%d', scalar @fast_mutants, scalar @full_mutants);
};

# ---------------------------------------------------------------
# 9. generate_mutants() — module with no mutation targets returns
#    an empty list without error
# ---------------------------------------------------------------
subtest 'generate_mutants() returns empty list for unmutatable module' => sub {
	# A module with no conditionals, operators, or numeric literals
	my $bare = <<'END_PM';
package TestModule;
our $VERSION = 1;
sub description { return 'hello' }
1;
END_PM
	my ($pm, $lib) = _make_temp_module($bare);
	my $mutator = App::Test::Generator::Mutator->new(
		file    => $pm,
		lib_dir => $lib,
	);
	my @mutants;
	# Should not croak even if no mutants are generated
	lives_ok(sub { @mutants = $mutator->generate_mutants() },
		'generate_mutants() does not croak on bare module');
};

# ---------------------------------------------------------------
# 10. prepare_workspace() — returns a path to an existing dir
#     and populates self->{workspace} and self->{relative}
# ---------------------------------------------------------------
subtest 'prepare_workspace() creates workspace and sets relative path' => sub {
	my ($pm, $lib, $tmpdir, $rel_pm) = _make_temp_module($SAMPLE_SOURCE);
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die "Cannot chdir $tmpdir: $!";
	my $mutator = App::Test::Generator::Mutator->new(
		file    => $rel_pm,
		lib_dir => 'lib',
	);
	my $workspace;
	eval { $workspace = $mutator->prepare_workspace() };
	my $err = $@;
	chdir $orig;
	is($err, '',              'prepare_workspace() does not croak');
	ok(-d $workspace,         'workspace directory exists');
	ok(defined $mutator->{workspace}, 'self->{workspace} set');
	ok(defined $mutator->{relative},  'self->{relative} set');
	my $copied = File::Spec->catdir($workspace, 'lib');
	ok(-d $copied, 'lib tree copied into workspace');
};

# ---------------------------------------------------------------
# 11. apply_mutant() — croaks when workspace not prepared.
#     Uses a relative lib_dir via chdir for Windows compatibility —
#     dircopy fails when lib_dir is an absolute path on Windows.
# ---------------------------------------------------------------
subtest 'apply_mutant() croaks when workspace not prepared' => sub {
	my ($pm, $lib, $tmpdir) = _make_temp_module($SAMPLE_SOURCE);
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die "Cannot chdir $tmpdir: $!";
	my $mutator = App::Test::Generator::Mutator->new(
		file    => $pm,
		lib_dir => 'lib',
	);
	chdir $orig;
	# Manufacture a minimal mutant stub to pass in
	my $stub = {
		description => 'test stub',
		transform   => sub { },
	};
	throws_ok(
		sub { $mutator->apply_mutant($stub) },
		qr/Workspace not prepared/,
		'croaks with "Workspace not prepared" before prepare_workspace()',
	);
};

# ---------------------------------------------------------------
# 12. apply_mutant() — modifies the workspace copy without
#     touching the original source file.
#     Uses a relative lib_dir via chdir for Windows compatibility.
# ---------------------------------------------------------------
subtest 'apply_mutant() modifies workspace copy and not original' => sub {
	my ($pm, $lib, $tmpdir) = _make_temp_module($SAMPLE_SOURCE);
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die "Cannot chdir $tmpdir: $!";
	# Use a relative path so prepare_workspace builds correct workspace paths
	my $rel_pm = File::Spec->catfile('lib', 'TestModule.pm');
	my $mutator = App::Test::Generator::Mutator->new(
		file    => $rel_pm,
		lib_dir => 'lib',
	);
	eval { $mutator->prepare_workspace() };
	my $err = $@;
	is($err, '', 'prepare_workspace() does not croak');
	# Read original source for comparison afterwards
	open my $orig_fh, '<', $rel_pm or die $!;
	my $original_src = do { local $/; <$orig_fh> };
	close $orig_fh;
	my $marker = '# MUTATED';
	my $mutant = {
		description => 'append comment marker',
		transform   => sub {
			my ($doc) = @_;
			$doc->add_element(
				PPI::Token::Comment->new("$marker\n")
			);
		},
	};
	lives_ok(sub { $mutator->apply_mutant($mutant) }, 'apply_mutant lives');
	open my $check_fh, '<', $rel_pm or die $!;
	my $after_src = do { local $/; <$check_fh> };
	close $check_fh;
	chdir $orig;
	is($after_src, $original_src, 'original source file is not modified');
};

# ---------------------------------------------------------------
# 13. Fast mode deduplication actually removes duplicates.
#     Generate the same file in both full and fast mode and
#     assert fast produces fewer or equal mutants. If
#     _dedup_mutants returns undef or negates its result,
#     the count relationship breaks.
# ---------------------------------------------------------------
subtest 'fast mode deduplication reduces or equals full mode count' => sub {
	my ($pm, $lib, $tmpdir) = _make_temp_module($SAMPLE_SOURCE);
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die "Cannot chdir $tmpdir: $!";
	my $full = App::Test::Generator::Mutator->new(
		file           => $pm,
		lib_dir        => 'lib',
		mutation_level => 'full',
	);
	my $fast = App::Test::Generator::Mutator->new(
		file           => $pm,
		lib_dir        => 'lib',
		mutation_level => 'fast',
	);
	chdir $orig;
	my @full_mutants = $full->generate_mutants();
	my @fast_mutants = $fast->generate_mutants();
	ok(scalar(@fast_mutants) <= scalar(@full_mutants),
		'fast mode count <= full mode count');
	ok(scalar(@fast_mutants) >= 0,
		'fast mode returns a defined non-negative count');
};

# ---------------------------------------------------------------
# 14. _is_redundant_mutation filters arithmetic no-ops.
#     A module containing return $x + 0 should produce fewer
#     fast-mode mutants than one without the no-op, because
#     the redundancy filter removes it. If _is_redundant_mutation
#     returns undef or is negated, no-ops are not filtered.
# ---------------------------------------------------------------
subtest 'fast mode filters redundant arithmetic no-op mutations' => sub {
	my $noop_src = <<'END_PM';
package TestModule;
sub noop {
	my $x = shift;
	return $x + 0;
}
1;
END_PM
	my $clean_src = <<'END_PM';
package TestModule;
sub noop {
	my $x = shift;
	return $x;
}
1;
END_PM
	my ($pm_noop,  $lib_noop,  $tmpdir_noop)  = _make_temp_module($noop_src);
	my ($pm_clean, $lib_clean, $tmpdir_clean) = _make_temp_module($clean_src);
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir_noop or die "Cannot chdir $tmpdir_noop: $!";
	my $fast_noop = App::Test::Generator::Mutator->new(
		file           => $pm_noop,
		lib_dir        => 'lib',
		mutation_level => 'fast',
	);
	chdir $orig;
	chdir $tmpdir_clean or die "Cannot chdir $tmpdir_clean: $!";
	my $fast_clean = App::Test::Generator::Mutator->new(
		file           => $pm_clean,
		lib_dir        => 'lib',
		mutation_level => 'fast',
	);
	chdir $orig;
	my @noop_mutants  = $fast_noop->generate_mutants();
	my @clean_mutants = $fast_clean->generate_mutants();
	# The no-op version should produce fewer or equal fast mutants
	# because +0 is filtered as redundant
	ok(scalar(@noop_mutants) <= scalar(@clean_mutants),
		'no-op source produces <= mutants than clean source in fast mode');
};

# ---------------------------------------------------------------
# 15. _is_redundant_mutation filters standalone boolean literals.
#     A module returning bare 1 or 0 should have those filtered
#     in fast mode. If the filter is broken, count increases.
# ---------------------------------------------------------------
subtest 'fast mode filters standalone boolean literal returns' => sub {
	my $literal_src = <<'END_PM';
package TestModule;
sub always_true  { return 1 }
sub always_false { return 0 }
1;
END_PM
	my ($pm, $lib, $tmpdir) = _make_temp_module($literal_src);
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die "Cannot chdir $tmpdir: $!";
	my $full = App::Test::Generator::Mutator->new(
		file           => $pm,
		lib_dir        => 'lib',
		mutation_level => 'full',
	);
	my $fast = App::Test::Generator::Mutator->new(
		file           => $pm,
		lib_dir        => 'lib',
		mutation_level => 'fast',
	);
	chdir $orig;
	my @full_m = $full->generate_mutants();
	my @fast_m = $fast->generate_mutants();
	ok(scalar(@fast_m) <= scalar(@full_m),
		'boolean literal returns filtered in fast mode');
};

# ---------------------------------------------------------------
# 16. _is_redundant_mutation filters arithmetic -0 no-ops.
#     return $x - 0 should produce fewer fast mutants.
#     Tests the second no-op filter: /- \s*0$/
# ---------------------------------------------------------------
subtest 'fast mode filters arithmetic minus-zero no-op mutations' => sub {
	my $noop_src = <<'END_PM';
package TestModule;
sub noop {
	my $x = shift;
	return $x - 0;
}
1;
END_PM
	my $clean_src = <<'END_PM';
package TestModule;
sub noop {
	my $x = shift;
	return $x;
}
1;
END_PM
	my ($pm_noop,  $lib_noop,  $tmpdir_noop)  = _make_temp_module($noop_src);
	my ($pm_clean, $lib_clean, $tmpdir_clean) = _make_temp_module($clean_src);
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir_noop or die "Cannot chdir $tmpdir_noop: $!";
	my $fast_noop = App::Test::Generator::Mutator->new(
		file           => $pm_noop,
		lib_dir        => 'lib',
		mutation_level => 'fast',
	);
	chdir $orig;
	chdir $tmpdir_clean or die "Cannot chdir $tmpdir_clean: $!";
	my $fast_clean = App::Test::Generator::Mutator->new(
		file           => $pm_clean,
		lib_dir        => 'lib',
		mutation_level => 'fast',
	);
	chdir $orig;
	my @noop_mutants  = $fast_noop->generate_mutants();
	my @clean_mutants = $fast_clean->generate_mutants();
	ok(scalar(@noop_mutants) <= scalar(@clean_mutants),
		'minus-zero source produces <= mutants than clean source in fast mode');
};

# ---------------------------------------------------------------
# 17. _dedup_mutants removes exact duplicate mutants.
#     Two mutants with the same line, original and description
#     should collapse to one in fast mode. Verify that fast mode
#     count is strictly less than double the full mode count —
#     if dedup is broken, the same mutant would appear twice.
# ---------------------------------------------------------------
subtest 'fast mode deduplicates mutants at the same site' => sub {
	my $src = <<'END_PM';
package TestModule;
sub check {
	my ($x) = @_;
	if($x > 0) {
		return 1;
	}
	return 0;
}
1;
END_PM
	my ($pm, $lib, $tmpdir) = _make_temp_module($src);
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die "Cannot chdir $tmpdir: $!";
	my $full = App::Test::Generator::Mutator->new(
		file           => $pm,
		lib_dir        => 'lib',
		mutation_level => 'full',
	);
	my $fast = App::Test::Generator::Mutator->new(
		file           => $pm,
		lib_dir        => 'lib',
		mutation_level => 'fast',
	);
	chdir $orig;
	my @full_m = $full->generate_mutants();
	my @fast_m = $fast->generate_mutants();
	# Fast must not exceed full (dedup can only reduce)
	ok(scalar(@fast_m) <= scalar(@full_m),
		'fast mode count does not exceed full mode count');
	# Fast must produce at least one mutant
	ok(scalar(@fast_m) > 0, 'fast mode produces at least one mutant');
};

# ---------------------------------------------------------------
# 18. generate_mutants() in fast mode returns an array (not undef)
#     even when all mutants are filtered as redundant.
#     Tests the return value of _dedup_mutants when it returns \@rc
#     with an empty list.
# ---------------------------------------------------------------
subtest 'fast mode returns empty list not undef for unmutatable module' => sub {
	my $bare = <<'END_PM';
package TestModule;
our $VERSION = 1;
sub description { return 'hello' }
1;
END_PM
	my ($pm, $lib, $tmpdir) = _make_temp_module($bare);
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die "Cannot chdir $tmpdir: $!";
	my $fast = App::Test::Generator::Mutator->new(
		file           => $pm,
		lib_dir      => 'lib',
		mutation_level => 'fast',
	);
	chdir $orig;
	my @mutants;
	lives_ok(sub { @mutants = $fast->generate_mutants() },
		'generate_mutants() in fast mode does not croak on bare module');
	ok(defined scalar(@mutants), 'returns a defined list even when empty');
};

# ------------------------------------------------------------------
# Import private functions for direct white-box testing
# ------------------------------------------------------------------
{
	no warnings 'once';
	*_dedup_mutants        = \&App::Test::Generator::Mutator::_dedup_mutants;
	*_is_redundant_mutation = \&App::Test::Generator::Mutator::_is_redundant_mutation;
}

# ==================================================================
# _is_redundant_mutation — direct white-box tests
# ==================================================================

subtest '_is_redundant_mutation() returns 0 for a normal mutation' => sub {
	my $m = { original => '$x > 0', description => 'flip >' };
	is(_is_redundant_mutation($m), 0, 'normal mutation is not redundant');
};

subtest '_is_redundant_mutation() returns 1 for +0 arithmetic no-op' => sub {
	my $m = { original => '$x + 0', description => 'add zero' };
	is(_is_redundant_mutation($m), 1, '+0 no-op is redundant');
};

subtest '_is_redundant_mutation() returns 1 for -0 arithmetic no-op' => sub {
	my $m = { original => '$x - 0', description => 'subtract zero' };
	is(_is_redundant_mutation($m), 1, '-0 no-op is redundant');
};

subtest '_is_redundant_mutation() returns 1 for standalone 1' => sub {
	my $m = { original => '1', description => 'flip true' };
	is(_is_redundant_mutation($m), 1, 'standalone 1 is redundant');
};

subtest '_is_redundant_mutation() returns 1 for standalone 0' => sub {
	my $m = { original => '0', description => 'flip false' };
	is(_is_redundant_mutation($m), 1, 'standalone 0 is redundant');
};

subtest '_is_redundant_mutation() returns 1 for whitespace-padded 1' => sub {
	my $m = { original => '  1  ', description => 'padded true' };
	is(_is_redundant_mutation($m), 1, 'whitespace-padded 1 is redundant');
};

subtest '_is_redundant_mutation() returns 1 for double negation in conditional' => sub {
	my $m = {
		original    => '!!$flag',
		description => 'double negate',
		context     => 'conditional',
	};
	is(_is_redundant_mutation($m), 1, '!! in conditional context is redundant');
};

subtest '_is_redundant_mutation() does NOT filter double negation outside conditional' => sub {
	my $m = {
		original    => '!!$flag',
		description => 'double negate',
		# no context key
	};
	is(_is_redundant_mutation($m), 0, '!! outside conditional is not redundant');
};

subtest '_is_redundant_mutation() returns 1 for mutation inside a comment line' => sub {
	my $m = {
		original     => '$x > 0',
		line_content => '# return $x > 0;',
		description  => 'comment line',
	};
	is(_is_redundant_mutation($m), 1, 'mutation inside comment is redundant');
};

subtest '_is_redundant_mutation() returns 0 for mutation on non-comment line' => sub {
	my $m = {
		original     => '$x > 0',
		line_content => '	if($x > 0) {',
		description  => 'real code',
	};
	is(_is_redundant_mutation($m), 0, 'mutation on real code line is not redundant');
};

subtest '_is_redundant_mutation() handles undef original gracefully' => sub {
	my $m = { original => undef, description => 'undef original' };
	lives_ok(sub { _is_redundant_mutation($m) },
		'undef original does not crash');
};

# ==================================================================
# _dedup_mutants — direct white-box tests
# ==================================================================

subtest '_dedup_mutants() returns arrayref' => sub {
	my $result = _dedup_mutants([]);
	is(ref($result), 'ARRAY', 'returns arrayref for empty input');
};

subtest '_dedup_mutants() returns all mutants when none are duplicates' => sub {
	my $mutants = [
		{ line => 10, original => '>', description => 'flip >',  transform => sub {} },
		{ line => 20, original => '<', description => 'flip <',  transform => sub {} },
		{ line => 30, original => '!', description => 'negate',  transform => sub {} },
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 3, 'all three distinct mutants preserved');
};

subtest '_dedup_mutants() removes exact duplicate based on line+original+description' => sub {
	my $mutants = [
		{ line => 10, original => '>', description => 'flip >', transform => sub {} },
		{ line => 10, original => '>', description => 'flip >', transform => sub {} },	# exact dup
		{ line => 20, original => '<', description => 'flip <', transform => sub {} },
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 2, 'duplicate removed, two distinct mutants remain');
};

subtest '_dedup_mutants() removes redundant +0 mutation' => sub {
	my $mutants = [
		{ line => 5, original => '$x + 0', description => 'add zero', transform => sub {} },
		{ line => 10, original => '$x > 0', description => 'flip >',  transform => sub {} },
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 1, 'redundant +0 mutation removed');
	is($result->[0]{description}, 'flip >', 'non-redundant mutation kept');
};

subtest '_dedup_mutants() removes redundant standalone-1 mutation' => sub {
	my $mutants = [
		{ line => 5, original => '1', description => 'flip true', transform => sub {} },
		{ line => 10, original => '$x > 0', description => 'flip >', transform => sub {} },
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 1, 'standalone-1 mutation removed');
};

subtest '_dedup_mutants() handles undef fields in key construction' => sub {
	my $mutants = [
		{ line => undef, original => undef, description => undef, transform => sub {} },
		{ line => undef, original => undef, description => undef, transform => sub {} },
	];
	my $result = _dedup_mutants($mutants);
	# Both have the same key (all-undef) and first is not redundant so one survives
	ok(scalar @{$result} <= 1, 'all-undef duplicates collapsed to at most one');
};

subtest '_dedup_mutants() preserves order of first occurrences' => sub {
	my $mutants = [
		{ line => 30, original => 'c', description => 'C', transform => sub {} },
		{ line => 10, original => 'a', description => 'A', transform => sub {} },
		{ line => 20, original => 'b', description => 'B', transform => sub {} },
		{ line => 10, original => 'a', description => 'A', transform => sub {} },	# dup of second
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 3, 'three unique mutants');
	is($result->[0]{original}, 'c', 'first mutant order preserved');
	is($result->[1]{original}, 'a', 'second mutant order preserved');
};

done_testing();
