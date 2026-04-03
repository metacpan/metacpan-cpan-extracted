#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

# unit.t - Black-box tests for the public API of Data::Hash::Diff::Smart

# Every test in this file exercises only the documented public interface.
# No internal helpers, no knowledge of Engine internals.  Each subtest
# cites the relevant POD section it is verifying.

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
# diff() — return structure
#
# POD: "Returns an arrayref of change operations"
# ===========================================================================

subtest 'diff() - return type' => sub {

	subtest 'always returns an arrayref' => sub {
		isa_ok(diff({}, {}),           'ARRAY', 'identical hashes');
		isa_ok(diff([], []),           'ARRAY', 'identical arrays');
		isa_ok(diff('a', 'a'),         'ARRAY', 'identical scalars');
		isa_ok(diff(undef, undef),     'ARRAY', 'both undef');
		isa_ok(diff({a=>1}, {a=>2}),   'ARRAY', 'changed hash');
	};

	subtest 'no changes: empty arrayref' => sub {
		is_deeply(diff({a => 1, b => 2}, {a => 1, b => 2}), [],
			'identical hashes produce empty arrayref');
		is_deeply(diff([1, 2, 3], [1, 2, 3]), [],
			'identical arrays produce empty arrayref');
		is_deeply(diff('hello', 'hello'), [],
			'identical scalars produce empty arrayref');
		is_deeply(diff(undef, undef), [],
			'both undef produces empty arrayref');
	};

};

# ===========================================================================
# diff() — change operation: op => 'change'
#
# POD: "{ op => 'change', path => '/user/name', from => 'Nigel', to => 'N. Horne' }"
# ===========================================================================

subtest "diff() - op 'change'" => sub {

	subtest 'scalar change at root' => sub {
		my $r = diff('hello', 'world');
		is(scalar @$r,    1,        'one change');
		is($r->[0]{op},   'change', 'op is change');
		is($r->[0]{from}, 'hello',  'from is correct');
		is($r->[0]{to},   'world',  'to is correct');
		is($r->[0]{path}, '',       'path is empty string at root');
	};

	subtest 'hash value change: path uses slash notation' => sub {
		my $r = diff({name => 'Nigel'}, {name => 'N. Horne'});
		is($r->[0]{op},   'change',   'op is change');
		is($r->[0]{path}, '/name',    'path is /name');
		is($r->[0]{from}, 'Nigel',    'from is Nigel');
		is($r->[0]{to},   'N. Horne', 'to is N. Horne');
	};

	subtest 'nested hash change: path reflects full depth' => sub {
		my $r = diff(
			{user => {name => 'Nigel'}},
			{user => {name => 'N. Horne'}},
		);
		is($r->[0]{path}, '/user/name', 'nested path is /user/name');
		is($r->[0]{from}, 'Nigel',      'from is Nigel');
		is($r->[0]{to},   'N. Horne',   'to is N. Horne');
	};

	subtest 'change record has no "value" key' => sub {
		my $r = diff({x => 1}, {x => 2});
		ok(!exists $r->[0]{value}, 'change record has no value key');
	};

	subtest 'undef to defined is a change' => sub {
		my $r = diff({x => undef}, {x => 'now defined'});
		is($r->[0]{op}, 'change', 'undef->defined is change');
	};

	subtest 'defined to undef is a change' => sub {
		my $r = diff({x => 'was defined'}, {x => undef});
		is($r->[0]{op}, 'change', 'defined->undef is change');
	};

	subtest 'type mismatch (scalar to hash) is a change' => sub {
		my $r = diff({x => 'scalar'}, {x => {nested => 1}});
		is($r->[0]{op}, 'change', 'scalar->hashref is change');
	};

	subtest 'type mismatch (hash to array) is a change' => sub {
		my $r = diff({x => {a => 1}}, {x => [1, 2]});
		is($r->[0]{op}, 'change', 'hashref->arrayref is change');
	};

};

# ===========================================================================
# diff() — add operation: op => 'add'
#
# POD: "{ op => 'add', path => '/tags/2', value => 'admin' }"
# ===========================================================================

