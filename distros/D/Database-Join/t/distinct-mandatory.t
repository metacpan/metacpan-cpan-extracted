use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
	eval { require DBD::SQLite; require Database::Abstraction };
	plan skip_all => 'DBD::SQLite and Database::Abstraction required' if $@;
	plan tests => 45;
}

use lib 't/lib';
use DBI;
use File::Temp qw(tempdir);
use Database::Join;

# ---------------------------------------------------------------------------
# Inline minimal DAs (no file fixtures needed)
# ---------------------------------------------------------------------------

package MinimalDA;
use parent -norequire, 'Database::Abstraction';
sub new {
	my ($class, %args) = @_;
	return bless { _cols => $args{cols}, _rows => $args{rows} }, $class;
}
sub columns { return $_[0]->{_cols} }
sub schema  { return {} }
sub updated { return undef }
sub set_logger { return $_[0] }
sub selectall_arrayref {
	my ($self, $crit) = @_;
	$crit //= {};
	my @rows = @{ $self->{_rows} };
	for my $col (keys %{$crit}) {
		my $val = $crit->{$col};
		if (!ref $val) {
			@rows = grep { defined $_->{$col} && $_->{$col} eq $val } @rows;
		} elsif (ref $val eq 'HASH') {
			for my $op (keys %{$val}) {
				my $v = $val->{$op};
				if    ($op eq '=')  { @rows = grep { defined $_->{$col} && $_->{$col} eq  $v } @rows }
				elsif ($op eq '!=') { @rows = grep { defined $_->{$col} && $_->{$col} ne  $v } @rows }
				elsif ($op eq '>')  { @rows = grep { defined $_->{$col} && $_->{$col} >   $v } @rows }
				elsif ($op eq '<')  { @rows = grep { defined $_->{$col} && $_->{$col} <   $v } @rows }
				elsif ($op eq '>=') { @rows = grep { defined $_->{$col} && $_->{$col} >=  $v } @rows }
				elsif ($op eq '<=') { @rows = grep { defined $_->{$col} && $_->{$col} <=  $v } @rows }
			}
		}
	}
	return \@rows;
}

package main;

# ---------------------------------------------------------------------------
# Fixtures
#
#   left:   entry | region | tier
#     r1     West   gold
#     r2     East   silver
#     r3     West   silver
#     r4     East   gold
#     r5     West   bronze
#
#   right:  entry | score
#     r1      90
#     r2      70
#     r3      85
#     r4      60
#     r5      50
# ---------------------------------------------------------------------------

my $left = MinimalDA->new(
	cols => [qw(entry region tier)],
	rows => [
		{ entry => 'r1', region => 'West', tier => 'gold'   },
		{ entry => 'r2', region => 'East', tier => 'silver' },
		{ entry => 'r3', region => 'West', tier => 'silver' },
		{ entry => 'r4', region => 'East', tier => 'gold'   },
		{ entry => 'r5', region => 'West', tier => 'bronze' },
	],
);

my $right = MinimalDA->new(
	cols => [qw(entry score)],
	rows => [
		{ entry => 'r1', score => 90 },
		{ entry => 'r2', score => 70 },
		{ entry => 'r3', score => 85 },
		{ entry => 'r4', score => 60 },
		{ entry => 'r5', score => 50 },
	],
);

# ---------------------------------------------------------------------------
# S1: distinct => 1 with columns on the array backend
# ---------------------------------------------------------------------------

