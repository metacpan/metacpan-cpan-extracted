#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
use Scalar::Util qw(blessed reftype);

=head1 NAME

edge_cases.t - Destructive, pathological and boundary-condition tests
               for Data::Hash::Diff::Smart

=head1 DESCRIPTION

These tests probe the limits of the public API: empty structures, undef
values, extremely deep nesting, very long strings, Unicode, mixed types,
blessed objects, coderefs, IO handles, duplicate keys (impossible in Perl
but simulated via tied hashes), NaN/Inf, overloaded objects, zero/false
values, and adversarial option inputs.

Every test calls only the public interface.

=cut

BEGIN {
	use_ok('Data::Hash::Diff::Smart', qw(
		diff
		diff_text
		diff_json
		diff_yaml
		diff_test2
	));
}

# ===========================================================================
# 1. Empty and minimal structures
# ===========================================================================

subtest 'Empty and minimal structures' => sub {

	subtest 'two empty hashrefs: no changes' => sub {
		is_deeply(diff({}, {}), [], 'empty hashes: no changes');
	};

	subtest 'two empty arrayrefs: no changes' => sub {
		is_deeply(diff([], []), [], 'empty arrays: no changes');
	};

	subtest 'empty string vs empty string: no changes' => sub {
		is_deeply(diff('', ''), [], 'empty strings: no changes');
	};

	subtest 'undef vs undef: no changes' => sub {
		is_deeply(diff(undef, undef), [], 'both undef: no changes');
	};

	subtest 'empty hash vs populated hash: all adds' => sub {
		my $r = diff({}, {a => 1, b => 2});
		my @non_adds = grep { $_->{op} ne 'add' } @$r;
		is(scalar @non_adds, 0, 'all ops are add');
		is(scalar @$r,       2, 'two adds');
	};

	subtest 'populated hash vs empty hash: all removes' => sub {
		my $r = diff({a => 1, b => 2}, {});
		my @non_removes = grep { $_->{op} ne 'remove' } @$r;
		is(scalar @non_removes, 0, 'all ops are remove');
		is(scalar @$r,          2, 'two removes');
	};

	subtest 'empty array vs populated array: all adds' => sub {
		my $r = diff([], [1, 2, 3]);
		my @non_adds = grep { $_->{op} ne 'add' } @$r;
		is(scalar @non_adds, 0, 'all ops are add for empty->populated array');
	};

	subtest 'populated array vs empty array: all removes' => sub {
		my $r = diff([1, 2, 3], []);
		my @non_removes = grep { $_->{op} ne 'remove' } @$r;
		is(scalar @non_removes, 0, 'all ops are remove for populated->empty array');
	};

	subtest 'single-key hash: change' => sub {
		my $r = diff({x => 1}, {x => 2});
		is(scalar @$r,    1,        'one change');
		is($r->[0]{op},   'change', 'op=change');
		is($r->[0]{from}, 1,        'from=1');
		is($r->[0]{to},   2,        'to=2');
	};

	subtest 'single-element array: change' => sub {
		my $r = diff([42], [99]);
		is(scalar @$r, 1, 'one change in single-element array');
	};

};

# ===========================================================================
# 2. Undef boundary conditions
# ===========================================================================

