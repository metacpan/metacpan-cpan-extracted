#!perl -w

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;

use Database::Abstraction;

# ---- Test subclasses ----

{
	package Database::disttest;
	use base 'Database::Abstraction';
	sub new {
		my ($class, %args) = (shift, @_);
		return $class->SUPER::new(sep_char => '!', %args);
	}
}

{
	package Database::disttest_ne;
	use base 'Database::Abstraction';
	sub new {
		my ($class, %args) = (shift, @_);
		return $class->SUPER::new(sep_char => '!', no_entry => 1, %args);
	}
}

# ---- Fixture: CSV with duplicate status values after column projection ----

my $dir = tempdir(CLEANUP => 1);

# Keyed CSV: entry!status!dept
my $csv_keyed = File::Spec->catfile($dir, 'disttest.csv');
open(my $fh, '>', $csv_keyed) or die $!;
print $fh "entry!status!dept\n";
print $fh "a!active!eng\n";
print $fh "b!active!eng\n";
print $fh "c!inactive!mkt\n";
print $fh "d!active!mkt\n";
print $fh "e!inactive!eng\n";
close $fh;

# No-entry CSV: status!dept
my $csv_ne = File::Spec->catfile($dir, 'disttest_ne.csv');
open($fh, '>', $csv_ne) or die $!;
print $fh "status!dept\n";
print $fh "active!eng\n";
print $fh "active!eng\n";
print $fh "inactive!mkt\n";
print $fh "active!mkt\n";
print $fh "inactive!eng\n";
close $fh;

my $db    = Database::disttest->new(directory => $dir);
my $db_ne = Database::disttest_ne->new(directory => $dir);

# ---- Section A: distinct => 1 with columns (slurp path, keyed hash) ----

# 5 rows: (active,eng)×2, (inactive,mkt), (active,mkt), (inactive,eng)
# Distinct (status,dept) pairs: 4
my $rows = $db->selectall_arrayref(distinct => 1, columns => [qw(status dept)]);
is(ref($rows), 'ARRAY', 'A1: returns arrayref');
my @sorted = sort { ($a->{status} cmp $b->{status}) || ($a->{dept} cmp $b->{dept}) } @{$rows};
is(scalar @sorted, 4, 'A2: four distinct (status,dept) pairs');
is($sorted[0]{status}, 'active',   'A3: first status');
is($sorted[0]{dept},   'eng',      'A4: first dept');
is($sorted[1]{status}, 'active',   'A5: second status');
is($sorted[1]{dept},   'mkt',      'A6: second dept');
is($sorted[2]{status}, 'inactive', 'A7: third status');

# Returned rows should only have the requested columns
ok(!exists($sorted[0]{entry}), 'A8: entry column absent after projection');

# ---- Section B: columns only (no distinct) ----

my $rows_cols = $db->selectall_arrayref(columns => ['status']);
is(ref($rows_cols), 'ARRAY', 'B1: returns arrayref');
is(scalar @{$rows_cols}, 5, 'B2: all 5 rows returned');
ok(!exists($rows_cols->[0]{entry}), 'B3: entry not in result');
ok(!exists($rows_cols->[0]{dept}),  'B4: dept not in result');
ok(exists($rows_cols->[0]{status}), 'B5: status present');

# ---- Section C: distinct => 1 without columns (no-op on slurp HASH) ----

my $rows_d = $db->selectall_arrayref(distinct => 1);
is(ref($rows_d), 'ARRAY', 'C1: returns arrayref');
is(scalar @{$rows_d}, 5, 'C2: all 5 rows (distinct without columns is no-op for keyed hash)');

# ---- Section D: no_entry mode with distinct + columns ----

# Same 5 rows: (active,eng)×2, (inactive,mkt), (active,mkt), (inactive,eng) → 4 distinct pairs
my $rows_ne = $db_ne->selectall_arrayref(distinct => 1, columns => [qw(status dept)]);
is(ref($rows_ne), 'ARRAY', 'D1: no_entry returns arrayref');
my @ne_sorted = sort { ($a->{status} cmp $b->{status}) || ($a->{dept} cmp $b->{dept}) } @{$rows_ne};
is(scalar @ne_sorted, 4, 'D2: four distinct (status,dept) pairs in no_entry mode');

