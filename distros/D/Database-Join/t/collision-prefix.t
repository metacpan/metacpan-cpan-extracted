#!/usr/bin/perl

# Tests for the collision_prefix constructor parameter.
#
# Verifies that colliding secondary database columns are published under
# "$prefix.$col" while preserving the original column from earlier databases,
# that non-colliding columns and the join_column pass through without any
# prefix, and that the previous last-wins behaviour is unchanged when no
# prefix is configured.

use strict;
use warnings;

use Test::Most;
use Readonly;

use_ok('Database::Join');

# ---------------------------------------------------------------------------
# Inline component DA — no disk I/O required; supports equality and operator
# criteria on any column via a simple row-scan.
# ---------------------------------------------------------------------------
{
	package CollDA;
	use parent -norequire, 'Database::Abstraction';

	sub new {
		my ($class, %args) = @_;
		return bless {
			cols    => $args{cols}    // ['entry'],
			rows    => $args{rows}    // [],
			schema  => $args{schema}  // {},
			updated => $args{updated} // 1,
		}, $class;
	}

	sub columns    { return $_[0]->{cols} }
	sub schema     { return $_[0]->{schema} }
	sub updated    { return $_[0]->{updated} }
	sub set_logger { return $_[0] }

	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		$criteria //= {};
		my @out;
		ROW: for my $row (@{ $self->{rows} }) {
			for my $col (keys %{$criteria}) {
				my $val = $criteria->{$col};
				if (ref $val eq 'HASH') {
					for my $op (keys %{$val}) {
						my $rhs = $val->{$op};
						if    ($op eq '>')  { next ROW unless defined $row->{$col} && $row->{$col} >  $rhs }
						elsif ($op eq '<')  { next ROW unless defined $row->{$col} && $row->{$col} <  $rhs }
						elsif ($op eq '>=') { next ROW unless defined $row->{$col} && $row->{$col} >= $rhs }
						elsif ($op eq '<=') { next ROW unless defined $row->{$col} && $row->{$col} <= $rhs }
					}
				} elsif (!defined $val) {
					next ROW if defined $row->{$col};
				} else {
					next ROW unless defined $row->{$col} && $row->{$col} eq $val;
				}
			}
			push @out, { %{$row} };
		}
		return \@out;
	}

	sub DESTROY {}
}

# ---------------------------------------------------------------------------
# Constants — no magic strings/numbers in the test body
# ---------------------------------------------------------------------------
Readonly::Scalar my $ENTRY_W  => 'w';
Readonly::Scalar my $ENTRY_G  => 'g';
Readonly::Scalar my $AMOUNT_W => 10;
Readonly::Scalar my $AMOUNT_G => 20;
Readonly::Scalar my $PRICE_W  => 5;
Readonly::Scalar my $PRICE_G  => 15;
Readonly::Scalar my $NOTE_L_W => 'left-notes-w';
Readonly::Scalar my $NOTE_L_G => 'left-notes-g';
Readonly::Scalar my $NOTE_R_W => 'right-notes-w';
Readonly::Scalar my $NOTE_R_G => 'right-notes-g';
Readonly::Scalar my $PREFIX_B => 'b';

# ---------------------------------------------------------------------------
# Fixture builders — construct fresh DA objects for each subtest to avoid
# shared-state interactions between subtests.
# ---------------------------------------------------------------------------

sub left_da {
	# Primary: entry (join key), amount (unique), notes (collides with right)
	return CollDA->new(
		cols   => [qw(entry amount notes)],
		rows   => [
			{ entry => $ENTRY_W, amount => $AMOUNT_W, notes => $NOTE_L_W },
			{ entry => $ENTRY_G, amount => $AMOUNT_G, notes => $NOTE_L_G },
		],
		schema => {
			entry  => { type => 'text' },
			amount => { type => 'integer' },
			notes  => { type => 'text', source => 'left' },
		},
	);
}