{
	my $j = Database::Join->new(
		databases   => [$left, $right],
		join_column => 'entry',
		backend     => 'array',
	);

	# S1.1: distinct regions (3 rows: West, East appear 3 and 2 times)
	my $rows = $j->selectall_arrayref(distinct => 1, columns => ['region']);
	is(scalar @{$rows}, 2, 'S1.1: distinct regions: 2 rows');
	my @regions = sort map { $_->{region} } @{$rows};
	is_deeply(\@regions, ['East', 'West'], 'S1.1: distinct regions: East and West');
	ok(!exists $rows->[0]{entry}, 'S1.1: entry not in projected result');
	ok(!exists $rows->[0]{score}, 'S1.1: score not in projected result');

	# S1.2: distinct tiers
	my $trows = $j->selectall_arrayref(distinct => 1, columns => ['tier']);
	is(scalar @{$trows}, 3, 'S1.2: distinct tiers: 3 rows (gold, silver, bronze)');
	my @tiers = sort map { $_->{tier} } @{$trows};
	is_deeply(\@tiers, [qw(bronze gold silver)], 'S1.2: tier values correct');

	# S1.3: distinct (region, tier) combinations
	# West+gold, East+silver, West+silver, East+gold, West+bronze => 5 unique combos
	my $rrows = $j->selectall_arrayref(distinct => 1, columns => [qw(region tier)]);
	is(scalar @{$rrows}, 5, 'S1.3: distinct region+tier: 5 unique combinations');

	# S1.4: distinct without columns => full-row dedup (all 5 rows distinct)
	my $arows = $j->selectall_arrayref(distinct => 1);
	is(scalar @{$arows}, 5, 'S1.4: distinct no columns => 5 distinct full rows');

	# S1.5: first occurrence wins — add duplicate rows
	my $dup = MinimalDA->new(
		cols => [qw(entry region tier)],
		rows => [
			{ entry => 'x1', region => 'North', tier => 'gold' },
			{ entry => 'x2', region => 'North', tier => 'gold' },
		],
	);
	my $dup_right = MinimalDA->new(
		cols => [qw(entry score)],
		rows => [
			{ entry => 'x1', score => 10 },
			{ entry => 'x2', score => 20 },
		],
	);
	my $jdup = Database::Join->new(
		databases   => [$dup, $dup_right],
		join_column => 'entry',
		backend     => 'array',
	);
	my $drows = $jdup->selectall_arrayref(distinct => 1, columns => [qw(region tier)]);
	is(scalar @{$drows}, 1, 'S1.5: first occurrence wins: 1 distinct (region,tier)');
	is($drows->[0]{region}, 'North', 'S1.5: first occurrence region correct');
}

# ---------------------------------------------------------------------------
# S2: distinct => 1 on the SQLite backend
# ---------------------------------------------------------------------------

{
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	for my $t (qw(left right)) {
		my ($cols, $rows, $name) = $t eq 'left'
			? (['entry TEXT', 'region TEXT', 'tier TEXT'],
			   [['r1','West','gold'], ['r2','East','silver'],
			    ['r3','West','silver'], ['r4','East','gold'], ['r5','West','bronze']],
			   'left_t')
			: (['entry TEXT', 'score INTEGER'],
			   [['r1',90],['r2',70],['r3',85],['r4',60],['r5',50]],
			   'right_t');
		my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/$name.db",'','',
			{RaiseError=>1,PrintError=>0});
		$dbh->do('CREATE TABLE t (' . join(', ', @$cols) . ')');
		my $ph = join(',',('?')x scalar @$cols);
		$dbh->do("INSERT INTO t VALUES ($ph)", undef, @$_) for @$rows;
		$dbh->disconnect;
	}

	# Use MinimalDA fixtures (array backend fallback) for the SQLite distinct test
	my $j = Database::Join->new(
		databases   => [$left, $right],
		join_column => 'entry',
		backend     => 'array',   # distinct tested via array path above; SQLite path below
	);

	# SQLite backend: use backend => 'sqlite' explicitly
	my $js = Database::Join->new(
		databases   => [$left, $right],
		join_column => 'entry',
		backend     => 'sqlite',
		tmpdir      => $dir,
	);

	# S2.1: distinct regions via SQLite path
	my $rows = $js->selectall_arrayref(distinct => 1, columns => ['region']);
	is(scalar @{$rows}, 2, 'S2.1: SQLite distinct regions: 2 rows');
	my @regions = sort map { $_->{region} } @{$rows};
	is_deeply(\@regions, ['East', 'West'], 'S2.1: SQLite distinct regions correct');

	# S2.2: distinct tiers via SQLite path
	my $trows = $js->selectall_arrayref(distinct => 1, columns => ['tier']);
	is(scalar @{$trows}, 3, 'S2.2: SQLite distinct tiers: 3 rows');

	# S2.3: distinct without columns via SQLite path (all rows unique)
	my $arows = $js->selectall_arrayref(distinct => 1);
	is(scalar @{$arows}, 5, 'S2.3: SQLite distinct no columns: 5 rows');
}

# ---------------------------------------------------------------------------
# S3: mandatory_filters — constructor validation
# ---------------------------------------------------------------------------