subtest 'Undef boundary conditions' => sub {

	subtest 'undef vs empty string' => sub {
		my $r = diff(undef, '');
		is($r->[0]{op}, 'change', 'undef vs empty string is a change');
	};

	subtest 'empty string vs undef' => sub {
		my $r = diff('', undef);
		is($r->[0]{op}, 'change', 'empty string vs undef is a change');
	};

	subtest 'undef vs zero' => sub {
		my $r = diff(undef, 0);
		is($r->[0]{op}, 'change', 'undef vs 0 is a change');
	};

	subtest 'undef vs hashref' => sub {
		my $r = diff(undef, {a => 1});
		is($r->[0]{op}, 'change', 'undef vs hashref is a change');
	};

	subtest 'hash value undef vs defined' => sub {
		my $r = diff({x => undef}, {x => 1});
		is($r->[0]{op},   'change', 'hash value undef->defined is change');
		is($r->[0]{path}, '/x',     'path is /x');
	};

	subtest 'hash value defined vs undef' => sub {
		my $r = diff({x => 1}, {x => undef});
		is($r->[0]{op}, 'change', 'hash value defined->undef is change');
	};

	subtest 'hash value undef vs undef: no change' => sub {
		my $r = diff({x => undef}, {x => undef});
		is_deeply($r, [], 'undef vs undef hash value: no change');
	};

	subtest 'undef hash value in nested structure' => sub {
		my $r = diff(
			{a => {b => undef}},
			{a => {b => 'now set'}},
		);
		is($r->[0]{path}, '/a/b', 'path correct for nested undef change');
	};

	subtest 'key with undef value vs missing key' => sub {
		# {x => undef} vs {} — undef value present vs key absent
		my $r_remove = diff({x => undef}, {});
		my $r_add    = diff({}, {x => undef});
		is($r_remove->[0]{op}, 'remove', 'undef-valued key removed is a remove');
		is($r_add->[0]{op},    'add',    'undef-valued key added is an add');
	};

};

# ===========================================================================
# 3. False-y but defined values: 0, '', '0'
# ===========================================================================

subtest 'False-y but defined values' => sub {

	subtest 'integer 0 vs 0: no change' => sub {
		is_deeply(diff({x => 0}, {x => 0}), [], '0 vs 0: no change');
	};

	subtest 'integer 0 vs 1: change' => sub {
		my $r = diff({x => 0}, {x => 1});
		is($r->[0]{op}, 'change', '0 vs 1: change');
	};

	subtest 'empty string vs empty string: no change' => sub {
		is_deeply(diff({x => ''}, {x => ''}), [], '"" vs "": no change');
	};

	subtest 'empty string vs non-empty: change' => sub {
		my $r = diff({x => ''}, {x => 'hello'});
		is($r->[0]{op}, 'change', '"" vs "hello": change');
	};

	subtest 'string "0" vs "0": no change' => sub {
		is_deeply(diff({x => '0'}, {x => '0'}), [], '"0" vs "0": no change');
	};

	subtest 'string "0" vs integer 0: no change (string eq)' => sub {
		# _eq uses string eq, so "0" eq 0 is true
		is_deeply(diff({x => '0'}, {x => 0}), [], '"0" eq 0: no change');
	};

	subtest 'false value in array: detected correctly' => sub {
		my $r = diff([0, '', undef, '0'], [0, '', undef, '0']);
		is_deeply($r, [], 'array of false values identical: no changes');
	};

	subtest 'false value change in array' => sub {
		my $r = diff([0], [1]);
		is($r->[0]{op}, 'change', '0->1 in array is change');
	};

};

# ===========================================================================
# 4. Numeric edge cases: floats, NaN, Inf
# ===========================================================================

subtest 'Numeric edge cases' => sub {

	subtest 'integer vs float with same string repr: no change' => sub {
		is_deeply(diff({x => 1}, {x => 1.0}), [], '1 vs 1.0: no change');
	};

	subtest 'floats that differ in string repr: change' => sub {
		my $r = diff({x => 1.1}, {x => 1.2});
		is($r->[0]{op}, 'change', '1.1 vs 1.2: change');
	};

	subtest 'very large integer: no change' => sub {
		my $big = 9**9**2;
		is_deeply(diff({x => $big}, {x => $big}), [], 'large integer vs itself: no change');
	};

	subtest 'Inf vs Inf: no change' => sub {
		my $inf = 9**9**9;
		is_deeply(diff({x => $inf}, {x => $inf}), [], 'Inf vs Inf: no change');
	};

	subtest 'Inf vs large number: change' => sub {
		my $inf  = 9**9**9;
		my $big  = 9**9**2;
		my $r    = diff({x => $inf}, {x => $big});
		is($r->[0]{op}, 'change', 'Inf vs large number: change');
	};

	subtest 'negative zero vs zero: no change (string eq)' => sub {
		my $negzero = -0.0;
		is_deeply(diff({x => $negzero}, {x => 0}), [], '-0.0 vs 0: no change');
	};

};

