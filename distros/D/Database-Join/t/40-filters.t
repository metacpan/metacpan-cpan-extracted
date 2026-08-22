use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
	eval { require DBD::SQLite; require Database::Abstraction };
	plan skip_all => 'DBD::SQLite and Database::Abstraction required' if $@;
	plan tests => 31;
}

use lib 't/lib';
use DBI;
use File::Temp qw(tempdir);
use Database::djcust;
use Database::djscore;
use Database::Join;

# ---------------------------------------------------------------------------
# Fixtures
#
#   djcust:  entry | name | tier
#       c001  Alice  gold
#       c002  Bob    silver
#       c003  Carol  gold
#
#   djscore: entry | score | age_days
#       c001   95    90
#       c002   70    30
#       c003   55   120
#
# Unfiltered join: 3 rows.
#
# Primary filter (tier='gold'): Alice and Carol only (2 rows).
# Secondary filter (score>60): Alice and Bob qualify; Carol has score=55 so
#   she is excluded from the merged view (inner-join semantics).
# Both filters combined: only Alice (gold tier AND score>60).
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/djcust.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE djcust (entry TEXT PRIMARY KEY, name TEXT, tier TEXT)');
	$dbh->do(q{INSERT INTO djcust VALUES ('c001','Alice','gold')});
	$dbh->do(q{INSERT INTO djcust VALUES ('c002','Bob',  'silver')});
	$dbh->do(q{INSERT INTO djcust VALUES ('c003','Carol','gold')});
	$dbh->disconnect;
}

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/djscore.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE djscore (entry TEXT PRIMARY KEY, score INTEGER, age_days INTEGER)');
	$dbh->do(q{INSERT INTO djscore VALUES ('c001', 95,  90)});
	$dbh->do(q{INSERT INTO djscore VALUES ('c002', 70,  30)});
	$dbh->do(q{INSERT INTO djscore VALUES ('c003', 55, 120)});
	$dbh->disconnect;
}

my $cust  = Database::djcust->new(directory  => $dir);
my $score = Database::djscore->new(directory => $dir);

# ---------------------------------------------------------------------------
# Baseline: no filters — all 3 rows
# ---------------------------------------------------------------------------

my $join_base = Database::Join->new(
	databases   => [ $cust, $score ],
	join_column => 'entry',
);
my $base_rows = $join_base->selectall_arrayref();
is(scalar @{$base_rows}, 3, 'baseline: 3 rows with no filter');

# ---------------------------------------------------------------------------
# Primary database filter (index 0): tier = 'gold'
# Only Alice (c001) and Carol (c003) pass; Bob (c002) is excluded.
# ---------------------------------------------------------------------------

my $join_pf;
lives_ok {
	$join_pf = Database::Join->new(
		databases   => [ $cust, $score ],
		join_column => 'entry',
		filters     => { 0 => { tier => 'gold' } },
	);
} 'new with primary filter lives';

my $pf_rows = $join_pf->selectall_arrayref();
is(scalar @{$pf_rows}, 2, 'primary filter: 2 gold-tier rows');
is($pf_rows->[0]{name}, 'Alice', 'primary filter row 0: Alice');
is($pf_rows->[0]{score}, 95,     'primary filter row 0: score still present');
is($pf_rows->[1]{name}, 'Carol', 'primary filter row 1: Carol');

# count() respects the filter
is($join_pf->count(), 2, 'count() respects primary filter');

# Additional query criteria layer on top
my $gold_high = $join_pf->selectall_arrayref(score => { '>' => 90 });
is(scalar @{$gold_high}, 1,       'query criteria narrow filtered view further');
is($gold_high->[0]{name}, 'Alice', 'only Alice has gold + score > 90');

# ---------------------------------------------------------------------------
# Secondary database filter (index 1): score > 60
# Alice (95) and Bob (70) pass; Carol (55) is excluded.
# Because the filtered secondary acts as an inner-join partner, Carol
# disappears from the merged output entirely (not just her score columns).
# ---------------------------------------------------------------------------

my $join_sf;
lives_ok {
	$join_sf = Database::Join->new(
		databases   => [ $cust, $score ],
		join_column => 'entry',
		filters     => { 1 => { score => { '>' => 60 } } },
	);
} 'new with secondary filter lives';

my $sf_rows = $join_sf->selectall_arrayref();
is(scalar @{$sf_rows}, 2, 'secondary filter: 2 rows with score > 60');
my %sf_names = map { $_->{name} => 1 } @{$sf_rows};
ok($sf_names{Alice}, 'secondary filter includes Alice (score 95)');
ok($sf_names{Bob},   'secondary filter includes Bob (score 70)');
ok(!$sf_names{Carol},'secondary filter excludes Carol (score 55, inner-join semantics)');

# ---------------------------------------------------------------------------
# Both filters combined: tier='gold' on index 0, score>60 on index 1.
# Alice:  gold + score 95  -> pass
# Bob:    silver + score 70 -> excluded by tier filter on primary
# Carol:  gold + score 55  -> excluded by score filter on secondary
# Result: Alice only.
# ---------------------------------------------------------------------------