subtest "diff() - op 'add'" => sub {

	subtest 'key present in new only' => sub {
		my $r = diff({a => 1}, {a => 1, b => 2});
		is(scalar @$r,      1,     'one change');
		is($r->[0]{op},     'add', 'op is add');
		is($r->[0]{path},   '/b',  'path is /b');
		is($r->[0]{value},  2,     'value is correct');
	};

	subtest 'add record has "value" key, not "from"' => sub {
		my $r = diff({}, {x => 99});
		ok( exists $r->[0]{value}, 'add record has value key');
		ok(!exists $r->[0]{from},  'add record has no from key');
		ok(!exists $r->[0]{to},    'add record has no to key');
	};

	subtest 'add of nested hash value' => sub {
		my $r = diff({user => {}}, {user => {role => 'admin'}});
		is($r->[0]{op},    'add',   'op is add');
		is($r->[0]{path},  '/user/role', 'path is /user/role');
		is($r->[0]{value}, 'admin', 'value is admin');
	};

	subtest 'adding element to array (index mode)' => sub {
		my $r = diff([1, 2], [1, 2, 3]);
		my @adds = grep { $_->{op} eq 'add' } @$r;
		is(scalar @adds,    1,   'one add');
		is($adds[0]{value}, 3,   'added value is 3');
		like($adds[0]{path}, qr{/2$}, 'path ends in index 2');
	};

};

# ===========================================================================
# diff() — remove operation: op => 'remove'
#
# POD: "{ op => 'remove', path => '/debug', from => 1 }"
# ===========================================================================

subtest "diff() - op 'remove'" => sub {

	subtest 'key present in old only' => sub {
		my $r = diff({a => 1, debug => 1}, {a => 1});
		is(scalar @$r,     1,        'one change');
		is($r->[0]{op},    'remove', 'op is remove');
		is($r->[0]{path},  '/debug', 'path is /debug');
		is($r->[0]{from},  1,        'from is correct');
	};

	subtest 'remove record has "from" key, not "value"' => sub {
		my $r = diff({x => 99}, {});
		ok( exists $r->[0]{from},  'remove record has from key');
		ok(!exists $r->[0]{value}, 'remove record has no value key');
		ok(!exists $r->[0]{to},    'remove record has no to key');
	};

	subtest 'remove of nested hash value' => sub {
		my $r = diff({user => {role => 'admin'}}, {user => {}});
		is($r->[0]{op},   'remove',      'op is remove');
		is($r->[0]{path}, '/user/role',  'path is /user/role');
		is($r->[0]{from}, 'admin',       'from is admin');
	};

	subtest 'removing element from array (index mode)' => sub {
		my $r = diff([1, 2, 3], [1, 2]);
		my @removes = grep { $_->{op} eq 'remove' } @$r;
		is(scalar @removes,    1,  'one remove');
		is($removes[0]{from},  3,  'removed value is 3');
	};

};

# ===========================================================================
# diff() — option: ignore
#
# POD: "ignore => [ '/path', qr{^/debug}, '/foo/*/bar' ]"
# POD: "Supports exact paths, regexes, and wildcard segments"
# ===========================================================================

subtest 'diff() - ignore option' => sub {

	subtest 'exact path: change suppressed' => sub {
		my $r = diff(
			{a => 1, b => 2},
			{a => 9, b => 2},
			ignore => ['/a'],
		);
		is_deeply($r, [], 'exact ignored path produces no changes');
	};

	subtest 'exact path: non-ignored path still reported' => sub {
		my $r = diff(
			{a => 1, b => 2},
			{a => 9, b => 9},
			ignore => ['/a'],
		);
		is(scalar @$r, 1, 'one change (b) despite ignore on a');
		is($r->[0]{path}, '/b', 'the surviving change is /b');
	};

	subtest 'regex: matching path suppressed' => sub {
		my $r = diff(
			{debug => 1, value => 'x'},
			{debug => 9, value => 'x'},
			ignore => [qr{^/debug$}],
		);
		is_deeply($r, [], 'regex-matched path suppressed');
	};

	subtest 'regex: non-matching path still reported' => sub {
		my $r = diff(
			{debug => 1, value => 'x'},
			{debug => 9, value => 'y'},
			ignore => [qr{^/debug$}],
		);
		is(scalar @$r, 1,       'one change survives regex ignore');
		is($r->[0]{path}, '/value', 'surviving change is /value');
	};

	subtest 'wildcard: matching path suppressed' => sub {
		my $r = diff(
			{users => {alice => {score => 1}, bob => {score => 2}}},
			{users => {alice => {score => 9}, bob => {score => 9}}},
			ignore => ['/users/*/score'],
		);
		is_deeply($r, [], 'wildcard-matched paths suppressed');
	};

	subtest 'wildcard: only matching segments suppressed' => sub {
		my $r = diff(
			{users => {alice => {score => 1, name => 'Alice'}}},
			{users => {alice => {score => 9, name => 'Alicia'}}},
			ignore => ['/users/*/score'],
		);
		is(scalar @$r, 1, 'one change survives (name)');
		like($r->[0]{path}, qr{/name$}, 'surviving change is the name field');
	};

	subtest 'multiple ignore rules applied together' => sub {
		my $r = diff(
			{a => 1, b => 2, c => 3},
			{a => 9, b => 9, c => 3},
			ignore => ['/a', '/b'],
		);
		is_deeply($r, [], 'both ignored paths suppressed');
	};

};