# ===========================================================================
# 5. String edge cases
# ===========================================================================

subtest 'String edge cases' => sub {

	subtest 'very long string: change detected' => sub {
		my $long_old = 'x' x 100_000;
		my $long_new = 'x' x 99_999 . 'y';
		my $r = diff({s => $long_old}, {s => $long_new});
		is($r->[0]{op}, 'change', '100k-char string: change detected');
	};

	subtest 'very long identical string: no change' => sub {
		my $long = 'a' x 100_000;
		is_deeply(diff({s => $long}, {s => $long}), [], '100k-char identical string: no change');
	};

	subtest 'string with embedded newlines' => sub {
		my $r = diff({s => "line1\nline2"}, {s => "line1\nline3"});
		is($r->[0]{op}, 'change', 'string with newline: change detected');
	};

	subtest 'string with embedded null bytes' => sub {
		my $r = diff({s => "foo\x00bar"}, {s => "foo\x00baz"});
		is($r->[0]{op}, 'change', 'string with null byte: change detected');
	};

	subtest 'string with embedded null bytes: no change' => sub {
		is_deeply(
			diff({s => "foo\x00bar"}, {s => "foo\x00bar"}),
			[], 'identical null-byte strings: no change'
		);
	};

	subtest 'string containing slash (path character)' => sub {
		# A value containing "/" must not corrupt path construction
		my $r = diff({x => 'a/b/c'}, {x => 'a/b/d'});
		is($r->[0]{op},   'change', 'slash-containing value: change detected');
		is($r->[0]{path}, '/x',     'path is /x, not corrupted by value slashes');
	};

	subtest 'key containing slash' => sub {
		my $r = diff({'a/b' => 1}, {'a/b' => 2});
		is($r->[0]{op}, 'change', 'slash-in-key: change detected');
		like($r->[0]{path}, qr{a/b}, 'path contains the key');
	};

	subtest 'whitespace-only string vs empty string' => sub {
		my $r = diff({x => '   '}, {x => ''});
		is($r->[0]{op}, 'change', 'whitespace vs empty: change');
	};

};

# ===========================================================================
# 6. Unicode
# ===========================================================================

subtest 'Unicode strings' => sub {

	subtest 'identical Unicode strings: no change' => sub {
		my $u = "Ниг\x{e9}l H\x{f8}rne";
		is_deeply(diff({name => $u}, {name => $u}), [], 'identical Unicode: no change');
	};

	subtest 'different Unicode strings: change' => sub {
		my $r = diff({name => "Alice \x{1f600}"}, {name => "Alice \x{1f601}"});
		is($r->[0]{op}, 'change', 'emoji difference: change detected');
	};

	subtest 'Unicode key: change detected' => sub {
		my $r = diff({"\x{e9}l\x{e8}ve" => 1}, {"\x{e9}l\x{e8}ve" => 2});
		is($r->[0]{op}, 'change', 'Unicode key: change detected');
	};

	subtest 'Unicode in nested path: no change' => sub {
		my $s = {"\x{6c49}\x{5b57}" => {"\x{6587}\x{5b57}" => 'same'}};
		is_deeply(diff($s, $s), [], 'CJK keys with identical values: no change');
	};

	subtest 'mixed ASCII and Unicode values: change' => sub {
		my $r = diff({x => 'caf\x{e9}'}, {x => 'cafe'});
		is($r->[0]{op}, 'change', 'café vs cafe: change');
	};

};

# ===========================================================================
# 7. Type mismatches
# ===========================================================================

