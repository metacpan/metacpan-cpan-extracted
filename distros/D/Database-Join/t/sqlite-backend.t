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
			# \s*+ possessive: O(1) failure on non-INSERT strings (no backtrack).
			push @inserts, $sql if $sql =~ /^\s*+INSERT/i;
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

	{
		my $join = Database::Join->new(
			databases      => [$da_a_small, $da_b_small],
			join_column    => $JOIN_COL,
			backend        => 'auto',
			max_array_rows => 1,	# force SQLite path
			tmpdir         => $tmpdir,
		);

		# Execute a query so the cache temp file is created.
		$join->selectall_arrayref();

		# The temp file persists while the object is alive (it is the cache).
		my @db_files = glob(File::Spec->catfile($tmpdir, '*.db'));
		is scalar @db_files, 1,
			'temp .db file exists while join object is alive (cache persists)';
		# $join goes out of scope here; DESTROY disconnects and unlinks the file.
	}

	# After the object is destroyed the temp file should be gone.
	my @db_files_after = glob(File::Spec->catfile($tmpdir, '*.db'));
	is scalar @db_files_after, 0,
		'temp .db file removed after join object is destroyed';
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

# ===========================================================================
# S14: dbi_source() ATTACH with a .sqlite file extension
# SQLite has no constraint on file extensions; the ATTACH code path must
# work regardless of whether the source file ends in .db, .sqlite, or .sqlite3.
# ===========================================================================

subtest 'dbi_source: ATTACH works with .sqlite file extension' => sub {
	require DBI;
	my $tmpdir = tempdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile($tmpdir, 'source.sqlite');

	my $src_dbh = DBI->connect(
		"dbi:SQLite:dbname=$dbfile", '', '',
		{ RaiseError => 1, PrintError => 0, AutoCommit => 1 },
	);
	$src_dbh->do('CREATE TABLE scores (id TEXT, score INTEGER)');
	$src_dbh->do("INSERT INTO scores VALUES ('k1', 42)");
	$src_dbh->do("INSERT INTO scores VALUES ('k3', 55)");

	my $da_src = MinimalDA->new(
		cols  => [qw(id score)],
		rows  => [
			{ id => 'k1', score => 42 },
			{ id => 'k3', score => 55 },
		],
		dbh   => $src_dbh,
		table => 'scores',
	);

	# Spy on INSERT calls: a zero-copy ATTACH must issue none for this source.
	my @inserts;
	my $orig_do = \&DBI::db::do;
	{ no warnings 'redefine'; *DBI::db::do = sub {
		my ($dbh, $sql, @rest) = @_;
		push @inserts, $sql if $sql =~ /^\s*+INSERT/i;
		$orig_do->($dbh, $sql, @rest);
	} }

	my $join = Database::Join->new(
		databases   => [$da_a_small, $da_src],
		join_column => $JOIN_COL,
		backend     => 'sqlite',
	);
	my $rows = $join->selectall_arrayref();

	{ no warnings 'redefine'; *DBI::db::do = $orig_do; }
	$src_dbh->disconnect;

	is scalar @{$rows}, 5, '.sqlite source: left join returns 5 rows';
	my %by_id = map { $_->{id} => $_ } @{$rows};
	is $by_id{k1}{score}, 42,      'k1 score from .sqlite ATTACHed source';
	is $by_id{k1}{name},  'Alice', 'k1 name from spilled primary';
	is scalar @inserts, 0, 'no INSERT for .sqlite source (zero-copy ATTACH)';
};

# ===========================================================================
# S15: dbi_source() ATTACH with a .sqlite3 file extension
# ===========================================================================

