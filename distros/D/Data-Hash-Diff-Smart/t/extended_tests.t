#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
use Scalar::Util qw(refaddr);

# extended_tests.t - Coverage-targeted tests for Data::Hash::Diff::Smart

# Targets specific branches, loop exits, and condition combinations in
# Engine.pm, the Path module, and both renderers that are not exercised by
# the other test files.  Each subtest cites the code path it is covering.

# All tests use only the public interface.

BEGIN {
	use_ok('Data::Hash::Diff::Smart', qw(
		diff
		diff_text
		diff_json
		diff_yaml
		diff_test2
	));
}

# Pull renderer render() functions directly for white-box renderer tests
BEGIN {
	require_ok('Data::Hash::Diff::Smart::Renderer::Text');
	require_ok('Data::Hash::Diff::Smart::Renderer::Test2');
}
my $render_text = \&Data::Hash::Diff::Smart::Renderer::Text::render;
my $render_t2   = \&Data::Hash::Diff::Smart::Renderer::Test2::render;

# ===========================================================================
# 1. Path construction edge cases
#    Data::Hash::Diff::Smart::Path::join is never directly tested.
# ===========================================================================

subtest 'Path construction' => sub {

	subtest 'root + scalar key produces /key' => sub {
		my $r = diff({a => 1}, {a => 2});
		is($r->[0]{path}, '/a', 'root + key = /a');
	};

	subtest 'root + numeric key 0 produces /0' => sub {
		my $r = diff([9], [8]);
		is($r->[0]{path}, '/0', 'array index 0 => path /0');
	};

	subtest 'root + numeric key produces /N' => sub {
		my $r = diff([1, 2, 9], [1, 2, 8]);
		is($r->[0]{path}, '/2', 'array index 2 => path /2');
	};

	subtest 'nested hash path concatenation' => sub {
		my $r = diff({a => {b => {c => 1}}}, {a => {b => {c => 2}}});
		is($r->[0]{path}, '/a/b/c', 'three-level path concatenated correctly');
	};

	subtest 'empty-string key produces path with double slash' => sub {
		# A key that is '' is legal in Perl hashes
		my $r = diff({'' => 1}, {'' => 2});
		like($r->[0]{path}, qr{/}, 'empty-string key produces a path');
		is($r->[0]{op}, 'change', 'change detected for empty-string key');
	};

	subtest 'key containing spaces' => sub {
		my $r = diff({'my key' => 1}, {'my key' => 2});
		is($r->[0]{op}, 'change', 'space-containing key: change detected');
		like($r->[0]{path}, qr/my key/, 'space-containing key appears in path');
	};

	subtest 'path for add op contains key' => sub {
		my $r = diff({}, {newkey => 42});
		is($r->[0]{path}, '/newkey', 'add op path is /newkey');
	};

	subtest 'path for remove op contains key' => sub {
		my $r = diff({gone => 1}, {});
		is($r->[0]{path}, '/gone', 'remove op path is /gone');
	};

};

# ===========================================================================
# 2. _diff fallback: stringify branch for non-HASH, non-ARRAY refs
#    Reached when both refs have the same reftype but it is not HASH or ARRAY.
# ===========================================================================

