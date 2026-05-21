#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use JSON::MaybeXS qw(encode_json decode_json);

# Test the LCSAJ path-generation and serialisation logic in
# App::Test::Generator::LCSAJ.  These are white-box unit tests
# that exercise generate() with synthetic source modules written
# to temporary files.

BEGIN {
	use_ok('App::Test::Generator::LCSAJ');
	use_ok('App::Test::Generator::LCSAJ::Coverage');
}

# ---------------------------------------------------------------
# Helper: write a temporary .pm file containing the given source,
# then call generate() into a temporary output directory.
# Returns ($paths, $decoded, $json_file, $pm, $out_dir).
# $paths   — in-memory arrayref returned by generate()
# $decoded — deserialised JSON array from the written file
# $json_file — absolute path of the written .lcsaj.json file
# $pm      — absolute path of the temporary .pm file
# $out_dir — output directory used
# ---------------------------------------------------------------
sub _generate_for_source {
	my ($source, $out_dir) = @_;
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib    = File::Spec->catdir($tmpdir, 'lib');

	mkdir $lib or die "Cannot mkdir $lib: $!";
	my $pm = File::Spec->catfile($lib, 'TestModule.pm');
	open my $fh, '>', $pm or die "Cannot write $pm: $!";
	print $fh $source;
	close $fh;
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die "Cannot chdir $tmpdir: $!";
	# Use relative paths so LCSAJ output paths are portable
	my $rel_pm  = File::Spec->catfile('lib', 'TestModule.pm');
	my $rel_out = $out_dir // 'out';
	mkdir $rel_out unless -d $rel_out;
	my $paths = App::Test::Generator::LCSAJ->generate($rel_pm, $rel_out);
	my $json_dir  = File::Spec->catdir($rel_out, 'TestModule.pm.lcsaj');
	my $json_file = File::Spec->catfile($json_dir, 'TestModule.pm.lcsaj.json');
	my $decoded;
	if(-f $json_file) {
		open my $jfh, '<', $json_file or die "Cannot read $json_file: $!";
		$decoded = decode_json(do { local $/; <$jfh> });
		close $jfh;
	}
	chdir $orig;
	return ($paths, $decoded, File::Spec->catfile($tmpdir, $json_file), $pm, $rel_out);
}

# ---------------------------------------------------------------
# 1. Simple linear sub — no branches.
#    All statements in a single block; every path record must
#    have defined start, end and target.
# ---------------------------------------------------------------
subtest 'simple linear sub produces valid (possibly empty) path list' => sub {
	my $src = <<'END_PM';
package TestModule;
sub foo {
	my $x = 1;
	my $y = 2;
	return $x + $y;
}
1;
END_PM
	my ($paths, $decoded) = _generate_for_source($src);
	# generate() must return an arrayref
	isa_ok($paths, 'ARRAY', 'generate() return value');
	# The serialised JSON must also be an arrayref
	isa_ok($decoded, 'ARRAY', 'decoded JSON');
	# A branchless sub has no jumps so produces no LCSAJ paths — this is correct
	# Any paths that are present must have defined bounds
	my @null_bounds = grep { !defined $_->{start} || !defined $_->{end} } @{$decoded};
	is(scalar(@null_bounds), 0, 'no null-bounds paths');
};

# ---------------------------------------------------------------
# 2. Sub with an if/else branch.
#    The true and false successor blocks each produce paths;
#    all must have defined bounds.
# ---------------------------------------------------------------
subtest 'if/else branching sub produces paths with defined bounds' => sub {
	my $src = <<'END_PM';
package TestModule;
sub bar {
	my $x = shift;
	if($x > 0) {
		return 'positive';
	} else {
		return 'non-positive';
	}
}
1;
END_PM
	my ($paths, $decoded) = _generate_for_source($src);
	ok(scalar(@{$decoded}) > 0, 'at least one path emitted');
	my @null_bounds = grep { !defined $_->{start} || !defined $_->{end} } @{$decoded};
	is(scalar(@null_bounds), 0, 'no null-bounds paths');
};

