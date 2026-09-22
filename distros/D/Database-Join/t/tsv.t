#!/usr/bin/perl

# End-to-end tests for Database::Join when the component databases are backed
# by tab-separated value (.tsv) files, discovered and parsed by
# Database::Abstraction 0.43+ via Text::xSV::Slurp with sep_char => "\t".
#
# Fixtures live in t/data/ as djtsv_a.tsv and djtsv_b.tsv.
# Stub packages in t/lib/Database/ map to those files.
#
#   djtsv_a (primary):
#       entry | name  | tier
#       A1      Alice   gold
#       A2      Bob     silver
#       A3      Carol   bronze   <- primary-only key
#
#   djtsv_b (secondary):
#       entry | score
#       A1      95
#       A2      72
#       A4      88               <- secondary-only key

use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;
use Test::Most;
use Readonly;

BEGIN {
	eval { require Database::Abstraction; require Text::xSV::Slurp };
	plan skip_all => 'Database::Abstraction and Text::xSV::Slurp required'
		if $@;
}

use lib 't/lib';
use Database::djtsv_a;
use Database::djtsv_b;
use_ok('Database::Join');

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $DIR    => File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
Readonly::Scalar my $KEY_A1 => 'A1';
Readonly::Scalar my $KEY_A2 => 'A2';
Readonly::Scalar my $KEY_A3 => 'A3';
Readonly::Scalar my $KEY_A4 => 'A4';

Readonly::Scalar my $NAME_A1  => 'Alice';
Readonly::Scalar my $NAME_A2  => 'Bob';
Readonly::Scalar my $TIER_A1  => 'gold';
Readonly::Scalar my $TIER_A2  => 'silver';
Readonly::Scalar my $SCORE_A1 => 95;
Readonly::Scalar my $SCORE_A2 => 72;
Readonly::Scalar my $SCORE_A4 => 88;

# ---------------------------------------------------------------------------
# Fixture instantiation
# ---------------------------------------------------------------------------

my $da_a = Database::djtsv_a->new($DIR);
my $da_b = Database::djtsv_b->new($DIR);

ok defined $da_a, 'djtsv_a DA instantiated from TSV file';
ok defined $da_b, 'djtsv_b DA instantiated from TSV file';

# ===========================================================================
# S1: Left join (default) -- primary defines the key set
# ===========================================================================

subtest 'left join: primary key set, secondary fills in where present' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	my $rows = $join->selectall_arrayref();
	is scalar @{$rows}, 3, 'left join returns 3 rows (A1, A2, A3)';

	my %by_key = map { $_->{entry} => $_ } @{$rows};
	ok  exists $by_key{$KEY_A1}, 'A1 present (in both)';
	ok  exists $by_key{$KEY_A2}, 'A2 present (in both)';
	ok  exists $by_key{$KEY_A3}, 'A3 present (primary-only)';
	ok !exists $by_key{$KEY_A4}, 'A4 absent (secondary-only)';

	is $by_key{$KEY_A1}{name},  $NAME_A1,  'A1 name from primary TSV';
	is $by_key{$KEY_A1}{score}, $SCORE_A1, 'A1 score from secondary TSV';
	ok !defined $by_key{$KEY_A3}{score}, 'A3 score undef (no secondary row)';
};

# ===========================================================================
# S2: Inner join -- only keys present in both databases
# ===========================================================================

subtest 'inner join: only keys present in both TSV databases' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
		join_type   => 'inner',
	);

	my $rows = $join->selectall_arrayref();
	is scalar @{$rows}, 2, 'inner join returns 2 rows (A1, A2)';

	my %by_key = map { $_->{entry} => $_ } @{$rows};
	ok  exists $by_key{$KEY_A1}, 'A1 present';
	ok  exists $by_key{$KEY_A2}, 'A2 present';
	ok !exists $by_key{$KEY_A3}, 'A3 absent (not in secondary)';
	ok !exists $by_key{$KEY_A4}, 'A4 absent (not in primary)';

	is $join->count(), 2, 'count() agrees with inner join row count';
};

# ===========================================================================
# S3: Outer join -- union of all keys
# ===========================================================================

subtest 'outer join: all keys from any TSV database' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
		join_type   => 'outer',
	);

	my $rows = $join->selectall_arrayref();
	is scalar @{$rows}, 4, 'outer join returns 4 rows (A1, A2, A3, A4)';

	my %by_key = map { $_->{entry} => $_ } @{$rows};
	ok  exists $by_key{$KEY_A3}, 'A3 present (primary-only)';
	ok  exists $by_key{$KEY_A4}, 'A4 present (secondary-only)';
	ok !defined $by_key{$KEY_A4}{name},  'A4 name undef (no primary row)';
	ok !defined $by_key{$KEY_A3}{score}, 'A3 score undef (no secondary row)';

	is $by_key{$KEY_A4}{score}, $SCORE_A4, 'A4 score correct from secondary TSV';
};

# ===========================================================================
# S4: Criteria routing -- column criteria reach the owning database only
# TSV uses the slurp cache; exact equality avoids the DBI/SQL path.
# ===========================================================================