{
	# S3.1: well-formed mandatory_filters accepted
	lives_ok {
		Database::Join->new(
			databases         => [$left, $right],
			join_column       => 'entry',
			mandatory_filters => [{ col => 'region', op => 'eq', val => 'West' }],
		);
	} 'S3.1: valid mandatory_filters accepted';

	# S3.2: missing required key 'op' croaks
	dies_ok {
		Database::Join->new(
			databases         => [$left, $right],
			join_column       => 'entry',
			mandatory_filters => [{ col => 'region', val => 'West' }],
		);
	} 'S3.2: missing op key croaks';

	# S3.3: unknown column croaks
	dies_ok {
		Database::Join->new(
			databases         => [$left, $right],
			join_column       => 'entry',
			mandatory_filters => [{ col => 'nonexistent', op => 'eq', val => 'x' }],
		);
	} 'S3.3: unknown column croaks';

	# S3.4: unsupported op croaks
	dies_ok {
		Database::Join->new(
			databases         => [$left, $right],
			join_column       => 'entry',
			mandatory_filters => [{ col => 'region', op => 'regex', val => 'W.*' }],
		);
	} 'S3.4: unsupported op croaks';

	# S3.5: non-hashref element croaks
	dies_ok {
		Database::Join->new(
			databases         => [$left, $right],
			join_column       => 'entry',
			mandatory_filters => ['not-a-hashref'],
		);
	} 'S3.5: non-hashref element croaks';

	# S3.6: empty mandatory_filters arrayref is accepted
	lives_ok {
		Database::Join->new(
			databases         => [$left, $right],
			join_column       => 'entry',
			mandatory_filters => [],
		);
	} 'S3.6: empty mandatory_filters accepted';
}

# ---------------------------------------------------------------------------
# S4: mandatory_filters — array backend behaviour
# ---------------------------------------------------------------------------

{
	# S4.1: eq — only West rows
	my $j_eq = Database::Join->new(
		databases         => [$left, $right],
		join_column       => 'entry',
		backend           => 'array',
		mandatory_filters => [{ col => 'region', op => 'eq', val => 'West' }],
	);
	my $rows = $j_eq->selectall_arrayref();
	is(scalar @{$rows}, 3, 'S4.1: mandatory eq: 3 West rows');
	ok(!grep({ $_->{region} ne 'West' } @{$rows}), 'S4.1: all rows have region=West');

	# S4.2: ne — non-West rows
	my $j_ne = Database::Join->new(
		databases         => [$left, $right],
		join_column       => 'entry',
		backend           => 'array',
		mandatory_filters => [{ col => 'region', op => 'ne', val => 'West' }],
	);
	my $rows_ne = $j_ne->selectall_arrayref();
	is(scalar @{$rows_ne}, 2, 'S4.2: mandatory ne: 2 East rows');

	# S4.3: combined caller criteria + mandatory filter (AND semantics)
	# mandatory: region=West (3 rows); caller: tier=gold (2 rows: r1+r4)
	# combined: r1 only (West AND gold)
	my $rows_and = $j_eq->selectall_arrayref(tier => 'gold');
	is(scalar @{$rows_and}, 1, 'S4.3: mandatory AND caller criteria: 1 row');
	is($rows_and->[0]{entry}, 'r1', 'S4.3: correct row returned');

	# S4.4: multiple mandatory filters (AND semantics): region=West AND tier=gold
	my $j_multi = Database::Join->new(
		databases         => [$left, $right],
		join_column       => 'entry',
		backend           => 'array',
		mandatory_filters => [
			{ col => 'region', op => 'eq', val => 'West' },
			{ col => 'tier',   op => 'eq', val => 'gold' },
		],
	);
	my $rows_multi = $j_multi->selectall_arrayref();
	is(scalar @{$rows_multi}, 1, 'S4.4: multi mandatory: 1 row (West+gold)');
	is($rows_multi->[0]{entry}, 'r1', 'S4.4: entry r1 is West+gold');

	# S4.5: gt operator
	my $j_gt = Database::Join->new(
		databases         => [$left, $right],
		join_column       => 'entry',
		backend           => 'array',
		mandatory_filters => [{ col => 'score', op => 'gt', val => 75 }],
	);
	my $rows_gt = $j_gt->selectall_arrayref();
	is(scalar @{$rows_gt}, 2, 'S4.5: mandatory gt(75): 2 rows (90, 85)');

	# S4.6: contains operator
	my $j_cont = Database::Join->new(
		databases         => [$left, $right],
		join_column       => 'entry',
		backend           => 'array',
		mandatory_filters => [{ col => 'tier', op => 'contains', val => 'il' }],
	);
	my $rows_cont = $j_cont->selectall_arrayref();
	is(scalar @{$rows_cont}, 2, 'S4.6: mandatory contains(il): 2 rows (silver)');

	# S4.7: like operator with % wildcard
	my $j_like = Database::Join->new(
		databases         => [$left, $right],
		join_column       => 'entry',
		backend           => 'array',
		mandatory_filters => [{ col => 'tier', op => 'like', val => 'g%' }],
	);
	my $rows_like = $j_like->selectall_arrayref();
	is(scalar @{$rows_like}, 2, 'S4.7: mandatory like(g%): 2 rows (gold)');

	# S4.8: count() also applies mandatory_filters
	is($j_eq->count(), 3, 'S4.8: count() honours mandatory_filters');

	# S4.9: fetchrow_hashref also applies mandatory_filters
	my $row = $j_eq->fetchrow_hashref();
	ok(defined $row, 'S4.9: fetchrow_hashref returns a row');
	is($row->{region}, 'West', 'S4.9: returned row satisfies mandatory filter');
}