# ===========================================================================
# diff() — option: compare
#
# POD: "compare => { '/price' => sub { abs($_[0] - $_[1]) < 0.01 } }"
# POD: "Custom comparator callbacks for specific paths"
# ===========================================================================

subtest 'diff() - compare option' => sub {

	subtest 'custom comparator: within tolerance, no change' => sub {
		my $r = diff(
			{price => 1.001},
			{price => 1.002},
			compare => { '/price' => sub { abs($_[0] - $_[1]) < 0.01 } },
		);
		is_deeply($r, [], 'within tolerance: no change reported');
	};

	subtest 'custom comparator: outside tolerance, change reported' => sub {
		my $r = diff(
			{price => 1.00},
			{price => 1.50},
			compare => { '/price' => sub { abs($_[0] - $_[1]) < 0.01 } },
		);
		is(scalar @$r, 1,        'outside tolerance: one change');
		is($r->[0]{op}, 'change', 'op is change');
	};

	subtest 'custom comparator: only applied to its own path' => sub {
		# /price has a tolerant comparator; /tax uses default equality
		my $r = diff(
			{price => 1.001, tax => 10},
			{price => 1.002, tax => 11},
			compare => { '/price' => sub { abs($_[0] - $_[1]) < 0.01 } },
		);
		is(scalar @$r, 1,      'one change (tax); price within tolerance');
		is($r->[0]{path}, '/tax', 'change is on /tax');
	};

	subtest 'custom comparator: receives old and new values as arguments' => sub {
		my ($got_old, $got_new);
		diff(
			{x => 'OLD'},
			{x => 'NEW'},
			compare => { '/x' => sub { $got_old = $_[0]; $got_new = $_[1]; 0 } },
		);
		is($got_old, 'OLD', 'comparator receives old value as first arg');
		is($got_new, 'NEW', 'comparator receives new value as second arg');
	};

	subtest 'custom comparator: exception captured in error field' => sub {
		my $r = diff(
			{x => 1},
			{x => 2},
			compare => { '/x' => sub { die "comparator exploded\n" } },
		);
		is($r->[0]{op}, 'change', 'exception still yields a change record');
		ok(exists $r->[0]{error}, 'error field present');
		like($r->[0]{error}, qr/comparator exploded/, 'error message captured');
	};

};

# ===========================================================================
# diff() — option: array_mode
#
# POD: "array_mode => 'index' | 'lcs' | 'unordered'"
# ===========================================================================

