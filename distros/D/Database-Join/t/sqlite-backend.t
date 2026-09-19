#!/usr/bin/perl

# Tests for the SQLite-backed join backend introduced in Database::Join 0.003.x.
# Covers: auto/sqlite/array dispatch, max_array_rows threshold, tmpdir,
#         result identity regression, 3-way join, collision_prefix, join_map,
#         dbi_source() zero-copy ATTACH, temp-file cleanup.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;
use Readonly;

use lib 't/lib';
use_ok('Database::Join');

# ---------------------------------------------------------------------------
# Inline test fixtures
# ---------------------------------------------------------------------------

# MinimalDA: a lightweight Database::Abstraction-compatible stub.
# Supports equality filtering, configurable columns/rows, and optional
# dbi_source() for the zero-copy ATTACH path.
{
	package MinimalDA;
	use strict;
	use warnings;

	sub new {
		my ($class, %args) = @_;
		return bless {
			_cols  => $args{cols}  // [],
			_rows  => $args{rows}  // [],
			_dbh   => $args{dbh},
			_table => $args{table},
		}, $class;
	}

	sub columns { return $_[0]->{_cols} }

	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		$criteria //= {};
		my @out;
		for my $row (@{ $self->{_rows} }) {
			my $match = 1;
			for my $col (keys %{$criteria}) {
				$match = 0, last
					unless defined $row->{$col}
					    && $row->{$col} eq $criteria->{$col};
			}
			push @out, {%{$row}} if $match;
		}
		return \@out;
	}

	sub dbi_source {
		my ($self) = @_;
		return undef unless $self->{_dbh} && $self->{_table};
		return { dbh => $self->{_dbh}, table => $self->{_table} };
	}

	sub schema {
		my ($self) = @_;
		return { map { $_ => 'TEXT' } @{$self->{_cols}} };
	}

	sub count {
		my ($self) = @_;
		return scalar @{$self->{_rows}};
	}

	1;
}

# ---------------------------------------------------------------------------
# Constants / fixture data
# ---------------------------------------------------------------------------

Readonly::Scalar my $JOIN_COL => 'id';

# Small dataset — five rows in each source, well below any threshold.
my @ROWS_A_SMALL = (
	{ id => 'k1', name => 'Alice', tier  => 'gold'   },
	{ id => 'k2', name => 'Bob',   tier  => 'silver' },
	{ id => 'k3', name => 'Carol', tier  => 'bronze' },
	{ id => 'k4', name => 'Dave',  tier  => 'gold'   },
	{ id => 'k5', name => 'Eve',   tier  => 'silver' },
);
my @ROWS_B_SMALL = (
	{ id => 'k1', score => 95 },
	{ id => 'k2', score => 72 },
	{ id => 'k3', score => 88 },
	{ id => 'k5', score => 61 },	# k4 absent from B (outer-join test)
);

my $da_a_small = MinimalDA->new(
	cols => [qw(id name tier)],
	rows => \@ROWS_A_SMALL,
);
my $da_b_small = MinimalDA->new(
	cols => [qw(id score)],
	rows => \@ROWS_B_SMALL,
);

# ===========================================================================
# S1: backend => 'array' — always uses in-memory path, never creates .db file
# ===========================================================================

subtest 'backend=array: in-memory path, no temp .db file' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);

	my $join = Database::Join->new(
		databases   => [$da_a_small, $da_b_small],
		join_column => $JOIN_COL,
		backend     => 'array',
		tmpdir      => $tmpdir,
	);

	my $rows = $join->selectall_arrayref();
	is scalar @{$rows}, 5, 'array backend: left join returns 5 rows';

	my @db_files = glob(File::Spec->catfile($tmpdir, '*.db'));
	is scalar @db_files, 0, 'array backend: no .db file created';
};

# ===========================================================================
# S2: backend => 'auto', small data — array path (no .db file)
# ===========================================================================

subtest 'backend=auto, below threshold: array path used, no .db file' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);

	my $join = Database::Join->new(
		databases      => [$da_a_small, $da_b_small],
		join_column    => $JOIN_COL,
		backend        => 'auto',
		max_array_rows => 10_000,
		tmpdir         => $tmpdir,
	);

	my $rows = $join->selectall_arrayref();
	is scalar @{$rows}, 5, 'auto/below threshold: left join returns 5 rows';

	my @db_files = glob(File::Spec->catfile($tmpdir, '*.db'));
	is scalar @db_files, 0, 'auto/below threshold: no .db file created';
};

