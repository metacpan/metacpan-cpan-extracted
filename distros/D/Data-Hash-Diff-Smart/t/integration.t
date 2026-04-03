#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

# integration.t - End-to-end black-box integration tests for Data::Hash::Diff::Smart

# These tests exercise complete workflows across multiple public functions.
# No internal helpers are called.  Each subtest drives the system from a
# realistic input through diff() and at least one renderer, verifying that
# the full pipeline — engine + renderer — behaves correctly together.

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
# 1. Round-trip consistency: diff() output drives every renderer
#
# The change list returned by diff() must be the same logical data that
# each renderer receives.  If diff() sees N changes, every renderer must
# reflect those same N changes.
# ===========================================================================

subtest 'Round-trip: diff() output is consistent across all renderers' => sub {

	my $old = { name => 'Alice', role => 'user',  score => 10 };
	my $new = { name => 'Alice', role => 'admin', score => 20 };

	my $changes = diff($old, $new);
	is(scalar @$changes, 2, 'diff: two changes (role and score)');

	my $text = diff_text($old, $new);
	like($text, qr/role/,  'diff_text: mentions role');
	like($text, qr/score/, 'diff_text: mentions score');

	require JSON::MaybeXS;
	my $json    = diff_json($old, $new);
	my $decoded = JSON::MaybeXS::decode_json($json);
	is(scalar @$decoded, 2, 'diff_json: two entries');

	my $yaml = diff_yaml($old, $new);
	like($yaml, qr/role/,  'diff_yaml: mentions role');
	like($yaml, qr/score/, 'diff_yaml: mentions score');

	my $t2 = diff_test2($old, $new);
	like($t2, qr/role/,  'diff_test2: mentions role');
	like($t2, qr/score/, 'diff_test2: mentions score');

};

# ===========================================================================
# 2. Identical structures: all renderers produce empty / no-op output
# ===========================================================================

subtest 'Identical structures: all renderers agree on no output' => sub {

	my $data = {
		user   => { name => 'Bob', age => 30 },
		tags   => [qw(perl cpan open-source)],
		active => 1,
	};

	my $changes = diff($data, $data);
	is_deeply($changes, [], 'diff: no changes for identical deep structure');

	my $text = diff_text($data, $data);
	ok(!length($text) || $text =~ /^\s*$/, 'diff_text: empty for identical');

	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS::decode_json(diff_json($data, $data));
	is_deeply($decoded, [], 'diff_json: empty array for identical');

	my $t2 = diff_test2($data, $data);
	ok(!length($t2) || $t2 =~ /^\s*$/, 'diff_test2: empty for identical');

};

# ===========================================================================
# 3. All three op types in a single diff
#
# One key changed, one key added, one key removed.  Every renderer must
# reflect all three operations.
# ===========================================================================