subtest 'criteria routing: primary and secondary TSV columns routed correctly' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	# Primary column criterion ('tier' belongs to djtsv_a)
	my $gold = $join->selectall_arrayref(tier => $TIER_A1);
	is scalar @{$gold}, 1,          'tier=gold returns 1 row (primary column routed)';
	is $gold->[0]{entry}, $KEY_A1,  'matched row is A1';

	# Secondary column criterion ('score' belongs to djtsv_b).
	# Left join: secondary criterion promotes db_b to inner-join partner.
	my $high = $join->selectall_arrayref(score => $SCORE_A1);
	is scalar @{$high}, 1,           'score=95 returns 1 row (secondary column routed)';
	is $high->[0]{entry}, $KEY_A1,   'matched row is A1';

	# Join-column criterion broadcast to both TSV databases
	my $just_a2 = $join->selectall_arrayref(entry => $KEY_A2);
	is scalar @{$just_a2}, 1,             'join-column criterion returns 1 row';
	is $just_a2->[0]{name},  $NAME_A2,    'A2 name correct from primary TSV';
	is $just_a2->[0]{score}, $SCORE_A2,   'A2 score correct from secondary TSV';
};

# ===========================================================================
# S5: fetchrow_hashref with TSV-backed databases
# ===========================================================================

subtest 'fetchrow_hashref: correct merged row from TSV-backed databases' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	my $row = $join->fetchrow_hashref(entry => $KEY_A1);
	ok  defined $row,               'fetchrow_hashref returned a row';
	is  $row->{name},  $NAME_A1,    'name from primary TSV';
	is  $row->{tier},  $TIER_A1,    'tier from primary TSV';
	is  $row->{score}, $SCORE_A1,   'score from secondary TSV';

	my $none = $join->fetchrow_hashref(entry => 'NOKEY');
	ok !defined $none, 'fetchrow_hashref returns undef for missing key';
};

# ===========================================================================
# S6: columns() and schema() reflect the merged TSV view
# ===========================================================================

subtest 'columns() and schema() reflect the merged TSV view' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	my $cols  = $join->columns();
	my %col_h = map { $_ => 1 } @{$cols};
	ok $col_h{entry}, '"entry" (join col) in columns()';
	ok $col_h{name},  '"name" (primary) in columns()';
	ok $col_h{tier},  '"tier" (primary) in columns()';
	ok $col_h{score}, '"score" (secondary) in columns()';

	my $schema = $join->schema();
	ok ref($schema) eq 'HASH', 'schema() returns a hashref';
};

# ===========================================================================
# S7: collision_prefix with TSV-backed databases
# ===========================================================================

subtest 'collision_prefix: no colliding column names in standard fixtures' => sub {
	# djtsv_a and djtsv_b have no overlapping non-key columns, so
	# collision_prefix has no effect on column output -- but constructing
	# with it set must not croak and must leave all columns accessible.
	my $join = Database::Join->new(
		databases        => [$da_a, $da_b],
		join_column => 'entry',
		collision_prefix => { 1 => 'b' },
	);

	my $cols  = $join->columns();
	my %col_h = map { $_ => 1 } @{$cols};
	ok $col_h{name},  '"name" present (no collision, not prefixed)';
	ok $col_h{score}, '"score" present (no collision, not prefixed)';
	ok !$col_h{'b.score'}, '"b.score" absent (score only in secondary, no collision)';

	my $row = $join->fetchrow_hashref(entry => $KEY_A1);
	is $row->{score}, $SCORE_A1, 'A1 score accessible by plain name with collision_prefix set';
};

# ===========================================================================
# S8: add_database with a TSV-backed DA
# ===========================================================================

subtest 'add_database: TSV-backed secondary DA added at runtime' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a],
		join_column => 'entry',
	);

	# Before add_database: only primary columns visible
	my $cols_before = $join->columns();
	my %cb = map { $_ => 1 } @{$cols_before};
	ok !$cb{score}, '"score" absent before add_database';

	$join->add_database($da_b);

	# After add_database: secondary TSV columns visible
	my $cols_after = $join->columns();
	my %ca = map { $_ => 1 } @{$cols_after};
	ok $ca{score}, '"score" visible after add_database';

	my $rows = $join->selectall_arrayref(entry => $KEY_A2);
	is scalar @{$rows}, 1, 'A2 row present after add_database';
	is $rows->[0]{score}, $SCORE_A2,   'A2 score from TSV secondary after add_database';
};

# ===========================================================================
# S9: SQLite backend with TSV-backed sources -- left join
# TSV DAs use the regular fetch path (not dbi_source() ATTACH) because
# DBD::CSV is not a SQLite driver.  The SQLite backend spills the fetched
# rows into a temp file and executes the JOIN there.  Results must be
# identical to the in-memory (array) path.
# ===========================================================================