# ===========================================================================
# S3: backend => 'auto', threshold=1 — SQLite path activated for any data
# ===========================================================================

subtest 'backend=auto, above threshold: SQLite path activated' => sub {
	my $join = Database::Join->new(
		databases      => [$da_a_small, $da_b_small],
		join_column    => $JOIN_COL,
		backend        => 'auto',
		max_array_rows => 1,	# threshold = 1: any data triggers SQLite
	);

	my $rows = $join->selectall_arrayref();
	is scalar @{$rows}, 5, 'auto/above threshold: left join still returns 5 rows';

	my %by_id = map { $_->{id} => $_ } @{$rows};
	is $by_id{k1}{name},  'Alice', 'k1 name correct via SQLite path';
	is $by_id{k1}{score}, 95,      'k1 score correct via SQLite path';
	is $by_id{k1}{tier},  'gold',  'k1 tier correct via SQLite path';
};

# ===========================================================================
# S4: backend => 'sqlite' on small data — SQLite path used regardless
# ===========================================================================

subtest 'backend=sqlite on small data: SQLite path always used' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a_small, $da_b_small],
		join_column => $JOIN_COL,
		backend     => 'sqlite',
	);

	my $rows = $join->selectall_arrayref();
	is scalar @{$rows}, 5, 'sqlite backend: left join returns 5 rows';

	my %by_id = map { $_->{id} => $_ } @{$rows};
	ok  defined $by_id{k4},          'k4 (B-absent) present in left join';
	ok !defined $by_id{k4}{score},   'k4 score undef (absent from B)';
	is  $by_id{k4}{tier}, 'gold',    'k4 tier correct';
	is  $by_id{k5}{score}, 61,       'k5 score correct';
};

# ===========================================================================
# S5: Result identity regression — sqlite and array paths produce same rows
# ===========================================================================

subtest 'result identity: sqlite and array paths agree on same input' => sub {
	my $join_array = Database::Join->new(
		databases   => [$da_a_small, $da_b_small],
		join_column => $JOIN_COL,
		backend     => 'array',
	);
	my $join_sqlite = Database::Join->new(
		databases   => [$da_a_small, $da_b_small],
		join_column => $JOIN_COL,
		backend     => 'sqlite',
	);

	my $rows_a = $join_array->selectall_arrayref();
	my $rows_s = $join_sqlite->selectall_arrayref();

	is scalar @{$rows_s}, scalar @{$rows_a}, 'same row count';

	# Sort both by id and compare field-by-field.
	my @sorted_a = sort { $a->{id} cmp $b->{id} } @{$rows_a};
	my @sorted_s = sort { $a->{id} cmp $b->{id} } @{$rows_s};

	for my $i (0 .. $#sorted_a) {
		for my $col (keys %{$sorted_a[$i]}) {
			is $sorted_s[$i]{$col}, $sorted_a[$i]{$col},
				"row[$i].$col matches between array and sqlite paths";
		}
	}
};

# ===========================================================================
# S6: Inner join via SQLite backend
# ===========================================================================

subtest 'sqlite backend: inner join' => sub {
	my $join = Database::Join->new(
		databases   => [$da_a_small, $da_b_small],
		join_column => $JOIN_COL,
		backend     => 'sqlite',
		join_type   => 'inner',
	);

	my $rows = $join->selectall_arrayref();
	# k1 k2 k3 k5 all present in both; k4 absent from B
	is scalar @{$rows}, 4, 'inner join returns 4 rows (k4 excluded)';

	my %by_id = map { $_->{id} => $_ } @{$rows};
	ok !exists $by_id{k4}, 'k4 absent from inner join result';
	ok  exists $by_id{k1}, 'k1 present';
};

# ===========================================================================
# S7: Outer join via SQLite backend
# ===========================================================================

