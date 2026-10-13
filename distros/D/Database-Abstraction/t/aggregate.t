#!perl -w

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;
use Test::Warn;

eval { require DBI; require DBD::SQLite };
if($@) {
	plan skip_all => 'DBD::SQLite not available';
}

# ---- SQLite fixture ----

{
	package Database::aggtest;
	use base 'Database::Abstraction';
}

my $dir  = tempdir(CLEANUP => 1);
my $file = File::Spec->catfile($dir, 'aggtest.sql');
my $dsn  = "dbi:SQLite:dbname=$file";

my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
$setup->do(q{
	CREATE TABLE aggtest (
		id INTEGER PRIMARY KEY,
		name TEXT NOT NULL,
		score REAL,
		status TEXT
	)
});
# Fixture rows
$setup->do(q{INSERT INTO aggtest VALUES (1,'Alice', 9.5,'active')});
$setup->do(q{INSERT INTO aggtest VALUES (2,'Bob',   7.0,'inactive')});
$setup->do(q{INSERT INTO aggtest VALUES (3,'Carol', 8.5,'active')});
$setup->do(q{INSERT INTO aggtest VALUES (4,'Dave',  6.0,'inactive')});
$setup->do(q{INSERT INTO aggtest VALUES (5,'Eve',  10.0,'active')});
$setup->do(q{INSERT INTO aggtest VALUES (6,'Frank', NULL,'active')});
$setup->disconnect();

my $db = Database::aggtest->new(dsn => $dsn, no_entry => 1);

# ---- Test 1: grouped sum ----

my $rows = $db->aggregate(
	by       => ['status'],
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
);
is(ref($rows), 'ARRAY', 'aggregate returns arrayref');
is(scalar @{$rows}, 2, 'test1: 2 groups');
my %by_status1 = map { $_->{'status'} => $_->{'total'} } @{$rows};
is($by_status1{'active'},   28.0, 'test1: active sum = 28');
is($by_status1{'inactive'}, 13.0, 'test1: inactive sum = 13');

# ---- Test 2: grand total (no by), sum + count ----

my $gt = $db->aggregate(
	measures => [
		{ col => 'score', fn => 'sum',   as => 'total' },
		{                 fn => 'count', as => 'n'     },
	],
);
is(scalar @{$gt}, 1, 'test2: grand total is 1 row');
is($gt->[0]{'total'}, 41.0, 'test2: grand total sum (NULL skipped by SUM) = 41');
is($gt->[0]{'n'},     6,    'test2: COUNT(*) includes NULL row = 6');

# ---- Test 3: COUNT(*) vs COUNT(col) ----

my $ct = $db->aggregate(
	by       => ['status'],
	measures => [
		{                 fn => 'count', as => 'all_rows'   },
		{ col => 'score', fn => 'count', as => 'score_rows' },
	],
);
my %by_status3 = map { $_->{'status'} => $_ } @{$ct};
is($by_status3{'active'}{'all_rows'},   4, 'test3: COUNT(*) active = 4 (inc NULL)');
is($by_status3{'active'}{'score_rows'}, 3, 'test3: COUNT(score) active = 3 (excl NULL)');

# ---- Test 4: NULL score row already verified in test 2/3 ----

# Confirm the NULL row (Frank, active) is excluded by COUNT(score) but not COUNT(*)
is($by_status3{'active'}{'all_rows'} - $by_status3{'active'}{'score_rows'}, 1,
	'test4: one NULL score in active group');

# ---- Test 5: avg, min, max ----

my $amm = $db->aggregate(
	by       => ['status'],
	measures => [
		{ col => 'score', fn => 'avg', as => 'mean' },
		{ col => 'score', fn => 'min', as => 'lo'   },
		{ col => 'score', fn => 'max', as => 'hi'   },
	],
	status => 'active',
);
is(scalar @{$amm}, 1, 'test5: active only');
my $act5 = $amm->[0];
ok(abs($act5->{'mean'} - (28.0/3)) < 1e-9, 'test5: avg active ≈ 9.333');
is($act5->{'lo'}, 8.5,  'test5: min active = 8.5');
is($act5->{'hi'}, 10.0, 'test5: max active = 10.0');

# ---- Test 6: count_distinct ----

my $cd = $db->aggregate(
	measures => [{ col => 'status', fn => 'count_distinct', as => 'statuses' }],
);
is($cd->[0]{'statuses'}, 2, 'test6: count_distinct status = 2');

# ---- Test 7: multi-key grouping ----