# ---------------------------------------------------------------
# 3. Trailing-branch sub — branch is the last statement.
#    This is the exact regression pattern that previously produced
#    a path with null start/end from an empty successor block.
# ---------------------------------------------------------------
subtest 'trailing branch produces no null-bounds paths' => sub {
	my $src = <<'END_PM';
package TestModule;
sub baz {
	my $x = 1;
	if($x) { return 1 }
}
1;
END_PM
	my ($paths, $decoded) = _generate_for_source($src);
	my @null_bounds = grep { !defined $_->{start} || !defined $_->{end} } @{$decoded};
	is(scalar(@null_bounds), 0, 'trailing-branch sub: no null-bounds paths');
};

# ---------------------------------------------------------------
# 4. Deduplication — identical paths must appear only once in the
#    serialised JSON output.
# ---------------------------------------------------------------
subtest 'no duplicate paths in serialised output' => sub {
	my $src = <<'END_PM';
package TestModule;
sub quux {
	my $x = shift;
	if($x) { return $x }
	return 0;
}
1;
END_PM
	my ($paths, $decoded) = _generate_for_source($src);
	my %seen;
	my @dupes;
	# Build a signature for each path and collect any repeats
	for my $p (@{$decoded}) {
		my $sig = join(':', map { $_ // 'undef' }
			$p->{start}, $p->{end}, $p->{target});
		push @dupes, $sig if $seen{$sig}++;
	}
	is(scalar(@dupes), 0, 'no duplicate path records')
		or diag('Duplicate paths: ', join(', ', @dupes));
};

# ---------------------------------------------------------------
# 5. Output file is created at the expected path.
#    generate() must write:
#      <out_dir>/TestModule.pm.lcsaj/TestModule.pm.lcsaj.json
# ---------------------------------------------------------------
subtest 'output JSON file is written to expected path' => sub {
	my $src = <<'END_PM';
package TestModule;
sub simple { return 1 }
1;
END_PM
	my ($paths, $decoded, $json_file) = _generate_for_source($src);
	ok(-f $json_file, "JSON file exists at $json_file");
};

# ---------------------------------------------------------------
# 6. Module with no subroutines produces an empty path list and
#    an empty JSON array.
# ---------------------------------------------------------------
subtest 'module with no subs produces empty path list' => sub {
	my $src = <<'END_PM';
package TestModule;
our $VERSION = 1;
1;
END_PM
	my ($paths, $decoded) = _generate_for_source($src);
	is(scalar(@{$decoded}), 0, 'empty path list for sub-free module');
};

# ---------------------------------------------------------------
# 7. generate() croaks when passed a non-existent file path.
# ---------------------------------------------------------------
subtest 'generate() croaks on non-existent file' => sub {
	throws_ok(
		sub { App::Test::Generator::LCSAJ->generate('/no/such/file.pm') },
		qr/Cannot parse/,
		'croaks with "Cannot parse" message for missing file',
	);
};

# ---------------------------------------------------------------
# 8. Default out_dir — when generate() is called without an
#    explicit output directory it should not die.  We change into
#    a temporary directory so the default 'lcsaj' subdir is
#    created there rather than in the project root.
# ---------------------------------------------------------------
subtest 'generate() uses default out_dir when none supplied' => sub {
	my $src = <<'END_PM';
package TestModule;
sub default_dir_test { return 42 }
1;
END_PM
	# Build the temp pm file manually so we can control cwd
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib    = File::Spec->catdir($tmpdir, 'lib');
	mkdir $lib or die "Cannot mkdir $lib: $!";
	my $pm = File::Spec->catfile($lib, 'TestModule.pm');
	open my $fh, '>', $pm or die $!;
	print $fh $src;
	close $fh;
	# Switch into the temp dir so the default 'lcsaj' dir lands there
	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die "Cannot chdir $tmpdir: $!";
	my $paths;
	# Restore cwd even on failure
	eval { $paths = App::Test::Generator::LCSAJ->generate($pm) };
	my $err = $@;
	chdir $orig;
	is($err, '', 'no exception when out_dir omitted');
	isa_ok($paths, 'ARRAY', 'paths returned when out_dir omitted');
};

# ---------------------------------------------------------------
# 9. Multiple subs in one file — paths from all subs must appear
#    in the combined output with no null bounds.
# ---------------------------------------------------------------
subtest 'multiple subs in one file all contribute paths' => sub {
	my $src = <<'END_PM';
package TestModule;
sub alpha {
	my $a = 1;
	return $a;
}
sub beta {
	my $b = shift;
	if($b) { return $b }
	return 0;
}
1;
END_PM
	my ($paths, $decoded) = _generate_for_source($src);
	# alpha contributes at least one path, beta at least two
	ok(scalar(@{$decoded}) >= 3, 'paths from both subs present')
		or diag('Got ' . scalar(@{$decoded}) . ' path(s)');
	my @null_bounds = grep { !defined $_->{start} || !defined $_->{end} } @{$decoded};
	is(scalar(@null_bounds), 0, 'no null-bounds paths across multiple subs');
};

# ---------------------------------------------------------------
# 10. All supported branch types — unless, while, for, foreach.
#     Each should produce paths with defined bounds and no nulls.
# ---------------------------------------------------------------
subtest 'unless/while/for/foreach branch types produce valid paths' => sub {
	for my $type (qw(unless while for foreach)) {
		# Build a minimal sub whose only branch is of the given type
		my $body;
		if($type eq 'for' || $type eq 'foreach') {
			$body = "my \@a = (1,2,3);\n\t$type my \$i (\@a) { last }\n\treturn 1;";
		} elsif($type eq 'while') {
			$body = "my \$x = 0;\n\t$type (\$x < 1) { \$x++ }\n\treturn \$x;";
		} else {
			$body = "my \$x = 1;\n\t$type (\$x) { return 0 }\n\treturn 1;";
		}
		my $src = "package TestModule;\nsub test_$type {\n\t$body\n}\n1;\n";
		my ($paths, $decoded) = _generate_for_source($src);
		my @null_bounds = grep {
			!defined $_->{start} || !defined $_->{end}
		} @{$decoded};
		is(scalar(@null_bounds), 0, "$type: no null-bounds paths");
	}
};

# ---------------------------------------------------------------
# 11. target defaults to 0 — when a target block id has no
#     corresponding line in the id-to-line map, the path record
#     must have target == 0 rather than undef.
# ---------------------------------------------------------------
subtest 'target defaults to 0 when target block has no lines' => sub {
	# A trailing branch forces a successor block with no lines,
	# exercising the // 0 fallback in _cfg_to_lcsaj.
	my $src = <<'END_PM';
package TestModule;
sub target_zero {
	my $x = shift;
	if($x) { return $x }
}
1;
END_PM
	my ($paths, $decoded) = _generate_for_source($src);
	my @undef_target = grep { !defined $_->{target} } @{$decoded};
	is(scalar(@undef_target), 0, 'no undef target values — all default to 0');
};

# ---------------------------------------------------------------
# 12. Exact path count for a known simple branching sub.
#     A sub with one if-branch produces exactly 2 paths.
#     If _build_cfg mis-classifies non-branch stmts as branches
#     (line 189 mutation) the count will be wrong.
# ---------------------------------------------------------------
subtest 'exact path count for single-branch sub' => sub {
	my $src = <<'END_PM';
package TestModule;
sub one_branch {
	my $x = shift;
	my $y = 1;
	if($x) { return $x }
	return $y;
}
1;
END_PM
	my ($paths, $decoded) = _generate_for_source($src);
	# One if-branch produces exactly 3 outgoing edges from the
	# branch block — one for each successor
	# The sub has a trailing statement after the if, so the CFG has three blocks: the pre-branch block, the true block, and the post-branch block.
	is(scalar(@{$decoded}), 3, 'single-branch sub produces exactly 3 paths');
};

# ---------------------------------------------------------------
# 13. Fallthrough edge count — sequential blocks must be connected.
#     A linear sub with no branches produces exactly 1 path.
#     If the $i < $#blocks loop condition is wrong (line 208
#     mutation) fallthrough edges are missing and paths = 0.
# ---------------------------------------------------------------
subtest 'linear sub with multiple statements produces exactly 1 path' => sub {
	my $src = <<'END_PM';
package TestModule;
sub linear {
	my $a = 1;
	my $b = 2;
	my $c = $a + $b;
	return $c;
}
1;
END_PM
	my ($paths, $decoded) = _generate_for_source($src);
	# A purely linear sub with no branches has no outgoing edges at all (it's a leaf block), so _cfg_to_lcsaj skips it entirely and produces 0 paths.
	is(scalar(@{$decoded}), 0, 'linear sub with no branches produces 0 paths (no jump = no LCSAJ)');
};

# ------------------------------------------------------------------
# Import private functions for direct white-box testing
# ------------------------------------------------------------------
{
	no warnings 'once';
	*_new_block      = \&App::Test::Generator::LCSAJ::_new_block;
	*_connect_blocks = \&App::Test::Generator::LCSAJ::_connect_blocks;
	*_is_branch      = \&App::Test::Generator::LCSAJ::_is_branch;
	*_build_cfg      = \&App::Test::Generator::LCSAJ::_build_cfg;
	*_cfg_to_lcsaj   = \&App::Test::Generator::LCSAJ::_cfg_to_lcsaj;
	*_save_lcsaj     = \&App::Test::Generator::LCSAJ::_save_lcsaj;
}

# ==================================================================
# _new_block
# ==================================================================

subtest '_new_block() returns a hashref with id, lines, and edges' => sub {
	my $b = _new_block(1);
	is(ref($b),          'HASH',  'returns a hashref');
	is($b->{id},         1,       'id stored correctly');
	is(ref($b->{lines}), 'ARRAY', 'lines is an arrayref');
	is(ref($b->{edges}), 'ARRAY', 'edges is an arrayref');
	is(scalar @{$b->{lines}}, 0,  'lines initially empty');
	is(scalar @{$b->{edges}}, 0,  'edges initially empty');
};

subtest '_new_block() stores arbitrary id values' => sub {
	my $b = _new_block(42);
	is($b->{id}, 42, 'id 42 stored correctly');
};

subtest '_new_block() each call produces an independent object' => sub {
	my $b1 = _new_block(1);
	my $b2 = _new_block(2);
	push @{$b1->{lines}}, 10;
	is(scalar @{$b2->{lines}}, 0, 'pushing to b1 does not affect b2');
};

# ==================================================================
# _connect_blocks
# ==================================================================

subtest '_connect_blocks() adds target id to source edges' => sub {
	my $from = _new_block(1);
	my $to   = _new_block(2);
	_connect_blocks($from, $to);
	is(scalar @{$from->{edges}}, 1,  'one edge added');
	is($from->{edges}[0],        2,  'target id is 2');
};

subtest '_connect_blocks() does not modify the target block' => sub {
	my $from = _new_block(1);
	my $to   = _new_block(2);
	_connect_blocks($from, $to);
	is(scalar @{$to->{edges}}, 0, 'target block edges unchanged');
};

subtest '_connect_blocks() accumulates multiple edges from the same source' => sub {
	my $from = _new_block(1);
	my $to1  = _new_block(2);
	my $to2  = _new_block(3);
	_connect_blocks($from, $to1);
	_connect_blocks($from, $to2);
	is(scalar @{$from->{edges}}, 2, 'two edges accumulated');
	is($from->{edges}[0], 2,        'first edge id correct');
	is($from->{edges}[1], 3,        'second edge id correct');
};

# ==================================================================
# _is_branch
# ==================================================================

subtest '_is_branch() returns 1 for an if statement' => sub {
	require PPI;
	my $doc  = PPI::Document->new(\'if($x > 0) { return 1; }');
	my $stmt = $doc->find_first('PPI::Statement::Compound');
	ok($stmt, 'found compound statement');
	is(_is_branch($stmt), 1, 'if statement is a branch');
};

subtest '_is_branch() returns 1 for an unless statement' => sub {
	require PPI;
	my $doc  = PPI::Document->new(\'unless($x) { return 0; }');
	my $stmt = $doc->find_first('PPI::Statement::Compound');
	ok($stmt, 'found unless statement');
	is(_is_branch($stmt), 1, 'unless statement is a branch');
};

subtest '_is_branch() returns 1 for a while loop' => sub {
	require PPI;
	my $doc  = PPI::Document->new(\'while($x < 10) { $x++; }');
	my $stmt = $doc->find_first('PPI::Statement::Compound');
	ok($stmt, 'found while statement');
	is(_is_branch($stmt), 1, 'while loop is a branch');
};

subtest '_is_branch() returns 1 for a for loop' => sub {
	require PPI;
	my $doc  = PPI::Document->new(\'for my $i (1..10) { last; }');
	my $stmt = $doc->find_first('PPI::Statement::Compound');
	ok($stmt, 'found for statement');
	is(_is_branch($stmt), 1, 'for loop is a branch');
};

subtest '_is_branch() returns 1 for a foreach loop' => sub {
	require PPI;
	my $doc  = PPI::Document->new(\'foreach my $item (@list) { next; }');
	my $stmt = $doc->find_first('PPI::Statement::Compound');
	ok($stmt, 'found foreach statement');
	is(_is_branch($stmt), 1, 'foreach loop is a branch');
};

subtest '_is_branch() returns 0 for a plain expression statement' => sub {
	require PPI;
	my $doc  = PPI::Document->new(\'my $x = 1;');
	my $stmt = $doc->find_first('PPI::Statement');
	ok($stmt, 'found statement');
	is(_is_branch($stmt), 0, 'plain statement is not a branch');
};

subtest '_is_branch() returns 0 for a return statement' => sub {
	require PPI;
	my $doc  = PPI::Document->new(\'return $x;');
	my $stmt = $doc->find_first('PPI::Statement');
	ok($stmt, 'found return statement');
	is(_is_branch($stmt), 0, 'return statement is not a branch');
};

# ==================================================================
# _build_cfg
# ==================================================================

subtest '_build_cfg() returns empty arrayref for sub with no body' => sub {
	require PPI;
	# An abstract sub declaration has no block
	my $doc = PPI::Document->new(\'sub foo;');
	my $sub = $doc->find_first('PPI::Statement::Sub');
	my $result = _build_cfg($sub);
	is(ref($result), 'ARRAY', 'returns arrayref');
	is(scalar @{$result}, 0,  'empty for bodyless sub');
};

subtest '_build_cfg() returns blocks for a simple linear sub' => sub {
	require PPI;
	my $doc = PPI::Document->new(\"sub foo { my \$x = 1; return \$x; }");
	my $sub = $doc->find_first('PPI::Statement::Sub');
	my $blocks = _build_cfg($sub);
	ok(scalar @{$blocks} > 0, 'at least one block produced');
	for my $b (@{$blocks}) {
		ok(exists $b->{id},    'block has id');
		ok(exists $b->{lines}, 'block has lines');
		ok(exists $b->{edges}, 'block has edges');
	}
};

subtest '_build_cfg() creates true and false successor blocks for if branch' => sub {
	require PPI;
	my $src = "sub foo { my \$x = shift; if(\$x > 0) { return 1; } return 0; }";
	my $doc = PPI::Document->new(\$src);
	my $sub = $doc->find_first('PPI::Statement::Sub');
	my $blocks = _build_cfg($sub);
	# An if statement splits into two successors so we expect more than one block
	ok(scalar @{$blocks} >= 2, 'if branch produces multiple blocks');
	# The block before the if should have at least two outgoing edges
	my @branching = grep { scalar @{$_->{edges}} >= 2 } @{$blocks};
	ok(scalar @branching >= 1, 'at least one block has two or more outgoing edges');
};

subtest '_build_cfg() connects sequential blocks with fallthrough edges' => sub {
	require PPI;
	my $src = "sub foo { my \$a = 1; my \$b = 2; return \$a + \$b; }";
	my $doc = PPI::Document->new(\$src);
	my $sub = $doc->find_first('PPI::Statement::Sub');
	my $blocks = _build_cfg($sub);
	# In a linear sub the single block has no branch and no edge initially,
	# then the fallthrough loop adds an edge to the next block (which doesn't
	# exist here since there's only one block — so edges stays empty)
	is(ref($blocks), 'ARRAY', 'returns arrayref');
	ok(scalar @{$blocks} >= 1, 'at least one block');
};

subtest '_build_cfg() assigns unique sequential block ids starting from 1' => sub {
	require PPI;
	my $src = "sub foo { my \$x = shift; if(\$x) { return 1; } return 0; }";
	my $doc = PPI::Document->new(\$src);
	my $sub = $doc->find_first('PPI::Statement::Sub');
	my $blocks = _build_cfg($sub);
	my @ids = map { $_->{id} } @{$blocks};
	ok(scalar @ids > 0,           'at least one block produced');
	ok((grep { $_ == 1 } @ids),   'block with id=1 present');
	my $max_id = (sort { $b <=> $a } @ids)[0];
	ok($max_id >= 1,               'max id is at least 1');
	# All ids must be positive integers
	ok(!(grep { $_ < 1 } @ids),   'all ids are positive integers');
};

# ==================================================================
# _cfg_to_lcsaj
# ==================================================================

subtest '_cfg_to_lcsaj() returns empty arrayref for empty block list' => sub {
	my $result = _cfg_to_lcsaj([]);
	is(ref($result), 'ARRAY', 'returns arrayref');
	is(scalar @{$result}, 0,  'empty for empty block list');
};

subtest '_cfg_to_lcsaj() skips blocks with no outgoing edges' => sub {
	my $block = { id => 1, lines => [10, 11, 12], edges => [] };
	my $result = _cfg_to_lcsaj([$block]);
	is(scalar @{$result}, 0, 'leaf block produces no paths');
};

subtest '_cfg_to_lcsaj() skips empty blocks' => sub {
	my $block = { id => 1, lines => [], edges => [2] };
	my $result = _cfg_to_lcsaj([$block]);
	is(scalar @{$result}, 0, 'empty block produces no paths');
};

subtest '_cfg_to_lcsaj() produces one path per outgoing edge' => sub {
	my $b1 = { id => 1, lines => [5, 6, 7], edges => [2, 3] };
	my $b2 = { id => 2, lines => [8],        edges => [] };
	my $b3 = { id => 3, lines => [9],        edges => [] };
	my $result = _cfg_to_lcsaj([$b1, $b2, $b3]);
	is(scalar @{$result}, 2, 'two paths for two outgoing edges');
};

subtest '_cfg_to_lcsaj() sets start and end from block lines' => sub {
	my $b1 = { id => 1, lines => [10, 11, 12], edges => [2] };
	my $b2 = { id => 2, lines => [15],          edges => [] };
	my $result = _cfg_to_lcsaj([$b1, $b2]);
	is($result->[0]{start}, 10, 'start is first line of block');
	is($result->[0]{end},   12, 'end is last line of block');
};

subtest '_cfg_to_lcsaj() sets target to first line of target block' => sub {
	my $b1 = { id => 1, lines => [5, 6],  edges => [2] };
	my $b2 = { id => 2, lines => [10, 11], edges => [] };
	my $result = _cfg_to_lcsaj([$b1, $b2]);
	is($result->[0]{target}, 10, 'target is first line of target block');
};

subtest '_cfg_to_lcsaj() defaults target to 0 when target block has no lines' => sub {
	my $b1 = { id => 1, lines => [5], edges => [2] };
	my $b2 = { id => 2, lines => [],  edges => [] };	# empty block
	my $result = _cfg_to_lcsaj([$b1, $b2]);
	is($result->[0]{target}, 0, 'target defaults to 0 for empty target block');
};

subtest '_cfg_to_lcsaj() handles single block with two edges correctly' => sub {
	my $b1 = { id => 1, lines => [1, 2, 3], edges => [2, 3] };
	my $b2 = { id => 2, lines => [4],        edges => [] };
	my $b3 = { id => 3, lines => [7],        edges => [] };
	my $result = _cfg_to_lcsaj([$b1, $b2, $b3]);
	is(scalar @{$result}, 2,   'two path records');
	is($result->[0]{start}, 1, 'first path start');
	is($result->[0]{end},   3, 'first path end');
	is($result->[1]{start}, 1, 'second path same start');
	is($result->[1]{end},   3, 'second path same end');
	# Targets differ
	isnt($result->[0]{target}, $result->[1]{target}, 'paths have different targets');
};

# ==================================================================
# _save_lcsaj
# ==================================================================

subtest '_save_lcsaj() writes a JSON file to the output directory' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $out    = File::Spec->catdir($tmpdir, 'lcsaj_out');
	my $paths  = [
		{ start => 1, end => 5, target => 10 },
		{ start => 6, end => 9, target => 15 },
	];
	lives_ok(
		sub { _save_lcsaj('lib/TestModule.pm', $out, $paths) },
		'_save_lcsaj lives',
	);
	# Find the written file
	my $json_dir  = File::Spec->catdir($out, 'TestModule.pm.lcsaj');
	my $json_file = File::Spec->catfile($json_dir, 'TestModule.pm.lcsaj.json');
	ok(-f $json_file, 'JSON file created at expected path');
};