sub right_da {
	# Secondary: entry (join key), price (unique), notes (collides), category (unique)
	return CollDA->new(
		cols   => [qw(entry price notes category)],
		rows   => [
			{ entry => $ENTRY_W, price => $PRICE_W, notes => $NOTE_R_W, category => 'widgets' },
			{ entry => $ENTRY_G, price => $PRICE_G, notes => $NOTE_R_G, category => 'gadgets' },
		],
		schema => {
			entry    => { type => 'text' },
			price    => { type => 'integer' },
			notes    => { type => 'text', source => 'right' },
			category => { type => 'text' },
		},
	);
}

# ===========================================================================
# S1: columns() — collision produces prefixed name; join_col never prefixed
# ===========================================================================

subtest 'columns: collision produces prefixed name, non-collisions pass through' => sub {
	my $join = Database::Join->new(
		databases        => [left_da(), right_da()],
		join_column      => 'entry',
		collision_prefix => { 1 => $PREFIX_B },
	);

	my $cols  = $join->columns;
	my %col_h = map { $_ => 1 } @{$cols};

	ok  $col_h{entry},              'join_column "entry" present';
	ok  $col_h{amount},             'primary-only "amount" present unchanged';
	ok  $col_h{notes},              'primary "notes" kept under its original name';
	ok  $col_h{"$PREFIX_B.notes"},  'secondary "notes" published as "b.notes"';
	ok  $col_h{price},              'secondary-only "price" present without prefix';
	ok  $col_h{category},           'secondary-only "category" present without prefix';
	ok !$col_h{"$PREFIX_B.entry"},  '"b.entry" absent — join_column is never prefixed';
	ok !$col_h{"$PREFIX_B.price"},  '"b.price" absent — price does not collide';
	is  scalar @{$cols}, 6, 'total 6 columns: entry, amount, notes, b.notes, price, category';
};

# ===========================================================================
# S2: Row merge — both the original value and the prefixed value survive
# ===========================================================================

subtest 'row merge: both original and prefixed values present in each merged row' => sub {
	my $join = Database::Join->new(
		databases        => [left_da(), right_da()],
		join_column      => 'entry',
		collision_prefix => { 1 => $PREFIX_B },
	);

	my $rows = $join->selectall_arrayref;
	is scalar @{$rows}, 2, 'two merged rows (one per join-key value)';

	my ($row_w) = grep { $_->{entry} eq $ENTRY_W } @{$rows};
	ok  defined $row_w,                    'row for entry=w found in result';
	is  $row_w->{notes},             $NOTE_L_W, 'notes (primary) = left value';
	is  $row_w->{"$PREFIX_B.notes"}, $NOTE_R_W, 'b.notes (secondary) = right value';
	is  $row_w->{price},             $PRICE_W,  'non-colliding price from secondary';
	is  $row_w->{amount},            $AMOUNT_W, 'non-colliding amount from primary';
};

# ===========================================================================
# S3: Criteria on the prefixed name route to the correct (secondary) database
# ===========================================================================

subtest 'criteria on prefixed column name route to the secondary database' => sub {
	my $join = Database::Join->new(
		databases        => [left_da(), right_da()],
		join_column      => 'entry',
		collision_prefix => { 1 => $PREFIX_B },
	);

	# Filtering by b.notes restricts via the secondary; secondary acts as
	# inner-join partner because it now has effective criteria.
	my $rows = $join->selectall_arrayref("$PREFIX_B.notes" => $NOTE_R_W);
	is scalar @{$rows}, 1,     'exactly one row matches b.notes=right-notes-w';
	is $rows->[0]{entry}, $ENTRY_W, 'matched row is entry=w';

	# Filtering by the plain 'notes' restricts via the primary.
	my $left_rows = $join->selectall_arrayref(notes => $NOTE_L_G);
	is scalar @{$left_rows}, 1,     'exactly one row matches notes=left-notes-g';
	is $left_rows->[0]{entry}, $ENTRY_G, 'matched row is entry=g';
};