subtest '_diff stringify fallback for exotic ref types' => sub {

	subtest 'two coderefs: same ref, no change' => sub {
		my $c = sub { 1 };
		is_deeply(diff($c, $c), [], 'same coderef address: no change');
	};

	subtest 'two different coderefs: change detected' => sub {
		my $c1 = sub { 1 };
		my $c2 = sub { 2 };
		my $r  = diff($c1, $c2);
		is($r->[0]{op}, 'change', 'different coderefs: stringify fallback fires, change detected');
	};

	subtest 'scalarref with same content, different addresses: change (address-based)' => sub {
		my $s1 = \"hello";
		my $s2 = \"hello";
		isnt(refaddr($s1), refaddr($s2), 'precondition: different addresses');
		# Stringify gives SCALAR(0x...) — different addresses = different strings
		my $r = diff($s1, $s2);
		isa_ok($r, 'ARRAY', 'scalarref diff: returns arrayref');
	};

	subtest 'same scalarref twice: no change' => sub {
		my $s = \"hello";
		is_deeply(diff($s, $s), [], 'same scalarref: no change');
	};

	subtest 'coderef inside hash value: stringify fallback fires' => sub {
		my $c1 = sub { 1 };
		my $c2 = sub { 2 };
		my $r  = diff({fn => $c1}, {fn => $c2});
		is($r->[0]{op},   'change', 'coderef hash value: change detected');
		is($r->[0]{path}, '/fn',    'path is /fn');
	};

	subtest 'one-ref-one-scalar at non-root path' => sub {
		# Exercises the "ref old, scalar new" branch with a real path
		my $r = diff({x => {nested => 1}}, {x => 'flat'});
		is($r->[0]{op},   'change', 'hashref->scalar at /x: change');
		is($r->[0]{path}, '/x',     'path is /x');
	};

	subtest 'one-scalar-one-ref at non-root path' => sub {
		my $r = diff({x => 'flat'}, {x => {nested => 1}});
		is($r->[0]{op},   'change', 'scalar->hashref at /x: change');
		is($r->[0]{path}, '/x',     'path is /x');
	};

};

# ===========================================================================
# 3. _diff_array_lcs: LCS walker branch coverage
#    The walker has five distinct branches plus the $li advancement condition.
# ===========================================================================

subtest '_diff_array_lcs: walker branch coverage' => sub {

	subtest 'branch: both equal at current position (no LCS advance needed)' => sub {
		# [1,2,3] vs [1,2,3] — every step hits the "both equal" branch
		my $r = diff([1, 2, 3], [1, 2, 3], array_mode => 'lcs');
		is_deeply($r, [], 'all-equal: no changes');
	};

	subtest 'branch: element in old matches LCS, new has an insertion before it' => sub {
		# [2] vs [1,2] — LCS is [2], so 1 is an add before the LCS element
		my $r = diff([2], [1, 2], array_mode => 'lcs');
		my @adds = grep { $_->{op} eq 'add' } @$r;
		is(scalar @adds,    1, 'one add');
		is($adds[0]{value}, 1, 'added value is 1');
	};

	subtest 'branch: element in new matches LCS, old has an element before it (remove)' => sub {
		# [1,2] vs [2] — LCS is [2], so 1 is a remove
		my $r = diff([1, 2], [2], array_mode => 'lcs');
		my @removes = grep { $_->{op} eq 'remove' } @$r;
		is(scalar @removes,    1, 'one remove');
		is($removes[0]{from},  1, 'removed value is 1');
	};

	subtest 'branch: $li advances mid-walk' => sub {
		# [1,2,3] vs [1,2,4] — LCS is [1,2], $li advances twice during walk
		my $r = diff([1, 2, 3], [1, 2, 4], array_mode => 'lcs');
		is(scalar @$r,    1,        'one change');
		is($r->[0]{from}, 3,        'from=3');
		is($r->[0]{to},   4,        'to=4');
	};

	subtest 'branch: $li never advances (no common elements)' => sub {
		# [1,2] vs [3,4] — LCS is [], $li advancement condition never true
		my $r = diff([1, 2], [3, 4], array_mode => 'lcs');
		ok(scalar @$r > 0, 'all-different: changes produced');
	};

	subtest 'branch: old exhausted mid-walk, drain adds remaining new elements' => sub {
		# [1] vs [1,2,3] — after matching 1, old is exhausted, 2 and 3 are adds
		my $r = diff([1], [1, 2, 3], array_mode => 'lcs');
		my @adds = grep { $_->{op} eq 'add' } @$r;
		is(scalar @adds, 2, 'two adds after old exhausted mid-walk');
		my %vals = map { $_->{value} => 1 } @adds;
		ok($vals{2} && $vals{3}, 'added values are 2 and 3');
	};

	subtest 'branch: new exhausted mid-walk, drain removes remaining old elements' => sub {
		# [1,2,3] vs [1] — after matching 1, new is exhausted, 2 and 3 are removes
		my $r = diff([1, 2, 3], [1], array_mode => 'lcs');
		my @removes = grep { $_->{op} eq 'remove' } @$r;
		is(scalar @removes, 2, 'two removes after new exhausted mid-walk');
		my %vals = map { $_->{from} => 1 } @removes;
		ok($vals{2} && $vals{3}, 'removed values are 2 and 3');
	};

	subtest 'arrays with duplicate elements: LCS handles correctly' => sub {
		# [1,1,2] vs [1,2,2] — LCS is [1,2]
		my $r = diff([1, 1, 2], [1, 2, 2], array_mode => 'lcs');
		isa_ok($r, 'ARRAY', 'duplicate elements: returns arrayref');
		# One extra 1 removed, one extra 2 added
		my @adds    = grep { $_->{op} eq 'add'    } @$r;
		my @removes = grep { $_->{op} eq 'remove' } @$r;
		ok(scalar @adds    >= 1, 'at least one add for extra 2');
		ok(scalar @removes >= 1, 'at least one remove for extra 1');
	};

	subtest 'single-element arrays: LCS with match' => sub {
		is_deeply(diff([42], [42], array_mode => 'lcs'), [], 'single match: no changes');
	};

	subtest 'single-element arrays: LCS with no match' => sub {
		my $r = diff([42], [99], array_mode => 'lcs');
		ok(scalar @$r > 0, 'single no-match: changes produced');
	};

	subtest 'lcs with hash-ref elements: _eq uses stringify, no exception' => sub {
		# _eq stringifies refs in LCS — should not die, just may not find LCS
		my $old = [{a => 1}, {b => 2}];
		my $new = [{a => 1}, {b => 3}];
		lives_ok(
			sub { diff($old, $new, array_mode => 'lcs') },
			'lcs with hash-ref elements: no exception'
		);
	};

};

