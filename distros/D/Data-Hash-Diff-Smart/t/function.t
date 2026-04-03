#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Scalar::Util qw(refaddr);

# ---------------------------------------------------------------------------
# Load the public interface
# ---------------------------------------------------------------------------

BEGIN {
	use_ok('Data::Hash::Diff::Smart', qw(
		diff
		diff_text
		diff_json
		diff_yaml
		diff_test2
	));
}

# ---------------------------------------------------------------------------
# Pull internal helpers into scope via the fully-qualified package name.
# Engine.pm is loaded transitively by Data::Hash::Diff::Smart.
# ---------------------------------------------------------------------------

# Convenience aliases so tests read cleanly
my $diff_fn          = \&Data::Hash::Diff::Smart::Engine::diff;
my $diff_scalar_fn   = \&Data::Hash::Diff::Smart::Engine::_diff_scalar;
my $diff_hash_fn     = \&Data::Hash::Diff::Smart::Engine::_diff_hash;
my $diff_array_fn    = \&Data::Hash::Diff::Smart::Engine::_diff_array;
my $diff_arr_index   = \&Data::Hash::Diff::Smart::Engine::_diff_array_index;
my $diff_arr_lcs     = \&Data::Hash::Diff::Smart::Engine::_diff_array_lcs;
my $diff_arr_unord   = \&Data::Hash::Diff::Smart::Engine::_diff_array_unordered;
my $normalize_ignore = \&Data::Hash::Diff::Smart::Engine::_normalize_ignore;
my $is_ignored       = \&Data::Hash::Diff::Smart::Engine::_is_ignored;
my $reftype_fn       = \&Data::Hash::Diff::Smart::Engine::_reftype;
my $eq_fn            = \&Data::Hash::Diff::Smart::Engine::_eq;
my $key_fn           = \&Data::Hash::Diff::Smart::Engine::_key;

# ---------------------------------------------------------------------------
# Helper: build a minimal $ctx as the engine does
# ---------------------------------------------------------------------------

sub make_ctx {
	my (%opts) = @_;
	return {
		ignore     => $normalize_ignore->($opts{ignore}),
		compare    => $opts{compare}    || {},
		array_mode => $opts{array_mode} || 'index',
		array_key  => $opts{array_key},
		seen       => {},
	};
}

# ===========================================================================
# SECTION 1: Public interface — Data::Hash::Diff::Smart
# ===========================================================================

subtest 'diff() - public entry point' => sub {

	subtest 'identical scalars' => sub {
		my $r = diff('hello', 'hello');
		is_deeply($r, [], 'same scalar → empty changes');
	};

	subtest 'changed scalar at root' => sub {
		my $r = diff('hello', 'world');
		is(scalar @$r, 1, 'one change');
		is($r->[0]{op},   'change', 'op is change');
		is($r->[0]{from}, 'hello',  'from is hello');
		is($r->[0]{to},   'world',  'to is world');
		is($r->[0]{path}, '',       'path is root');
	};

	subtest 'returns arrayref always' => sub {
		my $r = diff({a => 1}, {a => 1});
		isa_ok($r, 'ARRAY', 'return value');
	};

	subtest 'undef vs undef' => sub {
		my $r = diff(undef, undef);
		is_deeply($r, [], 'both undef → no changes');
	};

	subtest 'undef vs defined' => sub {
		my $r = diff(undef, 'x');
		is($r->[0]{op}, 'change', 'undef→defined is a change');
	};

	subtest 'type mismatch: hash vs array' => sub {
		my $r = diff({a => 1}, [1, 2]);
		is($r->[0]{op}, 'change', 'type mismatch is a change');
	};

	subtest 'type mismatch: scalar vs hash' => sub {
		my $r = diff('scalar', {a => 1});
		is($r->[0]{op}, 'change', 'scalar→hash is a change');
	};

	subtest 'ignore option: exact path suppressed' => sub {
		my $r = diff(
			{a => 1, b => 2},
			{a => 9, b => 2},
			ignore => ['/a'],
		);
		is_deeply($r, [], 'ignored path produces no changes');
	};

	subtest 'ignore option: regex' => sub {
		my $r = diff(
			{debug => 1, value => 'x'},
			{debug => 9, value => 'x'},
			ignore => [qr{^/debug$}],
		);
		is_deeply($r, [], 'regex ignore suppresses change');
	};

	subtest 'ignore option: wildcard' => sub {
		my $r = diff(
			{users => {alice => {score => 1}}},
			{users => {alice => {score => 9}}},
			ignore => ['/users/*/score'],
		);
		is_deeply($r, [], 'wildcard ignore suppresses nested change');
	};

	subtest 'compare option: custom comparator tolerates difference' => sub {
		my $r = diff(
			{price => 1.001},
			{price => 1.002},
			compare => { '/price' => sub { abs($_[0] - $_[1]) < 0.01 } },
		);
		is_deeply($r, [], 'custom comparator: values within tolerance = no change');
	};

	subtest 'compare option: custom comparator detects difference' => sub {
		my $r = diff(
			{price => 1.0},
			{price => 1.5},
			compare => { '/price' => sub { abs($_[0] - $_[1]) < 0.01 } },
		);
		is($r->[0]{op}, 'change', 'custom comparator: values outside tolerance = change');
	};

	subtest 'compare option: comparator exception is captured' => sub {
		my $r = diff(
			{x => 1},
			{x => 2},
			compare => { '/x' => sub { die "boom\n" } },
		);
		is($r->[0]{op}, 'change', 'comparator exception still records a change');
		like($r->[0]{error}, qr/boom/, 'error field contains exception message');
	};

	subtest 'cycle detection: does not loop infinitely' => sub {
		my $a = {x => 1};
		$a->{self} = $a;
		my $b = {x => 1};
		$b->{self} = $b;

		my $r;
		lives_ok(sub { $r = diff($a, $b) }, 'cycle detection: no infinite loop');
		isa_ok($r, 'ARRAY', 'result is still an arrayref after cycle');
	};

};

# ===========================================================================
# SECTION 2: diff_text()
# ===========================================================================