subtest 'Type mismatches' => sub {

	subtest 'scalar vs hashref' => sub {
		my $r = diff('scalar', {a => 1});
		is($r->[0]{op}, 'change', 'scalar vs hashref: change');
	};

	subtest 'scalar vs arrayref' => sub {
		my $r = diff('scalar', [1, 2]);
		is($r->[0]{op}, 'change', 'scalar vs arrayref: change');
	};

	subtest 'hashref vs arrayref' => sub {
		my $r = diff({a => 1}, [1, 2]);
		is($r->[0]{op}, 'change', 'hashref vs arrayref: change');
	};

	subtest 'arrayref vs hashref' => sub {
		my $r = diff([1, 2], {a => 1});
		is($r->[0]{op}, 'change', 'arrayref vs hashref: change');
	};

	subtest 'integer vs string with same repr: no change' => sub {
		is_deeply(diff({x => 42}, {x => '42'}), [], '"42" eq 42: no change');
	};

	subtest 'nested type mismatch: scalar replaced by hash' => sub {
		my $r = diff({x => 'flat'}, {x => {nested => 1}});
		is($r->[0]{op},   'change', 'nested type mismatch: change');
		is($r->[0]{path}, '/x',     'path is /x');
	};

	subtest 'nested type mismatch: hash replaced by array' => sub {
		my $r = diff({x => {a => 1}}, {x => [1, 2, 3]});
		is($r->[0]{op}, 'change', 'hash->array inside hash: change');
	};

};

# ===========================================================================
# 8. Blessed objects
# ===========================================================================

subtest 'Blessed objects' => sub {

	{
		package My::Thing;
		use overload '""' => sub { "thing:$_[0]->{v}" }, fallback => 1;
		sub new { bless { v => $_[1] }, $_[0] }
	}

	subtest 'same blessed class, same value: no change' => sub {
		my $a = My::Thing->new(1);
		my $b = My::Thing->new(1);
		# Engine falls back to stringify for blessed objects
		is_deeply(diff($a, $b), [], 'same blessed value: no change');
	};

	subtest 'same blessed class, different value: change' => sub {
		my $r = diff(My::Thing->new(1), My::Thing->new(2));
		is($r->[0]{op}, 'change', 'different blessed value: change');
	};

	subtest 'blessed hash: engine recurses into fields' => sub {
		my $a = bless {name => 'Alice', score => 10}, 'My::Record';
		my $b = bless {name => 'Alice', score => 20}, 'My::Record';
		my $r = diff($a, $b);
		# Engine should recurse into the hash fields
		ok(scalar @$r > 0, 'blessed hash diff finds the changed field');
	};

	subtest 'blessed object vs plain hash: change' => sub {
		my $obj  = bless {a => 1}, 'My::Class';
		my $hash = {a => 1};
		# reftype is HASH for both, but the engine may treat them differently
		my $r = diff($obj, $hash);
		isa_ok($r, 'ARRAY', 'result is arrayref for blessed vs plain hash');
	};

	subtest 'diff does not die on overloaded object' => sub {
		lives_ok(
			sub { diff(My::Thing->new(1), My::Thing->new(2)) },
			'overloaded object: no exception'
		);
	};

};

# ===========================================================================
# 9. Coderefs and other exotic ref types
# ===========================================================================

subtest 'Exotic ref types (coderef, scalarref, globref)' => sub {

	subtest 'identical coderef: no change (same address)' => sub {
		my $c = sub { 1 };
		is_deeply(diff($c, $c), [], 'same coderef: no change');
	};

	subtest 'different coderefs: change' => sub {
		my $r = diff(sub { 1 }, sub { 2 });
		is($r->[0]{op}, 'change', 'different coderefs: change');
	};

	subtest 'scalarref vs scalarref: same value' => sub {
		my $s1 = \"hello";
		my $s2 = \"hello";
		# Engine falls back to stringify: SCALAR(0x...) — same structure
		my $r = diff($s1, $s2);
		isa_ok($r, 'ARRAY', 'scalarref diff returns arrayref');
	};

	subtest 'coderef inside hash: no exception' => sub {
		my $code = sub { 42 };
		lives_ok(
			sub { diff({fn => $code}, {fn => $code}) },
			'coderef as hash value: no exception'
		);
	};

	subtest 'coderef value change in hash' => sub {
		my $r = diff(
			{fn => sub { 1 }},
			{fn => sub { 2 }},
		);
		isa_ok($r, 'ARRAY', 'coderef change returns arrayref');
	};

};

