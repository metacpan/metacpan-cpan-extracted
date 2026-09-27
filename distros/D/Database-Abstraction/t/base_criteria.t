#!perl -w

use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec;
use Test::Most tests => 29;
use Test::NoWarnings;

use lib 't/lib';
use Database::test1;

pass('Database::test1 loaded');

my $directory = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');

# ---------------------------------------------------------------------------
# BC1: Constructor validation — non-hashref base_criteria
# ---------------------------------------------------------------------------
throws_ok(
	sub { Database::test1->new({ directory => $directory, base_criteria => 'bad' }) },
	qr/base_criteria must be a hashref/,
	'BC1: non-hashref base_criteria croaks'
);

# BC2: Constructor validation — unsafe key in base_criteria
throws_ok(
	sub { Database::test1->new({ directory => $directory, base_criteria => { 'bad;key' => 1 } }) },
	qr/unsafe base_criteria key/,
	'BC2: unsafe base_criteria key croaks'
);

# BC3: Valid construction with base_criteria
my $bc_db = new_ok('Database::test1' => [{ directory => $directory, base_criteria => { number => 1 } }],
	'Database::test1 with base_criteria => {number => 1}');

# BC4: selectall_arrayref — only rows matching base_criteria are returned
my $rows = $bc_db->selectall_arrayref();
cmp_ok(scalar @{$rows}, '==', 1, 'BC4: base_criteria filters selectall_arrayref zero-criteria call');
is($rows->[0]{'entry'}, 'one', 'BC4: correct row returned');

# BC5: selectall_arrayref with additional caller criteria — both ANDed
my $rows2 = $bc_db->selectall_arrayref(entry => 'one');
cmp_ok(scalar @{$rows2}, '==', 1, 'BC5: base_criteria + caller criteria combined');
is($rows2->[0]{'entry'}, 'one', 'BC5: correct row');

# BC6: selectall_arrayref — caller criteria that conflicts with base_criteria
# number => 2 combined with base number => 1 gives 0 rows (1 != 2)
my $rows3 = $bc_db->selectall_arrayref(entry => 'two');
cmp_ok(scalar @{$rows3}, '==', 0, 'BC6: caller criteria conflicts with base_criteria → 0 rows');

# BC7: selectall_array
my @arr = $bc_db->selectall_array();
cmp_ok(scalar @arr, '==', 1, 'BC7: base_criteria filters selectall_array');
is($arr[0]{'entry'}, 'one', 'BC7: correct row');

# BC8: count with base_criteria
my $n = $bc_db->count();
cmp_ok($n, '==', 1, 'BC8: count respects base_criteria');

# BC9: count with caller criteria that narrows further
my $n2 = $bc_db->count(entry => 'one');
cmp_ok($n2, '==', 1, 'BC9: count with caller criteria');

my $n3 = $bc_db->count(entry => 'two');
cmp_ok($n3, '==', 0, 'BC9b: count with conflicting caller criteria → 0');

# BC10: fetchrow_hashref fast track — matching row returned
my $row = $bc_db->fetchrow_hashref(entry => 'one');
ok(defined $row, 'BC10: fetchrow_hashref returns matching row');
is($row->{'entry'}, 'one', 'BC10: correct entry');

# BC11: fetchrow_hashref fast track — row exists but fails base_criteria
my $row2 = $bc_db->fetchrow_hashref(entry => 'two');
ok(!defined $row2, 'BC11: fetchrow_hashref returns undef when base_criteria not met');

# BC12: AUTOLOAD respects base_criteria
my $num = $bc_db->number(entry => 'one');
is($num, 1, 'BC12: AUTOLOAD works with base_criteria');

# ---------------------------------------------------------------------------
# BC13: base_criteria with undef value (soft-delete style)
# entry 'empty' has number == undef; filter to rows where number IS NULL
# ---------------------------------------------------------------------------
my $null_db = Database::test1->new({ directory => $directory, base_criteria => { number => undef } });
my $null_rows = $null_db->selectall_arrayref();
cmp_ok(scalar @{$null_rows}, '==', 1, 'BC13: base_criteria undef value (IS NULL) works');
is($null_rows->[0]{'entry'}, 'empty', 'BC13: correct null row');

# ---------------------------------------------------------------------------
# BC14: Query builder respects base_criteria
# ---------------------------------------------------------------------------
my $q_rows = $bc_db->query->all();
cmp_ok(scalar @{$q_rows}, '==', 1, 'BC14: query->all() respects base_criteria');
is($q_rows->[0]{'entry'}, 'one', 'BC14: correct row via query builder');

my $q_count = $bc_db->query->count();
cmp_ok($q_count, '==', 1, 'BC14: query->count() respects base_criteria');

my $q_first = $bc_db->query->first();
ok(defined $q_first, 'BC14: query->first() respects base_criteria');
is($q_first->{'entry'}, 'one', 'BC14: correct first row via query builder');

# BC15: Query builder where() + base_criteria combined
my $q_where = $bc_db->query->where(entry => 'one')->all();
cmp_ok(scalar @{$q_where}, '==', 1, 'BC15: query->where() + base_criteria');

my $q_none = $bc_db->query->where(entry => 'two')->all();
cmp_ok(scalar @{$q_none}, '==', 0, 'BC15: conflicting where() and base_criteria → 0 rows');

# ---------------------------------------------------------------------------
# BC16: base_criteria shallow copy — mutating original hashref after
# construction does not affect the object
# ---------------------------------------------------------------------------
my %bc = (number => 1);
my $mut_db = Database::test1->new({ directory => $directory, base_criteria => \%bc });
$bc{number} = 999;    # mutate the original
my $mut_rows = $mut_db->selectall_arrayref();
cmp_ok(scalar @{$mut_rows}, '==', 1, 'BC16: mutation of original hashref does not affect object');