subtest 'diff_text()' => sub {

	subtest 'returns a string' => sub {
		my $t = diff_text({a => 1}, {a => 2});
		ok(defined $t,        'returns defined value');
		ok(!ref($t),          'returns a plain string');
		like($t, qr/\S/,      'non-empty for changed structures');
	};

	subtest 'no changes produces empty or whitespace-only output' => sub {
		my $t = diff_text({a => 1}, {a => 1});
		ok(defined $t, 'defined for identical structures');
		# Either empty string or whitespace is acceptable
		ok(!length($t) || $t =~ /^\s*$/, 'empty/whitespace for no changes');
	};

	subtest 'output mentions changed path' => sub {
		my $t = diff_text({user => {name => 'Alice'}}, {user => {name => 'Bob'}});
		like($t, qr/name|user/i, 'output references the changed field');
	};

};

# ===========================================================================
# SECTION 3: diff_json()
# ===========================================================================

subtest 'diff_json()' => sub {

	subtest 'returns valid JSON string' => sub {
		require JSON::MaybeXS;
		my $j = diff_json({a => 1}, {a => 2});
		ok(defined $j, 'returns a defined value');
		my $decoded = eval { JSON::MaybeXS::decode_json($j) };
		ok(!$@,        'output is valid JSON');
		isa_ok($decoded, 'ARRAY', 'decoded JSON is an array');
	};

	subtest 'JSON contains op field' => sub {
		require JSON::MaybeXS;
		my $j = diff_json({a => 1}, {a => 2});
		my $decoded = JSON::MaybeXS::decode_json($j);
		is($decoded->[0]{op}, 'change', 'first entry has op=change');
	};

	subtest 'JSON for identical structures' => sub {
		require JSON::MaybeXS;
		my $j = diff_json({a => 1}, {a => 1});
		my $decoded = JSON::MaybeXS::decode_json($j);
		is_deeply($decoded, [], 'empty JSON array for no changes');
	};

};

# ===========================================================================
# SECTION 4: diff_yaml()
# ===========================================================================

subtest 'diff_yaml()' => sub {

	subtest 'returns a YAML string' => sub {
		my $y = diff_yaml({a => 1}, {a => 2});
		ok(defined $y,     'returns a defined value');
		ok(!ref($y),       'returns a plain string');
		like($y, qr/\S/,   'non-empty for changed structures');
	};

	subtest 'YAML contains op key' => sub {
		my $y = diff_yaml({a => 1}, {a => 2});
		like($y, qr/op.*change|change.*op/s, 'YAML output mentions op: change');
	};

	subtest 'YAML for identical structures' => sub {
		my $y = diff_yaml({a => 1}, {a => 1});
		# An empty sequence in YAML is '--- []\n' or '--- \n- \n' etc.
		unlike($y, qr/op:/, 'no op entry in YAML for no changes');
	};

};

# ===========================================================================
# SECTION 5: diff_test2()
# ===========================================================================

subtest 'diff_test2()' => sub {

	subtest 'returns a string for changed structures' => sub {
		my $t = diff_test2({a => 1}, {a => 2});
		ok(defined $t, 'returns defined value');
		ok(!ref($t),   'returns a string');
		like($t, qr/\S/, 'non-empty for changes');
	};

	subtest 'returns something defined for identical structures' => sub {
		my $t = diff_test2({a => 1}, {a => 1});
		ok(defined $t, 'returns defined for identical structures');
	};

};

# ===========================================================================
# SECTION 5b: Renderer::Test2 - white-box unit tests
#
# We call the renderer directly with hand-crafted change lists so each
# branch of render() is exercised in isolation, independent of the diff
# engine.
# ===========================================================================

BEGIN { require Data::Hash::Diff::Smart::Renderer::Test2 }

my $render = \&Data::Hash::Diff::Smart::Renderer::Test2::render;