# ---- Section E: distinct with criteria ----

# active rows: a(active/eng), b(active/eng), d(active/mkt) → distinct depts: eng, mkt
my $rows_crit = $db->selectall_arrayref(status => 'active', distinct => 1, columns => ['dept']);
is(ref($rows_crit), 'ARRAY', 'E1: criteria+distinct returns arrayref');
my @depts = sort map { $_->{dept} } @{$rows_crit};
is(scalar @depts, 2, 'E2: two distinct depts for active rows');
is($depts[0], 'eng', 'E3: first dept');
is($depts[1], 'mkt', 'E4: second dept');

# ---- Section F: invalid columns carp and are dropped ----

{
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $rows_inv = $db->selectall_arrayref(columns => ['status', 'bad col']);
	ok(scalar(@warnings) > 0, 'F1: carp on unsafe column name');
	like($warnings[0], qr/unsafe column name/, 'F2: warning mentions unsafe column name');
	# valid column 'status' still returned
	is(ref($rows_inv), 'ARRAY', 'F3: returns arrayref even after bad column');
}

# ---- Section G: column that does not exist returns undef without croak ----

my $rows_miss = $db->selectall_arrayref(columns => ['status', 'nonexistent_col']);
is(ref($rows_miss), 'ARRAY', 'G1: missing column returns arrayref');
is(scalar @{$rows_miss}, 5, 'G2: all rows still returned');
ok(exists($rows_miss->[0]{nonexistent_col}), 'G3: missing column present in result as undef');
ok(!defined($rows_miss->[0]{nonexistent_col}), 'G4: missing column value is undef');

# ---- Section H: SQLite path with SELECT DISTINCT ----

eval { require DBI; require DBD::SQLite };
SKIP: {
	skip 'DBD::SQLite not available', 9 if $@;

	{
		package Database::distsqlite;
		use base 'Database::Abstraction';
	}

	my $sdir  = tempdir(CLEANUP => 1);
	my $file  = File::Spec->catfile($sdir, 'distsqlite.sql');
	my $dsn   = "dbi:SQLite:dbname=$file";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do(q{CREATE TABLE distsqlite (id INTEGER PRIMARY KEY, status TEXT, dept TEXT)});
	$setup->do(q{INSERT INTO distsqlite VALUES (1,'active','eng')});
	$setup->do(q{INSERT INTO distsqlite VALUES (2,'active','eng')});
	$setup->do(q{INSERT INTO distsqlite VALUES (3,'inactive','mkt')});
	$setup->do(q{INSERT INTO distsqlite VALUES (4,'active','mkt')});
	$setup->disconnect();

	my $sdb = Database::distsqlite->new(dsn => $dsn, no_entry => 1);

	my $srows = $sdb->selectall_arrayref(distinct => 1, columns => [qw(status dept)]);
	is(ref($srows), 'ARRAY', 'H1: SQLite distinct returns arrayref');
	my @ss = sort { ($a->{status} cmp $b->{status}) || ($a->{dept} cmp $b->{dept}) } @{$srows};
	is(scalar @ss, 3, 'H2: three distinct (status,dept) pairs from SQLite');
	is($ss[0]{status}, 'active',   'H3: first status');
	is($ss[0]{dept},   'eng',      'H4: first dept');

	my $srows_d = $sdb->selectall_arrayref(distinct => 1);
	is(ref($srows_d), 'ARRAY', 'H5: SELECT DISTINCT * returns arrayref');
	# id column makes every row unique, so DISTINCT * returns all 4 rows
	is(scalar @{$srows_d}, 4, 'H6: SELECT DISTINCT * returns all 4 rows (id makes each unique)');

	my $srows_nc = $sdb->selectall_arrayref(columns => ['status']);
	is(ref($srows_nc), 'ARRAY', 'H7: columns-only (no distinct) returns arrayref');
	is(scalar @{$srows_nc}, 4, 'H8: all 4 rows returned with columns-only');

	my $srows_dc = $sdb->selectall_arrayref(distinct => 1, columns => ['status']);
	is(scalar @{$srows_dc}, 2, 'H9: SELECT DISTINCT status returns 2 unique values');
}

done_testing();
