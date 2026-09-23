#!/usr/bin/perl

# End-to-end tests for Database::Join when the component databases are backed
# by JSON files, parsed by Database::Abstraction 0.45+ via JSON::MaybeXS.
#
# Fixtures live in t/data/ as djjson_a.json, djjson_b.json, djjson_c.json.
# Stub packages in t/lib/Database/ map to those files.
#
#   djjson_a (primary) -- array-form JSON:
#       entry | name  | tier
#       A1      Alice   gold
#       A2      Bob     silver
#       A3      Carol   bronze   <- primary-only key
#
#   djjson_b (secondary) -- array-form JSON:
#       entry | score
#       A1      95
#       A2      72
#       A4      88               <- secondary-only key
#
#   djjson_c (secondary) -- object-form JSON (key => {col:val}):
#       entry | city
#       A1      London
#       A2      Paris
#       A4      Berlin           <- secondary-only key
#
# djjson_c tests that the object-keyed JSON form ({"key":{"col":val}}) is
# normalized by DA into the same internal representation as array-form, so
# Database::Join can consume it identically.

use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;
use Test::Most;
use Readonly;

BEGIN {
	eval { require Database::Abstraction; require JSON::MaybeXS };
	plan skip_all => 'Database::Abstraction and JSON::MaybeXS required'
		if $@;
}

use lib 't/lib';
use Database::djjson_a;
use Database::djjson_b;
use Database::djjson_c;
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
Readonly::Scalar my $CITY_A1  => 'London';
Readonly::Scalar my $CITY_A4  => 'Berlin';

# ---------------------------------------------------------------------------
# Fixture instantiation
# ---------------------------------------------------------------------------

my $da_a = Database::djjson_a->new($DIR);
my $da_b = Database::djjson_b->new($DIR);
my $da_c = Database::djjson_c->new($DIR);

ok defined $da_a, 'djjson_a DA instantiated from array-form JSON file';
ok defined $da_b, 'djjson_b DA instantiated from array-form JSON file';
ok defined $da_c, 'djjson_c DA instantiated from object-form JSON file';

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

	is $by_key{$KEY_A1}{name},  $NAME_A1,  'A1 name from primary JSON';
	is $by_key{$KEY_A1}{score}, $SCORE_A1, 'A1 score from secondary JSON';
	ok !defined $by_key{$KEY_A3}{score}, 'A3 score undef (no secondary row)';
};

# ===========================================================================
# S2: Inner join -- only keys present in both databases
# ===========================================================================

subtest 'inner join: only keys present in both JSON databases' => sub {
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

subtest 'outer join: all keys from any JSON database' => sub {
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

	is $by_key{$KEY_A4}{score}, $SCORE_A4, 'A4 score correct from secondary JSON';
};

# ===========================================================================
# S4: Criteria routing -- column criteria reach the owning database only
# JSON uses the slurp cache; exact equality avoids the DBI/SQL path.
# ===========================================================================

subtest 'criteria routing: primary and secondary JSON columns routed correctly' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	# Primary column criterion ('tier' belongs to djjson_a)
	my $gold = $join->selectall_arrayref(tier => $TIER_A1);
	is scalar @{$gold}, 1,          'tier=gold returns 1 row (primary column routed)';
	is $gold->[0]{entry}, $KEY_A1,  'matched row is A1';

	# Secondary column criterion ('score' belongs to djjson_b).
	# Left join: secondary criterion promotes db_b to inner-join partner.
	my $high = $join->selectall_arrayref(score => $SCORE_A1);
	is scalar @{$high}, 1,          'score=95 returns 1 row (secondary column routed)';
	is $high->[0]{entry}, $KEY_A1,  'matched row is A1';

	# Join-column criterion broadcast to both JSON databases
	my $just_a2 = $join->selectall_arrayref(entry => $KEY_A2);
	is scalar @{$just_a2}, 1,             'join-column criterion returns 1 row';
	is $just_a2->[0]{name},  $NAME_A2,    'A2 name correct from primary JSON';
	is $just_a2->[0]{score}, $SCORE_A2,   'A2 score correct from secondary JSON';
};

# ===========================================================================
# S5: fetchrow_hashref with JSON-backed databases
# ===========================================================================

subtest 'fetchrow_hashref: correct merged row from JSON-backed databases' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	my $row = $join->fetchrow_hashref(entry => $KEY_A1);
	ok  defined $row,               'fetchrow_hashref returned a row';
	is  $row->{name},  $NAME_A1,    'name from primary JSON';
	is  $row->{tier},  $TIER_A1,    'tier from primary JSON';
	is  $row->{score}, $SCORE_A1,   'score from secondary JSON';

	my $none = $join->fetchrow_hashref(entry => 'NOKEY');
	ok !defined $none, 'fetchrow_hashref returns undef for missing key';
};

# ===========================================================================
# S6: columns() and schema() reflect the merged JSON view
# ===========================================================================

subtest 'columns() and schema() reflect the merged JSON view' => sub {
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
	ok exists $schema->{name},  '"name" in schema()';
	ok exists $schema->{score}, '"score" in schema()';
};

# ===========================================================================
# S7: Object-form JSON (hash-keyed) -- DA normalises it identically
# djjson_c is {"A1":{"city":"London"},...}, DA injects "entry" key per row.
# ===========================================================================