subtest 'diff() - array_mode option' => sub {

	# -----------------------------------------------------------------------
	# index (default)
	# POD: "compare by index (default)"
	# -----------------------------------------------------------------------

	subtest 'index mode: default when array_mode not specified' => sub {
		# [1,2] vs [2,1]: index 0 changes 1->2, index 1 changes 2->1
		my $r = diff([1, 2], [2, 1]);
		is(scalar @$r, 2, 'index mode (default): two element-wise changes');
	};

	subtest 'index mode: explicit, same result as default' => sub {
		my $r_default = diff([1, 2], [2, 1]);
		my $r_explicit = diff([1, 2], [2, 1], array_mode => 'index');
		is_deeply($r_default, $r_explicit, 'explicit index same as default');
	};

	subtest 'index mode: longer new array produces adds' => sub {
		my $r = diff([1], [1, 2, 3], array_mode => 'index');
		my @adds = grep { $_->{op} eq 'add' } @$r;
		is(scalar @adds, 2, 'two adds for two new elements');
	};

	subtest 'index mode: shorter new array produces removes' => sub {
		my $r = diff([1, 2, 3], [1], array_mode => 'index');
		my @removes = grep { $_->{op} eq 'remove' } @$r;
		is(scalar @removes, 2, 'two removes for two missing elements');
	};

	# -----------------------------------------------------------------------
	# lcs
	# POD: "minimal diff using Longest Common Subsequence"
	# -----------------------------------------------------------------------

	subtest 'lcs mode: insertion in middle detected' => sub {
		my $r = diff([1, 3], [1, 2, 3], array_mode => 'lcs');
		my @adds = grep { $_->{op} eq 'add' } @$r;
		is(scalar @adds,    1, 'one insertion');
		is($adds[0]{value}, 2, 'inserted value is 2');
	};

	subtest 'lcs mode: deletion in middle detected' => sub {
		my $r = diff([1, 2, 3], [1, 3], array_mode => 'lcs');
		my @removes = grep { $_->{op} eq 'remove' } @$r;
		is(scalar @removes,    1, 'one deletion');
		is($removes[0]{from},  2, 'deleted value is 2');
	};

	subtest 'lcs mode: identical arrays produce no changes' => sub {
		my $r = diff([1, 2, 3], [1, 2, 3], array_mode => 'lcs');
		is_deeply($r, [], 'identical arrays: no changes in lcs mode');
	};

	subtest 'lcs mode: produces fewer changes than index for mid-insertion' => sub {
		# Index mode sees two changes (0->1 and 1->2 shifted); LCS sees one add
		my $r_idx = diff([1, 3], [1, 2, 3], array_mode => 'index');
		my $r_lcs = diff([1, 3], [1, 2, 3], array_mode => 'lcs');
		ok(scalar @$r_lcs <= scalar @$r_idx,
			'lcs produces no more changes than index for mid-insertion');
	};

	subtest 'lcs mode: empty old array produces adds' => sub {
		my $r = diff([], [1, 2, 3], array_mode => 'lcs');
		ok(scalar @$r > 0, 'empty old: changes produced');
		my @non_adds = grep { $_->{op} ne 'add' } @$r;
		is(scalar @non_adds, 0, 'all operations are adds');
	};

	subtest 'lcs mode: empty new array produces removes' => sub {
		my $r = diff([1, 2, 3], [], array_mode => 'lcs');
		ok(scalar @$r > 0, 'empty new: changes produced');
		my @non_removes = grep { $_->{op} ne 'remove' } @$r;
		is(scalar @non_removes, 0, 'all operations are removes');
	};

	# -----------------------------------------------------------------------
	# unordered
	# POD: "treat arrays as multisets (order ignored)"
	# -----------------------------------------------------------------------

	subtest 'unordered mode: same elements different order: no changes' => sub {
		my $r = diff([qw(a b c)], [qw(c a b)], array_mode => 'unordered');
		is_deeply($r, [], 'reordered array: no changes in unordered mode');
	};

	subtest 'unordered mode: addition detected' => sub {
		my $r = diff([qw(a b)], [qw(a b c)], array_mode => 'unordered');
		my @adds = grep { $_->{op} eq 'add' } @$r;
		is(scalar @adds, 1, 'one element added');
	};

	subtest 'unordered mode: removal detected' => sub {
		my $r = diff([qw(a b c)], [qw(a b)], array_mode => 'unordered');
		my @removes = grep { $_->{op} eq 'remove' } @$r;
		is(scalar @removes, 1, 'one element removed');
	};

	subtest 'unordered mode: duplicate scalar semantics (multiset)' => sub {
		# [a, a, b] vs [a, b, b]: one 'a' removed, one 'b' added
		my $r = diff([qw(a a b)], [qw(a b b)], array_mode => 'unordered');
		my @adds    = grep { $_->{op} eq 'add'    } @$r;
		my @removes = grep { $_->{op} eq 'remove' } @$r;
		is(scalar @adds,    1, 'one add (extra b)');
		is(scalar @removes, 1, 'one remove (extra a)');
	};

	subtest 'unordered mode: hash-ref elements, reordered, no changes' => sub {
		# Tests the array_key fix (bug #1)
		my $old = [{id => 1, name => 'Alice'}, {id => 2, name => 'Bob'}];
		my $new = [{id => 2, name => 'Bob'},   {id => 1, name => 'Alice'}];
		my $r   = diff($old, $new, array_mode => 'unordered');
		is_deeply($r, [],
			'reordered hash-ref array: no changes in unordered mode');
	};

	subtest 'unordered mode with array_key: reordered, no changes' => sub {
		my $old = [{id => 1, name => 'Alice'}, {id => 2, name => 'Bob'}];
		my $new = [{id => 2, name => 'Bob'},   {id => 1, name => 'Alice'}];
		my $r   = diff($old, $new,
			array_mode => 'unordered',
			array_key  => 'id',
		);
		is_deeply($r, [],
			'array_key mode: reorder only = no changes');
	};

	subtest 'unordered mode with array_key: real change detected' => sub {
		my $old = [{id => 1, name => 'Alice'}, {id => 2, name => 'Bob'}];
		my $new = [{id => 2, name => 'Bob'},   {id => 1, name => 'Alicia'}];
		my $r   = diff($old, $new,
			array_mode => 'unordered',
			array_key  => 'id',
		);
		my @changes = grep { $_->{op} eq 'change' } @$r;
		ok(scalar @changes >= 1, 'array_key mode: field change detected');
		is($changes[0]{from}, 'Alice',  'from is Alice');
		is($changes[0]{to},   'Alicia', 'to is Alicia');
	};

	subtest 'unordered mode with array_key: addition detected' => sub {
		my $old = [{id => 1}];
		my $new = [{id => 1}, {id => 2, name => 'New'}];
		my $r   = diff($old, $new,
			array_mode => 'unordered',
			array_key  => 'id',
		);
		my @adds = grep { $_->{op} eq 'add' } @$r;
		is(scalar @adds, 1, 'array_key mode: addition detected');
	};

	subtest 'unordered mode with array_key: removal detected' => sub {
		my $old = [{id => 1}, {id => 2}];
		my $new = [{id => 1}];
		my $r   = diff($old, $new,
			array_mode => 'unordered',
			array_key  => 'id',
		);
		my @removes = grep { $_->{op} eq 'remove' } @$r;
		is(scalar @removes, 1, 'array_key mode: removal detected');
	};

};