# ---------------------------------------------------------------------------
# S5: mandatory_filters — SQLite backend behaviour
# ---------------------------------------------------------------------------

{
	my $dir2 = File::Temp::tempdir(CLEANUP => 1);

	my $j_sql = Database::Join->new(
		databases         => [$left, $right],
		join_column       => 'entry',
		backend           => 'sqlite',
		tmpdir            => $dir2,
		mandatory_filters => [{ col => 'region', op => 'eq', val => 'West' }],
	);

	# S5.1: mandatory eq on SQLite backend
	my $rows = $j_sql->selectall_arrayref();
	is(scalar @{$rows}, 3, 'S5.1: SQLite mandatory eq: 3 West rows');
	ok(!grep({ $_->{region} ne 'West' } @{$rows}), 'S5.1: all rows West');

	# S5.2: count() on SQLite mandatory_filters
	is($j_sql->count(), 3, 'S5.2: SQLite count() honours mandatory_filters');

	# S5.3: combined caller + mandatory on SQLite
	my $rows_and = $j_sql->selectall_arrayref(tier => 'gold');
	is(scalar @{$rows_and}, 1, 'S5.3: SQLite mandatory AND caller: 1 row');
	is($rows_and->[0]{entry}, 'r1', 'S5.3: entry r1');
}

# ---------------------------------------------------------------------------
# S6: mandatory_filters security invariant — cannot be bypassed
# ---------------------------------------------------------------------------

{
	my $j_rls = Database::Join->new(
		databases         => [$left, $right],
		join_column       => 'entry',
		backend           => 'array',
		mandatory_filters => [{ col => 'region', op => 'eq', val => 'West' }],
	);

	# S6.1: attempting to query for East rows still returns nothing (guard enforced)
	my $east_attempt = $j_rls->selectall_arrayref(region => 'East');
	is(scalar @{$east_attempt}, 0, 'S6.1: mandatory_filters: East query returns 0 rows');

	# S6.2: querying for West rows within mandatory filter returns matching rows
	my $west_query = $j_rls->selectall_arrayref(region => 'West');
	is(scalar @{$west_query}, 3, 'S6.2: West query within mandatory filter: 3 rows');

	# S6.3: even with no caller criteria, mandatory filter always applies
	my $all = $j_rls->selectall_arrayref();
	is(scalar @{$all}, 3, 'S6.3: unconditional query still only returns 3 West rows');
}

# ---------------------------------------------------------------------------
# S7: combined distinct + mandatory_filters
# ---------------------------------------------------------------------------

{
	my $j = Database::Join->new(
		databases         => [$left, $right],
		join_column       => 'entry',
		backend           => 'array',
		mandatory_filters => [{ col => 'region', op => 'eq', val => 'West' }],
	);

	# S7.1: distinct tiers from West rows: gold, silver, bronze (3)
	my $rows = $j->selectall_arrayref(distinct => 1, columns => ['tier']);
	is(scalar @{$rows}, 3, 'S7.1: distinct tiers from West rows: 3');
	my @tiers = sort map { $_->{tier} } @{$rows};
	is_deeply(\@tiers, [qw(bronze gold silver)], 'S7.1: West tier values correct');

	# S7.2: distinct regions from West-only view: only West
	my $rrows = $j->selectall_arrayref(distinct => 1, columns => ['region']);
	is(scalar @{$rrows}, 1, 'S7.2: distinct regions from West-only view: 1');
	is($rrows->[0]{region}, 'West', 'S7.2: region is West');
}