# ===========================================================================
# 4. _diff_array_unordered: additional branch coverage
# ===========================================================================

subtest '_diff_array_unordered: branch coverage' => sub {

	subtest 'array_key with duplicate key values: last writer wins, no exception' => sub {
		# Two elements share id=>1 — second overwrites first in the lookup hash
		my $old = [{id => 1, name => 'Alice'}, {id => 1, name => 'Alice2'}];
		my $new = [{id => 1, name => 'Alice'}];
		lives_ok(
			sub { diff($old, $new, array_mode => 'unordered', array_key => 'id') },
			'duplicate array_key values: no exception'
		);
	};

	subtest 'array_key on array of scalars (not hashrefs): no exception' => sub {
		# $_->{$key_field} on a scalar produces undef — after fix, silently skipped
		lives_ok(
			sub { diff([1, 2, 3], [3, 1, 2], array_mode => 'unordered', array_key => 'id') },
			'array_key on scalar array: no exception'
		);
	};

	subtest 'unordered: element count goes from 1 to 3 (net 2 adds)' => sub {
		my $r = diff(['x'], ['x', 'y', 'z'], array_mode => 'unordered');
		my @adds = grep { $_->{op} eq 'add' } @$r;
		is(scalar @adds, 2, 'two adds for two new elements');
	};

	subtest 'unordered: element count goes from 3 to 1 (net 2 removes)' => sub {
		my $r = diff(['x', 'y', 'z'], ['x'], array_mode => 'unordered');
		my @removes = grep { $_->{op} eq 'remove' } @$r;
		is(scalar @removes, 2, 'two removes for two missing elements');
	};

	subtest 'unordered: multiset with count > 2 of same element' => sub {
		# [a,a,a] vs [a,a] — one remove
		my $r = diff(['a','a','a'], ['a','a'], array_mode => 'unordered');
		my @removes = grep { $_->{op} eq 'remove' } @$r;
		is(scalar @removes, 1, 'one remove for count 3->2');
	};

	subtest 'unordered: array_key, both old and new empty' => sub {
		is_deeply(
			diff([], [], array_mode => 'unordered', array_key => 'id'),
			[], 'array_key on two empty arrays: no changes'
		);
	};

	subtest 'unordered: array_key, multiple fields change in matched element' => sub {
		my $old = [{id => 1, name => 'Alice', score => 10}];
		my $new = [{id => 1, name => 'Alicia', score => 20}];
		my $r   = diff($old, $new, array_mode => 'unordered', array_key => 'id');
		my @changes = grep { $_->{op} eq 'change' } @$r;
		is(scalar @changes, 2, 'two field changes within matched element');
	};

};

