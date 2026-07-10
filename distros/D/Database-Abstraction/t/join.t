#!perl -w

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;
use Test::NoWarnings;

eval { require DBI; require DBD::SQLite };
if ($@) {
	plan skip_all => 'DBD::SQLite not available';
} else {
	plan tests => 18;
}

{
	package Database::jointest;
	use base 'Database::Abstraction';
}

my $dir  = tempdir(CLEANUP => 1);
my $file = File::Spec->catfile($dir, 'jointest.sql');
my $dsn  = "dbi:SQLite:dbname=$file";

my $dbh = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
$dbh->do(q{CREATE TABLE jointest (id INTEGER PRIMARY KEY, name TEXT, dept_id INTEGER)});
$dbh->do(q{CREATE TABLE dept (id INTEGER PRIMARY KEY, dept_name TEXT)});
$dbh->do(q{INSERT INTO jointest VALUES (1, 'Alice', 10)});
$dbh->do(q{INSERT INTO jointest VALUES (2, 'Bob',   20)});
$dbh->do(q{INSERT INTO jointest VALUES (3, 'Carol', 10)});
$dbh->do(q{INSERT INTO jointest VALUES (4, 'Dave',  NULL)});
$dbh->do(q{INSERT INTO dept VALUES (10, 'Engineering')});
$dbh->do(q{INSERT INTO dept VALUES (20, 'Marketing')});
$dbh->disconnect();

my $db = Database::jointest->new(dsn => $dsn, no_entry => 1);

# ---- INNER JOIN ----

my $rows = $db->selectall_arrayref(
	join => { table => 'dept', on => 'jointest.dept_id = dept.id', type => 'INNER' }
);
is(scalar @{$rows}, 3, 'INNER JOIN returns 3 rows (Dave excluded — no dept)');

# ---- LEFT JOIN ----

$rows = $db->selectall_arrayref(
	join => { table => 'dept', on => 'jointest.dept_id = dept.id', type => 'LEFT' }
);
is(scalar @{$rows}, 4, 'LEFT JOIN returns all 4 rows');
my ($dave) = grep { $_->{name} eq 'Dave' } @{$rows};
ok($dave, 'Dave is present in LEFT JOIN');
ok(!defined($dave->{dept_name}), 'Dave has NULL dept_name in LEFT JOIN');

# ---- INNER JOIN default type ----

$rows = $db->selectall_arrayref(
	join => { table => 'dept', on => 'jointest.dept_id = dept.id' }
);
is(scalar @{$rows}, 3, 'default JOIN type (INNER) returns 3 rows');

# ---- JOIN + criteria ----

$rows = $db->selectall_arrayref(
	dept_name => 'Engineering',
	join => { table => 'dept', on => 'jointest.dept_id = dept.id', type => 'INNER' }
);
is(scalar @{$rows}, 2, 'JOIN + where dept=Engineering gives 2 rows');
ok((grep { $_->{name} eq 'Alice' } @{$rows}), 'Alice is in Engineering');
ok((grep { $_->{name} eq 'Carol' } @{$rows}), 'Carol is in Engineering');

# ---- Multiple joins ----

$rows = $db->selectall_arrayref(
	join => [
		{ table => 'dept', on => 'jointest.dept_id = dept.id', type => 'LEFT' },
	]
);
is(scalar @{$rows}, 4, 'array-of-joins with one element returns 4 rows');

# ---- fetchrow_hashref with join ----

my $row = $db->fetchrow_hashref(
	name => 'Alice',
	join => { table => 'dept', on => 'jointest.dept_id = dept.id', type => 'INNER' }
);
ok($row, 'fetchrow_hashref with join returns a row');
is($row->{name}, 'Alice', 'fetchrow_hashref join: name is Alice');
is($row->{dept_name}, 'Engineering', 'fetchrow_hashref join: dept_name is Engineering');

# ---- selectall_array with join ----

my @arr = $db->selectall_array(
	join => { table => 'dept', on => 'jointest.dept_id = dept.id', type => 'INNER' }
);
is(scalar @arr, 3, 'selectall_array with join returns 3 rows');

# ---- Validation: invalid join type ----

throws_ok {
	$db->selectall_arrayref(
		join => { table => 'dept', on => 'jointest.dept_id = dept.id', type => 'BOGUS' }
	);
} qr/Invalid JOIN type/, 'invalid join type throws';

# ---- Validation: missing table ----

throws_ok {
	$db->selectall_arrayref(
		join => { on => 'jointest.dept_id = dept.id' }
	);
} qr/missing "table"/, 'join without table throws';

# ---- Validation: missing on ----

throws_ok {
	$db->selectall_arrayref(
		join => { table => 'dept' }
	);
} qr/missing "on"/, 'join without on throws';

# ---- BerkeleyDB: joins must croak ----

SKIP: {
	eval { require DB_File };
	skip 'DB_File not available', 1 if $@;

	use Fcntl qw(O_CREAT O_RDWR);
	my $bdir  = File::Temp::tempdir(CLEANUP => 1);
	# File must match class name: Database::joinbdb → joinbdb.db
	my $bfile = File::Spec->catfile($bdir, 'joinbdb.db');
	tie my %bdb, 'DB_File', $bfile, O_CREAT|O_RDWR, 0644, $DB_File::DB_HASH
		or skip "Cannot create BerkeleyDB: $!", 1;
	%bdb = (k1 => 'v1');
	untie %bdb;

	{
		package Database::joinbdb;
		use base 'Database::Abstraction';
	}
	my $bobj = Database::joinbdb->new(directory => $bdir);

	# Trigger _open so $self->{'berkeley'} is set
	eval { $bobj->fetchrow_hashref(entry => 'k1') };

	dies_ok {
		$bobj->selectall_arrayref(join => { table => 't', on => 'a=b' });
	} 'joins on BerkeleyDB die';
}