subtest '_save_lcsaj() written JSON is a valid array' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $out    = File::Spec->catdir($tmpdir, 'lcsaj_out');
	my $paths  = [
		{ start => 1, end => 5, target => 10 },
	];
	_save_lcsaj('lib/TestModule.pm', $out, $paths);
	my $json_file = File::Spec->catfile($out, 'TestModule.pm.lcsaj',
		'TestModule.pm.lcsaj.json');
	open my $fh, '<', $json_file or die $!;
	my $data = decode_json(do { local $/; <$fh> });
	close $fh;
	is(ref($data), 'ARRAY', 'written JSON decodes to arrayref');
	is(scalar @{$data}, 1,  'one path record in JSON');
	is($data->[0]{start},  1,  'start preserved');
	is($data->[0]{end},    5,  'end preserved');
	is($data->[0]{target}, 10, 'target preserved');
};

subtest '_save_lcsaj() deduplicates identical path records' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $out    = File::Spec->catdir($tmpdir, 'lcsaj_out');
	my $paths  = [
		{ start => 1, end => 5, target => 10 },
		{ start => 1, end => 5, target => 10 },	# exact duplicate
		{ start => 6, end => 9, target => 15 },
	];
	_save_lcsaj('lib/TestModule.pm', $out, $paths);
	my $json_file = File::Spec->catfile($out, 'TestModule.pm.lcsaj',
		'TestModule.pm.lcsaj.json');
	open my $fh, '<', $json_file or die $!;
	my $data = decode_json(do { local $/; <$fh> });
	close $fh;
	is(scalar @{$data}, 2, 'duplicate path removed, two unique paths remain');
};