# ===========================================================================
# diff() — cycle detection
#
# POD: (implied by "recursive comparison" — must not loop infinitely)
# ===========================================================================

subtest 'diff() - cycle detection' => sub {

	subtest 'self-referential hash: does not loop' => sub {
		my $a = {x => 1};
		$a->{self} = $a;
		my $b = {x => 1};
		$b->{self} = $b;
		my $r;
		lives_ok(sub { $r = diff($a, $b) }, 'self-referential hash: no infinite loop');
		isa_ok($r, 'ARRAY', 'result is arrayref despite cycle');
	};

	subtest 'mutually referential hashes: does not loop' => sub {
		my $a1 = {name => 'a1'};
		my $a2 = {name => 'a2', ref => $a1};
		$a1->{ref} = $a2;
		my $b1 = {name => 'a1'};
		my $b2 = {name => 'a2', ref => $b1};
		$b1->{ref} = $b2;
		my $r;
		lives_ok(sub { $r = diff($a1, $b1) }, 'mutual cycle: no infinite loop');
		isa_ok($r, 'ARRAY', 'result is arrayref');
	};

};

# ===========================================================================
# diff_text() — public function
#
# POD: "Render the diff as a human-readable text format"
# ===========================================================================

subtest 'diff_text()' => sub {

	subtest 'returns a plain string' => sub {
		my $t = diff_text({a => 1}, {a => 2});
		ok(defined $t, 'defined');
		ok(!ref($t),   'plain string, not a reference');
	};

	subtest 'no changes: empty or whitespace-only string' => sub {
		my $t = diff_text({a => 1}, {a => 1});
		ok(!length($t) || $t =~ /^\s*$/, 'empty/whitespace for identical structures');
	};

	subtest 'changed value: output is non-empty' => sub {
		my $t = diff_text({a => 1}, {a => 2});
		like($t, qr/\S/, 'non-empty output for changed structures');
	};

	subtest 'output references the changed path' => sub {
		my $t = diff_text({user => {name => 'Alice'}}, {user => {name => 'Bob'}});
		like($t, qr/name|user/i, 'output mentions the changed field');
	};

	subtest 'old value appears in output' => sub {
		my $t = diff_text({x => 'old_value'}, {x => 'new_value'});
		like($t, qr/old_value/, 'old value present in output');
	};

	subtest 'new value appears in output' => sub {
		my $t = diff_text({x => 'old_value'}, {x => 'new_value'});
		like($t, qr/new_value/, 'new value present in output');
	};

	subtest 'accepts and applies options' => sub {
		my $t = diff_text(
			{a => 1, b => 2},
			{a => 9, b => 2},
			ignore => ['/a'],
		);
		ok(!length($t) || $t =~ /^\s*$/, 'ignored path: empty output');
	};

};

