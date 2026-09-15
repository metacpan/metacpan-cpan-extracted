#!/usr/bin/perl

# End-to-end tests for Database::Join when the component databases are backed
# by Excel workbooks (.xlsx extension, read via DBD::Excel).
#
# Fixtures are written at run-time using Spreadsheet::WriteExcel (which
# produces the old XLS binary format; DBD::Excel reads both) and are named
# with the .xlsx extension so that Database::Abstraction's file-probe logic
# discovers them.  No pre-committed fixture files are required.

use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;
use Readonly;

BEGIN {
	eval {
		require DBD::Excel;
		require Spreadsheet::WriteExcel;
		require Database::Abstraction;
	};
	plan skip_all => 'DBD::Excel, Spreadsheet::WriteExcel and Database::Abstraction required'
		if $@;
}

use lib 't/lib';
use Database::xljoin_a;
use Database::xljoin_b;
use_ok('Database::Join');

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $KEY_K1 => 'k1';
Readonly::Scalar my $KEY_K2 => 'k2';
Readonly::Scalar my $KEY_K3 => 'k3';
Readonly::Scalar my $KEY_K4 => 'k4';

Readonly::Scalar my $AMT_K1 => 10;
Readonly::Scalar my $AMT_K2 => 20;
Readonly::Scalar my $AMT_K3 => 30;

Readonly::Scalar my $PRC_K1 => 5;
Readonly::Scalar my $PRC_K2 => 15;
Readonly::Scalar my $PRC_K4 => 25;

Readonly::Scalar my $NOTE_A_K1 => 'note-a-k1';
Readonly::Scalar my $NOTE_A_K2 => 'note-a-k2';
Readonly::Scalar my $NOTE_B_K1 => 'note-b-k1';
Readonly::Scalar my $NOTE_B_K2 => 'note-b-k2';

Readonly::Scalar my $PREFIX_B => 'b';

# ---------------------------------------------------------------------------
# Fixtures
#
#   xljoin_a (primary):
#       entry | amount | notes
#       k1      10       note-a-k1
#       k2      20       note-a-k2
#       k3      30       note-a-k3   <- only in 'a'; absent from inner join
#
#   xljoin_b (secondary):
#       entry | price | notes
#       k1      5        note-b-k1
#       k2      15       note-b-k2
#       k4      25       note-b-k4   <- only in 'b'; appears only in outer join
#
# Join-key 'entry' is shared.  'notes' collides between the two databases.
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);

sub write_xlsx {
	my ($dir, $name, $cols, @rows) = @_;
	my $path = File::Spec->catfile($dir, "$name.xlsx");
	my $wb   = Spreadsheet::WriteExcel->new($path);
	my $ws   = $wb->add_worksheet($name);

	# Header row (row 0)
	for my $ci (0 .. $#{ $cols }) {
		$ws->write(0, $ci, $cols->[$ci]);
	}
	# Data rows
	for my $ri (0 .. $#rows) {
		my $row = $rows[$ri];
		for my $ci (0 .. $#{ $cols }) {
			$ws->write($ri + 1, $ci, $row->[ $ci ]);
		}
	}
	$wb->close;
	return $path;
}

write_xlsx($dir, 'xljoin_a', [qw(entry amount notes)],
	[$KEY_K1, $AMT_K1, $NOTE_A_K1],
	[$KEY_K2, $AMT_K2, $NOTE_A_K2],
	[$KEY_K3, $AMT_K3, 'note-a-k3'],
);

write_xlsx($dir, 'xljoin_b', [qw(entry price notes)],
	[$KEY_K1, $PRC_K1, $NOTE_B_K1],
	[$KEY_K2, $PRC_K2, $NOTE_B_K2],
	[$KEY_K4, $PRC_K4, 'note-b-k4'],
);

my $da_a = Database::xljoin_a->new($dir);
my $da_b = Database::xljoin_b->new($dir);

# ===========================================================================
# S1: Left join (default) — primary defines the key set
# ===========================================================================

subtest 'left join: primary key set, secondary fills in where present' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	my $rows = $join->selectall_arrayref;
	is scalar @{$rows}, 3, 'left join returns 3 rows (k1, k2, k3)';

	my %by_key = map { $_->{entry} => $_ } @{$rows};
	ok  exists $by_key{$KEY_K1}, 'k1 present (in both)';
	ok  exists $by_key{$KEY_K2}, 'k2 present (in both)';
	ok  exists $by_key{$KEY_K3}, 'k3 present (only in primary)';
	ok !exists $by_key{$KEY_K4}, 'k4 absent (only in secondary)';

	is $by_key{$KEY_K1}{amount}, $AMT_K1, 'k1 amount from primary';
	is $by_key{$KEY_K1}{price},  $PRC_K1, 'k1 price from secondary';
	ok !defined $by_key{$KEY_K3}{price},   'k3 price undef (no secondary row)';
};

# ===========================================================================
# S2: Inner join — only keys present in both databases
# ===========================================================================

subtest 'inner join: only keys present in both databases' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
		join_type   => 'inner',
	);

	my $rows  = $join->selectall_arrayref;
	is scalar @{$rows}, 2, 'inner join returns 2 rows (k1, k2)';

	my %by_key = map { $_->{entry} => $_ } @{$rows};
	ok  exists $by_key{$KEY_K1}, 'k1 present';
	ok  exists $by_key{$KEY_K2}, 'k2 present';
	ok !exists $by_key{$KEY_K3}, 'k3 absent (not in secondary)';
	ok !exists $by_key{$KEY_K4}, 'k4 absent (not in primary)';

	is $join->count, 2, 'count() agrees with inner join row count';
};