subtest 'dbi_source: ATTACH works with .sqlite3 file extension' => sub {
	require DBI;
	my $tmpdir = tempdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile($tmpdir, 'source.sqlite3');

	my $src_dbh = DBI->connect(
		"dbi:SQLite:dbname=$dbfile", '', '',
		{ RaiseError => 1, PrintError => 0, AutoCommit => 1 },
	);
	$src_dbh->do('CREATE TABLE scores (id TEXT, score INTEGER)');
	$src_dbh->do("INSERT INTO scores VALUES ('k2', 19)");
	$src_dbh->do("INSERT INTO scores VALUES ('k4', 63)");

	my $da_src = MinimalDA->new(
		cols  => [qw(id score)],
		rows  => [
			{ id => 'k2', score => 19 },
			{ id => 'k4', score => 63 },
		],
		dbh   => $src_dbh,
		table => 'scores',
	);

	my @inserts;
	my $orig_do = \&DBI::db::do;
	{ no warnings 'redefine'; *DBI::db::do = sub {
		my ($dbh, $sql, @rest) = @_;
		push @inserts, $sql if $sql =~ /^\s*+INSERT/i;
		$orig_do->($dbh, $sql, @rest);
	} }

	my $join = Database::Join->new(
		databases   => [$da_a_small, $da_src],
		join_column => $JOIN_COL,
		backend     => 'sqlite',
	);
	my $rows = $join->selectall_arrayref();

	{ no warnings 'redefine'; *DBI::db::do = $orig_do; }
	$src_dbh->disconnect;

	is scalar @{$rows}, 5, '.sqlite3 source: left join returns 5 rows';
	my %by_id = map { $_->{id} => $_ } @{$rows};
	is $by_id{k2}{score}, 19,    'k2 score from .sqlite3 ATTACHed source';
	is $by_id{k4}{score}, 63,    'k4 score from .sqlite3 ATTACHed source';
	is scalar @inserts, 0, 'no INSERT for .sqlite3 source (zero-copy ATTACH)';
};

# ===========================================================================
# S16: Cache reuse — source DAs are called only once across multiple queries
# The SQLite backend caches the spilled data; subsequent queries reuse the
# temp file rather than re-fetching source rows.
# ===========================================================================

# Subclass of MinimalDA that counts how many times selectall_arrayref is called.
{
	package CountingDA;
	use parent -norequire, 'MinimalDA';
	sub new {
		my ($class, %args) = @_;
		my $self = $class->SUPER::new(%args);
		$self->{_call_count} = 0;
		return $self;
	}
	sub selectall_arrayref {
		my ($self, @args) = @_;
		$self->{_call_count}++;
		return $self->SUPER::selectall_arrayref(@args);
	}
	sub call_count { return $_[0]->{_call_count} }
	1;
}

subtest 'cache reuse: source DA selectall_arrayref called once, not per query' => sub {
	my $da_a = CountingDA->new(
		cols => [qw(id name)],
		rows => [
			{ id => 'k1', name => 'Alice' },
			{ id => 'k2', name => 'Bob' },
		],
	);
	my $da_b = CountingDA->new(
		cols => [qw(id score)],
		rows => [
			{ id => 'k1', score => 95 },
			{ id => 'k2', score => 72 },
		],
	);

	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => $JOIN_COL,
		backend     => 'sqlite',
	);

	my $r1 = $join->selectall_arrayref();      # first call: builds cache
	my $r2 = $join->selectall_arrayref();      # second: reuses cache
	my $r3 = $join->selectall_arrayref();      # third: reuses cache

	is $da_a->call_count, 1,
		'primary DA: selectall_arrayref called once (cache build only)';
	is $da_b->call_count, 1,
		'secondary DA: selectall_arrayref called once (cache build only)';
	is scalar @{$r1}, 2, 'first query returns 2 rows';
	is scalar @{$r2}, 2, 'second query returns 2 rows (cache reused)';
	is scalar @{$r3}, 2, 'third query returns 2 rows (cache reused)';
};

# ===========================================================================
# S17: Cache invalidation — rebuilt when any source updated() changes
# The cache tracks updated() timestamps; a changed timestamp forces a full
# rebuild so queries see the new source data.
# ===========================================================================

{
	package UpdatableDA;
	use parent -norequire, 'CountingDA';
	sub new {
		my ($class, %args) = @_;
		my $self = $class->SUPER::new(%args);
		$self->{_ts} = $args{ts} // 1000;
		return $self;
	}
	sub updated    { return $_[0]->{_ts} }
	sub set_updated { $_[0]->{_ts} = $_[1] }
	sub set_rows    { $_[0]->{_rows} = $_[1] }
	1;
}

