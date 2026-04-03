#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Data::Hash::Diff::Smart', qw(diff diff_text)) }

# github_1.t - Regression test for GitHub issue #1

# Unordered array mode with arrays of hash references was comparing by
# memory address (C<HASH(0x...)>) rather than by structure or nominated
# key field, causing false positives and garbled diff output.

# ---------------------------------------------------------------------------
# 1. Baseline: sorted order, no options - must report no changes
# ---------------------------------------------------------------------------

{
	my $old = [
		{ id => 1, name => 'Alice' },
		{ id => 2, name => 'Bob'   },
	];
	my $new = [
		{ id => 1, name => 'Alice' },
		{ id => 2, name => 'Bob'   },
	];

	my $changes = diff($old, $new);
	is_deeply($changes, [], 'identical sorted arrays: no changes (baseline)')
		or diag diff_text($old, $new);
}

# ---------------------------------------------------------------------------
# 2. The bug: reversed order, unordered mode, no array_key
#    Old behaviour: reported spurious changes with HASH(0x...) values.
#    Correct behaviour: no changes (elements are structurally identical).
# ---------------------------------------------------------------------------

{
	my $old = [
		{ id => 1, name => 'Alice' },
		{ id => 2, name => 'Bob'   },
	];
	my $new = [
		{ id => 2, name => 'Bob'   },
		{ id => 1, name => 'Alice' },
	];

	my $changes = diff($old, $new, array_mode => 'unordered');

	is_deeply($changes, [],
		'reversed order, unordered mode, no array_key: no changes reported')
		or diag diff_text($old, $new, array_mode => 'unordered');

	# Guard against the original HASH(0x...) symptom explicitly
	if (@$changes) {
		my @addr_changes = grep {
			   (defined $_->{value} && $_->{value} =~ /^HASH\(0x/)
			|| (defined $_->{from}  && $_->{from}  =~ /^HASH\(0x/)
		} @$changes;

		is(scalar @addr_changes, 0,
			'no HASH(0x...) memory addresses appear in diff output');
	}
}

# ---------------------------------------------------------------------------
# 3. array_key: reversed order, nominated key field - no changes
# ---------------------------------------------------------------------------

{
	my $old = [
		{ id => 1, name => 'Alice' },
		{ id => 2, name => 'Bob'   },
	];
	my $new = [
		{ id => 2, name => 'Bob'   },
		{ id => 1, name => 'Alice' },
	];

	my $changes = diff($old, $new, array_mode => 'unordered', array_key => 'id');

	is_deeply($changes, [],
		'reversed order, array_key => id: no changes reported')
		or diag diff_text($old, $new, array_mode => 'unordered', array_key => 'id');
}

# ---------------------------------------------------------------------------
# 4. array_key: real change detected after reordering
# ---------------------------------------------------------------------------

{
	my $old = [
		{ id => 1, name => 'Alice' },
		{ id => 2, name => 'Bob'   },
	];
	my $new = [
		{ id => 2, name => 'Bob'      },
		{ id => 1, name => 'Alicia'   },   # name changed
	];

	my $changes = diff($old, $new, array_mode => 'unordered', array_key => 'id');

	ok(scalar @$changes > 0,
		'array_key mode: real change in reordered array is detected');

	my ($change) = grep { $_->{op} eq 'change' } @$changes;
	ok(defined $change, 'a "change" operation is present');
	is($change->{from}, 'Alice',  'from value is Alice');
	is($change->{to},   'Alicia', 'to value is Alicia');
}

# ---------------------------------------------------------------------------
# 5. array_key: element added in new, after reordering
# ---------------------------------------------------------------------------

{
	my $old = [
		{ id => 1, name => 'Alice' },
		{ id => 2, name => 'Bob'   },
	];
	my $new = [
		{ id => 2, name => 'Bob'   },
		{ id => 3, name => 'Carol' },   # new element
		{ id => 1, name => 'Alice' },
	];

	my $changes = diff($old, $new, array_mode => 'unordered', array_key => 'id');

	my @adds = grep { $_->{op} eq 'add' } @$changes;
	is(scalar @adds, 1, 'one element added');
	is_deeply($adds[0]{value}, { id => 3, name => 'Carol' },
		'added element is Carol')
		or diag explain \@adds;
}

# ---------------------------------------------------------------------------
# 6. array_key: element removed in new, after reordering
# ---------------------------------------------------------------------------

{
	my $old = [
		{ id => 1, name => 'Alice' },
		{ id => 2, name => 'Bob'   },
		{ id => 3, name => 'Carol' },
	];
	my $new = [
		{ id => 3, name => 'Carol' },
		{ id => 1, name => 'Alice' },
		# Bob removed
	];

	my $changes = diff($old, $new, array_mode => 'unordered', array_key => 'id');

	my @removes = grep { $_->{op} eq 'remove' } @$changes;
	is(scalar @removes, 1, 'one element removed');
	is_deeply($removes[0]{from}, { id => 2, name => 'Bob' },
		'removed element is Bob')
		or diag explain \@removes;
}

# ---------------------------------------------------------------------------
# 7. array_key: three-way change, add, and remove simultaneously
# ---------------------------------------------------------------------------

{
	my $old = [
		{ id => 1, name => 'Alice' },
		{ id => 2, name => 'Bob'   },
		{ id => 3, name => 'Carol' },
	];
	my $new = [
		{ id => 3, name => 'Caroline' },  # changed
		{ id => 4, name => 'Dave'     },  # added
		{ id => 1, name => 'Alice'    },  # unchanged
		# Bob (id=2) removed
	];

	my $changes = diff($old, $new, array_mode => 'unordered', array_key => 'id');

	my @adds    = grep { $_->{op} eq 'add'    } @$changes;
	my @removes = grep { $_->{op} eq 'remove' } @$changes;
	my @changes_op = grep { $_->{op} eq 'change' } @$changes;

	is(scalar @adds,       1, 'one add (Dave)');
	is(scalar @removes,    1, 'one remove (Bob)');
	ok(scalar @changes_op >= 1, 'at least one change (Carol -> Caroline)');
}

# ---------------------------------------------------------------------------
# 8. Unordered scalar arrays still work (no array_key)
# ---------------------------------------------------------------------------

{
	my $old = [qw(apple banana cherry)];
	my $new = [qw(cherry apple banana)];

	my $changes = diff($old, $new, array_mode => 'unordered');

	is_deeply($changes, [],
		'unordered scalar array: same elements in different order = no changes');
}

# ---------------------------------------------------------------------------
# 9. Unordered scalar array: genuine addition and removal
# ---------------------------------------------------------------------------

{
	my $old = [qw(apple banana cherry)];
	my $new = [qw(apple cherry damson)];

	my $changes = diff($old, $new, array_mode => 'unordered');

	my @adds    = grep { $_->{op} eq 'add'    } @$changes;
	my @removes = grep { $_->{op} eq 'remove' } @$changes;

	is(scalar @adds,    1, 'one scalar added (damson)');
	is(scalar @removes, 1, 'one scalar removed (banana)');
}

done_testing();