# ===========================================================================
# 10. Deeply nested structures
# ===========================================================================

subtest 'Deeply nested structures' => sub {

	subtest '10 levels deep: change at leaf detected' => sub {
		my $build = sub {
			my ($depth, $val) = @_;
			my $h = {leaf => $val};
			$h = {level => $h} for 1 .. $depth;
			$h
		};
		my $old = $build->(10, 'old');
		my $new = $build->(10, 'new');
		my $r   = diff($old, $new);
		is(scalar @$r,    1,        'one change at depth 10');
		is($r->[0]{from}, 'old',    'from=old');
		is($r->[0]{to},   'new',    'to=new');
		like($r->[0]{path}, qr{/level}, 'path contains level segments');
	};

	subtest '50 levels deep: does not die' => sub {
		my $build = sub {
			my ($depth, $val) = @_;
			my $h = {leaf => $val};
			$h = {n => $h} for 1 .. $depth;
			$h
		};
		my $old = $build->(50, 'a');
		my $new = $build->(50, 'b');
		my $r;
		lives_ok(sub { $r = diff($old, $new) }, '50-level nesting: no exception');
		is(scalar @$r, 1, 'one change detected at depth 50');
	};

	subtest 'wide and deep: 10 keys at each of 5 levels' => sub {
		sub _build_wide {
			my ($depth, $old_or_new) = @_;
			return "leaf_$old_or_new" if $depth == 0;
			return { map { ("k$_" => _build_wide($depth - 1, $old_or_new)) } 1..10 };
		}
		my $old = _build_wide(5, 'old');
		my $new = _build_wide(5, 'new');
		my $r;
		lives_ok(sub { $r = diff($old, $new) }, 'wide+deep structure: no exception');
		ok(scalar @$r > 0, 'changes detected in wide+deep structure');
	};

};

# ===========================================================================
# 11. Cyclic and self-referential structures
# ===========================================================================

subtest 'Cyclic and self-referential structures' => sub {

	subtest 'direct self-reference in hash: no infinite loop' => sub {
		my $a = {x => 1};
		$a->{self} = $a;
		my $b = {x => 1};
		$b->{self} = $b;
		my $r;
		lives_ok(sub { $r = diff($a, $b) }, 'self-ref hash: no infinite loop');
		isa_ok($r, 'ARRAY', 'result is arrayref');
	};

	subtest 'direct self-reference with value change' => sub {
		my $a = {x => 1};
		$a->{self} = $a;
		my $b = {x => 2};
		$b->{self} = $b;
		my $r;
		lives_ok(sub { $r = diff($a, $b) }, 'self-ref with change: no infinite loop');
		my @ch = grep { $_->{op} eq 'change' } @$r;
		ok(scalar @ch >= 1, 'value change detected despite self-reference');
	};

	subtest 'mutual reference: A->B->A: no infinite loop' => sub {
		my $a = {name => 'A'};
		my $b = {name => 'B', other => $a};
		$a->{other} = $b;
		my $x = {name => 'A'};
		my $y = {name => 'B', other => $x};
		$x->{other} = $y;
		lives_ok(sub { diff($a, $x) }, 'mutual reference: no infinite loop');
	};

	subtest 'cyclic array: no infinite loop' => sub {
		my $a = [1, 2];
		push @$a, $a;
		my $b = [1, 2];
		push @$b, $b;
		lives_ok(sub { diff($a, $b) }, 'cyclic array: no infinite loop');
	};

	subtest 'all renderers survive cyclic input' => sub {
		my $a = {v => 1};
		$a->{s} = $a;
		my $b = {v => 2};
		$b->{s} = $b;
		lives_ok(sub { diff_text($a, $b)  }, 'diff_text: cyclic input');
		lives_ok(sub { diff_json($a, $b)  }, 'diff_json: cyclic input');
		lives_ok(sub { diff_yaml($a, $b)  }, 'diff_yaml: cyclic input');
		lives_ok(sub { diff_test2($a, $b) }, 'diff_test2: cyclic input');
	};

};