# ===========================================================================
# S4: fetchrow_hashref returns the full prefixed structure
# ===========================================================================

subtest 'fetchrow_hashref: merged row has both original and prefixed keys' => sub {
	my $join = Database::Join->new(
		databases        => [left_da(), right_da()],
		join_column      => 'entry',
		collision_prefix => { 1 => $PREFIX_B },
	);

	my $row = $join->fetchrow_hashref(entry => $ENTRY_G);
	ok  defined $row,                     'fetchrow_hashref returned a row';
	is  $row->{notes},             $NOTE_L_G, 'notes = left (primary) value';
	is  $row->{"$PREFIX_B.notes"}, $NOTE_R_G, 'b.notes = right (secondary) value';
	is  $row->{price},             $PRICE_G,  'non-colliding price accessible';
};

# ===========================================================================
# S5: schema() keys entries under published (prefixed) names
# ===========================================================================

subtest 'schema: collision column keyed under its prefixed published name' => sub {
	my $join = Database::Join->new(
		databases        => [left_da(), right_da()],
		join_column      => 'entry',
		collision_prefix => { 1 => $PREFIX_B },
	);

	my $s = $join->schema;
	ok  exists $s->{notes},              'schema has "notes" (from primary)';
	ok  exists $s->{"$PREFIX_B.notes"},  'schema has "b.notes" (from secondary)';
	ok  exists $s->{price},              'schema has "price" (non-colliding)';
	is  $s->{notes}{source},             'left',  '"notes" schema entry comes from primary';
	is  $s->{"$PREFIX_B.notes"}{source}, 'right', '"b.notes" schema entry comes from secondary';
};

# ===========================================================================
# S6: Backward compatibility — omitting collision_prefix means last-wins
# ===========================================================================

subtest 'backward compat: no collision_prefix preserves original last-wins behaviour' => sub {
	my $join = Database::Join->new(
		databases   => [left_da(), right_da()],
		join_column => 'entry',
		# Deliberately no collision_prefix
	);

	my $cols  = $join->columns;
	my %col_h = map { $_ => 1 } @{$cols};
	ok !exists $col_h{"$PREFIX_B.notes"}, '"b.notes" absent when no collision_prefix';
	ok  exists $col_h{notes},             '"notes" present (routing to secondary, last-wins)';

	my $rows = $join->selectall_arrayref;
	my ($row) = grep { $_->{entry} eq $ENTRY_W } @{$rows};
	is  $row->{notes},            $NOTE_R_W, 'notes value is from secondary (last-wins)';
	ok !exists $row->{"$PREFIX_B.notes"}, 'no prefixed key in row hashrefs either';
};

# ===========================================================================
# S7: Index-0 entry in collision_prefix is silently ignored
# ===========================================================================

subtest 'collision_prefix index-0 entry is silently ignored' => sub {
	my $join;
	lives_ok {
		$join = Database::Join->new(
			databases        => [left_da(), right_da()],
			join_column      => 'entry',
			collision_prefix => { 0 => 'prim', 1 => $PREFIX_B },
		);
	} 'construction with index-0 prefix entry does not croak';

	my $cols  = $join->columns;
	my %col_h = map { $_ => 1 } @{$cols};
	ok !$col_h{'prim.notes'},        'primary columns not prefixed (index-0 ignored)';
	ok !$col_h{'prim.amount'},       'primary amount not prefixed';
	ok  $col_h{"$PREFIX_B.notes"},   'secondary notes still prefixed correctly';
};

# ===========================================================================
# S8: Non-colliding secondary columns carry no prefix regardless of config
# ===========================================================================