subtest 'object-form JSON: hash-keyed DA treated identically to array-form' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_c],
		join_column => 'entry',
	);

	my $row_a1 = $join->fetchrow_hashref(entry => $KEY_A1);
	ok  defined $row_a1,               'A1 present in join with object-form JSON';
	is  $row_a1->{name}, $NAME_A1,     'A1 name from array-form primary';
	is  $row_a1->{city}, $CITY_A1,     'A1 city from object-form secondary';

	# A3 is primary-only; no city entry
	my $row_a3 = $join->fetchrow_hashref(entry => $KEY_A3);
	ok  defined $row_a3,               'A3 present (primary-only, left join)';
	ok !defined $row_a3->{city},       'A3 city undef (not in object-form JSON)';

	# A4 is secondary-only; left join excludes it
	my $row_a4 = $join->fetchrow_hashref(entry => $KEY_A4);
	ok !defined $row_a4,               'A4 absent in left join (secondary-only)';

	# Outer join brings A4 in
	my $join_outer = Database::Join->new(
		databases   => [$da_a, $da_c],
		join_column => 'entry',
		join_type   => 'outer',
	);
	my $row_a4_outer = $join_outer->fetchrow_hashref(entry => $KEY_A4);
	ok  defined $row_a4_outer,              'A4 present in outer join';
	is  $row_a4_outer->{city}, $CITY_A4,    'A4 city correct from object-form JSON';
};

# ===========================================================================
# S8: Three-way join: two array-form + one object-form JSON
# ===========================================================================

subtest 'three-way JSON join: array+array+object form' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a, $da_b, $da_c],
		join_column => 'entry',
		join_type   => 'outer',
	);

	my $rows = $join->selectall_arrayref();
	# All unique keys: A1, A2, A3 (primary), A4 (secondary)
	is scalar @{$rows}, 4, 'three-way outer join returns 4 rows';

	my %by_key = map { $_->{entry} => $_ } @{$rows};
	is $by_key{$KEY_A1}{name},  $NAME_A1,  'A1 name present';
	is $by_key{$KEY_A1}{score}, $SCORE_A1, 'A1 score present';
	is $by_key{$KEY_A1}{city},  $CITY_A1,  'A1 city present';
	ok !defined $by_key{$KEY_A3}{city},    'A3 city undef (not in djjson_c)';
};

# ===========================================================================
# S9: collision_prefix with JSON-backed databases
# ===========================================================================

subtest 'collision_prefix: no colliding column names in standard fixtures' => sub {
	my $join = Database::Join->new(
		databases        => [$da_a, $da_b],
		join_column      => 'entry',
		collision_prefix => { 1 => 'b' },
	);

	my $cols  = $join->columns();
	my %col_h = map { $_ => 1 } @{$cols};
	ok $col_h{name},       '"name" present (no collision, not prefixed)';
	ok $col_h{score},      '"score" present (no collision, not prefixed)';
	ok !$col_h{'b.score'}, '"b.score" absent (score only in secondary, no collision)';

	my $row = $join->fetchrow_hashref(entry => $KEY_A1);
	is $row->{score}, $SCORE_A1, 'A1 score accessible by plain name with collision_prefix set';
};

# ===========================================================================
# S10: add_database with a JSON-backed DA
# ===========================================================================

subtest 'add_database: JSON-backed secondary DA added at runtime' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a],
		join_column => 'entry',
	);

	my $cols_before = $join->columns();
	my %cb = map { $_ => 1 } @{$cols_before};
	ok !$cb{score}, '"score" absent before add_database';

	$join->add_database($da_b);

	my $cols_after = $join->columns();
	my %ca = map { $_ => 1 } @{$cols_after};
	ok $ca{score}, '"score" visible after add_database';

	my $rows = $join->selectall_arrayref(entry => $KEY_A2);
	is scalar @{$rows}, 1,           'A2 row present after add_database';
	is $rows->[0]{score}, $SCORE_A2, 'A2 score from JSON secondary after add_database';
};

# ===========================================================================
# S11: updated() is non-undef for JSON-backed DAs (file mtime)
# DB::Join's _cache_fresh uses updated() for cache invalidation;
# JSON-backed DAs must return a defined timestamp so the check works.
# ===========================================================================

subtest 'updated() is defined for JSON-backed DA (file mtime)' => sub {
	# DA sets _updated from stat() of the slurp file.
	ok defined $da_a->updated(), 'djjson_a updated() is defined';
	ok defined $da_b->updated(), 'djjson_b updated() is defined';
	ok defined $da_c->updated(), 'djjson_c updated() is defined';

	# timestamp must be a positive integer (Unix epoch seconds)
	ok $da_a->updated() > 0, 'djjson_a updated() is a positive epoch timestamp';
};

# ===========================================================================
# S12: SQLite backend with JSON-backed sources
# JSON DAs don't implement dbi_source(), so DB::Join always uses the spill
# path.  Results must be identical to the in-memory (array) path.
# ===========================================================================

SKIP: {
	eval { require DBD::SQLite };
	skip 'DBD::SQLite required for SQLite backend tests', 5 if $@;

	subtest 'SQLite backend: left join over JSON-backed sources' => sub {
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

	subtest 'SQLite backend: JSON results identical to array path' => sub {
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
					"JSON row[$i].$col matches between array and sqlite backends";
			}
		}
	};

	subtest 'SQLite backend: inner join over JSON-backed sources' => sub {
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

	subtest 'SQLite backend: outer join over JSON-backed sources' => sub {
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

	subtest 'SQLite backend: object-form JSON spilled correctly' => sub {
		# djjson_c is object-keyed; DA normalises it to array-of-hashrefs
		# before DB::Join sees it.  The spill path must handle this correctly.
		my $join = Database::Join->new(
			databases   => [$da_a, $da_c],
			join_column => 'entry',
			backend     => 'sqlite',
		);

		my $row = $join->fetchrow_hashref(entry => $KEY_A1);
		ok  defined $row,              'A1 row present (SQLite + object-form JSON)';
		is  $row->{name}, $NAME_A1,    'A1 name from array-form primary';
		is  $row->{city}, $CITY_A1,    'A1 city from object-form secondary (spilled)';
	};
}

done_testing();