my $join_both;
lives_ok {
	$join_both = Database::Join->new(
		databases   => [ $cust, $score ],
		join_column => 'entry',
		filters     => {
			0 => { tier  => 'gold'        },
			1 => { score => { '>' => 60 } },
		},
	);
} 'new with both filters lives';

my $both_rows = $join_both->selectall_arrayref();
is(scalar @{$both_rows}, 1,       'both filters: 1 row survives');
is($both_rows->[0]{name},  'Alice','both filters: surviving row is Alice');
is($both_rows->[0]{score},  95,    'both filters: score present');

# ---------------------------------------------------------------------------
# Criteria merging: base filter + query criterion on the same column
# Base filter: score > 60 (excludes Carol).
# Query criterion: score < 90 (excludes Alice).
# Merged: score > 60 AND score < 90 → only Bob (70).
# ---------------------------------------------------------------------------

my $joined_merge = Database::Join->new(
	databases   => [ $cust, $score ],
	join_column => 'entry',
	filters     => { 1 => { score => { '>' => 60 } } },
);

my $merged_rows = $joined_merge->selectall_arrayref(score => { '<' => 90 });
is(scalar @{$merged_rows}, 1,     'criteria merge: base+query gives 1 row');
is($merged_rows->[0]{name}, 'Bob', 'criteria merge: surviving row is Bob (70)');

# ---------------------------------------------------------------------------
# add_database with filter =>
# Build a join by first constructing with only $cust, then add $score with
# a filter.  Should produce the same result as the secondary-filter case above.
# ---------------------------------------------------------------------------

my $join_add;
lives_ok {
	$join_add = Database::Join->new(
		databases   => [ $cust ],
		join_column => 'entry',
	);
	$join_add->add_database($score, filter => { score => { '>' => 60 } });
} 'add_database with filter lives';

my $add_rows = $join_add->selectall_arrayref();
is(scalar @{$add_rows}, 2, 'add_database filter: 2 rows with score > 60');
my %add_names = map { $_->{name} => 1 } @{$add_rows};
ok($add_names{Alice}, 'add_database filter includes Alice');
ok($add_names{Bob},   'add_database filter includes Bob');
ok(!$add_names{Carol},'add_database filter excludes Carol');

# ---------------------------------------------------------------------------
# add_database: filter and join_column together (join_map scenario)
# ---------------------------------------------------------------------------

# Build a second score table using a different join-key column name.
{
	my $dbh2 = DBI->connect("dbi:SQLite:dbname=$dir/djscore.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	# djscore already exists; just reuse it via a second object.
	$dbh2->disconnect;
}

# $score already uses 'entry' as the join column; here we pretend it uses a
# different name by adding it with join_column => 'entry' (same value, but
# exercises the combined path).
my $join_jm_filter;
lives_ok {
	$join_jm_filter = Database::Join->new(
		databases   => [ $cust ],
		join_column => 'entry',
	);
	$join_jm_filter->add_database($score,
		join_column => 'entry',
		filter      => { score => { '>' => 60 } },
	);
} 'add_database with join_column + filter lives';

my $jmf_rows = $join_jm_filter->selectall_arrayref();
is(scalar @{$jmf_rows}, 2, 'join_column + filter: 2 rows');

# ---------------------------------------------------------------------------
# Filter is applied before AUTOLOAD shortcuts too
# ---------------------------------------------------------------------------

my $join_al = Database::Join->new(
	databases   => [ $cust, $score ],
	join_column => 'entry',
	filters     => { 1 => { score => { '>' => 60 } } },
);

# Carol has score=55 which the secondary filter (score > 60) excludes.
# The full join query sees no merged row for c003, so AUTOLOAD returns undef.
is($join_al->score('c003'), undef,
	'AUTOLOAD respects filter: filtered-out row returns undef');

# Alice's score is above the threshold, so it is accessible.
is($join_al->score('c001'), 95, 'AUTOLOAD returns score for passing row');

# ---------------------------------------------------------------------------
# Constructor filter on an invalid (non-existent) index is silently ignored
# ---------------------------------------------------------------------------

my $join_bad_idx;
lives_ok {
	$join_bad_idx = Database::Join->new(
		databases   => [ $cust, $score ],
		join_column => 'entry',
		filters     => { 99 => { score => { '>' => 60 } } },
	);
} 'filter on non-existent database index is silently ignored';

my $bad_rows = $join_bad_idx->selectall_arrayref();
is(scalar @{$bad_rows}, 3, 'ignored filter leaves all 3 rows');

# Release DBI connections before File::Temp's cleanup END block fires.
# On Windows, SQLite keeps files locked until all handles are closed; file-scoped
# 'my' variables outlive END blocks, so we undef explicitly (joins first).
undef $_ for ($join_base, $join_pf, $join_sf, $join_both, $joined_merge,
              $join_add, $join_jm_filter, $join_al, $join_bad_idx,
              $cust, $score);