# ===========================================================================
# 5. _normalize_ignore / _is_ignored: uncovered rule combinations
# ===========================================================================

subtest 'Ignore rule edge cases' => sub {

	subtest 'wildcard with single segment /*' => sub {
		# Ignore any top-level key
		my $r = diff({a => 1}, {a => 2}, ignore => [qr{^/[^/]+$}]);
		is_deeply($r, [], 'regex matching any single-segment path: suppressed');
	};

	subtest 'wildcard where * is first segment' => sub {
		my $r = diff(
			{x => {sub => 1}, y => {sub => 2}},
			{x => {sub => 9}, y => {sub => 9}},
			ignore => ['/*/sub'],
		);
		is_deeply($r, [], 'wildcard first segment: all /*/sub changes suppressed');
	};

	subtest 'wildcard where * is last segment' => sub {
		my $r = diff(
			{users => {alice => 1, bob => 2}},
			{users => {alice => 9, bob => 9}},
			ignore => ['/users/*'],
		);
		is_deeply($r, [], 'wildcard last segment: all /users/* changes suppressed');
	};

	subtest 'wildcard with two * segments' => sub {
		my $r = diff(
			{a => {b => {c => 1}}},
			{a => {b => {c => 2}}},
			ignore => ['/a/*/*'],
		);
		is_deeply($r, [], 'double wildcard /a/*/* suppresses /a/b/c change');
	};

	subtest 'exact ignore of root path suppresses root scalar change' => sub {
		my $r = diff('old', 'new', ignore => ['']);
		is_deeply($r, [], 'ignoring root empty-string path suppresses change');
	};

	subtest 'regex ignore with capture groups: no exception' => sub {
		lives_ok(
			sub { diff({a => 1}, {a => 2}, ignore => [qr{(/\w+)$}]) },
			'regex with capture group in ignore: no exception'
		);
	};

	subtest 'multiple wildcard rules: first match wins, rest not needed' => sub {
		my $r = diff(
			{a => {b => 1}},
			{a => {b => 2}},
			ignore => ['/a/b', '/a/*', '/*/b'],
		);
		is_deeply($r, [], 'multiple overlapping rules all suppress /a/b');
	};

	subtest 'ignore rule on add op: add suppressed' => sub {
		my $r = diff({}, {secret => 'value'}, ignore => ['/secret']);
		is_deeply($r, [], 'ignore suppresses add op');
	};

	subtest 'ignore rule on remove op: remove suppressed' => sub {
		my $r = diff({secret => 'value'}, {}, ignore => ['/secret']);
		is_deeply($r, [], 'ignore suppresses remove op');
	};

};

# ===========================================================================
# 6. Cycle detection: seen-table behaviour
#    The seen table keys on {refaddr_old}{refaddr_new}.  We need to confirm
#    that a second *different* pair at the same depth is still processed.
# ===========================================================================

subtest 'Cycle detection: seen table does not over-suppress' => sub {

	subtest 'sibling keys with different refs are both diffed' => sub {
		# $a->{x} and $a->{y} are different refs — seen table must not
		# suppress the second one because the first was already visited
		my $r = diff(
			{x => {v => 1}, y => {v => 3}},
			{x => {v => 2}, y => {v => 4}},
		);
		is(scalar @$r, 2, 'both sibling sub-hashes diffed independently');
		my %by_path = map { $_->{path} => $_ } @$r;
		ok(exists $by_path{'/x/v'}, 'change at /x/v');
		ok(exists $by_path{'/y/v'}, 'change at /y/v');
	};

	subtest 'seen table: same pair seen twice, second visit suppressed' => sub {
		my $inner = {v => 1};
		my $a = {x => $inner, y => $inner};   # same ref in two places
		my $b = {x => $inner, y => $inner};
		my $r;
		lives_ok(sub { $r = diff($a, $b) }, 'shared inner ref: no infinite loop');
		isa_ok($r, 'ARRAY', 'result is arrayref');
	};

	subtest 'cycle with value change: genuine change still surfaces' => sub {
		my $a = {x => 1};  $a->{self} = $a;
		my $b = {x => 2};  $b->{self} = $b;
		my $r = diff($a, $b);
		my @ch = grep { $_->{path} eq '/x' } @$r;
		is(scalar @ch, 1, 'change at /x detected despite self-reference');
	};

};