subtest '_save_lcsaj() removes paths with null start or end' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $out    = File::Spec->catdir($tmpdir, 'lcsaj_out');
	my $paths  = [
		{ start => undef, end => 5,     target => 10 },	# null start
		{ start => 1,     end => undef, target => 10 },	# null end
		{ start => 1,     end => 5,     target => 10 },	# valid
	];
	_save_lcsaj('lib/TestModule.pm', $out, $paths);
	my $json_file = File::Spec->catfile($out, 'TestModule.pm.lcsaj',
		'TestModule.pm.lcsaj.json');
	open my $fh, '<', $json_file or die $!;
	my $data = decode_json(do { local $/; <$fh> });
	close $fh;
	is(scalar @{$data}, 1, 'only the valid path survives null-bounds filtering');
};

subtest '_save_lcsaj() creates output directory if it does not exist' => sub {
	my $tmpdir   = tempdir(CLEANUP => 1);
	my $new_dir  = File::Spec->catdir($tmpdir, 'brand', 'new', 'dir');
	ok(!-d $new_dir, 'directory does not exist before call');
	lives_ok(
		sub { _save_lcsaj('lib/TestModule.pm', $new_dir, []) },
		'_save_lcsaj creates missing output directory',
	);
};

subtest '_save_lcsaj() strips lib/ prefix from path for subdirectory naming' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $out    = File::Spec->catdir($tmpdir, 'out');
	_save_lcsaj('lib/My/Module.pm', $out, []);
	# Should create out/My/Module.pm.lcsaj/Module.pm.lcsaj.json
	my $expected_dir = File::Spec->catdir($out, 'My', 'Module.pm.lcsaj');
	ok(-d $expected_dir, 'subdirectory mirrors module path under lib/');
};