subtest 'All three op types together' => sub {

	my $old = { keep => 'same', change => 'old', remove => 'gone' };
	my $new = { keep => 'same', change => 'new', add    => 'here' };

	my $changes = diff($old, $new);

	my %by_op;
	push @{ $by_op{$_->{op}} }, $_ for @$changes;

	is(scalar @{ $by_op{change} // [] }, 1, 'one change op');
	is(scalar @{ $by_op{add}    // [] }, 1, 'one add op');
	is(scalar @{ $by_op{remove} // [] }, 1, 'one remove op');

	# diff_text must contain markers for all three
	my $text = diff_text($old, $new);
	like($text, qr/change|new|old/i, 'diff_text: change present');
	like($text, qr/add|here/i,       'diff_text: add present');
	like($text, qr/remove|gone/i,    'diff_text: remove present');

	# diff_json must contain all three op types
	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS::decode_json(diff_json($old, $new));
	my %json_ops;
	$json_ops{$_->{op}}++ for @$decoded;
	ok($json_ops{change}, 'diff_json: change op present');
	ok($json_ops{add},    'diff_json: add op present');
	ok($json_ops{remove}, 'diff_json: remove op present');

	# diff_test2 lines must all carry the "# " prefix
	my $t2   = diff_test2($old, $new);
	my @bad  = grep { length($_) && $_ !~ /^# / } split /\n/, $t2;
	is(scalar @bad, 0, 'diff_test2: all non-empty lines carry "# " prefix');

};

# ===========================================================================
# 4. ignore option flows through engine into every renderer
# ===========================================================================

subtest 'ignore option: end-to-end through all renderers' => sub {

	my $old = { public => 'changed', secret => 'also changed' };
	my $new = { public => 'new',     secret => 'new secret'   };

	my %opts = (ignore => ['/secret']);

	my $changes = diff($old, $new, %opts);
	is(scalar @$changes, 1,         'diff: only one change (secret ignored)');
	is($changes->[0]{path}, '/public', 'diff: surviving change is /public');

	my $text = diff_text($old, $new, %opts);
	like($text,   qr/public/,  'diff_text: public mentioned');
	unlike($text, qr/secret/,  'diff_text: secret suppressed');

	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS::decode_json(diff_json($old, $new, %opts));
	is(scalar @$decoded, 1, 'diff_json: one entry');
	is($decoded->[0]{path}, '/public', 'diff_json: entry is /public');

	my $t2 = diff_test2($old, $new, %opts);
	like($t2,   qr/public/, 'diff_test2: public mentioned');
	unlike($t2, qr/secret/, 'diff_test2: secret suppressed');

};

# ===========================================================================
# 5. compare option: custom comparator flows through to renderers
# ===========================================================================

subtest 'compare option: end-to-end through all renderers' => sub {

	my %opts = (
		compare => { '/price' => sub { abs($_[0] - $_[1]) < 0.01 } }
	);

	# Within tolerance: all renderers must show no changes
	{
		my $old = { price => 9.999, label => 'same' };
		my $new = { price => 10.001, label => 'same' };

		my $changes = diff($old, $new, %opts);
		is_deeply($changes, [], 'diff: within tolerance = no changes');

		my $text = diff_text($old, $new, %opts);
		ok(!length($text) || $text =~ /^\s*$/, 'diff_text: empty within tolerance');

		require JSON::MaybeXS;
		my $decoded = JSON::MaybeXS::decode_json(diff_json($old, $new, %opts));
		is_deeply($decoded, [], 'diff_json: empty within tolerance');
	}

	# Outside tolerance: all renderers must show the price change
	{
		my $old = { price => 9.00,  label => 'same' };
		my $new = { price => 10.00, label => 'same' };

		my $changes = diff($old, $new, %opts);
		is(scalar @$changes, 1, 'diff: outside tolerance = one change');

		my $text = diff_text($old, $new, %opts);
		like($text, qr/price|9|10/, 'diff_text: price change mentioned');

		require JSON::MaybeXS;
		my $decoded = JSON::MaybeXS::decode_json(diff_json($old, $new, %opts));
		is($decoded->[0]{path}, '/price', 'diff_json: change is on /price');
	}

};

# ===========================================================================
# 6. array_mode => 'index': end-to-end
# ===========================================================================

subtest "array_mode => 'index': end-to-end" => sub {

	my $old = { items => [qw(a b c)] };
	my $new = { items => [qw(a x c)] };

	my $changes = diff($old, $new, array_mode => 'index');
	is(scalar @$changes, 1,          'one element changed');
	is($changes->[0]{from}, 'b',     'from is b');
	is($changes->[0]{to},   'x',     'to is x');
	like($changes->[0]{path}, qr{/items/1}, 'path includes array index');

	my $text = diff_text($old, $new, array_mode => 'index');
	like($text, qr/b|x/, 'diff_text: old/new values present');

	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS::decode_json(
		diff_json($old, $new, array_mode => 'index')
	);
	is($decoded->[0]{from}, 'b', 'diff_json: from is b');
	is($decoded->[0]{to},   'x', 'diff_json: to is x');

};

# ===========================================================================
# 7. array_mode => 'lcs': end-to-end
# ===========================================================================

subtest "array_mode => 'lcs': end-to-end" => sub {

	# Insertion in the middle: LCS should detect one add, not two changes
	my $old = { items => [1, 3, 5] };
	my $new = { items => [1, 2, 3, 5] };

	my $changes = diff($old, $new, array_mode => 'lcs');
	my @adds    = grep { $_->{op} eq 'add' } @$changes;
	my @changes_op = grep { $_->{op} eq 'change' } @$changes;
	is(scalar @adds, 1,        'lcs: one insertion detected');
	is($adds[0]{value}, 2,     'lcs: inserted value is 2');
	is(scalar @changes_op, 0,  'lcs: no spurious change ops');

	# diff_text must mention the added value
	my $text = diff_text($old, $new, array_mode => 'lcs');
	like($text, qr/2/, 'diff_text: added value 2 mentioned');

	# diff_json must agree
	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS::decode_json(
		diff_json($old, $new, array_mode => 'lcs')
	);
	my @jadd = grep { $_->{op} eq 'add' } @$decoded;
	is(scalar @jadd,      1, 'diff_json: one add');
	is($jadd[0]{value},   2, 'diff_json: added value is 2');

	# Deletion in the middle
	my $old2 = { items => [1, 2, 3, 5] };
	my $new2 = { items => [1, 3, 5]    };

	my $changes2 = diff($old2, $new2, array_mode => 'lcs');
	my @removes  = grep { $_->{op} eq 'remove' } @$changes2;
	is(scalar @removes,     1, 'lcs: one deletion detected');
	is($removes[0]{from},   2, 'lcs: deleted value is 2');

};

# ===========================================================================
# 8. array_mode => 'unordered': end-to-end (bug #1 regression)
# ===========================================================================

subtest "array_mode => 'unordered': end-to-end" => sub {

	# Scalar elements reordered: no changes
	{
		my $old = { tags => [qw(perl cpan open-source)] };
		my $new = { tags => [qw(open-source perl cpan)] };

		my $changes = diff($old, $new, array_mode => 'unordered');
		is_deeply($changes, [], 'unordered scalars reordered: no changes');

		my $text = diff_text($old, $new, array_mode => 'unordered');
		ok(!length($text) || $text =~ /^\s*$/, 'diff_text: empty for reorder');
	}

	# Hash-ref elements reordered: no changes (bug #1)
	{
		my $old = { users => [{id=>1,name=>'Alice'},{id=>2,name=>'Bob'}] };
		my $new = { users => [{id=>2,name=>'Bob'},{id=>1,name=>'Alice'}] };

		my $changes = diff($old, $new, array_mode => 'unordered');
		is_deeply($changes, [],
			'unordered hash-refs reordered: no changes (bug #1 regression)');
	}

	# Real change within reordered hash-refs, using array_key
	{
		my $old = { users => [{id=>1,name=>'Alice'},{id=>2,name=>'Bob'}] };
		my $new = { users => [{id=>2,name=>'Bob'},{id=>1,name=>'Alicia'}] };

		my $changes = diff($old, $new,
			array_mode => 'unordered',
			array_key  => 'id',
		);
		my @ch = grep { $_->{op} eq 'change' } @$changes;
		ok(scalar @ch >= 1, 'array_key: name change detected after reorder');
		is($ch[0]{from}, 'Alice',  'from is Alice');
		is($ch[0]{to},   'Alicia', 'to is Alicia');

		my $text = diff_text($old, $new,
			array_mode => 'unordered',
			array_key  => 'id',
		);
		like($text, qr/Alice|Alicia/, 'diff_text: name change reflected');

		require JSON::MaybeXS;
		my $decoded = JSON::MaybeXS::decode_json(diff_json($old, $new,
			array_mode => 'unordered',
			array_key  => 'id',
		));
		my @jch = grep { $_->{op} eq 'change' } @$decoded;
		ok(scalar @jch >= 1, 'diff_json: name change reflected');
	}

};

# ===========================================================================
# 9. Deeply nested structures: path notation and renderer output
# ===========================================================================

subtest 'Deeply nested structures: paths and renderer output' => sub {

	my $old = {
		org => {
			dept => {
				team => {
					lead => 'Alice',
				}
			}
		}
	};
	my $new = {
		org => {
			dept => {
				team => {
					lead => 'Bob',
				}
			}
		}
	};

	my $changes = diff($old, $new);
	is(scalar @$changes, 1, 'one change in deeply nested structure');
	is($changes->[0]{path}, '/org/dept/team/lead', 'full path correct');
	is($changes->[0]{from}, 'Alice', 'from is Alice');
	is($changes->[0]{to},   'Bob',   'to is Bob');

	my $text = diff_text($old, $new);
	like($text, qr/Alice/, 'diff_text: old value present');
	like($text, qr/Bob/,   'diff_text: new value present');

	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS::decode_json(diff_json($old, $new));
	is($decoded->[0]{path}, '/org/dept/team/lead',
		'diff_json: full nested path preserved');

	my $t2 = diff_test2($old, $new);
	like($t2, qr/org|dept|team|lead/, 'diff_test2: path components mentioned');

};

# ===========================================================================
# 10. Mixed structure: hash containing arrays containing hashes
# ===========================================================================

subtest 'Mixed structure: hashes, arrays, and nested hashes together' => sub {

	my $old = {
		title  => 'Report',
		scores => [10, 20, 30],
		meta   => { version => 1, author => 'Nigel' },
	};
	my $new = {
		title  => 'Report',
		scores => [10, 99, 30],
		meta   => { version => 2, author => 'Nigel' },
	};

	my $changes = diff($old, $new);
	is(scalar @$changes, 2, 'two changes: score[1] and meta.version');

	my %by_path = map { $_->{path} => $_ } @$changes;
	ok(exists $by_path{'/scores/1'},       'change at /scores/1');
	ok(exists $by_path{'/meta/version'},   'change at /meta/version');
	is($by_path{'/scores/1'}{from},  20,   '/scores/1 from=20');
	is($by_path{'/scores/1'}{to},    99,   '/scores/1 to=99');
	is($by_path{'/meta/version'}{from}, 1, '/meta/version from=1');
	is($by_path{'/meta/version'}{to},   2, '/meta/version to=2');

	# All renderers agree on two changes
	my $text = diff_text($old, $new);
	like($text, qr/20|99/,  'diff_text: scores change present');
	like($text, qr/version/, 'diff_text: version change present');

	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS::decode_json(diff_json($old, $new));
	is(scalar @$decoded, 2, 'diff_json: two entries');

};

# ===========================================================================
# 11. Multiple options combined: ignore + compare + array_mode together
# ===========================================================================

subtest 'Multiple options combined: ignore + compare + array_mode' => sub {

	my $old = {
		name   => 'Widget',
		price  => 9.999,
		tags   => [qw(sale new)],
		debug  => 'verbose',
	};
	my $new = {
		name   => 'Widget',
		price  => 10.001,
		tags   => [qw(new sale)],   # reordered
		debug  => 'changed',        # ignored
	};

	my %opts = (
		ignore     => ['/debug'],
		compare    => { '/price' => sub { abs($_[0] - $_[1]) < 0.01 } },
		array_mode => 'unordered',
	);

	my $changes = diff($old, $new, %opts);
	is_deeply($changes, [],
		'combined options: price within tolerance, tags reordered, debug ignored = no changes');

	my $text = diff_text($old, $new, %opts);
	ok(!length($text) || $text =~ /^\s*$/, 'diff_text: empty with combined options');

	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS::decode_json(diff_json($old, $new, %opts));
	is_deeply($decoded, [], 'diff_json: empty with combined options');

	my $t2 = diff_test2($old, $new, %opts);
	ok(!length($t2) || $t2 =~ /^\s*$/, 'diff_test2: empty with combined options');

};

# ===========================================================================
# 12. Cycle detection: all renderers survive cyclic input
# ===========================================================================

subtest 'Cycle detection: all renderers survive cyclic input' => sub {

	my $a = { name => 'root', value => 1 };
	$a->{self} = $a;

	my $b = { name => 'root', value => 2 };
	$b->{self} = $b;

	my ($changes, $text, $json, $yaml, $t2);

	lives_ok(sub { $changes = diff($a, $b)           }, 'diff: survives cycle');
	lives_ok(sub { $text    = diff_text($a, $b)      }, 'diff_text: survives cycle');
	lives_ok(sub { $json    = diff_json($a, $b)      }, 'diff_json: survives cycle');
	lives_ok(sub { $yaml    = diff_yaml($a, $b)      }, 'diff_yaml: survives cycle');
	lives_ok(sub { $t2      = diff_test2($a, $b)     }, 'diff_test2: survives cycle');

	isa_ok($changes, 'ARRAY', 'diff: result is arrayref after cycle');

	require JSON::MaybeXS;
	my $decoded = eval { JSON::MaybeXS::decode_json($json) };
	ok(!$@, 'diff_json: output is valid JSON after cycle');

	# The one genuine change (value 1->2) must survive even with cycles
	my @value_changes = grep {
		$_->{op} eq 'change' && $_->{path} eq '/value'
	} @$changes;
	is(scalar @value_changes, 1, 'value change detected despite cyclic structure');

};

# ===========================================================================
# 13. Large flat hash: performance / correctness at scale
# ===========================================================================

subtest 'Large flat hash: correctness at scale' => sub {

	my %old;
	for my $i (1 .. 200) { $old{"key_$i"} = $i }
	my %new = %old;

	# Change 10 values, add 5 keys, remove 5 keys
	foreach my $i (1 .. 10) { $new{"key_$i"}   = $i * 100   }
	foreach my $i (1 .. 5)  { $new{"extra_$i"} = "added_$i" }
	foreach my $i (1 .. 5)  { delete $new{"key_1$i"}         }  # removes key_11..key_15

	my $changes = diff(\%old, \%new);

	my @changes_op = grep { $_->{op} eq 'change' } @$changes;
	my @adds       = grep { $_->{op} eq 'add'    } @$changes;
	my @removes    = grep { $_->{op} eq 'remove' } @$changes;

	is(scalar @changes_op, 10, '10 value changes detected');
	is(scalar @adds,        5, '5 additions detected');
	is(scalar @removes,     5, '5 removals detected');

	# All renderers must produce non-empty output
	my $text = diff_text(\%old, \%new);
	like($text, qr/\S/, 'diff_text: non-empty for large hash');

	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS::decode_json(diff_json(\%old, \%new));
	is(scalar @$decoded, 20, 'diff_json: 20 total entries (10+5+5)');

};

# ===========================================================================
# 14. Realistic use-case: API response comparison
#
# Simulates comparing two versions of a JSON-like API response, the
# kind of real-world task the module's SYNOPSIS implies.
# ===========================================================================

subtest 'Realistic: API response diff with ignore and array_key' => sub {

	my $v1 = {
		status  => 200,
		request_id => 'aaa-111',    # volatile — should be ignored
		user    => {
			id    => 42,
			name  => 'Nigel Horne',
			email => 'njh@nigelhorne.com',
			roles => [
				{ id => 1, name => 'editor'  },
				{ id => 2, name => 'viewer'  },
			],
		},
	};

	my $v2 = {
		status  => 200,
		request_id => 'bbb-222',    # different but ignored
		user    => {
			id    => 42,
			name  => 'N. Horne',    # changed
			email => 'njh@nigelhorne.com',
			roles => [
				{ id => 2, name => 'viewer'  },   # reordered
				{ id => 1, name => 'editor'  },
				{ id => 3, name => 'admin'   },   # added
			],
		},
	};

	my %opts = (
		ignore     => ['/request_id'],
		array_mode => 'unordered',
		array_key  => 'id',
	);

	my $changes = diff($v1, $v2, %opts);

	my @name_ch = grep { $_->{path} =~ /name/ && $_->{op} eq 'change' } @$changes;
	my @role_add = grep { $_->{op} eq 'add' } @$changes;
	my @req_id   = grep { $_->{path} =~ /request_id/ } @$changes;

	ok(scalar @name_ch  >= 1, 'name change detected');
	ok(scalar @role_add >= 1, 'new role (admin) detected as add');
	is(scalar @req_id,   0,   'request_id ignored');

	# Renderers all reflect the name change
	my $text = diff_text($v1, $v2, %opts);
	like($text, qr/Nigel Horne|N\. Horne/, 'diff_text: name change reflected');
	unlike($text, qr/request_id/, 'diff_text: request_id suppressed');

	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS::decode_json(diff_json($v1, $v2, %opts));
	my @jreq = grep { ($_->{path}//'') =~ /request_id/ } @$decoded;
	is(scalar @jreq, 0, 'diff_json: request_id not in output');

	my $t2 = diff_test2($v1, $v2, %opts);
	my @bad_lines = grep { length($_) && $_ !~ /^# / } split /\n/, $t2;
	is(scalar @bad_lines, 0, 'diff_test2: all lines carry "# " prefix');

};

# ===========================================================================
# 15. Realistic use-case: configuration file comparison
#
# Simulates diffing two versions of a parsed config, with wildcard ignore
# rules for auto-generated timestamps and per-section comparators.
# ===========================================================================

subtest 'Realistic: configuration file diff with wildcard ignore' => sub {

	my $cfg_old = {
		database => {
			host     => 'db1.example.com',
			port     => 5432,
			updated  => '2025-01-01',   # volatile timestamp
		},
		cache => {
			host     => 'cache1.example.com',
			ttl      => 300,
			updated  => '2025-01-01',   # volatile timestamp
		},
		workers => 4,
	};

	my $cfg_new = {
		database => {
			host     => 'db2.example.com',   # changed
			port     => 5432,
			updated  => '2026-04-01',        # changed but ignored
		},
		cache => {
			host     => 'cache1.example.com',
			ttl      => 600,                 # changed
			updated  => '2026-04-01',        # changed but ignored
		},
		workers => 8,                        # changed
	};

	my %opts = (
		ignore => ['/database/updated', '/cache/updated'],
	);

	my $changes = diff($cfg_old, $cfg_new, %opts);

	my %by_path = map { $_->{path} => $_ } @$changes;

	ok( exists $by_path{'/database/host'}, 'database host change detected');
	ok( exists $by_path{'/cache/ttl'},     'cache ttl change detected');
	ok( exists $by_path{'/workers'},       'workers change detected');
	ok(!exists $by_path{'/database/updated'}, 'database updated ignored');
	ok(!exists $by_path{'/cache/updated'},    'cache updated ignored');

	is(scalar @$changes, 3, 'exactly three changes after ignoring timestamps');

	# All renderers agree on three changes
	my $text = diff_text($cfg_old, $cfg_new, %opts);
	like($text, qr/db1|db2/,     'diff_text: db host change present');
	like($text, qr/300|600/,     'diff_text: ttl change present');
	like($text, qr/4|8/,         'diff_text: workers change present');
	unlike($text, qr/updated/,   'diff_text: timestamps suppressed');

	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS::decode_json(diff_json($cfg_old, $cfg_new, %opts));
	is(scalar @$decoded, 3, 'diff_json: three entries');

	my @updated = grep { ($_->{path}//'') =~ /updated/ } @$decoded;
	is(scalar @updated, 0, 'diff_json: no updated entries');

};

# ===========================================================================
# 16. diff() output drives subsequent diff_text / diff_json calls identically
#
# Calling diff() once and calling diff_text() / diff_json() independently
# must yield consistent results — the renderers must not apply different
# diffing logic from the engine.
# ===========================================================================

subtest 'diff() output is consistent with independent renderer calls' => sub {

	my $old = { a => 1, b => [1, 2, 3], c => { d => 'x' } };
	my $new = { a => 9, b => [1, 2, 9], c => { d => 'y' } };

	my $changes = diff($old, $new);

	# Count ops from diff()
	my $n = scalar @$changes;
	ok($n > 0, 'diff: at least one change');

	# diff_json should contain the same number of entries
	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS::decode_json(diff_json($old, $new));
	is(scalar @$decoded, $n, 'diff_json entry count matches diff() count');

	# Each path from diff() must appear in diff_text output
	my $text = diff_text($old, $new);
	for my $c (@$changes) {
		# paths like /a or /b/2 — take the last segment as a unique token
		(my $leaf = $c->{path}) =~ s{.*/}{};
		next unless length $leaf;
		like($text, qr/\Q$leaf\E/, "diff_text: path segment '$leaf' present");
	}

};

done_testing();