my $mk = $db->aggregate(
	by       => ['status', 'name'],
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
);
is(scalar @{$mk}, 6, 'test7: 6 groups for status+name');

# ---- Test 8: pre-agg criteria filter ----

my $filt = $db->aggregate(
	by       => ['status'],
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
	status   => 'active',
);
is(scalar @{$filt}, 1, 'test8: criteria filters before grouping');
is($filt->[0]{'status'}, 'active', 'test8: only active group');

# ---- Test 9: operator criteria ----

my $op9 = $db->aggregate(
	measures => [{ fn => 'count', as => 'n' }],
	score    => { '>' => 8 },
);
is($op9->[0]{'n'}, 3, 'test9: COUNT(*) with score > 8 = 3');

# ---- Test 10: -or criteria ----

my $or10 = $db->aggregate(
	by       => ['name'],
	measures => [{ fn => 'count', as => 'n' }],
	'-or'    => [
		{ status => 'active'             },
		{ score  => { '<=' => 6.0 }      },
	],
);
# active: Alice, Carol, Eve, Frank; score<=6: Dave — Dave already excluded by active
# so unique names: Alice, Carol, Dave, Eve, Frank = 5
is(scalar @{$or10}, 5, 'test10: -or criteria gives 5 unique names');

# ---- Test 11: HAVING on alias ----

my $hav11 = $db->aggregate(
	by       => ['status'],
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
	having   => { total => { '>' => 20 } },
);
is(scalar @{$hav11}, 1,        'test11: HAVING total>20 gives 1 row');
is($hav11->[0]{'status'}, 'active', 'test11: HAVING filters to active');

# ---- Test 12: HAVING on group-by column ----

my $hav12 = $db->aggregate(
	by       => ['status'],
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
	having   => { status => 'active' },
);
is(scalar @{$hav12}, 1, 'test12: HAVING on group column');
is($hav12->[0]{'status'}, 'active', 'test12: HAVING group col = active');

# ---- Test 13: HAVING unknown key croaks ----