SKIP: {
	eval { require DBD::SQLite };
	skip 'DBD::SQLite required for SQLite backend tests', 5 if $@;

	subtest 'SQLite backend: left join over TSV-backed sources' => sub {
		my $join = Database::Join->new(
			databases   => [$da_a, $da_b],
			join_column => 'entry',
			backend     => 'sqlite',
		);

		my $rows = $join->selectall_arrayref();
		is scalar @{$rows}, 3, 'SQLite backend left join: 3 rows (A1, A2, A3)';

		my %by_key = map { $_->{entry} => $_ } @{$rows};
		ok  exists $by_key{$KEY_A1}, 'A1 present';
		ok  exists $by_key{$KEY_A3}, 'A3 present (primary-only)';
		ok !exists $by_key{$KEY_A4}, 'A4 absent (secondary-only in left join)';

		is $by_key{$KEY_A1}{name},  $NAME_A1,  'A1 name correct';
		is $by_key{$KEY_A1}{score}, $SCORE_A1, 'A1 score correct';
		ok !defined $by_key{$KEY_A3}{score}, 'A3 score undef (no secondary row)';
	};

	# =========================================================================
	# S10: SQLite backend with TSV sources -- result identity vs. array path
	# =========================================================================

	subtest 'SQLite backend: TSV results identical to array path' => sub {
		my $join_array = Database::Join->new(
			databases   => [$da_a, $da_b],
			join_column => 'entry',
			backend     => 'array',
		);
		my $join_sqlite = Database::Join->new(
			databases   => [$da_a, $da_b],
			join_column => 'entry',
			backend     => 'sqlite',
		);

		my $rows_a = $join_array->selectall_arrayref();
		my $rows_s = $join_sqlite->selectall_arrayref();

		is scalar @{$rows_s}, scalar @{$rows_a}, 'same row count from both backends';

		my @sorted_a = sort { $a->{entry} cmp $b->{entry} } @{$rows_a};
		my @sorted_s = sort { $a->{entry} cmp $b->{entry} } @{$rows_s};

		for my $i (0 .. $#sorted_a) {
			for my $col (keys %{$sorted_a[$i]}) {
				is $sorted_s[$i]{$col}, $sorted_a[$i]{$col},
					"TSV row[$i].$col matches between array and sqlite backends";
			}
		}
	};

	# =========================================================================
	# S11: SQLite backend with TSV sources -- inner join
	# =========================================================================

	subtest 'SQLite backend: inner join over TSV-backed sources' => sub {
		my $join = Database::Join->new(
			databases   => [$da_a, $da_b],
			join_column => 'entry',
			backend     => 'sqlite',
			join_type   => 'inner',
		);

		my $rows = $join->selectall_arrayref();
		is scalar @{$rows}, 2, 'SQLite backend inner join: 2 rows (A1, A2)';

		my %by_key = map { $_->{entry} => $_ } @{$rows};
		ok  exists $by_key{$KEY_A1}, 'A1 present (in both)';
		ok  exists $by_key{$KEY_A2}, 'A2 present (in both)';
		ok !exists $by_key{$KEY_A3}, 'A3 absent (primary-only)';
		ok !exists $by_key{$KEY_A4}, 'A4 absent (secondary-only)';
	};

	# =========================================================================
	# S12: SQLite backend with TSV sources -- outer join
	# =========================================================================

	subtest 'SQLite backend: outer join over TSV-backed sources' => sub {
		my $join = Database::Join->new(
			databases   => [$da_a, $da_b],
			join_column => 'entry',
			backend     => 'sqlite',
			join_type   => 'outer',
		);

		my $rows = $join->selectall_arrayref();
		is scalar @{$rows}, 4, 'SQLite backend outer join: 4 rows (A1-A4)';

		my %by_key = map { $_->{entry} => $_ } @{$rows};
		ok  exists $by_key{$KEY_A3}, 'A3 present (primary-only)';
		ok  exists $by_key{$KEY_A4}, 'A4 present (secondary-only)';
		ok !defined $by_key{$KEY_A4}{name},  'A4 name undef';
		ok !defined $by_key{$KEY_A3}{score}, 'A3 score undef';
		is $by_key{$KEY_A4}{score}, $SCORE_A4, 'A4 score correct';
	};

	# =========================================================================
	# S13: SQLite backend with TSV sources -- fetchrow_hashref
	# =========================================================================

	subtest 'SQLite backend: fetchrow_hashref with TSV-backed sources' => sub {
		my $join = Database::Join->new(
			databases   => [$da_a, $da_b],
			join_column => 'entry',
			backend     => 'sqlite',
		);

		my $row = $join->fetchrow_hashref(entry => $KEY_A1);
		ok  defined $row,              'fetchrow_hashref returned a row';
		is  $row->{name},  $NAME_A1,   'name from primary TSV';
		is  $row->{tier},  $TIER_A1,   'tier from primary TSV';
		is  $row->{score}, $SCORE_A1,  'score from secondary TSV';

		my $none = $join->fetchrow_hashref(entry => 'NOKEY');
		ok !defined $none, 'fetchrow_hashref returns undef for missing key';
	};
}

done_testing();