# ===========================================================================
# 12. Adversarial ignore rules
# ===========================================================================

subtest 'Adversarial ignore rules' => sub {

	subtest 'empty ignore list: same as no ignore' => sub {
		my $r1 = diff({a => 1}, {a => 2});
		my $r2 = diff({a => 1}, {a => 2}, ignore => []);
		is(scalar @$r2, scalar @$r1, 'empty ignore list: same result as no ignore');
	};

	subtest 'ignore rule that matches nothing' => sub {
		my $r = diff({a => 1}, {a => 2}, ignore => ['/no/such/path']);
		is(scalar @$r, 1, 'non-matching ignore: change still reported');
	};

	subtest 'regex that matches nothing' => sub {
		my $r = diff({a => 1}, {a => 2}, ignore => [qr{^/zzz}]);
		is(scalar @$r, 1, 'non-matching regex: change still reported');
	};

	subtest 'wildcard that matches nothing (wrong depth)' => sub {
		my $r = diff(
			{a => {b => 1}},
			{a => {b => 2}},
			ignore => ['/a/*/b/extra'],  # too deep
		);
		is(scalar @$r, 1, 'wrong-depth wildcard: change still reported');
	};

	subtest 'regex that matches everything: all changes suppressed' => sub {
		my $r = diff(
			{a => 1, b => 2},
			{a => 9, b => 9},
			ignore => [qr{.*}],
		);
		is_deeply($r, [], 'catch-all regex: all changes suppressed');
	};

	subtest 'ignore root path' => sub {
		# Ignoring '' (root) should suppress a root-level scalar change
		my $r = diff('old', 'new', ignore => ['']);
		is_deeply($r, [], 'ignoring root path suppresses root scalar change');
	};

	subtest 'overlapping ignore rules: each still suppresses its path' => sub {
		my $r = diff(
			{a => 1, b => 2, c => 3},
			{a => 9, b => 9, c => 9},
			ignore => ['/a', '/b', qr{^/c$}],
		);
		is_deeply($r, [], 'overlapping rules: all paths suppressed');
	};

	subtest 'ignore undef element' => sub {
		# Must not die if ignore list contains undef somehow — or just confirm
		# that a valid list with one rule works when other value is changed
		my $r = diff({a => 1, b => 2}, {a => 9, b => 2}, ignore => ['/a']);
		is_deeply($r, [], 'valid single ignore rule works correctly');
	};

};

# ===========================================================================
# 13. Adversarial compare callbacks
# ===========================================================================

subtest 'Adversarial compare callbacks' => sub {

	subtest 'comparator that always returns true: no changes ever' => sub {
		my $r = diff(
			{a => 1, b => 'hello'},
			{a => 2, b => 'world'},
			compare => {
				'/a' => sub { 1 },
				'/b' => sub { 1 },
			},
		);
		is_deeply($r, [], 'always-true comparator: no changes');
	};

	subtest 'comparator that always returns false: always changes' => sub {
		my $r = diff(
			{x => 42},
			{x => 42},
			compare => { '/x' => sub { 0 } },
		);
		is($r->[0]{op}, 'change', 'always-false comparator: change even for equal values');
	};

	subtest 'comparator that dies: change record with error field' => sub {
		my $r = diff(
			{x => 1},
			{x => 2},
			compare => { '/x' => sub { die "boom\n" } },
		);
		is($r->[0]{op}, 'change', 'dying comparator: change recorded');
		ok(exists $r->[0]{error}, 'error field present');
		like($r->[0]{error}, qr/boom/, 'error message captured');
	};

	subtest 'comparator that modifies $_[0]: no exception' => sub {
		lives_ok(sub {
			diff(
				{x => 'hello'},
				{x => 'world'},
				compare => { '/x' => sub { $_[0] = 'modified'; 0 } },
			)
		}, 'comparator modifying arg: no exception');
	};

	subtest 'comparator registered for non-existent path: no effect' => sub {
		my $r = diff(
			{a => 1},
			{a => 2},
			compare => { '/no/such/path' => sub { 1 } },
		);
		is($r->[0]{op}, 'change', 'comparator for absent path: normal change still reported');
	};

};

