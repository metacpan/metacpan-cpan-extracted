#!perl -w

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;

use Database::Abstraction;

# ---- Subclass backed by CSV slurp (exercises Perl fold path) ----

{
	package Database::medtest;
	use base 'Database::Abstraction';
	sub new {
		my ($class, %args) = (shift, @_);
		return $class->SUPER::new(sep_char => '!', no_entry => 1, %args);
	}
}

my $dir = tempdir(CLEANUP => 1);
my $csv = File::Spec->catfile($dir, 'medtest.csv');
open(my $fh, '>', $csv) or die $!;
print $fh "group!value\n";
print $fh "A!1\n";
print $fh "A!3\n";
print $fh "A!5\n";
print $fh "A!7\n";
print $fh "B!2\n";
print $fh "B!4\n";
print $fh "B!6\n";
close $fh;

my $db = Database::medtest->new(directory => $dir);

# ---- Section A: median ----

# Group A: 1,3,5,7 (4 values) → median = (3+5)/2 = 4
# Group B: 2,4,6   (3 values) → median = 4

my $rows = $db->aggregate(
	by       => ['group'],
	measures => [{ col => 'value', fn => 'median', as => 'med' }],
	sort_by  => 'group',
);
is(ref($rows), 'ARRAY', 'A1: aggregate median returns arrayref');
is(scalar @{$rows}, 2, 'A2: two groups');
is($rows->[0]{'group'}, 'A', 'A3: first group is A');
is($rows->[0]{med},     4,   'A4: median of 1,3,5,7 is 4');
is($rows->[1]{'group'}, 'B', 'A5: second group is B');
is($rows->[1]{med},     4,   'A6: median of 2,4,6 is 4');

# Ungrouped median: all 7 values 1,2,3,4,5,6,7 → 4
my $all = $db->aggregate(
	measures => [{ col => 'value', fn => 'median', as => 'med' }],
);
is(scalar @{$all}, 1, 'A7: ungrouped returns one row');
is($all->[0]{med}, 4, 'A8: overall median is 4');

# ---- Section B: stddev ----

# Group A: 1,3,5,7; mean=4; sum sq dev=20; s=sqrt(20/3)≈2.582
# Group B: 2,4,6; mean=4; sum sq dev=8; s=sqrt(8/2)=2

my $srows = $db->aggregate(
	by       => ['group'],
	measures => [{ col => 'value', fn => 'stddev', as => 'sd' }],
	sort_by  => 'group',
);
is(ref($srows), 'ARRAY', 'B1: aggregate stddev returns arrayref');
is(scalar @{$srows}, 2, 'B2: two groups');
cmp_ok(abs($srows->[0]{sd} - sqrt(20/3)), '<', 1e-9, 'B3: stddev of A correct');
cmp_ok(abs($srows->[1]{sd} - 2),          '<', 1e-9, 'B4: stddev of B = 2');

# ---- Section C: edge cases ----

my $dir2 = tempdir(CLEANUP => 1);
my $csv2 = File::Spec->catfile($dir2, 'medtest.csv');
open($fh, '>', $csv2) or die $!;
print $fh "group!value\n";
print $fh "X!42\n";
close $fh;

my $db2 = Database::medtest->new(directory => $dir2);

my $s1 = $db2->aggregate(
	by       => ['group'],
	measures => [{ col => 'value', fn => 'stddev', as => 'sd' }],
);
is($s1->[0]{sd}, 0, 'C1: stddev of single-row group is 0');

my $m1 = $db2->aggregate(
	by       => ['group'],
	measures => [{ col => 'value', fn => 'median', as => 'med' }],
);
is($m1->[0]{med}, 42, 'C2: median of single-row group is the value itself');

# ---- Section D: empty group set ----

my $dir3 = tempdir(CLEANUP => 1);
my $csv3 = File::Spec->catfile($dir3, 'medtest.csv');
open($fh, '>', $csv3) or die $!;
print $fh "group!value\n";
close $fh;

my $db3 = Database::medtest->new(directory => $dir3);

my $empty = $db3->aggregate(
	measures => [{ col => 'value', fn => 'median', as => 'med' }],
);
is(ref($empty), 'ARRAY', 'D1: aggregate on empty set returns arrayref');
is(scalar @{$empty}, 0,  'D2: empty set has no groups');

# ---- Section E: median + stddev together ----

my $combined = $db->aggregate(
	by       => ['group'],
	measures => [
		{ col => 'value', fn => 'median', as => 'med' },
		{ col => 'value', fn => 'stddev', as => 'sd'  },
	],
	sort_by => 'group',
);
is(scalar @{$combined}, 2, 'E1: two groups with combined measures');
is($combined->[0]{med}, 4, 'E2: median A');
cmp_ok(abs($combined->[0]{sd} - sqrt(20/3)), '<', 1e-9, 'E3: stddev A');
is($combined->[1]{med}, 4, 'E4: median B');
cmp_ok(abs($combined->[1]{sd} - 2), '<', 1e-9, 'E5: stddev B');

# ---- Section F: unknown fn still croaks ----

eval {
	$db->aggregate(
		measures => [{ col => 'value', fn => 'variance', as => 'v' }],
	);
};
like($@, qr/unknown measure function/, 'F1: unknown fn croaks');

# ---- Section G: SQLite path forces Perl fold for median ----

eval { require DBI; require DBD::SQLite };
SKIP: {
	skip 'DBD::SQLite not available', 4 if $@;

	{
		package Database::medsqlite;
		use base 'Database::Abstraction';
	}

	my $sdir  = tempdir(CLEANUP => 1);
	my $file  = File::Spec->catfile($sdir, 'medsqlite.sql');
	my $dsn   = "dbi:SQLite:dbname=$file";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do(q{CREATE TABLE medsqlite (id INTEGER PRIMARY KEY, grp TEXT, val REAL)});
	$setup->do(q{INSERT INTO medsqlite VALUES (1,'A',1)});
	$setup->do(q{INSERT INTO medsqlite VALUES (2,'A',3)});
	$setup->do(q{INSERT INTO medsqlite VALUES (3,'A',5)});
	$setup->do(q{INSERT INTO medsqlite VALUES (4,'B',2)});
	$setup->do(q{INSERT INTO medsqlite VALUES (5,'B',4)});
	$setup->disconnect();

	my $sdb = Database::medsqlite->new(dsn => $dsn, no_entry => 1);

	my $srows = $sdb->aggregate(
		by       => ['grp'],
		measures => [{ col => 'val', fn => 'median', as => 'med' }],
		sort_by  => 'grp',
	);
	is(ref($srows), 'ARRAY', 'G1: SQLite median returns arrayref (Perl fold)');
	is(scalar @{$srows}, 2,  'G2: two groups');
	is($srows->[0]{med}, 3,  'G3: median of A (1,3,5) = 3');
	is($srows->[1]{med}, 3,  'G4: median of B (2,4) = (2+4)/2 = 3');
}

done_testing();