# ===========================================================================
# diff_json() — public function
#
# POD: "Render the diff as JSON using JSON::MaybeXS"
# ===========================================================================

subtest 'diff_json()' => sub {

	subtest 'returns a defined string' => sub {
		my $j = diff_json({a => 1}, {a => 2});
		ok(defined $j, 'defined');
		ok(!ref($j),   'plain string');
	};

	subtest 'output is valid JSON' => sub {
		require JSON::MaybeXS;
		my $j = diff_json({a => 1}, {a => 2});
		my $decoded = eval { JSON::MaybeXS::decode_json($j) };
		ok(!$@, "output parses as JSON: $@");
	};

	subtest 'decoded JSON is an array' => sub {
		require JSON::MaybeXS;
		my $j       = diff_json({a => 1}, {a => 2});
		my $decoded = JSON::MaybeXS::decode_json($j);
		isa_ok($decoded, 'ARRAY', 'decoded JSON');
	};

	subtest 'no changes: decoded JSON is empty array' => sub {
		require JSON::MaybeXS;
		my $j       = diff_json({a => 1}, {a => 1});
		my $decoded = JSON::MaybeXS::decode_json($j);
		is_deeply($decoded, [], 'empty JSON array for identical structures');
	};

	subtest 'change record present in JSON output' => sub {
		require JSON::MaybeXS;
		my $j       = diff_json({a => 1}, {a => 2});
		my $decoded = JSON::MaybeXS::decode_json($j);
		is($decoded->[0]{op}, 'change', 'first entry has op=change');
	};

	subtest 'path field present in JSON output' => sub {
		require JSON::MaybeXS;
		my $j       = diff_json({name => 'A'}, {name => 'B'});
		my $decoded = JSON::MaybeXS::decode_json($j);
		is($decoded->[0]{path}, '/name', 'path field is /name');
	};

	subtest 'from and to fields present for change' => sub {
		require JSON::MaybeXS;
		my $j       = diff_json({x => 'old'}, {x => 'new'});
		my $decoded = JSON::MaybeXS::decode_json($j);
		is($decoded->[0]{from}, 'old', 'from field present');
		is($decoded->[0]{to},   'new', 'to field present');
	};

	subtest 'accepts and applies options' => sub {
		require JSON::MaybeXS;
		my $j       = diff_json(
			{a => 1, b => 2},
			{a => 9, b => 2},
			ignore => ['/a'],
		);
		my $decoded = JSON::MaybeXS::decode_json($j);
		is_deeply($decoded, [], 'ignored path: empty JSON array');
	};

};

# ===========================================================================
# diff_yaml() — public function
#
# POD: "Render the diff as YAML using YAML::XS"
# ===========================================================================

subtest 'diff_yaml()' => sub {

	subtest 'returns a defined string' => sub {
		my $y = diff_yaml({a => 1}, {a => 2});
		ok(defined $y, 'defined');
		ok(!ref($y),   'plain string');
	};

	subtest 'output is non-empty for changed structures' => sub {
		my $y = diff_yaml({a => 1}, {a => 2});
		like($y, qr/\S/, 'non-empty YAML for changes');
	};

	subtest 'output contains op field' => sub {
		my $y = diff_yaml({a => 1}, {a => 2});
		like($y, qr/op.*change|change.*op/s, 'op: change appears in YAML');
	};

	subtest 'output contains path field' => sub {
		my $y = diff_yaml({name => 'A'}, {name => 'B'});
		like($y, qr{/name}, 'path /name appears in YAML output');
	};

	subtest 'no changes: no op key in output' => sub {
		my $y = diff_yaml({a => 1}, {a => 1});
		unlike($y, qr/\bop\b/, 'no op key in YAML for identical structures');
	};

	subtest 'output is valid YAML' => sub {
		require YAML::XS;
		my $y   = diff_yaml({a => 1}, {a => 2});
		my $loaded = eval { YAML::XS::Load($y) };
		ok(!$@, "output parses as YAML: $@");
	};

	subtest 'accepts and applies options' => sub {
		my $y = diff_yaml(
			{a => 1, b => 2},
			{a => 9, b => 2},
			ignore => ['/a'],
		);
		unlike($y, qr/\bop\b/, 'ignored path: no op key in YAML');
	};

};