subtest 'sqlite backend: outer join' => sub {
	# Add a B-only row to test the outer join direction.
	my $da_b_extra = MinimalDA->new(
		cols => [qw(id score)],
		rows => [
			@ROWS_B_SMALL,
			{ id => 'k9', score => 100 },	# B-only key
		],
	);

	my $join = Database::Join->new(
		databases   => [$da_a_small, $da_b_extra],
		join_column => $JOIN_COL,
		backend     => 'sqlite',
		join_type   => 'outer',
	);

	my $rows = $join->selectall_arrayref();
	# A has k1-k5, B has k1,k2,k3,k5,k9; union = k1..k5 + k9 = 6 rows
	is scalar @{$rows}, 6, 'outer join returns 6 rows (all keys from either source)';

	my %by_id = map { $_->{id} => $_ } @{$rows};
	ok  exists $by_id{k9},          'k9 (B-only) present in outer join';
	ok !defined $by_id{k9}{name},   'k9 name undef (no A row)';
	is  $by_id{k9}{score}, 100,     'k9 score correct';
};

# ===========================================================================
# S8: 3-way join via SQLite backend
# ===========================================================================

subtest 'sqlite backend: 3-way join, all columns present' => sub {
	my $da_c = MinimalDA->new(
		cols => [qw(id rank)],
		rows => [
			{ id => 'k1', rank => 1 },
			{ id => 'k2', rank => 2 },
			{ id => 'k3', rank => 3 },
		],
	);

	my $join = Database::Join->new(
		databases   => [$da_a_small, $da_b_small, $da_c],
		join_column => $JOIN_COL,
		backend     => 'sqlite',
	);

	my $rows = $join->selectall_arrayref();
	is scalar @{$rows}, 5, '3-way: left join returns 5 rows';

	my %by_id = map { $_->{id} => $_ } @{$rows};
	is $by_id{k1}{rank},  1,       'k1 rank from third DA';
	is $by_id{k1}{name},  'Alice', 'k1 name from first DA';
	is $by_id{k1}{score}, 95,      'k1 score from second DA';
	ok !defined $by_id{k4}{rank},  'k4 rank undef (absent from DA C)';
};

# ===========================================================================
# S9: collision_prefix via SQLite backend
# ===========================================================================

subtest 'sqlite backend: collision_prefix renames colliding columns' => sub {
	# Both DAs have a 'notes' column — a collision.
	my $da_x = MinimalDA->new(
		cols => [qw(id name notes)],
		rows => [
			{ id => 'k1', name => 'Alice', notes => 'primary note' },
		],
	);
	my $da_y = MinimalDA->new(
		cols => [qw(id score notes)],
		rows => [
			{ id => 'k1', score => 90, notes => 'secondary note' },
		],
	);

	my $join = Database::Join->new(
		databases        => [$da_x, $da_y],
		join_column      => $JOIN_COL,
		backend          => 'sqlite',
		collision_prefix => { 1 => 'b' },
	);

	my $rows = $join->selectall_arrayref();
	is scalar @{$rows}, 1, 'collision_prefix: one row returned';
	my $row = $rows->[0];

	is $row->{notes},   'primary note',   '"notes" = primary value (not overwritten)';
	is $row->{'b.notes'}, 'secondary note', '"b.notes" = secondary value';
	is $row->{score},   90,                'score present';
};

# ===========================================================================
# S10: join_map via SQLite backend
# ===========================================================================

subtest 'sqlite backend: join_map — asymmetric key column names' => sub {
	# Primary has 'entry'; secondary has 'product_id' as the join key.
	my $da_p = MinimalDA->new(
		cols => [qw(entry item)],
		rows => [
			{ entry => 'X1', item => 'Widget' },
			{ entry => 'X2', item => 'Gadget' },
		],
	);
	my $da_q = MinimalDA->new(
		cols => [qw(product_id price)],
		rows => [
			{ product_id => 'X1', price => 9.99 },
			{ product_id => 'X2', price => 14.99 },
		],
	);

	my $join = Database::Join->new(
		databases   => [$da_p, $da_q],
		join_column => 'entry',
		join_map    => { 1 => 'product_id' },
		backend     => 'sqlite',
	);

	my $rows = $join->selectall_arrayref();
	is scalar @{$rows}, 2, 'join_map: two rows returned';

	my %by_id = map { $_->{entry} => $_ } @{$rows};
	is $by_id{X1}{item},  'Widget', 'X1 item correct';
	is $by_id{X1}{price}, 9.99,     'X1 price correct';
	is $by_id{X2}{price}, 14.99,    'X2 price correct';

	# The local join-key column 'product_id' must not appear in the result.
	ok !exists $by_id{X1}{product_id}, 'product_id not exposed in result';
};

# ===========================================================================
# S11: dbi_source() zero-copy ATTACH
# ===========================================================================