eval {
	$db->aggregate(
		by       => ['status'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		having   => { nosuchcol => 'x' },
	);
};
like($@, qr/having key 'nosuchcol' is not a group-by column or measure alias/,
	'test13: HAVING unknown key croaks');

# ---- Test 14: sort_by DESC and default ascending ----

my $sorted14 = $db->aggregate(
	by       => ['status'],
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
);
# Default sort: status ASC → active before inactive
is($sorted14->[0]{'status'}, 'active',   'test14: default sort active first');
is($sorted14->[1]{'status'}, 'inactive', 'test14: default sort inactive second');

my $sortedD = $db->aggregate(
	by       => ['status'],
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
	sort_by  => ['total', 'DESC'],
);
is($sortedD->[0]{'status'}, 'active', 'test14: DESC sort active (28) first');

# ---- Test 15: limit and offset ----

my $lim15 = $db->aggregate(
	by       => ['status'],
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
	limit    => 1,
);
is(scalar @{$lim15}, 1, 'test15: limit 1 gives 1 row');

my $off15 = $db->aggregate(
	by       => ['status'],
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
	limit    => 1,
	offset   => 1,
);
is(scalar @{$off15}, 1, 'test15: offset 1 gives second row');
isnt($off15->[0]{'status'}, $lim15->[0]{'status'}, 'test15: offset yields different row');

# ---- Test 16: empty result ----

my $empty16 = $db->aggregate(
	measures => [
		{ col => 'score', fn => 'sum',   as => 'total' },
		{                 fn => 'count', as => 'n'     },
	],
	status => 'nosuchstatus',
);
is(ref($empty16), 'ARRAY', 'test16: empty result is arrayref');
# SQL SUM over no rows may return NULL (normalised to 0), or 0 rows.
# With no GROUP BY and no rows: SQLite returns one row with NULLs for aggregates.
# After normalisation: sum→0, count→0.
if(scalar @{$empty16}) {
	is($empty16->[0]{'total'}, 0, 'test16: empty sum → 0');
	is($empty16->[0]{'n'},     0, 'test16: empty count → 0');
} else {
	pass('test16: empty result → [] (no groups, no grand total row)');
	pass('test16: (no grand total row — count/sum not checked)');
}

# ---- Test 17: all-NULL group ----

my $null17 = $db->aggregate(
	by       => ['name'],
	measures => [
		{ col => 'score', fn => 'sum', as => 'total' },
		{ col => 'score', fn => 'avg', as => 'mean'  },
	],
	name => 'Frank',
);
is(scalar @{$null17}, 1, 'test17: all-NULL group gives 1 row');
is($null17->[0]{'total'}, 0,     'test17: all-NULL sum → 0');
is($null17->[0]{'mean'},  undef, 'test17: all-NULL avg → undef');

# ---- Test 18: return-value shapes ----

my $shape18 = $db->aggregate(
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
);
is(ref($shape18), 'ARRAY', 'test18: result is arrayref');
is(ref($shape18->[0]), 'HASH', 'test18: each row is hashref');
my @list18 = $db->aggregate(
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
);
ok(scalar @list18 >= 1, 'test18: list context works');

# ---- Test 19: no_fixate ----

my $nf19 = $db->aggregate(
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
	no_fixate => 1,
);
ok(defined $nf19, 'test19: no_fixate returns defined result');
is(ref($nf19), 'ARRAY', 'test19: no_fixate result is arrayref');

# ---- Test 20: validation croaks ----

eval { $db->aggregate() };
like($@, qr/measures.*non-empty arrayref/, 'test20: missing measures croaks');

eval { $db->aggregate(measures => []) };
like($@, qr/measures.*non-empty arrayref/, 'test20: empty measures croaks');

eval { $db->aggregate(measures => ['notahashref']) };
like($@, qr/measure must be a hashref/, 'test20: non-hashref measure croaks');

eval { $db->aggregate(measures => [{ col => 'score', fn => 'nosuchfn', as => 'x' }]) };
like($@, qr/unknown measure function/, 'test20: unknown fn croaks');

eval { $db->aggregate(measures => [{ fn => 'sum', as => 'x' }]) };
like($@, qr/measure column is required/, 'test20: missing col for sum croaks');

eval { $db->aggregate(measures => [{ col => 'score', fn => 'sum' }]) };
like($@, qr/measure 'as' is required/, 'test20: missing as croaks');

eval { $db->aggregate(measures => [
	{ col => 'score', fn => 'sum', as => 'x' },
	{ col => 'score', fn => 'avg', as => 'x' },
]) };
like($@, qr/duplicate measure alias/, 'test20: duplicate alias croaks');

eval { $db->aggregate(
	by       => ['status'],
	measures => [{ col => 'score', fn => 'sum', as => 'status' }],
) };
like($@, qr/measure alias.*collides with a group-by column/, 'test20: alias/by collision croaks');

eval { $db->aggregate(measures => [{ col => 'score', fn => 'sum', as => '1bad' }]) };
like($@, qr/unsafe measure alias/, 'test20: unsafe alias croaks');

eval { $db->aggregate(by => ['bad col!'], measures => [{ col => 'score', fn => 'sum', as => 'x' }]) };
like($@, qr/unsafe group-by column/, 'test20: unsafe by column croaks');

eval { $db->aggregate(measures => [{ col => 'bad col!', fn => 'sum', as => 'x' }]) };
like($@, qr/unsafe measure column/, 'test20: unsafe measure col croaks');

eval { $db->aggregate(by => 'notanarray', measures => [{ col => 'score', fn => 'sum', as => 'x' }]) };
like($@, qr/'by' must be an arrayref/, 'test20: non-arrayref by croaks');

# ---- Test 21: Perl-fold path via CSV ----
# CSV backend uses DBD::CSV which has a DBI handle, so use DBM::Deep if available.
# Fallback: skip (matches the xlxs/deep skip pattern from existing test files).

SKIP: {
	eval { require DBM::Deep };
	skip 'DBM::Deep not available', 4 if $@;

	{
		package Database::aggdeep;
		use base 'Database::Abstraction';
	}

	my $deep_dir  = tempdir(CLEANUP => 1);
	my $deep_file = File::Spec->catfile($deep_dir, 'aggdeep.dbm');

	my $d = DBM::Deep->new({ file => $deep_file, type => DBM::Deep->TYPE_HASH });
	$d->{'alice'} = { name => 'Alice', score => '9.5',  status => 'active'   };
	$d->{'bob'}   = { name => 'Bob',   score => '7.0',  status => 'inactive' };
	$d->{'carol'} = { name => 'Carol', score => '8.5',  status => 'active'   };
	$d->{'dave'}  = { name => 'Dave',  score => '6.0',  status => 'inactive' };
	$d->{'eve'}   = { name => 'Eve',   score => '10.0', status => 'active'   };
	undef $d;

	my $ddb = Database::aggdeep->new(directory => $deep_dir);

	my $drows = $ddb->aggregate(
		by       => ['status'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
	);
	is(ref($drows), 'ARRAY', 'test21: DBM::Deep aggregate returns arrayref');
	is(scalar @{$drows}, 2, 'test21: DBM::Deep 2 groups');
	my %ds = map { $_->{'status'} => $_->{'total'} } @{$drows};
	is($ds{'active'},   28.0, 'test21: Deep active sum = 28');
	is($ds{'inactive'}, 13.0, 'test21: Deep inactive sum = 13');
}

# ---- Test 22: non-numeric warning on Perl fold ----

SKIP: {
	eval { require DBM::Deep };
	skip 'DBM::Deep not available', 2 if $@;

	{
		package Database::aggnumwarn;
		use base 'Database::Abstraction';
	}

	my $nw_dir  = tempdir(CLEANUP => 1);
	my $nw_file = File::Spec->catfile($nw_dir, 'aggnumwarn.dbm');

	my $nw = DBM::Deep->new({ file => $nw_file, type => DBM::Deep->TYPE_HASH });
	$nw->{'r1'} = { val => 'abc', grp => 'g1' };
	$nw->{'r2'} = { val => '10',  grp => 'g1' };
	undef $nw;

	my $nwdb = Database::aggnumwarn->new(directory => $nw_dir);

	my $result;
	warnings_like(
		sub {
			$result = $nwdb->aggregate(
				by       => ['grp'],
				measures => [{ col => 'val', fn => 'sum', as => 'total' }],
			);
		},
		qr/non-numeric/,
		'test22: non-numeric warning emitted',
	);
	is($result->[0]{'total'}, 10, 'test22: sum skips non-numeric value');
}

# ---- Test 23: CSV comment-row guard ----

{
	package Database::aggcsv;
	use base 'Database::Abstraction';
}

my $csv_dir = tempdir(CLEANUP => 1);
{
	open my $fh, '>', File::Spec->catfile($csv_dir, 'aggcsv.csv') or die $!;
	# Default sep_char is '!' for this dist
	print $fh "entry!score!status\n";
	print $fh "#comment!0!comment\n";
	print $fh "alice!9.5!active\n";
	print $fh "bob!7.0!inactive\n";
	close $fh;
}
my $csvdb = Database::aggcsv->new(directory => $csv_dir, sep_char => '!');

my $csv23 = $csvdb->aggregate(
	measures => [{ fn => 'count', as => 'n' }],
);
# Comment row must be excluded; only alice and bob count
is($csv23->[0]{'n'}, 2, 'test23: CSV comment row excluded from COUNT(*)');

# ---- Test 24: query-builder parity ----

my $direct24 = $db->aggregate(
	by       => ['status'],
	measures => [{ col => 'score', fn => 'sum', as => 'total' }],
	sort_by  => ['status', 'ASC'],
);

my $builder24 = $db->query
	->group_by('status')
	->measure('score', 'sum', 'total')
	->order_by('status ASC')
	->all();

# Sort both by status for stable comparison
my @d24 = sort { $a->{'status'} cmp $b->{'status'} } @{$direct24};
my @b24 = sort { $a->{'status'} cmp $b->{'status'} } @{$builder24};
is(scalar @b24, scalar @d24, 'test24: builder and flat API give same row count');
is($b24[0]{'total'}, $d24[0]{'total'}, 'test24: first group totals match');
is($b24[1]{'total'}, $d24[1]{'total'}, 'test24: second group totals match');

# ---- Test 25: builder chaining ----

my $chain25 = $db->query
	->where(status => 'active')
	->group_by('status')
	->measure('score', 'sum', 'total')
	->having(total => { '>' => 20 })
	->order_by('status ASC')
	->limit(5)
	->all();
is(scalar @{$chain25}, 1,        'test25: chained query returns 1 row');
is($chain25->[0]{'status'}, 'active', 'test25: chained query = active');

# ---- Test 26: count() after measure() croaks; first() returns one row ----

eval {
	$db->query->measure('score', 'sum', 'total')->count();
};
like($@, qr/count\(\) is not available once measure\(\) has been called/,
	'test26: count() after measure() croaks');

my $first26 = $db->query
	->group_by('status')
	->measure('score', 'sum', 'total')
	->first();
ok(defined $first26, 'test26: first() returns defined row');
is(ref($first26), 'HASH', 'test26: first() returns hashref');
ok(exists $first26->{'total'}, 'test26: first() row has total key');

done_testing();