# ===========================================================================
# 7. Hash with numeric string keys
# ===========================================================================

subtest 'Hash with numeric string keys' => sub {

	subtest 'numeric string keys sorted correctly' => sub {
		my $r = diff({'1' => 'a', '10' => 'b', '2' => 'c'},
		             {'1' => 'a', '10' => 'b', '2' => 'd'});
		is(scalar @$r, 1, 'one change');
		is($r->[0]{path}, '/2', 'path is /2');
	};

	subtest 'key "0" vs key 0: treated as same key' => sub {
		my $r = diff({0 => 'zero'}, {'0' => 'zero'});
		is_deeply($r, [], '"0" and 0 are the same hash key: no change');
	};

	subtest 'large numeric key' => sub {
		my $r = diff({99999 => 'old'}, {99999 => 'new'});
		is($r->[0]{path}, '/99999', 'large numeric key path correct');
	};

};

# ===========================================================================
# 8. compare callback: paths with array indices
# ===========================================================================

subtest 'compare callback with array-index paths' => sub {

	subtest 'comparator on array-index path fires correctly' => sub {
		# Path for index 1 is '/1' — comparator keyed on '/1'
		my $r = diff(
			[10, 1.001, 30],
			[10, 1.002, 30],
			compare => { '/1' => sub { abs($_[0] - $_[1]) < 0.01 } },
		);
		is_deeply($r, [], 'array-index comparator within tolerance: no change');
	};

	subtest 'comparator on nested array-index path' => sub {
		my $r = diff(
			{data => [10, 20]},
			{data => [10, 25]},
			compare => { '/data/1' => sub { abs($_[0] - $_[1]) < 10 } },
		);
		is_deeply($r, [], 'nested array-index comparator within tolerance: no change');
	};

	subtest 'comparator receives correct values for array element' => sub {
		my ($got_old, $got_new);
		diff(
			[100, 200],
			[100, 999],
			compare => { '/1' => sub { $got_old = $_[0]; $got_new = $_[1]; 0 } },
		);
		is($got_old, 200, 'comparator arg 0 is old array element');
		is($got_new, 999, 'comparator arg 1 is new array element');
	};

	subtest 'comparator not called for add op' => sub {
		my $called = 0;
		diff(
			{},
			{x => 42},
			compare => { '/x' => sub { $called++; 1 } },
		);
		is($called, 0, 'comparator not invoked for add op');
	};

	subtest 'comparator not called for remove op' => sub {
		my $called = 0;
		diff(
			{x => 42},
			{},
			compare => { '/x' => sub { $called++; 1 } },
		);
		is($called, 0, 'comparator not invoked for remove op');
	};

};

# ===========================================================================
# 9. Renderer: undef field values
#    Engine can produce undef from/to/value if Perl data contains undef.
#    Renderers must not die.
# ===========================================================================

