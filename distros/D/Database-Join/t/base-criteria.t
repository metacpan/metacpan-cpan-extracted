use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
	eval { require DBD::SQLite; require Database::Abstraction };
	plan skip_all => 'DBD::SQLite and Database::Abstraction required' if $@;
	plan tests => 32;
}

use lib 't/lib';
use DBI;
use File::Temp qw(tempdir);
use Database::djcust;
use Database::djscore;
use_ok('Database::Join');

# ---------------------------------------------------------------------------
# Fixtures
#
#   djcust:  entry | name  | tier
#       c001  Alice   gold
#       c002  Bob     silver
#       c003  Carol   gold
#
#   djscore: entry | score | age_days
#       c001   95    90
#       c002   70    30
#       c003   55   120
#
# base_criteria tests mirror the filters tests, but criteria are specified
# by column name instead of database index.
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
# BC-01: baseline — no base_criteria, all 3 rows
# ---------------------------------------------------------------------------

my $join_base = Database::Join->new(
	databases   => [ $cust, $score ],
	join_column => 'entry',
);
is(scalar @{ $join_base->selectall_arrayref() }, 3,
	'BC-01: baseline with no base_criteria: 3 rows');

# ---------------------------------------------------------------------------
# BC-02/03: primary-database column filter via base_criteria
# tier='gold' lives in djcust (index 0); only Alice and Carol pass.
# ---------------------------------------------------------------------------

my $join_primary;
lives_ok {
	$join_primary = Database::Join->new(
		databases     => [ $cust, $score ],
		join_column   => 'entry',
		base_criteria => { tier => 'gold' },
	);
} 'BC-02: new with base_criteria on primary column lives';

my $pc_rows = $join_primary->selectall_arrayref();
is(scalar @{$pc_rows}, 2, 'BC-03: primary-col base_criteria: 2 gold rows');
is($pc_rows->[0]{name}, 'Alice', 'BC-03a: row 0 is Alice');
is($pc_rows->[1]{name}, 'Carol', 'BC-03b: row 1 is Carol');

# ---------------------------------------------------------------------------
# BC-04: count() respects base_criteria
# ---------------------------------------------------------------------------

is($join_primary->count(), 2, 'BC-04: count() respects base_criteria');

# ---------------------------------------------------------------------------
# BC-05: fetchrow_hashref respects base_criteria
# ---------------------------------------------------------------------------

is($join_primary->fetchrow_hashref(entry => 'c002'), undef,
	'BC-05: fetchrow_hashref returns undef for filtered-out row');

# ---------------------------------------------------------------------------
# BC-06/07: secondary-database column filter via base_criteria
# score > 60 lives in djscore (index 1).
# Alice (95) and Bob (70) pass; Carol (55) is excluded entirely (inner-join).
# ---------------------------------------------------------------------------

my $join_secondary;
lives_ok {
	$join_secondary = Database::Join->new(
		databases     => [ $cust, $score ],
		join_column   => 'entry',
		base_criteria => { score => { '>' => 60 } },
	);
} 'BC-06: new with base_criteria on secondary column lives';

my $sc_rows = $join_secondary->selectall_arrayref();
is(scalar @{$sc_rows}, 2, 'BC-07: secondary-col base_criteria: 2 rows (score > 60)');
my %sc_names = map { $_->{name} => 1 } @{$sc_rows};
ok($sc_names{Alice}, 'BC-07a: Alice (score 95) included');
ok($sc_names{Bob},   'BC-07b: Bob (score 70) included');
ok(!$sc_names{Carol},'BC-07c: Carol (score 55) excluded — inner-join semantics');

# ---------------------------------------------------------------------------
# BC-08: multi-column base_criteria across both databases
# tier='gold' on primary AND score > 60 on secondary.
# Alice:  gold, 95 -> pass
# Bob:    silver, 70 -> excluded by tier
# Carol:  gold, 55 -> excluded by score
# Result: Alice only.
# ---------------------------------------------------------------------------

my $join_both;
lives_ok {
	$join_both = Database::Join->new(
		databases     => [ $cust, $score ],
		join_column   => 'entry',
		base_criteria => { tier => 'gold', score => { '>' => 60 } },
	);
} 'BC-08: new with multi-column base_criteria lives';

my $both_rows = $join_both->selectall_arrayref();
is(scalar @{$both_rows}, 1,        'BC-08a: multi-col base_criteria: 1 row survives');
is($both_rows->[0]{name},  'Alice', 'BC-08b: surviving row is Alice');
is($both_rows->[0]{score},  95,     'BC-08c: score present in merged row');

# ---------------------------------------------------------------------------
# BC-09: base_criteria is equivalent to the corresponding filters entry
# ---------------------------------------------------------------------------

my $join_via_filters = Database::Join->new(
	databases   => [ $cust, $score ],
	join_column => 'entry',
	filters     => { 0 => { tier => 'gold' } },
);

