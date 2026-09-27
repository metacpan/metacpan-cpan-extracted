#!perl -w

use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec;
use Test::Most tests => 31;
use Test::NoWarnings;

use lib 't/lib';
use Database::test1;
use Database::test4ne;

pass('Database::test1 loaded');

my $directory = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');

my $db = new_ok('Database::test1' => [$directory]);

# ---------------------------------------------------------------------------
# ER1: callback must be a code reference
# ---------------------------------------------------------------------------
throws_ok(
	sub { $db->each_row('not_a_coderef') },
	qr/callback must be a code reference/,
	'ER1: non-coderef callback croaks'
);

# ---------------------------------------------------------------------------
# ER2: basic iteration — all rows, correct count
# ---------------------------------------------------------------------------
my @collected;
my $count = $db->each_row(sub { push @collected, shift });
# test1.csv has: one, two, three, empty (4 data rows; comment line ignored)
cmp_ok($count, '==', 4, 'ER2: each_row returns row count');
cmp_ok(scalar @collected, '==', 4, 'ER2: callback called once per row');

my %entries = map { $_->{'entry'} => 1 } @collected;
ok(exists $entries{'one'},   'ER2: entry "one" present');
ok(exists $entries{'two'},   'ER2: entry "two" present');
ok(exists $entries{'three'}, 'ER2: entry "three" present');
ok(exists $entries{'empty'}, 'ER2: entry "empty" present');

# ---------------------------------------------------------------------------
# ER3: criteria filtering
# ---------------------------------------------------------------------------
my @filtered;
$db->each_row(sub { push @filtered, shift }, number => 1);
cmp_ok(scalar @filtered, '==', 1, 'ER3: criteria filter works');
is($filtered[0]{'entry'}, 'one', 'ER3: correct row returned');

# ---------------------------------------------------------------------------
# ER4: no matching rows → count = 0, callback never called
# ---------------------------------------------------------------------------
my $called = 0;
my $n = $db->each_row(sub { $called++ }, entry => 'nonexistent');
cmp_ok($n, '==', 0, 'ER4: returns 0 for no matches');
cmp_ok($called, '==', 0, 'ER4: callback not called for empty result');

# ---------------------------------------------------------------------------
# ER5: sort_by
# ---------------------------------------------------------------------------
my @sorted;
$db->each_row(sub { push @sorted, shift->{'entry'} }, sort_by => 'entry');
is_deeply(\@sorted, [sort @sorted], 'ER5: sort_by ASC produces sorted order');

my @sorted_desc;
$db->each_row(sub { push @sorted_desc, shift->{'entry'} }, sort_by => ['entry', 'DESC']);
is_deeply(\@sorted_desc, [reverse sort @sorted_desc], 'ER5: sort_by DESC produces reverse order');

# ---------------------------------------------------------------------------
# ER6: limit / offset
# ---------------------------------------------------------------------------
my @limited;
$db->each_row(sub { push @limited, shift }, sort_by => 'entry', limit => 2);
cmp_ok(scalar @limited, '==', 2, 'ER6: limit respected');

my @offset;
$db->each_row(sub { push @offset, shift }, sort_by => 'entry', limit => 2, offset => 1);
cmp_ok(scalar @offset, '==', 2, 'ER6: offset + limit combination');
isnt($limited[0]{'entry'}, $offset[0]{'entry'}, 'ER6: offset shifts the window');

# ---------------------------------------------------------------------------
# ER7: exception inside callback propagates and does not loop
# ---------------------------------------------------------------------------
my $calls_before_die = 0;
eval {
	$db->each_row(sub {
		$calls_before_die++;
		die "deliberate test exception\n" if $calls_before_die == 2;
	});
};
like($@, qr/deliberate test exception/, 'ER7: callback exception propagates');
cmp_ok($calls_before_die, '==', 2, 'ER7: iteration stopped at exception');

# ---------------------------------------------------------------------------
# ER8: no_entry mode (arrayref-backed slurp)
# ---------------------------------------------------------------------------
my $ne_db = new_ok('Database::test4ne' => [{ directory => $directory }]);
my @ne_rows;
my $ne_count = $ne_db->each_row(sub { push @ne_rows, shift });
cmp_ok($ne_count, '>=', 1, 'ER8: each_row works with no_entry backend');
ok(ref($ne_rows[0]) eq 'HASH', 'ER8: rows are hashrefs in no_entry mode');

# ---------------------------------------------------------------------------
# ER9: base_criteria respected
# ---------------------------------------------------------------------------
my $bc_db = Database::test1->new({ directory => $directory, base_criteria => { number => 1 } });
my @bc_rows;
my $bc_n = $bc_db->each_row(sub { push @bc_rows, shift });
cmp_ok($bc_n, '==', 1, 'ER9: base_criteria filters each_row');
is($bc_rows[0]{'entry'}, 'one', 'ER9: correct row under base_criteria');

# ---------------------------------------------------------------------------
# ER10: Query builder each() terminal method
# ---------------------------------------------------------------------------
my @q_rows;
my $q_n = $db->query->each(sub { push @q_rows, shift });
cmp_ok($q_n, '==', 4, 'ER10: query->each() returns row count');
cmp_ok(scalar @q_rows, '==', 4, 'ER10: query->each() visits all rows');

# ER10b: query->where()->each()
my @q_filtered;
$db->query->where(number => 1)->each(sub { push @q_filtered, shift });
cmp_ok(scalar @q_filtered, '==', 1, 'ER10b: query->where()->each() filters');
is($q_filtered[0]{'entry'}, 'one', 'ER10b: correct row');

# ER10c: query->each() callback croak
throws_ok(
	sub { Database::Abstraction::Query->new(_db => $db)->each('bad') },
	qr/callback must be a code reference/,
	'ER10c: Query each() croaks on non-coderef'
);