subtest 'Renderer: undef field values' => sub {

	subtest 'Renderer::Text: undef from value: no exception' => sub {
		lives_ok(
			sub { $render_text->([{op => 'change', path => '/x', from => undef, to => 'y'}]) },
			'Text renderer: undef from: no exception'
		);
	};

	subtest 'Renderer::Text: undef to value: no exception' => sub {
		lives_ok(
			sub { $render_text->([{op => 'change', path => '/x', from => 'y', to => undef}]) },
			'Text renderer: undef to: no exception'
		);
	};

	subtest 'Renderer::Text: undef value in add: no exception' => sub {
		lives_ok(
			sub { $render_text->([{op => 'add', path => '/x', value => undef}]) },
			'Text renderer: undef add value: no exception'
		);
	};

	subtest 'Renderer::Test2: undef from value: no exception' => sub {
		lives_ok(
			sub { $render_t2->([{op => 'change', path => '/x', from => undef, to => 'y'}]) },
			'Test2 renderer: undef from: no exception'
		);
	};

	subtest 'Renderer::Test2: undef to value: no exception' => sub {
		lives_ok(
			sub { $render_t2->([{op => 'remove', path => '/x', from => undef}]) },
			'Test2 renderer: undef remove from: no exception'
		);
	};

	subtest 'diff_text: undef hash value change renders without exception' => sub {
		lives_ok(
			sub { diff_text({x => undef}, {x => 'now set'}) },
			'diff_text: undef->defined: no exception'
		);
	};

	subtest 'diff_json: undef hash value: valid JSON output' => sub {
		require JSON::MaybeXS;
		my $j;
		lives_ok(sub { $j = diff_json({x => undef}, {x => 'now set'}) },
			'diff_json: undef value: no exception');
		my $d = eval { JSON::MaybeXS::decode_json($j) };
		ok(!$@, 'diff_json: undef value: valid JSON');
	};

};

# ===========================================================================
# 10. Renderer: multiple changes to same path (hand-crafted)
#     The engine never produces this but a caller could pass it to a renderer.
# ===========================================================================