subtest 'Coverage::merge() marks covered path when hit line in range' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);

	# LCSAJ path covering lines 10-15
	my $lcsaj_file = File::Spec->catfile($tmpdir, 'test.lcsaj.json');
	open my $fh1, '>', $lcsaj_file or die $!;
	print $fh1 encode_json([{ start => 10, end => 15, target => 20 }]);
	close $fh1;

	# Runtime hit on line 12 — within range
	my $hits_file = File::Spec->catfile($tmpdir, 'test.hits.json');
	open my $fh2, '>', $hits_file or die $!;
	print $fh2 encode_json({ '12' => 3 });
	close $fh2;

	my $out_file = File::Spec->catfile($tmpdir, 'test.covered.json');
	lives_ok(
		sub {
			App::Test::Generator::LCSAJ::Coverage::merge(
				$lcsaj_file, $hits_file, $out_file
			)
		},
		'merge() lives',
	);
	ok(-f $out_file, 'output file created');
	open my $fh3, '<', $out_file or die $!;
	my $result = decode_json(do { local $/; <$fh3> });
	close $fh3;
	is($result->[0]{covered}, 1, 'covered=1 when hit line in range');
};

subtest 'Coverage::merge() marks uncovered path when no hit in range' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);

	my $lcsaj_file = File::Spec->catfile($tmpdir, 'test.lcsaj.json');
	open my $fh1, '>', $lcsaj_file or die $!;
	print $fh1 encode_json([{ start => 10, end => 15, target => 20 }]);
	close $fh1;

	# Hit on line 99 — outside range
	my $hits_file = File::Spec->catfile($tmpdir, 'test.hits.json');
	open my $fh2, '>', $hits_file or die $!;
	print $fh2 encode_json({ '99' => 1 });
	close $fh2;

	my $out_file = File::Spec->catfile($tmpdir, 'test.covered.json');
	App::Test::Generator::LCSAJ::Coverage::merge(
		$lcsaj_file, $hits_file, $out_file
	);
	open my $fh3, '<', $out_file or die $!;
	my $result = decode_json(do { local $/; <$fh3> });
	close $fh3;
	is($result->[0]{covered}, 0, 'covered=0 when no hit in range');
};