subtest 'non-colliding secondary columns are added without any prefix' => sub {
	my $join = Database::Join->new(
		databases        => [left_da(), right_da()],
		join_column      => 'entry',
		collision_prefix => { 1 => $PREFIX_B },
	);

	my $cols  = $join->columns;
	my %col_h = map { $_ => 1 } @{$cols};
	ok  $col_h{price},             '"price" present under its original name';
	ok !$col_h{"$PREFIX_B.price"}, '"b.price" absent — price has no collision';
	ok  $col_h{category},          '"category" present under its original name';

	my ($row) = grep { $_->{entry} eq $ENTRY_W } @{ $join->selectall_arrayref };
	is $row->{price}, $PRICE_W, 'price value accessible at the plain key';
};

# ===========================================================================
# S9: remove_column on the prefixed name hides the collision column only
# ===========================================================================

subtest 'remove_column on prefixed name hides collision; original column intact' => sub {
	my $join = Database::Join->new(
		databases        => [left_da(), right_da()],
		join_column      => 'entry',
		collision_prefix => { 1 => $PREFIX_B },
	)->remove_column("$PREFIX_B.notes");

	my $cols  = $join->columns;
	my %col_h = map { $_ => 1 } @{$cols};
	ok !$col_h{"$PREFIX_B.notes"}, '"b.notes" absent after remove_column';
	ok  $col_h{notes},             '"notes" (primary) still present';

	my ($row) = grep { $_->{entry} eq $ENTRY_W } @{ $join->selectall_arrayref };
	ok !exists $row->{"$PREFIX_B.notes"}, 'merged row has no b.notes key';
	is  $row->{notes}, $NOTE_L_W,         'primary notes value still correct';
};

# ===========================================================================
# S10: Three databases — independent prefixes at indices 1 and 2
# ===========================================================================

subtest 'three databases: separate prefixes produce three distinct "notes" columns' => sub {
	my $third = CollDA->new(
		cols   => [qw(entry notes extra)],
		rows   => [
			{ entry => $ENTRY_W, notes => 'third-notes-w', extra => 'ex-w' },
			{ entry => $ENTRY_G, notes => 'third-notes-g', extra => 'ex-g' },
		],
		schema => {
			entry => { type => 'text' },
			notes => { type => 'text', source => 'third' },
			extra => { type => 'text' },
		},
	);

	my $join = Database::Join->new(
		databases        => [left_da(), right_da(), $third],
		join_column      => 'entry',
		collision_prefix => { 1 => 'mid', 2 => 'tip' },
	);

	my $cols  = $join->columns;
	my %col_h = map { $_ => 1 } @{$cols};
	ok $col_h{notes},       '"notes" from primary (index 0)';
	ok $col_h{'mid.notes'}, '"mid.notes" from index-1';
	ok $col_h{'tip.notes'}, '"tip.notes" from index-2';
	ok $col_h{extra},       '"extra" from index-2, no collision, no prefix';

	my ($row) = grep { $_->{entry} eq $ENTRY_W } @{ $join->selectall_arrayref };
	is $row->{notes},       $NOTE_L_W,       'notes = primary (left) value';
	is $row->{'mid.notes'}, $NOTE_R_W,       'mid.notes = secondary (right) value';
	is $row->{'tip.notes'}, 'third-notes-w', 'tip.notes = third database value';
};

# ===========================================================================
# S11: add_database honours a collision_prefix entry pre-declared for that index
# ===========================================================================

subtest 'add_database uses a pre-declared collision_prefix entry for the new index' => sub {
	my $join = Database::Join->new(
		databases        => [left_da()],
		join_column      => 'entry',
		collision_prefix => { 1 => $PREFIX_B },
	);

	$join->add_database(right_da());

	my $cols  = $join->columns;
	my %col_h = map { $_ => 1 } @{$cols};
	ok $col_h{"$PREFIX_B.notes"}, '"b.notes" present after add_database';
	ok $col_h{notes},             '"notes" (primary) still present';

	my ($row) = grep { $_->{entry} eq $ENTRY_W } @{ $join->selectall_arrayref };
	is $row->{notes},             $NOTE_L_W, 'notes = left (primary) value';
	is $row->{"$PREFIX_B.notes"}, $NOTE_R_W, 'b.notes = right (secondary) value via add_database';
};

done_testing;