# ===========================================================================
# diff_test2() — public function
#
# POD: "Render the diff as Test2 diagnostics suitable for diag"
# ===========================================================================

subtest 'diff_test2()' => sub {

	subtest 'returns a defined string' => sub {
		my $t = diff_test2({a => 1}, {a => 2});
		ok(defined $t, 'defined');
		ok(!ref($t),   'plain string');
	};

	subtest 'no changes: returns defined value' => sub {
		my $t = diff_test2({a => 1}, {a => 1});
		ok(defined $t, 'defined for identical structures');
	};

	subtest 'changed structure: output is non-empty' => sub {
		my $t = diff_test2({a => 1}, {a => 2});
		like($t, qr/\S/, 'non-empty for changed structures');
	};

	subtest 'output lines prefixed with "# " for Test2::diag compatibility' => sub {
		my $t = diff_test2({a => 1}, {a => 2});
		my @lines = grep { length($_) } split /\n/, $t;
		my @bad   = grep { $_ !~ /^# / } @lines;
		is(scalar @bad, 0, 'all non-empty lines start with "# "')
			or diag "Offending lines:\n" . join("\n", @bad);
	};

	subtest 'old value mentioned in output' => sub {
		my $t = diff_test2({x => 'before'}, {x => 'after'});
		like($t, qr/before/, 'old value appears in output');
	};

	subtest 'new value mentioned in output' => sub {
		my $t = diff_test2({x => 'before'}, {x => 'after'});
		like($t, qr/after/, 'new value appears in output');
	};

	subtest 'accepts and applies options' => sub {
		my $t = diff_test2(
			{a => 1, b => 2},
			{a => 9, b => 2},
			ignore => ['/a'],
		);
		ok(!length($t) || $t =~ /^\s*$/, 'ignored path: empty output');
	};

};

# ===========================================================================
# Cross-function consistency
#
# All four renderers must agree on whether a diff is empty or non-empty,
# and must all accept the same options.
# ===========================================================================

subtest 'Cross-function consistency' => sub {

	subtest 'all functions agree: no changes for identical input' => sub {
		my $old = {a => 1, b => [1, 2], c => {d => 'x'}};
		my $new = {a => 1, b => [1, 2], c => {d => 'x'}};

		my $changes = diff($old, $new);
		is_deeply($changes, [], 'diff: no changes');

		my $text = diff_text($old, $new);
		ok(!length($text) || $text =~ /^\s*$/, 'diff_text: empty for no changes');

		require JSON::MaybeXS;
		my $json    = diff_json($old, $new);
		my $decoded = JSON::MaybeXS::decode_json($json);
		is_deeply($decoded, [], 'diff_json: empty array for no changes');

		my $t2 = diff_test2($old, $new);
		ok(!length($t2) || $t2 =~ /^\s*$/, 'diff_test2: empty for no changes');
	};

	subtest 'all functions agree: changes present for differing input' => sub {
		my $old = {x => 1};
		my $new = {x => 2};

		my $changes = diff($old, $new);
		ok(scalar @$changes > 0, 'diff: changes present');

		my $text = diff_text($old, $new);
		like($text, qr/\S/, 'diff_text: non-empty for changes');

		require JSON::MaybeXS;
		my $json    = diff_json($old, $new);
		my $decoded = JSON::MaybeXS::decode_json($json);
		ok(scalar @$decoded > 0, 'diff_json: non-empty array for changes');

		my $t2 = diff_test2($old, $new);
		like($t2, qr/\S/, 'diff_test2: non-empty for changes');
	};

	subtest 'ignore option honoured consistently across all functions' => sub {
		my $old  = {a => 1, b => 2};
		my $new  = {a => 9, b => 2};
		my %opts = (ignore => ['/a']);

		my $changes = diff($old, $new, %opts);
		is_deeply($changes, [], 'diff: ignored');

		my $text = diff_text($old, $new, %opts);
		ok(!length($text) || $text =~ /^\s*$/, 'diff_text: empty when ignored');

		require JSON::MaybeXS;
		my $decoded = JSON::MaybeXS::decode_json(diff_json($old, $new, %opts));
		is_deeply($decoded, [], 'diff_json: empty when ignored');

		my $t2 = diff_test2($old, $new, %opts);
		ok(!length($t2) || $t2 =~ /^\s*$/, 'diff_test2: empty when ignored');
	};

};

done_testing();