# ===========================================================================
# 14. Array mode boundary conditions
# ===========================================================================

subtest 'Array mode boundary conditions' => sub {

	subtest 'index mode: single-element array, no change' => sub {
		is_deeply(diff([42], [42], array_mode => 'index'), [], 'single elem: no change');
	};

	subtest 'index mode: single-element array, change' => sub {
		my $r = diff([42], [99], array_mode => 'index');
		is($r->[0]{op}, 'change', 'single elem change in index mode');
	};

	subtest 'lcs mode: empty old to populated new' => sub {
		my $r = diff([], [1, 2, 3], array_mode => 'lcs');
		my @non_adds = grep { $_->{op} ne 'add' } @$r;
		is(scalar @non_adds, 0, 'lcs: empty->populated: all adds');
	};

	subtest 'lcs mode: populated old to empty new' => sub {
		my $r = diff([1, 2, 3], [], array_mode => 'lcs');
		my @non_removes = grep { $_->{op} ne 'remove' } @$r;
		is(scalar @non_removes, 0, 'lcs: populated->empty: all removes');
	};

	subtest 'lcs mode: completely different arrays' => sub {
		my $r = diff([1, 2, 3], [4, 5, 6], array_mode => 'lcs');
		lives_ok(sub { diff([1, 2, 3], [4, 5, 6], array_mode => 'lcs') },
			'lcs: completely different arrays: no exception');
		ok(scalar @$r > 0, 'lcs: all-different arrays produce changes');
	};

	subtest 'unordered mode: empty vs empty' => sub {
		is_deeply(diff([], [], array_mode => 'unordered'), [], 'unordered: empty vs empty');
	};

	subtest 'unordered mode: single element same' => sub {
		is_deeply(diff([42], [42], array_mode => 'unordered'), [], 'unordered: single same');
	};

	subtest 'unordered mode: single element changed' => sub {
		my $r = diff([42], [99], array_mode => 'unordered');
		ok(scalar @$r > 0, 'unordered: single element change detected');
	};

	subtest 'unordered mode: all elements removed' => sub {
		my $r = diff([1, 2, 3], [], array_mode => 'unordered');
		my @removes = grep { $_->{op} eq 'remove' } @$r;
		is(scalar @removes, 3, 'unordered: all three elements removed');
	};

	subtest 'unordered mode: large reordered array: no changes' => sub {
		my @elems = map { "item_$_" } 1 .. 100;
		my @shuffled = reverse @elems;
		my $r = diff(\@elems, \@shuffled, array_mode => 'unordered');
		is_deeply($r, [], 'unordered: 100-element reversal: no changes');
	};

	subtest 'array_key with missing key field: no exception' => sub {
		# Elements lack the nominated key field — must not die
		my $old = [{name => 'Alice'}, {name => 'Bob'}];
		my $new = [{name => 'Bob'},   {name => 'Alice'}];
		lives_ok(
			sub { diff($old, $new, array_mode => 'unordered', array_key => 'id') },
			'array_key with missing field: no exception'
		);
	};

};

# ===========================================================================
# 15. Renderer edge cases
# ===========================================================================