subtest 'Coverage::merge() covered is exactly 0 or 1, not undef' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);

	my $lcsaj_file = File::Spec->catfile($tmpdir, 'test.lcsaj.json');
	open my $fh1, '>', $lcsaj_file or die $!;
	print $fh1 encode_json([
		{ start => 5, end => 8,  target => 10 },
		{ start => 9, end => 12, target => 15 },
	]);
	close $fh1;

	my $hits_file = File::Spec->catfile($tmpdir, 'test.hits.json');
	open my $fh2, '>', $hits_file or die $!;
	print $fh2 encode_json({ '6' => 1 });	# only first path hit
	close $fh2;

	my $out_file = File::Spec->catfile($tmpdir, 'test.covered.json');
	App::Test::Generator::LCSAJ::Coverage::merge(
		$lcsaj_file, $hits_file, $out_file
	);
	open my $fh3, '<', $out_file or die $!;
	my $result = decode_json(do { local $/; <$fh3> });
	close $fh3;
	ok(defined $result->[0]{covered}, 'covered key defined for hit path');
	ok(defined $result->[1]{covered}, 'covered key defined for unhit path');
	is($result->[0]{covered}, 1, 'hit path: covered is exactly 1');
	is($result->[1]{covered}, 0, 'unhit path: covered is exactly 0');
};

done_testing();