subtest 'Renderer: duplicate path entries in change list' => sub {

	subtest 'Renderer::Text: two changes to same path: both rendered' => sub {
		my $out = $render_text->([
			{op => 'change', path => '/x', from => 1, to => 2},
			{op => 'change', path => '/x', from => 2, to => 3},
		]);
		my @headers = ($out =~ /^~ \/x$/mg);
		is(scalar @headers, 2, 'Text renderer: both changes rendered');
	};

	subtest 'Renderer::Test2: two changes to same path: both rendered' => sub {
		my $out = $render_t2->([
			{op => 'change', path => '/x', from => 1, to => 2},
			{op => 'change', path => '/x', from => 2, to => 3},
		]);
		my @headers = ($out =~ /^# Difference at \/x$/mg);
		is(scalar @headers, 2, 'Test2 renderer: both changes rendered');
	};

};

# ===========================================================================
# 11. diff_yaml: structural round-trip
#     The YAML output must decode back to a structure that faithfully
#     represents the change list.
# ===========================================================================

subtest 'diff_yaml: structural round-trip' => sub {

	subtest 'decoded YAML is an arrayref of hashrefs' => sub {
		require YAML::XS;
		my $y       = diff_yaml({a => 1}, {a => 2});
		my $decoded = YAML::XS::Load($y);
		isa_ok($decoded, 'ARRAY', 'decoded YAML is arrayref');
		isa_ok($decoded->[0], 'HASH', 'first element is hashref');
	};

	subtest 'decoded YAML preserves op field' => sub {
		require YAML::XS;
		my $decoded = YAML::XS::Load(diff_yaml({a => 1}, {a => 2}));
		is($decoded->[0]{op}, 'change', 'op=change preserved through YAML');
	};

	subtest 'decoded YAML preserves path field' => sub {
		require YAML::XS;
		my $decoded = YAML::XS::Load(diff_yaml({name => 'A'}, {name => 'B'}));
		is($decoded->[0]{path}, '/name', 'path preserved through YAML');
	};

	subtest 'decoded YAML preserves from and to fields' => sub {
		require YAML::XS;
		my $decoded = YAML::XS::Load(diff_yaml({x => 'old'}, {x => 'new'}));
		is($decoded->[0]{from}, 'old', 'from preserved through YAML');
		is($decoded->[0]{to},   'new', 'to preserved through YAML');
	};

	subtest 'decoded YAML for add op has value field' => sub {
		require YAML::XS;
		my $decoded = YAML::XS::Load(diff_yaml({}, {added => 42}));
		is($decoded->[0]{op},    'add', 'op=add preserved');
		is($decoded->[0]{value},  42,   'value=42 preserved');
	};

	subtest 'decoded YAML for remove op has from field' => sub {
		require YAML::XS;
		my $decoded = YAML::XS::Load(diff_yaml({gone => 'bye'}, {}));
		is($decoded->[0]{op},   'remove', 'op=remove preserved');
		is($decoded->[0]{from}, 'bye',    'from=bye preserved');
	};

	subtest 'decoded YAML entry count matches diff() count' => sub {
		require YAML::XS;
		my $old = {a => 1, b => 2, c => 3};
		my $new = {a => 9, b => 2, c => 99};
		my $changes = diff($old, $new);
		my $decoded = YAML::XS::Load(diff_yaml($old, $new));
		is(scalar @$decoded, scalar @$changes,
			'YAML entry count matches diff() count');
	};

};

# ===========================================================================
# 12. array_mode interactions with other options
# ===========================================================================

subtest 'array_mode interactions with ignore and compare' => sub {

	subtest 'lcs + ignore: ignored path within array element suppressed' => sub {
		my $r = diff(
			[{a => 1, b => 10}, {a => 2, b => 20}],
			[{a => 1, b => 99}, {a => 2, b => 99}],
			array_mode => 'lcs',
			ignore     => [qr{/b$}],
		);
		is_deeply($r, [], 'lcs + ignore: b changes suppressed');
	};

	subtest 'unordered + ignore: ignored path within matched element suppressed' => sub {
		my $r = diff(
			[{id => 1, ts => 'old', val => 'x'}],
			[{id => 1, ts => 'new', val => 'x'}],
			array_mode => 'unordered',
			array_key  => 'id',
			ignore     => [qr{/ts$}],
		);
		is_deeply($r, [], 'unordered + array_key + ignore: ts change suppressed');
	};

	subtest 'index + compare: comparator fires for array element' => sub {
		my $r = diff(
			[1.001, 2.0],
			[1.002, 3.0],
			array_mode => 'index',
			compare    => { '/0' => sub { abs($_[0] - $_[1]) < 0.01 } },
		);
		is(scalar @$r, 1, 'index + compare: only /1 change reported');
		is($r->[0]{path}, '/1', 'surviving change is at /1');
	};

};

# ===========================================================================
# 13. Sorting stability in _diff_hash
#     Changes must always be emitted in sorted key order regardless of the
#     order keys were inserted into the hash.
# ===========================================================================

subtest '_diff_hash: sorted key order is stable' => sub {

	subtest 'keys in reverse insertion order: paths still sorted' => sub {
		my %old;
		my %new;
		for my $k (reverse 'a'..'f') {
			$old{$k} = 1;
			$new{$k} = 2;
		}
		my $r     = diff(\%old, \%new);
		my @paths = map { $_->{path} } @$r;
		is_deeply(\@paths, [sort @paths], 'paths emitted in sorted order');
	};

	subtest 'mixed numeric and alpha keys: paths sorted lexicographically' => sub {
		my $r = diff(
			{z => 1, a => 2, '1' => 3},
			{z => 9, a => 9, '1' => 9},
		);
		my @paths = map { $_->{path} } @$r;
		is_deeply(\@paths, [sort @paths], 'mixed keys: sorted order');
	};

};

# ===========================================================================
# 14. Public API: options that should not interfere with each other
# ===========================================================================

subtest 'Option orthogonality' => sub {

	subtest 'ignore does not affect compare paths' => sub {
		# ignore /a, compare /b — /b change should still be caught by comparator
		my $r = diff(
			{a => 1, b => 1.001},
			{a => 9, b => 1.002},
			ignore  => ['/a'],
			compare => { '/b' => sub { abs($_[0] - $_[1]) < 0.01 } },
		);
		is_deeply($r, [], 'ignore /a + compare /b within tolerance: no changes');
	};

	subtest 'compare does not bleed into ignored paths' => sub {
		my $called = 0;
		diff(
			{a => 1},
			{a => 2},
			ignore  => ['/a'],
			compare => { '/a' => sub { $called++; 0 } },
		);
		is($called, 0, 'comparator not called for ignored path');
	};

	subtest 'array_mode does not affect hash diffing' => sub {
		# Setting array_mode should not change how top-level hash is diffed
		my $r1 = diff({a => 1}, {a => 2});
		my $r2 = diff({a => 1}, {a => 2}, array_mode => 'lcs');
		is_deeply($r1, $r2, 'array_mode does not affect hash diff');
	};

	subtest 'all options together on a structure that exercises all of them' => sub {
		my $old = {
			name   => 'Widget',
			price  => 9.999,
			debug  => 'old',
			items  => ['b', 'a'],
		};
		my $new = {
			name   => 'Widget',
			price  => 10.001,
			debug  => 'new',           # ignored
			items  => ['a', 'b'],      # reordered — unordered sees no change
		};
		my $r = diff($old, $new,
			ignore     => ['/debug'],
			compare    => { '/price' => sub { abs($_[0] - $_[1]) < 0.01 } },
			array_mode => 'unordered',
		);
		is_deeply($r, [], 'all options combined: no spurious changes');
	};

};

# ===========================================================================
# 15. Renderer::Text: sigil distinction
#     "- /path" (remove header) vs "- value" (remove/change body) look
#     similar; the path line must carry the path, the body line the value.
# ===========================================================================

subtest 'Renderer::Text: sigil and content distinction' => sub {

	subtest 'change: ~ on header, - on from, + on to' => sub {
		my $out = $render_text->([
			{op => 'change', path => '/p', from => 'F', to => 'T'}
		]);
		like($out, qr/^~ \/p$/m,  'change header uses ~ sigil');
		like($out, qr/^- F$/m,    'from uses - sigil without path');
		like($out, qr/^\+ T$/m,   'to uses + sigil without path');
		unlike($out, qr/^~ F/m,   'from value not prefixed with ~');
		unlike($out, qr/^~ T/m,   'to value not prefixed with ~');
	};

	subtest 'remove: - on header path, - on from value' => sub {
		my $out = $render_text->([
			{op => 'remove', path => '/gone', from => 'val'}
		]);
		like($out, qr/^- \/gone$/m, 'remove header: - /gone');
		like($out, qr/^- val$/m,    'remove body: - val');
	};

	subtest 'add: + on header path, + on value' => sub {
		my $out = $render_text->([
			{op => 'add', path => '/new', value => 'v'}
		]);
		like($out, qr/^\+ \/new$/m, 'add header: + /new');
		like($out, qr/^\+ v$/m,     'add body: + v');
	};

	subtest 'no ~ sigil appears in add or remove output' => sub {
		my $out = $render_text->([
			{op => 'add',    path => '/x', value => 'v'},
			{op => 'remove', path => '/y', from  => 'w'},
		]);
		unlike($out, qr/^~/m, 'no ~ sigil in add/remove output');
	};

};

# ===========================================================================
# 16. Large array modes: correctness at scale
# ===========================================================================

subtest 'Array modes at scale' => sub {

	subtest 'index mode: 1000-element array, one change' => sub {
		my @old = (1..1000);
		my @new = @old;
		$new[499] = 9999;
		my $r = diff(\@old, \@new, array_mode => 'index');
		is(scalar @$r,    1,     '1000-elem index: one change');
		is($r->[0]{from}, 500,   'from=500');
		is($r->[0]{to},   9999,  'to=9999');
	};

	subtest 'lcs mode: 200-element array, one insertion' => sub {
		my @old = (1..200);
		my @new = (1..100, 9999, 101..200);
		my $r   = diff(\@old, \@new, array_mode => 'lcs');
		my @adds = grep { $_->{op} eq 'add' } @$r;
		is(scalar @adds,    1,    'lcs 200-elem: one insertion');
		is($adds[0]{value}, 9999, 'inserted value is 9999');
	};

	subtest 'unordered mode: 500-element array reversed, no changes' => sub {
		my @elems = map { "e$_" } 1..500;
		my @rev   = reverse @elems;
		my $r     = diff(\@elems, \@rev, array_mode => 'unordered');
		is_deeply($r, [], 'unordered 500-elem reversal: no changes');
	};

};

done_testing();