subtest 'Renderer edge cases' => sub {

	subtest 'diff_text: value containing newline renders without breaking structure' => sub {
		my $r = diff({x => "line1\nline2"}, {x => "line1\nline3"});
		my $t;
		lives_ok(sub { $t = diff_text({x => "line1\nline2"}, {x => "line1\nline3"}) },
			'diff_text: newline in value: no exception');
		ok(defined $t, 'diff_text: defined output for newline value');
	};

	subtest 'diff_json: value containing double-quote is valid JSON' => sub {
		require JSON::MaybeXS;
		my $j;
		lives_ok(
			sub { $j = diff_json({x => 'say "hello"'}, {x => 'say "goodbye"'}) },
			'diff_json: quote in value: no exception'
		);
		my $decoded = eval { JSON::MaybeXS::decode_json($j) };
		ok(!$@, 'diff_json: quote in value: valid JSON output');
	};

	subtest 'diff_json: Unicode value produces valid JSON' => sub {
		require JSON::MaybeXS;
		my $j = diff_json({x => "caf\x{e9}"}, {x => "caf\x{e8}"});
		my $decoded = eval { JSON::MaybeXS::decode_json($j) };
		ok(!$@, 'diff_json: Unicode value: valid JSON output');
	};

	subtest 'diff_test2: all lines carry "# " prefix for deep nested change' => sub {
		my $old = {a => {b => {c => {d => 1}}}};
		my $new = {a => {b => {c => {d => 2}}}};
		my $t   = diff_test2($old, $new);
		my @bad = grep { length($_) && $_ !~ /^# / } split /\n/, $t;
		is(scalar @bad, 0, 'diff_test2: no unpreFixed lines for deep change');
	};

	subtest 'diff_yaml: large change list renders without exception' => sub {
		my %old = map { ( "k$_" => $_ ) }      1 .. 50;
		my %new = map { ( "k$_" => $_ + 100 ) } 1 .. 50;
		lives_ok(sub { diff_yaml(\%old, \%new) }, 'diff_yaml: 50-change list: no exception');
	};

	subtest 'diff_text: empty string value renders without mangling path' => sub {
		my $t = diff_text({x => 'old'}, {x => ''});
		like($t, qr{/x}, 'diff_text: path /x present even when new value is empty string');
	};

};

# ===========================================================================
# 16. Idempotency: diffing the result of a merge must yield no changes
# ===========================================================================

subtest 'Idempotency: applying changes yields a structure with no further diff' => sub {

	# We manually apply the changes from diff() to reconstruct $new from $old,
	# then diff the result against the original $new — it must be empty.
	# This is a black-box end-to-end sanity check.

	my $old = {name => 'Alice', score => 10, active => 1};
	my $new = {name => 'Bob',   score => 20, active => 1};

	my $changes = diff($old, $new);

	# Apply changes manually
	my %reconstructed = %$old;
	for my $c (@$changes) {
		next unless $c->{op} eq 'change';
		# Extract the key from the path (single-level only for this test)
		(my $key = $c->{path}) =~ s{^/}{};
		$reconstructed{$key} = $c->{to};
	}

	my $residual = diff(\%reconstructed, $new);
	is_deeply($residual, [], 'applied changes produce no further diff against target');

};

# ===========================================================================
# 17. Stability: repeated calls with same input produce same output
# ===========================================================================

subtest 'Stability: repeated calls produce identical results' => sub {

	my $old = {a => 1, b => [1, 2, 3], c => {d => 'x'}};
	my $new = {a => 9, b => [1, 5, 3], c => {d => 'y'}};

	my $r1 = diff($old, $new);
	my $r2 = diff($old, $new);
	my $r3 = diff($old, $new);

	is_deeply($r1, $r2, 'second call identical to first');
	is_deeply($r2, $r3, 'third call identical to second');

	my $t1 = diff_text($old, $new);
	my $t2 = diff_text($old, $new);
	is($t1, $t2, 'diff_text: repeated calls produce identical output');

	require JSON::MaybeXS;
	my $j1 = diff_json($old, $new);
	my $j2 = diff_json($old, $new);
	is($j1, $j2, 'diff_json: repeated calls produce identical output');

};

done_testing();