# ===========================================================================
# S3: Outer join — union of all keys
# ===========================================================================

subtest 'outer join: all keys from any database' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
		join_type   => 'outer',
	);

	my $rows = $join->selectall_arrayref;
	is scalar @{$rows}, 4, 'outer join returns 4 rows (k1, k2, k3, k4)';

	my %by_key = map { $_->{entry} => $_ } @{$rows};
	ok exists $by_key{$KEY_K4}, 'k4 present (secondary-only key)';
	ok exists $by_key{$KEY_K3}, 'k3 present (primary-only key)';
	ok !defined $by_key{$KEY_K4}{amount}, 'k4 amount undef (no primary row)';
	ok !defined $by_key{$KEY_K3}{price},  'k3 price undef (no secondary row)';
};

# ===========================================================================
# S4: Criteria routing across XLSX-backed databases
# ===========================================================================

subtest 'criteria routing: primary and secondary columns routed correctly' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	# Primary column criterion — 'amount' belongs to xljoin_a
	my $high_amt = $join->selectall_arrayref(amount => { '>' => $AMT_K2 });
	is scalar @{$high_amt}, 1, 'amount > 20 returns 1 row';
	is $high_amt->[0]{entry}, $KEY_K3, 'matched row is k3';

	# Secondary column criterion — 'price' belongs to xljoin_b.
	# With a left join, secondary criteria promote it to inner-join partner.
	my $low_prc = $join->selectall_arrayref(price => { '<' => $PRC_K2 });
	is scalar @{$low_prc}, 1, 'price < 15 returns 1 row';
	is $low_prc->[0]{entry}, $KEY_K1, 'matched row is k1';

	# Join-column criterion broadcast to both databases
	my $just_k2 = $join->selectall_arrayref(entry => $KEY_K2);
	is scalar @{$just_k2}, 1,     'join-column criterion returns 1 row';
	is $just_k2->[0]{amount}, $AMT_K2, 'k2 amount correct';
	is $just_k2->[0]{price},  $PRC_K2, 'k2 price correct';
};

# ===========================================================================
# S5: fetchrow_hashref
# ===========================================================================

subtest 'fetchrow_hashref returns the correct merged row' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	my $row = $join->fetchrow_hashref(entry => $KEY_K1);
	ok  defined $row,            'fetchrow_hashref returned a row';
	is  $row->{amount}, $AMT_K1, 'amount from primary';
	is  $row->{price},  $PRC_K1, 'price from secondary';
};

# ===========================================================================
# S6: columns() and schema() reflect the merged XLSX-backed view
# ===========================================================================

subtest 'columns() reflects the merged XLSX-backed view; schema() returns a hashref' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	my $cols  = $join->columns;
	my %col_h = map { $_ => 1 } @{$cols};
	ok $col_h{entry},  '"entry" (join col) in columns()';
	ok $col_h{amount}, '"amount" (primary) in columns()';
	ok $col_h{price},  '"price" (secondary) in columns()';
	ok $col_h{notes},  '"notes" (last-wins from secondary) in columns()';

	# DBD::Excel does not expose column type metadata, so schema() returns an
	# empty hashref for XLSX-backed databases.  Assert it is a hashref (not
	# undef, not a crash), but do not assert any specific keys.
	my $s = $join->schema;
	ok ref($s) eq 'HASH', 'schema() returns a hashref for XLSX-backed join';
};

# ===========================================================================
# S7: collision_prefix preserves both 'notes' values from XLSX-backed DAs
# ===========================================================================

subtest 'collision_prefix: both "notes" values preserved from XLSX-backed databases' => sub {
	my $join = Database::Join->new(
		databases        => [$da_a, $da_b],
		join_column      => 'entry',
		collision_prefix => { 1 => $PREFIX_B },
	);

	my $cols  = $join->columns;
	my %col_h = map { $_ => 1 } @{$cols};
	ok  $col_h{notes},             '"notes" (primary) in columns()';
	ok  $col_h{"$PREFIX_B.notes"}, '"b.notes" (secondary collision) in columns()';
	ok !$col_h{"$PREFIX_B.entry"}, '"b.entry" absent (join_col never prefixed)';

	my ($row) = grep { $_->{entry} eq $KEY_K1 } @{ $join->selectall_arrayref };
	is  $row->{notes},             $NOTE_A_K1, 'notes = primary (a) value';
	is  $row->{"$PREFIX_B.notes"}, $NOTE_B_K1, 'b.notes = secondary (b) value';

	# Criteria on the prefixed name route to the secondary database
	my $filtered = $join->selectall_arrayref("$PREFIX_B.notes" => $NOTE_B_K2);
	is scalar @{$filtered}, 1,     'b.notes criterion returns 1 row';
	is $filtered->[0]{entry}, $KEY_K2, 'matched row is k2';
};

# ===========================================================================
# S8: add_database with an XLSX-backed DA
# ===========================================================================

subtest 'add_database: XLSX-backed DA added at runtime joins correctly' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a],
		join_column => 'entry',
	);

	$join->add_database($da_b);

	my $rows  = $join->selectall_arrayref;
	my %by_key = map { $_->{entry} => $_ } @{$rows};
	ok exists  $by_key{$KEY_K1}, 'k1 present after add_database';
	is $by_key{$KEY_K2}{price}, $PRC_K2, 'k2 price from XLSX secondary after add_database';

	my $cols  = $join->columns;
	my %col_h = map { $_ => 1 } @{$cols};
	ok $col_h{price}, '"price" available after add_database';
};

done_testing;