subtest 'dbi_source: ATTACH used, no INSERT issued for that source' => sub {
	require DBI;
	my $tmpdir = tempdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile($tmpdir, 'source.db');

	# Build a real SQLite file as the "secondary" source.
	my $src_dbh = DBI->connect(
		"dbi:SQLite:dbname=$dbfile", '', '',
		{ RaiseError => 1, PrintError => 0, AutoCommit => 1 },
	);
	$src_dbh->do('CREATE TABLE scores (id TEXT, score INTEGER)');
	$src_dbh->do("INSERT INTO scores VALUES ('k1', 99)");
	$src_dbh->do("INSERT INTO scores VALUES ('k2', 77)");

	# Wrap it in a DA stub that implements dbi_source().
	my $da_src = MinimalDA->new(
		cols  => [qw(id score)],
		rows  => [
			{ id => 'k1', score => 99 },
			{ id => 'k2', score => 77 },
		],
		dbh   => $src_dbh,
		table => 'scores',
	);

	# Track INSERT calls issued by the temp db to verify zero-copy.
	my @inserts;
	my $orig_do = \&DBI::db::do;
	{
		no warnings 'redefine';
		*DBI::db::do = sub {
			my ($dbh, $sql, @rest) = @_;
			push @inserts, $sql if $sql =~ /^\s*INSERT/i;
			$orig_do->($dbh, $sql, @rest);
		};
	}

	my $join = Database::Join->new(
		databases   => [$da_a_small, $da_src],
		join_column => $JOIN_COL,
		backend     => 'sqlite',
	);
	my $rows = $join->selectall_arrayref();

	# Restore
	{
		no warnings 'redefine';
		*DBI::db::do = $orig_do;
	}

	$src_dbh->disconnect;

	is scalar @{$rows}, 5, 'dbi_source: left join returns 5 rows';

	my %by_id = map { $_->{id} => $_ } @{$rows};
	is $by_id{k1}{score}, 99,      'k1 score from ATTACHed source';
	is $by_id{k1}{name},  'Alice', 'k1 name from spilled primary';

	# No INSERT should have been issued for the secondary (zero-copy).
	is scalar @inserts, 0, 'no INSERT issued for dbi_source() source (zero-copy)';
};

# ===========================================================================
# S12: Temp file cleanup — .db file removed after $join goes out of scope
# ===========================================================================

subtest 'temp file cleanup after object goes out of scope' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $tmpfile_path;

	{
		my $join = Database::Join->new(
			databases      => [$da_a_small, $da_b_small],
			join_column    => $JOIN_COL,
			backend        => 'auto',
			max_array_rows => 1,	# force SQLite path
			tmpdir         => $tmpdir,
		);

		# Execute a query so the temp file is actually created.
		$join->selectall_arrayref();

		# Temp file is cleaned up immediately after the query completes
		# (stored in $self->{_tmpfile} only for the duration of the call).
		my @db_files = glob(File::Spec->catfile($tmpdir, '*.db'));
		is scalar @db_files, 0,
			'temp .db file not present after query completes (per-call cleanup)';
	}

	pass 'join object went out of scope without error';
};

# ===========================================================================
# S13: max_array_rows boundary — exactly at threshold => array path
# ===========================================================================

subtest 'max_array_rows boundary: exactly at threshold => array path' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);

	# 5 rows in A + 4 rows in B = 9 total.  Set threshold = 9 => array path.
	my $join_at = Database::Join->new(
		databases      => [$da_a_small, $da_b_small],
		join_column    => $JOIN_COL,
		backend        => 'auto',
		max_array_rows => 9,
		tmpdir         => $tmpdir,
	);
	$join_at->selectall_arrayref();
	my @files_at = glob(File::Spec->catfile($tmpdir, '*.db'));
	is scalar @files_at, 0, 'threshold=9, 9 rows: array path (no .db file)';

	# Set threshold = 8 => one row above => SQLite path.
	# (We verify result correctness, not file presence, since file is cleaned up.)
	my $join_above = Database::Join->new(
		databases      => [$da_a_small, $da_b_small],
		join_column    => $JOIN_COL,
		backend        => 'auto',
		max_array_rows => 8,
	);
	my $rows = $join_above->selectall_arrayref();
	is(scalar @{$rows}, 5, 'threshold=8, 9 rows: SQLite path, correct row count');
};

done_testing();