my $bc_rows = $join_primary->selectall_arrayref();
my $fi_rows = $join_via_filters->selectall_arrayref();
is_deeply($bc_rows, $fi_rows,
	'BC-09: base_criteria result matches equivalent filters result');

# ---------------------------------------------------------------------------
# BC-10: criteria merging — base_criteria + query-time criterion on same column
# base_criteria: score > 60 (excludes Carol)
# query:         score < 90 (excludes Alice)
# Merged (AND):  score > 60 AND score < 90 -> only Bob (70)
# ---------------------------------------------------------------------------

my $join_merge = Database::Join->new(
	databases     => [ $cust, $score ],
	join_column   => 'entry',
	base_criteria => { score => { '>' => 60 } },
);

my $merged = $join_merge->selectall_arrayref(score => { '<' => 90 });
is(scalar @{$merged}, 1,     'BC-10a: criteria merge (AND): 1 row survives');
is($merged->[0]{name}, 'Bob', 'BC-10b: surviving row is Bob (70)');

# ---------------------------------------------------------------------------
# BC-11: precedence — when same column appears in both base_criteria and
# filters, the filters entry wins on plain-scalar conflicts.
# base_criteria: tier = 'silver' (would keep only Bob)
# filters:       tier = 'gold'   (should override, keeping Alice + Carol)
# ---------------------------------------------------------------------------

my $join_prec = Database::Join->new(
	databases     => [ $cust, $score ],
	join_column   => 'entry',
	base_criteria => { tier => 'silver' },
	filters       => { 0 => { tier => 'gold' } },
);

my $prec_rows = $join_prec->selectall_arrayref();
is(scalar @{$prec_rows}, 2, 'BC-11a: filters wins over base_criteria (2 gold rows)');
my %prec_names = map { $_->{name} => 1 } @{$prec_rows};
ok($prec_names{Alice}, 'BC-11b: Alice present (gold, from filters)');
ok($prec_names{Carol}, 'BC-11c: Carol present (gold, from filters)');
ok(!$prec_names{Bob},  'BC-11d: Bob absent (silver, base_criteria overridden)');

# ---------------------------------------------------------------------------
# BC-12: empty base_criteria is a no-op
# ---------------------------------------------------------------------------

my $join_empty;
lives_ok {
	$join_empty = Database::Join->new(
		databases     => [ $cust, $score ],
		join_column   => 'entry',
		base_criteria => {},
	);
} 'BC-12a: empty base_criteria accepted';
is(scalar @{ $join_empty->selectall_arrayref() }, 3,
	'BC-12b: empty base_criteria: all 3 rows visible');

# ---------------------------------------------------------------------------
# BC-13: unknown column in base_criteria — carp + silently dropped
# ---------------------------------------------------------------------------

my @warnings;
{
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $join_unk = Database::Join->new(
		databases     => [ $cust, $score ],
		join_column   => 'entry',
		base_criteria => { no_such_col => 'x' },
	);
	my $rows = $join_unk->selectall_arrayref();
	is(scalar @{$rows}, 3, 'BC-13a: unknown base_criteria col dropped; all rows visible');
}
ok(scalar @warnings > 0,              'BC-13b: unknown column triggered a carp warning');
like($warnings[0], qr/no_such_col/,   'BC-13c: warning names the unknown column');

# ---------------------------------------------------------------------------
# BC-14: join_type=outer with base_criteria on secondary — inner-join wins
# With outer join and no filter, all 3 primary keys are in the result.
# Adding base_criteria on the secondary converts it to inner-join: only
# keys that pass the secondary filter appear in the output.
# ---------------------------------------------------------------------------

my $join_outer_bc = Database::Join->new(
	databases     => [ $cust, $score ],
	join_column   => 'entry',
	join_type     => 'outer',
	base_criteria => { score => { '>' => 60 } },
);

my $outer_bc_rows = $join_outer_bc->selectall_arrayref();
is(scalar @{$outer_bc_rows}, 2,
	'BC-14: outer join_type with base_criteria on secondary: inner-join semantics win');

# ---------------------------------------------------------------------------
# BC-15: AUTOLOAD respects base_criteria
# ---------------------------------------------------------------------------

my $join_al = Database::Join->new(
	databases     => [ $cust, $score ],
	join_column   => 'entry',
	base_criteria => { score => { '>' => 60 } },
);

is($join_al->score('c003'), undef,
	'BC-15a: AUTOLOAD returns undef for filtered-out row (Carol, score 55)');
is($join_al->score('c001'), 95,
	'BC-15b: AUTOLOAD returns value for passing row (Alice, score 95)');

# Release DBI connections before File::Temp cleanup.
undef $_ for ($join_base, $join_primary, $join_secondary, $join_both,
              $join_via_filters, $join_merge, $join_prec, $join_empty,
              $join_outer_bc, $join_al, $cust, $score);