subtest 'Renderer::Test2::render()' => sub {

	# ------------------------------------------------------------------
	# Empty input
	# ------------------------------------------------------------------

	subtest 'empty changes list: returns empty string' => sub {
		my $out = $render->([]);
		is($out, '', 'empty arrayref -> empty string');
	};

	# ------------------------------------------------------------------
	# Every output line must start with "# "
	# ------------------------------------------------------------------

	subtest 'every non-empty line is prefixed with "# "' => sub {
		my $out = $render->([
			{ op => 'change', path => '/x', from => 1, to => 2 },
		]);
		my @lines = split /\n/, $out;
		my @bad = grep { length($_) && $_ !~ /^# / } @lines;
		is(scalar @bad, 0, 'all non-empty lines start with "# "')
			or diag "Offending lines: @bad";
	};

	subtest 'output ends with a newline' => sub {
		my $out = $render->([
			{ op => 'add', path => '/y', value => 'v' },
		]);
		like($out, qr/\n$/, 'output ends with newline');
	};

	# ------------------------------------------------------------------
	# op => 'change'
	# ------------------------------------------------------------------

	subtest 'change op: header line' => sub {
		my $out = $render->([
			{ op => 'change', path => '/user/name', from => 'Alice', to => 'Bob' },
		]);
		like($out, qr/^# Difference at \/user\/name$/m,
			'"Difference at <path>" line present');
	};

	subtest 'change op: from line with "  - " marker' => sub {
		my $out = $render->([
			{ op => 'change', path => '/x', from => 'old', to => 'new' },
		]);
		like($out, qr/^#   - old$/m, 'from line shows "  - old"');
	};

	subtest 'change op: to line with "  + " marker' => sub {
		my $out = $render->([
			{ op => 'change', path => '/x', from => 'old', to => 'new' },
		]);
		like($out, qr/^#   \+ new$/m, 'to line shows "  + new"');
	};

	subtest 'change op: blank separator line present' => sub {
		my $out = $render->([
			{ op => 'change', path => '/x', from => 1, to => 2 },
		]);
		like($out, qr/^# $/m, 'blank "# " separator line present after change block');
	};

	# ------------------------------------------------------------------
	# op => 'add'
	# ------------------------------------------------------------------

	subtest 'add op: header line' => sub {
		my $out = $render->([
			{ op => 'add', path => '/tags/2', value => 'admin' },
		]);
		like($out, qr/^# Added at \/tags\/2$/m, '"Added at <path>" line present');
	};

	subtest 'add op: value line with "  + " marker' => sub {
		my $out = $render->([
			{ op => 'add', path => '/tags/2', value => 'admin' },
		]);
		like($out, qr/^#   \+ admin$/m, 'value line shows "  + admin"');
	};

	subtest 'add op: blank separator line present' => sub {
		my $out = $render->([
			{ op => 'add', path => '/x', value => 'v' },
		]);
		like($out, qr/^# $/m, 'blank separator line present after add block');
	};

	# ------------------------------------------------------------------
	# op => 'remove'
	# ------------------------------------------------------------------

	subtest 'remove op: header line' => sub {
		my $out = $render->([
			{ op => 'remove', path => '/debug', from => 1 },
		]);
		like($out, qr/^# Removed at \/debug$/m, '"Removed at <path>" line present');
	};

	subtest 'remove op: from line with "  - " marker' => sub {
		my $out = $render->([
			{ op => 'remove', path => '/debug', from => 1 },
		]);
		like($out, qr/^#   - 1$/m, 'from line shows "  - 1"');
	};

	subtest 'remove op: blank separator line present' => sub {
		my $out = $render->([
			{ op => 'remove', path => '/x', from => 'gone' },
		]);
		like($out, qr/^# $/m, 'blank separator line present after remove block');
	};

	# ------------------------------------------------------------------
	# op => unknown
	# ------------------------------------------------------------------

	subtest 'unknown op: fallback line emitted' => sub {
		my $out = $render->([
			{ op => 'frobnicate', path => '/x' },
		]);
		like($out, qr/Unknown op 'frobnicate' at \/x/,
			'unknown op produces fallback message');
	};

	subtest 'unknown op: line is still prefixed with "# "' => sub {
		my $out = $render->([
			{ op => 'bogus', path => '/y' },
		]);
		like($out, qr/^# Unknown op/m, 'unknown op line is "# "-prefixed');
	};

	# ------------------------------------------------------------------
	# Multiple changes: ordering and separation
	# ------------------------------------------------------------------

	subtest 'multiple ops: all appear in output' => sub {
		my $out = $render->([
			{ op => 'change', path => '/a', from => 1,     to    => 2   },
			{ op => 'add',    path => '/b', value => 'new'              },
			{ op => 'remove', path => '/c', from  => 'old'              },
		]);
		like($out, qr/Difference at \/a/, 'change block present');
		like($out, qr/Added at \/b/,      'add block present');
		like($out, qr/Removed at \/c/,    'remove block present');
	};

	subtest 'multiple ops: change appears before add in output' => sub {
		my $out = $render->([
			{ op => 'change', path => '/a', from => 1, to => 2 },
			{ op => 'add',    path => '/b', value => 'x'       },
		]);
		my $pos_change = index($out, 'Difference at');
		my $pos_add    = index($out, 'Added at');
		ok($pos_change < $pos_add, 'change block precedes add block');
	};

	subtest 'multiple ops: each block separated by blank "# " line' => sub {
		my $out = $render->([
			{ op => 'add',    path => '/x', value => 1 },
			{ op => 'remove', path => '/y', from  => 2 },
		]);
		my @blanks = ($out =~ /^# $/mg);
		ok(scalar @blanks >= 2, 'at least two blank separator lines for two blocks');
	};

};

# ===========================================================================
# SECTION 5c: Renderer::Text - white-box unit tests
#
# Unlike Test2, the Text renderer has no "# " prefix, uses sigil-led lines
# (~, +, -) and a distinct unknown-op format.  Each branch and formatting
# detail is pinned directly via hand-crafted change lists.
# ===========================================================================

BEGIN { require Data::Hash::Diff::Smart::Renderer::Text }

my $render_text = \&Data::Hash::Diff::Smart::Renderer::Text::render;

subtest 'Renderer::Text::render()' => sub {

	# ------------------------------------------------------------------
	# Empty input
	# ------------------------------------------------------------------

	subtest 'empty changes list: returns empty string' => sub {
		my $out = $render_text->([]);
		is($out, '', 'empty arrayref -> empty string');
	};

	# ------------------------------------------------------------------
	# Global output invariants
	# ------------------------------------------------------------------

	subtest 'output ends with a newline' => sub {
		my $out = $render_text->([
			{ op => 'add', path => '/x', value => 'v' },
		]);
		like($out, qr/\n$/, 'output ends with newline');
	};

	subtest 'output lines are NOT prefixed with "# "' => sub {
		# Text renderer must not add the Test2 diagnostic prefix
		my $out = $render_text->([
			{ op => 'change', path => '/x', from => 1, to => 2 },
		]);
		unlike($out, qr/^# /m, 'no "# " prefix on any line');
	};

	# ------------------------------------------------------------------
	# op => 'change'
	# ------------------------------------------------------------------

	subtest 'change op: header line with "~ " sigil' => sub {
		my $out = $render_text->([
			{ op => 'change', path => '/user/name', from => 'Alice', to => 'Bob' },
		]);
		like($out, qr/^~ \/user\/name$/m, '"~ <path>" header line present');
	};

	subtest 'change op: from line with "- " sigil' => sub {
		my $out = $render_text->([
			{ op => 'change', path => '/x', from => 'old', to => 'new' },
		]);
		like($out, qr/^- old$/m, '"- old" from line present');
	};

	subtest 'change op: to line with "+ " sigil' => sub {
		my $out = $render_text->([
			{ op => 'change', path => '/x', from => 'old', to => 'new' },
		]);
		like($out, qr/^\+ new$/m, '"+ new" to line present');
	};

	subtest 'change op: blank separator line present' => sub {
		my $out = $render_text->([
			{ op => 'change', path => '/x', from => 1, to => 2 },
		]);
		like($out, qr/\n\n/, 'blank separator line present after change block');
	};

	subtest 'change op: three content lines before separator' => sub {
		# "~ path\n- from\n+ to\n\n" => splitting on \n gives exactly
		# [header, from, to, '', ...], i.e. four tokens before next block
		my $out = $render_text->([
			{ op => 'change', path => '/x', from => 'A', to => 'B' },
		]);
		my @lines = split /\n/, $out, -1;
		is($lines[0], '~ /x',  'first line is header');
		is($lines[1], '- A',   'second line is from');
		is($lines[2], '+ B',   'third line is to');
		is($lines[3], '',      'fourth line is blank separator');
	};

	# ------------------------------------------------------------------
	# op => 'add'
	# ------------------------------------------------------------------

	subtest 'add op: header line with "+ " sigil and path' => sub {
		# Unlike Test2, the Text renderer uses "+ $path" as the header,
		# not a prose "Added at" string.
		my $out = $render_text->([
			{ op => 'add', path => '/tags/2', value => 'admin' },
		]);
		like($out, qr/^\+ \/tags\/2$/m, '"+ <path>" header line present');
	};

	subtest 'add op: value line with "+ " sigil' => sub {
		my $out = $render_text->([
			{ op => 'add', path => '/tags/2', value => 'admin' },
		]);
		like($out, qr/^\+ admin$/m, '"+ <value>" line present');
	};

	subtest 'add op: blank separator line present' => sub {
		my $out = $render_text->([
			{ op => 'add', path => '/x', value => 'v' },
		]);
		like($out, qr/\n\n/, 'blank separator line present after add block');
	};

	subtest 'add op: two content lines before separator' => sub {
		my $out = $render_text->([
			{ op => 'add', path => '/p', value => 'V' },
		]);
		my @lines = split /\n/, $out, -1;
		is($lines[0], '+ /p', 'first line is "+ <path>"');
		is($lines[1], '+ V',  'second line is "+ <value>"');
		is($lines[2], '',     'third line is blank separator');
	};

	# ------------------------------------------------------------------
	# op => 'remove'
	# ------------------------------------------------------------------

	subtest 'remove op: header line with "- " sigil and path' => sub {
		my $out = $render_text->([
			{ op => 'remove', path => '/debug', from => 1 },
		]);
		like($out, qr/^- \/debug$/m, '"- <path>" header line present');
	};

	subtest 'remove op: from line with "- " sigil' => sub {
		my $out = $render_text->([
			{ op => 'remove', path => '/debug', from => 'gone' },
		]);
		like($out, qr/^- gone$/m, '"- <from>" line present');
	};

	subtest 'remove op: blank separator line present' => sub {
		my $out = $render_text->([
			{ op => 'remove', path => '/x', from => 'v' },
		]);
		like($out, qr/\n\n/, 'blank separator line present after remove block');
	};

	subtest 'remove op: two content lines before separator' => sub {
		my $out = $render_text->([
			{ op => 'remove', path => '/p', from => 'F' },
		]);
		my @lines = split /\n/, $out, -1;
		is($lines[0], '- /p', 'first line is "- <path>"');
		is($lines[1], '- F',  'second line is "- <from>"');
		is($lines[2], '',     'third line is blank separator');
	};

	# ------------------------------------------------------------------
	# op => unknown
	# ------------------------------------------------------------------

	subtest 'unknown op: fallback line format is "# unknown op: <op>"' => sub {
		my $out = $render_text->([
			{ op => 'frobnicate', path => '/x' },
		]);
		like($out, qr/^# unknown op: frobnicate$/m,
			'"# unknown op: <op>" line emitted');
	};

	subtest 'unknown op: does not contain path in fallback line' => sub {
		# The Text renderer's else branch only emits the op name, not the path
		my $out = $render_text->([
			{ op => 'bogus', path => '/should/not/appear' },
		]);
		unlike($out, qr/should\/not\/appear/,
			'path does not appear in unknown op fallback line');
	};

	subtest 'unknown op: no blank separator added' => sub {
		# The else branch pushes only one line with no trailing ''
		my $out = $render_text->([
			{ op => 'bogus', path => '/x' },
		]);
		# Only one \n at the end (the final join \n), no \n\n double-blank
		unlike($out, qr/\n\n/, 'no blank separator after unknown op');
	};

	# ------------------------------------------------------------------
	# Contrast with Test2 renderer: sigils not prose labels
	# ------------------------------------------------------------------

	subtest 'output contains no prose "Difference at" label' => sub {
		my $out = $render_text->([
			{ op => 'change', path => '/x', from => 1, to => 2 },
		]);
		unlike($out, qr/Difference at/, 'Text renderer uses sigils, not prose labels');
	};

	subtest 'output contains no prose "Added at" label' => sub {
		my $out = $render_text->([
			{ op => 'add', path => '/x', value => 'v' },
		]);
		unlike($out, qr/Added at/, 'Text renderer uses sigils, not prose labels');
	};

	subtest 'output contains no prose "Removed at" label' => sub {
		my $out = $render_text->([
			{ op => 'remove', path => '/x', from => 'v' },
		]);
		unlike($out, qr/Removed at/, 'Text renderer uses sigils, not prose labels');
	};

	# ------------------------------------------------------------------
	# Multiple changes: ordering and separation
	# ------------------------------------------------------------------

	subtest 'multiple ops: all appear in output' => sub {
		my $out = $render_text->([
			{ op => 'change', path => '/a', from => 1,     to    => 2   },
			{ op => 'add',    path => '/b', value => 'new'              },
			{ op => 'remove', path => '/c', from  => 'old'              },
		]);
		like($out, qr/^~ \/a$/m, 'change block present');
		like($out, qr/^\+ \/b$/m, 'add block present');
		like($out, qr/^- \/c$/m,  'remove block present');
	};

	subtest 'multiple ops: input order preserved in output' => sub {
		my $out = $render_text->([
			{ op => 'add',    path => '/first',  value => 1 },
			{ op => 'remove', path => '/second', from  => 2 },
		]);
		my $pos_add    = index($out, '+ /first');
		my $pos_remove = index($out, '- /second');
		ok($pos_add < $pos_remove, 'add block precedes remove block');
	};

	subtest 'multiple ops: blank separator between blocks' => sub {
		my $out = $render_text->([
			{ op => 'add',    path => '/x', value => 1 },
			{ op => 'remove', path => '/y', from  => 2 },
		]);
		# Two blocks with trailing '' each => at least two \n\n sequences
		my @blanks = ($out =~ /\n\n/g);
		ok(scalar @blanks >= 2, 'at least two blank separators for two blocks');
	};

};

# ===========================================================================
# SECTION 6: Engine::diff() - entry point
# ===========================================================================

subtest 'Engine::diff() - entry point' => sub {

	subtest 'returns arrayref' => sub {
		my $r = $diff_fn->({}, {});
		isa_ok($r, 'ARRAY');
	};

	subtest 'defaults array_mode to index' => sub {
		# [1,2] vs [2,1] in index mode should find two changes
		my $r = $diff_fn->([1, 2], [2, 1]);
		is(scalar @$r, 2, 'index mode: two element changes for reversal');
	};

	subtest 'accepts all three array_modes without dying' => sub {
		for my $mode (qw(index lcs unordered)) {
			lives_ok(
				sub { $diff_fn->([1, 2], [2, 1], array_mode => $mode) },
				"array_mode=$mode: no exception"
			);
		}
	};

	subtest 'unknown array_mode dies' => sub {
		throws_ok(
			sub { $diff_fn->([1], [1], array_mode => 'bogus') },
			qr/Unsupported array_mode/,
			'unknown array_mode throws',
		);
	};

};

# ===========================================================================
# SECTION 7: _diff_scalar()
# ===========================================================================

subtest '_diff_scalar()' => sub {

	subtest 'equal strings: no change recorded' => sub {
		my @changes;
		$diff_scalar_fn->('foo', 'foo', '/x', \@changes, make_ctx());
		is(scalar @changes, 0, 'equal strings: nothing pushed');
	};

	subtest 'different strings: change recorded' => sub {
		my @changes;
		$diff_scalar_fn->('foo', 'bar', '/x', \@changes, make_ctx());
		is(scalar @changes, 1, 'one change pushed');
		is($changes[0]{op},   'change', 'op=change');
		is($changes[0]{from}, 'foo',    'from=foo');
		is($changes[0]{to},   'bar',    'to=bar');
		is($changes[0]{path}, '/x',     'path preserved');
	};

	subtest 'undef vs undef: no change' => sub {
		my @changes;
		$diff_scalar_fn->(undef, undef, '/x', \@changes, make_ctx());
		is(scalar @changes, 0, 'both undef: no change');
	};

	subtest 'undef vs defined: change recorded' => sub {
		my @changes;
		$diff_scalar_fn->(undef, 'val', '/x', \@changes, make_ctx());
		is($changes[0]{op}, 'change', 'undef→defined: change');
	};

	subtest 'numeric equality: no change' => sub {
		my @changes;
		$diff_scalar_fn->(42, 42, '/n', \@changes, make_ctx());
		is(scalar @changes, 0, 'equal numbers: no change');
	};

	subtest 'custom comparator: same-path match' => sub {
		my @changes;
		my $ctx = make_ctx(compare => {
			'/price' => sub { abs($_[0] - $_[1]) < 0.01 }
		});
		$diff_scalar_fn->(1.001, 1.002, '/price', \@changes, $ctx);
		is(scalar @changes, 0, 'within tolerance: no change');
	};

	subtest 'custom comparator: exception captured in error field' => sub {
		my @changes;
		my $ctx = make_ctx(compare => {
			'/x' => sub { die "test error\n" }
		});
		$diff_scalar_fn->(1, 2, '/x', \@changes, $ctx);
		is($changes[0]{op}, 'change', 'comparator exception still produces change');
		like($changes[0]{error}, qr/test error/, 'error message captured');
	};

};

# ===========================================================================
# SECTION 8: _diff_hash()
# ===========================================================================

subtest '_diff_hash()' => sub {

	subtest 'identical hashes: no changes' => sub {
		my @changes;
		$diff_hash_fn->({a => 1, b => 2}, {a => 1, b => 2}, '', \@changes, make_ctx());
		is(scalar @changes, 0, 'identical hashes: nothing pushed');
	};

	subtest 'changed value: one change' => sub {
		my @changes;
		$diff_hash_fn->({a => 1}, {a => 2}, '', \@changes, make_ctx());
		is(scalar @changes, 1,        'one change');
		is($changes[0]{op}, 'change', 'op=change');
		like($changes[0]{path}, qr{/a}, 'path contains key name');
	};

	subtest 'key present in old only: remove' => sub {
		my @changes;
		$diff_hash_fn->({a => 1, b => 2}, {a => 1}, '', \@changes, make_ctx());
		is(scalar @changes, 1,         'one change');
		is($changes[0]{op}, 'remove',  'op=remove');
		is($changes[0]{from}, 2,       'from value is 2');
	};

	subtest 'key present in new only: add' => sub {
		my @changes;
		$diff_hash_fn->({a => 1}, {a => 1, b => 9}, '', \@changes, make_ctx());
		is(scalar @changes, 1,       'one change');
		is($changes[0]{op}, 'add',   'op=add');
		is($changes[0]{value}, 9,    'value is 9');
	};

	subtest 'empty hashes: no changes' => sub {
		my @changes;
		$diff_hash_fn->({}, {}, '', \@changes, make_ctx());
		is(scalar @changes, 0, 'both empty: no changes');
	};

	subtest 'old empty, new has keys: all adds' => sub {
		my @changes;
		$diff_hash_fn->({}, {x => 1, y => 2}, '', \@changes, make_ctx());
		is(scalar @changes, 2, 'two adds');
		my @non_adds = grep { $_->{op} ne 'add' } @changes;
		is(scalar @non_adds, 0, 'all ops are add');
	};

	subtest 'new empty, old has keys: all removes' => sub {
		my @changes;
		$diff_hash_fn->({x => 1, y => 2}, {}, '', \@changes, make_ctx());
		is(scalar @changes, 2, 'two removes');
		my @non_removes = grep { $_->{op} ne 'remove' } @changes;
		is(scalar @non_removes, 0, 'all ops are remove');
	};

	subtest 'nested hash: path constructed correctly' => sub {
		my @changes;
		$diff_hash_fn->(
			{user => {name => 'Alice'}},
			{user => {name => 'Bob'}},
			'', \@changes, make_ctx()
		);
		is(scalar @changes, 1, 'one nested change');
		is($changes[0]{path}, '/user/name', 'full nested path is correct');
	};

	subtest 'keys processed in sorted order' => sub {
		# We can verify by checking the order of the paths in @changes
		my @changes;
		$diff_hash_fn->(
			{z => 1, a => 2, m => 3},
			{z => 9, a => 9, m => 9},
			'', \@changes, make_ctx()
		);
		my @paths = map { $_->{path} } @changes;
		is_deeply(\@paths, [sort @paths], 'changes emitted in sorted key order');
	};

};

# ===========================================================================
# SECTION 9: _diff_array_index()
# ===========================================================================

subtest '_diff_array_index()' => sub {

	subtest 'identical arrays: no changes' => sub {
		my @changes;
		$diff_arr_index->([1,2,3], [1,2,3], '', \@changes, make_ctx());
		is(scalar @changes, 0, 'identical arrays: no changes');
	};

	subtest 'changed element: one change' => sub {
		my @changes;
		$diff_arr_index->([1,2,3], [1,9,3], '', \@changes, make_ctx());
		is(scalar @changes, 1, 'one change');
		is($changes[0]{from}, 2, 'from=2');
		is($changes[0]{to},   9, 'to=9');
		like($changes[0]{path}, qr{/1$}, 'path ends in index 1');
	};

	subtest 'new array longer: additions' => sub {
		my @changes;
		$diff_arr_index->([1], [1, 2, 3], '', \@changes, make_ctx());
		my @adds = grep { $_->{op} eq 'add' } @changes;
		is(scalar @adds, 2, 'two elements added');
	};

	subtest 'old array longer: removals' => sub {
		my @changes;
		$diff_arr_index->([1, 2, 3], [1], '', \@changes, make_ctx());
		my @removes = grep { $_->{op} eq 'remove' } @changes;
		is(scalar @removes, 2, 'two elements removed');
	};

	subtest 'both empty: no changes' => sub {
		my @changes;
		$diff_arr_index->([], [], '', \@changes, make_ctx());
		is(scalar @changes, 0, 'both empty arrays: no changes');
	};

	subtest 'path contains index' => sub {
		my @changes;
		$diff_arr_index->([10, 20], [10, 99], '/arr', \@changes, make_ctx());
		is($changes[0]{path}, '/arr/1', 'path is /arr/1');
	};

};

# ===========================================================================
# SECTION 10: _diff_array_lcs()
# ===========================================================================

subtest '_diff_array_lcs()' => sub {

	subtest 'identical arrays: no changes' => sub {
		my @changes;
		$diff_arr_lcs->([1,2,3], [1,2,3], '', \@changes, make_ctx());
		is(scalar @changes, 0, 'identical: no changes');
	};

	subtest 'insertion detected' => sub {
		my @changes;
		$diff_arr_lcs->([1,3], [1,2,3], '', \@changes, make_ctx());
		my @adds = grep { $_->{op} eq 'add' } @changes;
		is(scalar @adds, 1, 'one insertion');
		is($adds[0]{value}, 2, 'added value is 2');
	};

	subtest 'deletion detected' => sub {
		my @changes;
		$diff_arr_lcs->([1,2,3], [1,3], '', \@changes, make_ctx());
		my @removes = grep { $_->{op} eq 'remove' } @changes;
		is(scalar @removes, 1, 'one deletion');
		is($removes[0]{from}, 2, 'removed value is 2');
	};

	subtest 'old empty: all adds' => sub {
		my @changes;
		$diff_arr_lcs->([], [1,2,3], '', \@changes, make_ctx());
		ok(scalar @changes > 0, 'some changes when old is empty');
	};

	subtest 'new empty: all removes' => sub {
		my @changes;
		$diff_arr_lcs->([1,2,3], [], '', \@changes, make_ctx());
		my @removes = grep { $_->{op} eq 'remove' } @changes;
		ok(scalar @removes > 0, 'some removes when new is empty');
	};

	subtest 'no common elements: all replaced' => sub {
		my @changes;
		lives_ok(
			sub { $diff_arr_lcs->([1,2,3], [4,5,6], '', \@changes, make_ctx()) },
			'no common elements: does not die'
		);
		ok(scalar @changes > 0, 'changes produced when no common elements');
	};

};

# ===========================================================================
# SECTION 11: _diff_array_unordered()
# ===========================================================================

subtest '_diff_array_unordered()' => sub {

	subtest 'identical scalar arrays: no changes' => sub {
		my @changes;
		$diff_arr_unord->([qw(a b c)], [qw(c a b)], '', \@changes, make_ctx());
		is(scalar @changes, 0, 'same elements, different order: no changes');
	};

	subtest 'scalar addition detected' => sub {
		my @changes;
		$diff_arr_unord->([qw(a b)], [qw(a b c)], '', \@changes, make_ctx());
		my @adds = grep { $_->{op} eq 'add' } @changes;
		is(scalar @adds, 1, 'one element added');
	};

	subtest 'scalar removal detected' => sub {
		my @changes;
		$diff_arr_unord->([qw(a b c)], [qw(a b)], '', \@changes, make_ctx());
		my @removes = grep { $_->{op} eq 'remove' } @changes;
		is(scalar @removes, 1, 'one element removed');
	};

	subtest 'no HASH(0x...) in output for hash-ref elements (bug #1 regression)' => sub {
		# Before the fix, _key() stringified refs to their memory address,
		# producing HASH(0x...) tokens in the diff output and causing false
		# positives whenever two structurally identical hashrefs happened to
		# live at different addresses.  After the fix, _key() uses
		# Data::Dumper for structural keying, so this must never appear.
		my @changes;
		my $old = [{id => 1, name => 'Alice'}, {id => 2, name => 'Bob'}];
		my $new = [{id => 2, name => 'Bob'},   {id => 1, name => 'Alice'}];
		$diff_arr_unord->($old, $new, '', \@changes, make_ctx());

		my @addr = grep {
			   (defined $_->{value} && $_->{value} =~ /^HASH\(0x/)
			|| (defined $_->{from}  && $_->{from}  =~ /^HASH\(0x/)
		} @changes;

		is(scalar @addr, 0, 'no HASH(0x...) memory addresses in diff output');
	};

	subtest 'structurally equal hash-refs in different order: no changes (bug #1)' => sub {
		# Core of bug #1: without array_key, the fallback structural keying
		# (Data::Dumper) must still recognise that the two arrays contain the
		# same elements and report no changes.
		my @changes;
		my $old = [{id => 1, name => 'Alice'}, {id => 2, name => 'Bob'}];
		my $new = [{id => 2, name => 'Bob'},   {id => 1, name => 'Alice'}];
		$diff_arr_unord->($old, $new, '', \@changes, make_ctx());
		is(scalar @changes, 0,
			'reordered structurally equal hash-refs: no changes without array_key');
	};

	subtest 'array_key: reordered hash-refs produce no changes' => sub {
		my @changes;
		my $old = [{id => 1, name => 'Alice'}, {id => 2, name => 'Bob'}];
		my $new = [{id => 2, name => 'Bob'},   {id => 1, name => 'Alice'}];
		my $ctx = make_ctx(array_key => 'id');
		$diff_arr_unord->($old, $new, '', \@changes, $ctx);
		is(scalar @changes, 0, 'array_key mode: reorder only = no changes');
	};

	subtest 'array_key: real change detected' => sub {
		my @changes;
		my $old = [{id => 1, name => 'Alice'}, {id => 2, name => 'Bob'}];
		my $new = [{id => 2, name => 'Bob'},   {id => 1, name => 'Alicia'}];
		my $ctx = make_ctx(array_key => 'id');
		$diff_arr_unord->($old, $new, '', \@changes, $ctx);
		my @ch = grep { $_->{op} eq 'change' } @changes;
		ok(scalar @ch >= 1, 'array_key mode: name change detected');
	};

	subtest 'array_key: element added' => sub {
		my @changes;
		my $old = [{id => 1}];
		my $new = [{id => 1}, {id => 2, name => 'New'}];
		my $ctx = make_ctx(array_key => 'id');
		$diff_arr_unord->($old, $new, '', \@changes, $ctx);
		my @adds = grep { $_->{op} eq 'add' } @changes;
		is(scalar @adds, 1, 'array_key mode: addition detected');
	};

	subtest 'array_key: element removed' => sub {
		my @changes;
		my $old = [{id => 1}, {id => 2}];
		my $new = [{id => 1}];
		my $ctx = make_ctx(array_key => 'id');
		$diff_arr_unord->($old, $new, '', \@changes, $ctx);
		my @removes = grep { $_->{op} eq 'remove' } @changes;
		is(scalar @removes, 1, 'array_key mode: removal detected');
	};

	subtest 'duplicate scalars handled (multiset semantics)' => sub {
		my @changes;
		$diff_arr_unord->([qw(a a b)], [qw(a b b)], '', \@changes, make_ctx());
		my @adds    = grep { $_->{op} eq 'add'    } @changes;
		my @removes = grep { $_->{op} eq 'remove' } @changes;
		is(scalar @adds,    1, 'one b added');
		is(scalar @removes, 1, 'one a removed');
	};

};

# ===========================================================================
# SECTION 12: _normalize_ignore()
# ===========================================================================

subtest '_normalize_ignore()' => sub {

	subtest 'undef input: returns empty arrayref' => sub {
		my $r = $normalize_ignore->(undef);
		is_deeply($r, [], 'undef → []');
	};

	subtest 'exact string rule' => sub {
		my $r = $normalize_ignore->(['/foo/bar']);
		is(scalar @$r,       1,       'one rule');
		is($r->[0]{type},    'exact', 'type=exact');
		is($r->[0]{path},    '/foo/bar', 'path stored');
	};

	subtest 'regex rule' => sub {
		my $re = qr{^/debug};
		my $r  = $normalize_ignore->([$re]);
		is($r->[0]{type}, 'regex', 'type=regex');
		is($r->[0]{re},   $re,     'regex stored');
	};

	subtest 'wildcard rule' => sub {
		my $r = $normalize_ignore->(['/users/*/score']);
		is($r->[0]{type}, 'wildcard', 'type=wildcard');
		is_deeply($r->[0]{parts}, [qw(users * score)], 'parts split correctly');
	};

	subtest 'mixed rules' => sub {
		my $r = $normalize_ignore->(['/exact', qr{regex}, '/wild/*/card']);
		is(scalar @$r, 3, 'three rules normalized');
		is($r->[0]{type}, 'exact',    'first is exact');
		is($r->[1]{type}, 'regex',    'second is regex');
		is($r->[2]{type}, 'wildcard', 'third is wildcard');
	};

	subtest 'empty arrayref: returns empty arrayref' => sub {
		my $r = $normalize_ignore->([]);
		is_deeply($r, [], 'empty input → empty rules');
	};

};

# ===========================================================================
# SECTION 13: _is_ignored()
# ===========================================================================

subtest '_is_ignored()' => sub {

	subtest 'empty rules: never ignored' => sub {
		my $r = $is_ignored->('/anything', []);
		ok(!$r, 'empty rules: not ignored');
	};

	subtest 'exact match: ignored' => sub {
		my $rules = $normalize_ignore->(['/foo/bar']);
		ok( $is_ignored->('/foo/bar', $rules), 'exact match: ignored');
		ok(!$is_ignored->('/foo/baz', $rules), 'non-match: not ignored');
	};

	subtest 'regex match: ignored' => sub {
		my $rules = $normalize_ignore->([qr{^/debug}]);
		ok( $is_ignored->('/debug',    $rules), 'regex match: ignored');
		ok(!$is_ignored->('/nodebug',  $rules), 'non-match: not ignored');
	};

	subtest 'wildcard match: ignored' => sub {
		my $rules = $normalize_ignore->(['/users/*/score']);
		ok( $is_ignored->('/users/alice/score', $rules), 'wildcard match: ignored');
		ok(!$is_ignored->('/users/alice/name',  $rules), 'different leaf: not ignored');
		ok(!$is_ignored->('/users/alice',       $rules), 'shorter path: not ignored');
	};

	subtest 'wildcard: segment count must match exactly' => sub {
		my $rules = $normalize_ignore->(['/a/*/c']);
		ok(!$is_ignored->('/a/b/c/d', $rules), 'too many segments: not ignored');
		ok(!$is_ignored->('/a/b',     $rules), 'too few segments: not ignored');
	};

	subtest 'root path not ignored by non-matching exact rule' => sub {
		my $rules = $normalize_ignore->(['/foo']);
		ok(!$is_ignored->('', $rules), 'root path not matched by /foo');
	};

};

# ===========================================================================
# SECTION 14: _reftype()
# ===========================================================================

subtest '_reftype()' => sub {

	subtest 'non-reference returns undef' => sub {
		ok(!defined $reftype_fn->('scalar'), 'plain string → undef');
		ok(!defined $reftype_fn->(42),       'number → undef');
		ok(!defined $reftype_fn->(undef),    'undef → undef');
	};

	subtest 'hashref returns HASH' => sub {
		is($reftype_fn->({a => 1}), 'HASH', 'hashref → HASH');
	};

	subtest 'arrayref returns ARRAY' => sub {
		is($reftype_fn->([1,2,3]), 'ARRAY', 'arrayref → ARRAY');
	};

	subtest 'scalarref returns SCALAR' => sub {
		my $s = \"hello";
		is($reftype_fn->($s), 'SCALAR', 'scalarref → SCALAR');
	};

	subtest 'coderef returns CODE' => sub {
		is($reftype_fn->(sub {}), 'CODE', 'coderef → CODE');
	};

	subtest 'blessed object returns underlying reftype' => sub {
		my $obj = bless {}, 'MyClass';
		is($reftype_fn->($obj), 'HASH', 'blessed hashref → HASH');
	};

};

# ===========================================================================
# SECTION 15: _eq()
# ===========================================================================

subtest '_eq()' => sub {

	subtest 'equal strings' => sub {
		ok( $eq_fn->('hello', 'hello'), 'equal strings: true');
	};

	subtest 'different strings' => sub {
		ok(!$eq_fn->('hello', 'world'), 'different strings: false');
	};

	subtest 'both undef' => sub {
		ok( $eq_fn->(undef, undef), 'both undef: true');
	};

	subtest 'undef vs defined' => sub {
		ok(!$eq_fn->(undef, 'x'), 'undef vs defined: false');
		ok(!$eq_fn->('x', undef), 'defined vs undef: false');
	};

	subtest 'numeric strings' => sub {
		ok( $eq_fn->('42', '42'), '"42" eq "42": true');
		ok(!$eq_fn->('42', '43'), '"42" ne "43": false');
	};

	subtest 'empty string vs undef' => sub {
		ok(!$eq_fn->('', undef),  'empty string vs undef: false');
		ok(!$eq_fn->(undef, ''),  'undef vs empty string: false');
	};

	subtest 'empty string vs empty string' => sub {
		ok( $eq_fn->('', ''), 'empty string eq empty string: true');
	};

	subtest 'numeric 0 vs empty string' => sub {
		# _eq uses string eq, so '0' ne ''
		ok(!$eq_fn->('0', ''), '"0" ne "": false');
	};

};

# ===========================================================================
# SECTION 16: _key()
#
# After the bug-#1 fix, _key() uses Data::Dumper (Sortkeys=1, Indent=0,
# Terse=1) for reference values so that structural equality — not memory
# address — determines the key.  Plain scalars are still returned as-is.
# ===========================================================================

subtest '_key()' => sub {

	subtest 'plain string: returned as-is' => sub {
		is($key_fn->('hello'), 'hello', 'plain string returned unchanged');
	};

	subtest 'plain number: returned as-is' => sub {
		is($key_fn->(42), 42, 'plain number returned unchanged');
	};

	subtest 'undef: returned as undef' => sub {
		ok(!defined $key_fn->(undef), 'undef → undef');
	};

	subtest 'reference: key is a plain string, never a ref' => sub {
		my $k = $key_fn->({a => 1});
		ok(defined $k, 'key for hashref is defined');
		ok(!ref($k),   'key for hashref is a plain string, not a reference');
	};

	subtest 'same reference called twice: identical key' => sub {
		my $href = {a => 1};
		is($key_fn->($href), $key_fn->($href), 'same ref always yields same key');
	};

	subtest 'structurally equal hashrefs at different addresses: same key' => sub {
		# Core of the fix: _key() must be address-independent for hash refs.
		my $h1 = {x => 1, y => 2};
		my $h2 = {x => 1, y => 2};
		isnt(refaddr($h1), refaddr($h2), 'precondition: refs live at different addresses');
		is($key_fn->($h1), $key_fn->($h2),
			'structurally equal hashrefs produce the same key');
	};

	subtest 'structurally different hashrefs: different keys' => sub {
		my $h1 = {x => 1};
		my $h2 = {x => 2};
		isnt($key_fn->($h1), $key_fn->($h2),
			'structurally different hashrefs produce different keys');
	};

	subtest 'structurally equal arrayrefs: same key' => sub {
		my $a1 = [1, 2, 3];
		my $a2 = [1, 2, 3];
		isnt(refaddr($a1), refaddr($a2), 'precondition: different addresses');
		is($key_fn->($a1), $key_fn->($a2),
			'structurally equal arrayrefs produce the same key');
	};

	subtest 'structurally different arrayrefs: different keys' => sub {
		my $a1 = [1, 2, 3];
		my $a2 = [1, 2, 4];
		isnt($key_fn->($a1), $key_fn->($a2),
			'structurally different arrayrefs produce different keys');
	};

	subtest 'nested structure: key captures full depth' => sub {
		my $deep1 = {a => {b => 1}};
		my $deep2 = {a => {b => 2}};
		my $deep3 = {a => {b => 1}};
		isnt($key_fn->($deep1), $key_fn->($deep2), 'different nested value → different key');
		is($key_fn->($deep1),   $key_fn->($deep3), 'same nested value → same key');
	};

	subtest 'key is hash-key-order independent' => sub {
		# Data::Dumper with Sortkeys=1 must produce the same output regardless
		# of the order in which keys were inserted into the hash.
		my $h1 = {a => 1, b => 2};
		my $h2 = {};
		$h2->{b} = 2;
		$h2->{a} = 1;
		is($key_fn->($h1), $key_fn->($h2), 'insertion-order difference: same key');
	};

};

# ===========================================================================
# SECTION 17: Full-stack integration — nested structures
# ===========================================================================

subtest 'Integration: nested and mixed structures' => sub {

	subtest 'deep nested change' => sub {
		my $r = diff(
			{a => {b => {c => 1}}},
			{a => {b => {c => 2}}},
		);
		is(scalar @$r, 1, 'one change');
		is($r->[0]{path}, '/a/b/c', 'deep path correct');
	};

	subtest 'array inside hash' => sub {
		my $r = diff(
			{tags => [qw(foo bar)]},
			{tags => [qw(foo baz)]},
		);
		is(scalar @$r, 1, 'one change inside nested array');
		like($r->[0]{path}, qr{/tags/}, 'path includes tags');
	};

	subtest 'hash inside array (index mode)' => sub {
		my $r = diff(
			[{name => 'Alice'}, {name => 'Bob'}],
			[{name => 'Alice'}, {name => 'Bobby'}],
		);
		is(scalar @$r, 1, 'one change');
		is($r->[0]{from}, 'Bob',   'from=Bob');
		is($r->[0]{to},   'Bobby', 'to=Bobby');
	};

	subtest 'multiple simultaneous changes' => sub {
		my $r = diff(
			{a => 1, b => 2, c => 3},
			{a => 9, b => 2, c => 99},
		);
		is(scalar @$r, 2, 'two changes');
		my %by_path = map { $_->{path} => $_ } @$r;
		is($by_path{'/a'}{from}, 1,  '/a from=1');
		is($by_path{'/a'}{to},   9,  '/a to=9');
		is($by_path{'/c'}{from}, 3,  '/c from=3');
		is($by_path{'/c'}{to},   99, '/c to=99');
	};

	subtest 'object (blessed ref) falls back to stringify comparison' => sub {
		{
			package Counter;
			use overload '""' => sub { $_[0]->{n} }, fallback => 1;
			sub new { bless { n => $_[1] }, $_[0] }
		}
		my $r = diff(Counter->new(1), Counter->new(2));
		is($r->[0]{op}, 'change', 'blessed object change detected');
	};

};

done_testing();