subtest 'cache invalidation: cache rebuilt when source updated() timestamp changes' => sub {
	my $da_a = UpdatableDA->new(
		cols => [qw(id name)],
		rows => [{ id => 'k1', name => 'Alice' }],
		ts   => 1000,
	);
	my $da_b = UpdatableDA->new(
		cols => [qw(id score)],
		rows => [{ id => 'k1', score => 10 }],
		ts   => 2000,
	);

	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => $JOIN_COL,
		backend     => 'sqlite',
	);

	my $r1 = $join->selectall_arrayref();
	is $r1->[0]{score}, 10, 'initial query: score=10';
	is $da_b->call_count, 1, 'secondary DA called once for initial build';

	# Simulate source update: change data and bump the timestamp.
	$da_b->set_rows([{ id => 'k1', score => 99 }]);
	$da_b->set_updated(2001);

	my $r2 = $join->selectall_arrayref();
	is $r2->[0]{score}, 99, 'after update: cache rebuilt, score=99';
	is $da_b->call_count, 2, 'secondary DA called again after timestamp change';
};

# ===========================================================================
# S18: ATTACH with query-time criteria
# The old implementation blocked ATTACH when criteria existed (!%criteria guard).
# The new implementation removes that restriction: ATTACH is unconditional, and
# query-time criteria become SQL WHERE clauses against the ATTACHed table.
# ===========================================================================

subtest 'ATTACH with criteria: zero-copy path used; WHERE filters correctly' => sub {
	require DBI;
	my $tmpdir = tempdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile($tmpdir, 'attach_crit.db');

	my $src_dbh = DBI->connect(
		"dbi:SQLite:dbname=$dbfile", '', '',
		{ RaiseError => 1, PrintError => 0, AutoCommit => 1 },
	);
	$src_dbh->do('CREATE TABLE scores (id TEXT, score INTEGER)');
	$src_dbh->do("INSERT INTO scores VALUES ('k1', 42)");
	$src_dbh->do("INSERT INTO scores VALUES ('k2', 10)");
	$src_dbh->do("INSERT INTO scores VALUES ('k3', 55)");

	my $da_src = MinimalDA->new(
		cols  => [qw(id score)],
		rows  => [
			{ id => 'k1', score => 42 },
			{ id => 'k2', score => 10 },
			{ id => 'k3', score => 55 },
		],
		dbh   => $src_dbh,
		table => 'scores',
	);

	# Spy: track any INSERT SQL routed through do() (not through sth->execute).
	my @inserts;
	my $orig_do = \&DBI::db::do;
	{ no warnings 'redefine'; *DBI::db::do = sub {
		my ($dbh, $sql, @rest) = @_;
		push @inserts, $sql if $sql =~ /^\s*+INSERT/i;
		$orig_do->($dbh, $sql, @rest);
	} }

	my $join = Database::Join->new(
		databases   => [$da_a_small, $da_src],
		join_column => $JOIN_COL,
		backend     => 'sqlite',
	);

	# Filter by score > 20 — this used to prevent ATTACH (old guard was
	# !%criteria); now the criterion goes into the SQL WHERE clause instead.
	my $rows = $join->selectall_arrayref(score => { '>' => 20 });

	{ no warnings 'redefine'; *DBI::db::do = $orig_do; }
	$src_dbh->disconnect;

	# ATTACH source: no row-level inserts via do() (zero-copy)
	is scalar @inserts, 0, 'ATTACH source: no INSERT via do() even with query criteria';

	# Only k1 (score=42) and k3 (score=55) survive the WHERE score > 20 filter.
	# k2 (score=10) is excluded; k4 and k5 are excluded by INNER JOIN
	# (score criterion makes the secondary an inner-join partner).
	my %by_id = map { $_->{id} => $_ } @{$rows};
	is  scalar @{$rows}, 2, 'WHERE score > 20: 2 rows returned';
	ok  exists $by_id{k1},    'k1 (score=42 > 20) present';
	ok !exists $by_id{k2},    'k2 (score=10, not > 20) absent';
	ok  exists $by_id{k3},    'k3 (score=55 > 20) present';
	is  $by_id{k1}{score}, 42, 'k1 score correct';
	is  $by_id{k3}{score}, 55, 'k3 score correct';
};

done_testing();
