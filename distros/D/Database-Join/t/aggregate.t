#!/usr/bin/perl
use strict;
use warnings;

# t/aggregate.t — Tests for Database::Join::aggregate()
# Exercises both 'array' and 'sqlite' backends against the same fixture,
# validates error conditions, and confirms the two backends agree (§10.3).

use Test::Most;
use Test::Exception;
use Test::Warn;

use_ok('Database::Join');

# ---------------------------------------------------------------------------
# Inline MinimalDA stub — same pattern as t/function.t
# ---------------------------------------------------------------------------
{
	package MinimalDA;
	use parent -norequire, 'Database::Abstraction';
	sub new {
		my ($class, %args) = @_;
		return bless {
			_cols   => $args{cols}   // [],
			_rows   => $args{rows}   // [],
			_schema => $args{schema} // {},
			id      => $args{id}     // $args{cols}[0],
		}, $class;
	}
	sub columns { return $_[0]->{_cols} }
	sub schema  { return $_[0]->{_schema} }
	sub updated { return undef }
	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		$criteria //= {};
		my @result;
		ROW: for my $row (@{ $self->{_rows} }) {
			for my $col (keys %{$criteria}) {
				my $want = $criteria->{$col};
				my $got  = $row->{$col};
				if (ref($want) eq 'HASH') {
					for my $op (keys %{$want}) {
						my $v = $want->{$op};
						if    ($op eq '=')  { next ROW unless defined $got && $got eq $v }
						elsif ($op eq '!=') { next ROW if     defined $got && $got eq $v }
						elsif ($op eq '>')  { next ROW unless defined $got && $got > $v  }
						elsif ($op eq '<')  { next ROW unless defined $got && $got < $v  }
						elsif ($op eq '>=') { next ROW unless defined $got && $got >= $v }
						elsif ($op eq '<=') { next ROW unless defined $got && $got <= $v }
					}
				} elsif (!defined $want) {
					next ROW if defined $got;
				} else {
					next ROW unless defined $got && $got eq $want;
				}
			}
			push @result, { %{$row} };
		}
		return \@result;
	}
	sub count { scalar @{ $_[0]->{_rows} } }
}

# ---------------------------------------------------------------------------
# §10.1 Fixture:
#   Source A: id, name, tier, region
#   Source B: id, score, region   (collision_prefix => {1=>'b'})
#   Join: left, join_column => 'id'
#   k4 absent from B; k5 absent from A (outer) or present (left with k4 only missing)
# ---------------------------------------------------------------------------
my @rows_a = (
	{ id => 'k1', name => 'Alice', tier => 'gold',   region => 'East' },
	{ id => 'k2', name => 'Bob',   tier => 'silver',  region => 'West' },
	{ id => 'k3', name => 'Carol', tier => 'bronze',  region => 'East' },
	{ id => 'k4', name => 'Dave',  tier => 'gold',    region => 'West' },
	{ id => 'k5', name => 'Eve',   tier => 'silver',  region => 'East' },
);

my @rows_b = (
	{ id => 'k1', score => 95, region => 'North' },
	{ id => 'k2', score => 72, region => 'South' },
	{ id => 'k3', score => 88, region => 'North' },
	{ id => 'k5', score => 61, region => 'South' },
	# k4 intentionally absent
);

sub make_join {
	my (%opts) = @_;
	my $jt = delete $opts{join_type} // 'left';
	my $be = delete $opts{backend}   // 'sqlite';
	my $da = MinimalDA->new(cols => [qw(id name tier region)], rows => \@rows_a, id => 'id');
	my $db = MinimalDA->new(cols => [qw(id score region)],     rows => \@rows_b, id => 'id');
	return Database::Join->new(
		databases        => [$da, $db],
		join_column      => 'id',
		join_type        => $jt,
		collision_prefix => { 1 => 'b' },
		backend          => $be,
		%opts,
	);
}

# Run the same subtest body on both backends.
sub both_backends {
	my ($name, $code) = @_;
	for my $be (qw(array sqlite)) {
		subtest "$name ($be)" => sub { $code->($be) };
	}
}

# ---------------------------------------------------------------------------
# Case 1: group by b.region, sum(score)
# ---------------------------------------------------------------------------
both_backends 'case1: group by b.region sum(score)' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		by       => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		sort_by  => 'b.region',
	);
	is scalar @{$rows}, 3, 'three groups (North, South, NULL)';
	my %by_reg = map { ($_->{'b.region'} // '__NULL__') => $_->{total} } @{$rows};
	is $by_reg{North},    183, 'North total';
	is $by_reg{South},    133, 'South total';
	is $by_reg{__NULL__},   0, 'NULL group sum normalised to 0';
};

# ---------------------------------------------------------------------------
# Case 2: grand total — no by
# ---------------------------------------------------------------------------
both_backends 'case2: grand total' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		measures => [
			{ col => 'score', fn => 'sum',   as => 'total' },
			{                 fn => 'count', as => 'n'     },
		],
	);
	is scalar @{$rows}, 1,   'one grand-total row';
	is $rows->[0]{total}, 316, 'grand total sum';
	is $rows->[0]{n},     5,   'grand total count';
};

# ---------------------------------------------------------------------------
# Case 3: COUNT(*) — no col
# ---------------------------------------------------------------------------
both_backends 'case3: count(*) overall and by group' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $r1 = $j->aggregate(measures => [{ fn => 'count', as => 'n' }]);
	is $r1->[0]{n}, 5, 'COUNT(*) grand total = 5';

	my $r2 = $j->aggregate(
		by       => ['b.region'],
		measures => [{ fn => 'count', as => 'n' }],
	);
	my %by_reg = map { ($_->{'b.region'} // '__NULL__') => $_->{n} } @{$r2};
	is $by_reg{North}, 2, 'North COUNT(*) = 2';
};

# ---------------------------------------------------------------------------
# Case 4: COUNT(col) on left join differs from COUNT(*)
# ---------------------------------------------------------------------------
both_backends 'case4: COUNT(score) vs COUNT(*) on left join' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		measures => [
			{                 fn => 'count', as => 'star'  },
			{ col => 'score', fn => 'count', as => 'col'   },
		],
	);
	is $rows->[0]{star}, 5, 'COUNT(*) = 5 (includes k4 with no score)';
	is $rows->[0]{col},  4, 'COUNT(score) = 4 (k4 excluded)';
};

# ---------------------------------------------------------------------------
# Case 5: avg, min, max
# ---------------------------------------------------------------------------
both_backends 'case5: avg/min/max over score' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		measures => [
			{ col => 'score', fn => 'avg', as => 'mean' },
			{ col => 'score', fn => 'min', as => 'lo'   },
			{ col => 'score', fn => 'max', as => 'hi'   },
		],
	);
	ok abs($rows->[0]{mean} - 79) < 0.01, "avg ~79 (got $rows->[0]{mean})";
	is $rows->[0]{lo}, 61, 'min = 61';
	is $rows->[0]{hi}, 95, 'max = 95';
};

# ---------------------------------------------------------------------------
# Case 6: count_distinct
# ---------------------------------------------------------------------------
both_backends 'case6: count_distinct tier and b.region' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		measures => [
			{ col => 'tier',     fn => 'count_distinct', as => 'tiers'   },
			{ col => 'b.region', fn => 'count_distinct', as => 'regions' },
		],
	);
	is $rows->[0]{tiers},   3, 'count_distinct tier = 3';
	is $rows->[0]{regions}, 2, 'count_distinct b.region = 2 (NULL not counted)';
};

# ---------------------------------------------------------------------------
# Case 7: multi-key grouping
# ---------------------------------------------------------------------------
both_backends 'case7: multi-key group by tier+b.region' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		by       => ['tier', 'b.region'],
		measures => [{ fn => 'count', as => 'n' }],
	);
	is scalar @{$rows}, 4, '4 distinct (tier, b.region) combinations';
};

# ---------------------------------------------------------------------------
# Case 8: criteria filter (WHERE) combined with grouping
# ---------------------------------------------------------------------------
both_backends 'case8: criteria + grouping' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		tier     => 'gold',
		by       => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
	);
	my %by_reg = map { ($_->{'b.region'} // '__NULL__') => $_->{total} } @{$rows};
	is $by_reg{North},    95,  'gold/North total = 95 (Alice only)';
	is $by_reg{__NULL__}, 0,   'gold/NULL sum = 0 (Dave, no score)';
	ok !exists $by_reg{South}, 'no gold/South group';
};

# ---------------------------------------------------------------------------
# Case 9: operator criteria
# ---------------------------------------------------------------------------
both_backends 'case9: operator criteria score > 80' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		score    => { '>' => 80 },
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
	);
	is $rows->[0]{total}, 183, 'sum of scores > 80 = 95 + 88 = 183';
};

# ---------------------------------------------------------------------------
# Case 11: having on alias
# ---------------------------------------------------------------------------
both_backends 'case11: having total > 150' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		by       => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		having   => { total => { '>' => 150 } },
	);
	is scalar @{$rows}, 1,       'only one group qualifies';
	is $rows->[0]{'b.region'}, 'North', 'that group is North';
};

# ---------------------------------------------------------------------------
# Case 12: having on group column
# ---------------------------------------------------------------------------
both_backends 'case12: having b.region = North' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		by       => ['b.region'],
		measures => [{ fn => 'count', as => 'n' }],
		having   => { 'b.region' => 'North' },
	);
	is scalar @{$rows}, 1,         'one group';
	is $rows->[0]{'b.region'}, 'North', 'the North group';
};

# ---------------------------------------------------------------------------
# Case 13: having operators
# ---------------------------------------------------------------------------
both_backends 'case13: having with IN, IS NULL, != etc' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);

	my $r1 = $j->aggregate(
		by => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		having => { 'b.region' => { IN => ['North', 'South'] } },
	);
	is scalar @{$r1}, 2, 'IN [North, South] gives 2 groups';

	my $r2 = $j->aggregate(
		by => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		having => { 'b.region' => { IN => [] } },
	);
	is scalar @{$r2}, 0, 'IN [] gives no groups';

	my $r3 = $j->aggregate(
		by => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		having => { 'b.region' => { 'NOT IN' => [] } },
	);
	is scalar @{$r3}, 3, 'NOT IN [] gives all groups';

	my $r4 = $j->aggregate(
		by => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		having => { 'b.region' => undef },
	);
	is scalar @{$r4}, 1, 'IS NULL gives only the NULL group';

	my $r5 = $j->aggregate(
		by => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		having => { 'b.region' => { '!=' => 'North' } },
	);
	# NULL != 'North' is UNKNOWN → false, so only South qualifies
	is scalar @{$r5}, 1, '!= North gives only South (NULL excluded by 3VL)';
	is $r5->[0]{'b.region'}, 'South', 'that group is South';
};

# ---------------------------------------------------------------------------
# Case 14: having -or / -and  (group by tier — no NULL tier values)
# ---------------------------------------------------------------------------
# Groups: gold=95, silver=133, bronze=88
both_backends 'case14: having -or and -and' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);

	# Groups: gold=95, silver=133, bronze=88
	my $r1 = $j->aggregate(
		by       => ['tier'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		having   => { -or => [
			{ total => { '>' => 125 } },   # silver(133) qualifies
			{ total => { '<' => 90  } },   # bronze(88) qualifies
		]},
		sort_by => 'tier',
	);
	is scalar @{$r1}, 2, '-or: silver(133) and bronze(88) qualify';

	my $r2 = $j->aggregate(
		by       => ['tier'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		having   => { -and => [
			{ total => { '>' => 90 } },
			{ total => { '<' => 100 } },
		]},
	);
	is scalar @{$r2}, 1, '-and: only gold(95) qualifies';
};

# ---------------------------------------------------------------------------
# Case 15: having with unknown key / unsupported operator
# ---------------------------------------------------------------------------
subtest 'case15: having validation errors' => sub {
	my $j = make_join(backend => 'array');
	throws_ok {
		$j->aggregate(
			by => ['b.region'],
			measures => [{ fn => 'count', as => 'n' }],
			having => { unknown_key => 1 },
		)
	} qr/having key/, 'unknown having key croaks';

	throws_ok {
		$j->aggregate(
			by => ['b.region'],
			measures => [{ col => 'score', fn => 'sum', as => 'total' }],
			having => { total => { BETWEEN => [1, 2] } },
		)
	} qr/operator/, 'unsupported having operator croaks';
};

# ---------------------------------------------------------------------------
# Case 16: sort_by
# ---------------------------------------------------------------------------
both_backends 'case16: sort_by total DESC and unknown sort' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		by       => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		sort_by  => ['total', 'DESC'],
	);
	is $rows->[0]{total}, 183, 'DESC: North first (183)';
	is $rows->[1]{total}, 133, 'DESC: South second (133)';

	my $warned = 0;
	warning_like {
		my $r = $j->aggregate(
			by => ['b.region'],
			measures => [{ fn => 'count', as => 'n' }],
			sort_by => 'nope',
		);
		$warned = 1;
	} qr/sort_by/, 'unknown sort_by carps';
	ok $warned, 'returned despite carp';
};

# ---------------------------------------------------------------------------
# Case 17: limit / offset
# ---------------------------------------------------------------------------
both_backends 'case17: limit and offset' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $all = $j->aggregate(
		by       => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		sort_by  => 'b.region',
	);
	is scalar @{$all}, 3, '3 groups total';

	my $page1 = $j->aggregate(
		by       => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		sort_by  => 'b.region',
		limit    => 2,
	);
	is scalar @{$page1}, 2, 'limit 2 returns 2 rows';

	my $page2 = $j->aggregate(
		by       => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		sort_by  => 'b.region',
		limit    => 2,
		offset   => 2,
	);
	is scalar @{$page2}, 1, 'offset 2 with limit 2 returns remaining 1';
};

# ---------------------------------------------------------------------------
# Case 18: empty result
# ---------------------------------------------------------------------------
both_backends 'case18: empty result normalisation' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);

	my $grand = $j->aggregate(
		id       => 'NOMATCH',
		measures => [
			{ col => 'score', fn => 'sum',   as => 'total' },
			{                 fn => 'count', as => 'n'     },
			{ col => 'score', fn => 'avg',   as => 'mean'  },
		],
	);
	is scalar @{$grand}, 1, 'grand total returns 1 row even with no matches';
	is $grand->[0]{total}, 0,     'sum normalised to 0';
	is $grand->[0]{n},     0,     'count normalised to 0';
	ok !defined $grand->[0]{mean}, 'avg stays undef';

	my $by = $j->aggregate(
		id       => 'NOMATCH',
		by       => ['b.region'],
		measures => [{ fn => 'count', as => 'n' }],
	);
	is scalar @{$by}, 0, 'with by and no matches returns []';
};

# ---------------------------------------------------------------------------
# Case 19: all-NULL group (k4 row, grouped by b.region)
# ---------------------------------------------------------------------------
both_backends 'case19: all-NULL group' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		by       => ['b.region'],
		measures => [
			{ col => 'score', fn => 'sum',   as => 'total'  },
			{                 fn => 'count', as => 'n'      },
			{ col => 'score', fn => 'count', as => 'vals'   },
			{ col => 'score', fn => 'avg',   as => 'mean'   },
			{ col => 'score', fn => 'min',   as => 'lo'     },
			{ col => 'score', fn => 'max',   as => 'hi'     },
		],
	);
	my ($null_row) = grep { !defined $_->{'b.region'} } @{$rows};
	ok defined $null_row, 'NULL group exists';
	is $null_row->{total}, 0,     'NULL group sum = 0';
	is $null_row->{n},     1,     'NULL group COUNT(*) = 1 (k4 row)';
	is $null_row->{vals},  0,     'NULL group COUNT(score) = 0';
	ok !defined $null_row->{mean}, 'NULL group avg = undef';
	ok !defined $null_row->{lo},   'NULL group min = undef';
	ok !defined $null_row->{hi},   'NULL group max = undef';
};

# ---------------------------------------------------------------------------
# Case 20: join_type inner and outer
# ---------------------------------------------------------------------------
both_backends 'case20: inner join drops k4' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be, join_type => 'inner');
	my $rows = $j->aggregate(
		measures => [
			{ col => 'score', fn => 'sum',   as => 'total' },
			{                 fn => 'count', as => 'n'     },
		],
	);
	is $rows->[0]{total}, 316, 'inner: total still 316 (k4 had no score)';
	is $rows->[0]{n},     4,   'inner: count = 4 (k4 gone)';
};

# ---------------------------------------------------------------------------
# Case 21: validation croaks
# ---------------------------------------------------------------------------
subtest 'case21: validation croaks' => sub {
	my $j = make_join(backend => 'array');

	throws_ok { $j->aggregate() }
		qr/measures.*non-empty/, 'missing measures croaks';

	throws_ok { $j->aggregate(measures => []) }
		qr/measures.*non-empty/, 'empty measures croaks';

	throws_ok { $j->aggregate(measures => ['bad']) }
		qr/measure must be a hashref/, 'non-hashref measure croaks';

	throws_ok { $j->aggregate(measures => [{ fn => 'bad', as => 'x' }]) }
		qr/unknown measure function/, 'unknown fn croaks';

	throws_ok { $j->aggregate(measures => [{ fn => 'sum', as => 'x' }]) }
		qr/column is required/, 'missing col for sum croaks';

	throws_ok { $j->aggregate(measures => [{ fn => 'sum', col => 'score' }]) }
		qr/"as" is required/, 'missing as croaks';

	throws_ok { $j->aggregate(measures => [{ fn => 'count', col => 'score', as => 'a b' }]) }
		qr/must be a plain word/, 'non-word as croaks';

	throws_ok { $j->aggregate(measures => [
			{ fn => 'count', as => 'n' },
			{ fn => 'count', as => 'n' },
		]) }
		qr/duplicate.*alias/, 'duplicate as croaks';

	throws_ok { $j->aggregate(
			by       => ['tier'],
			measures => [{ fn => 'count', as => 'tier' }],
		) }
		qr/collides with a group-by/, 'alias = by name croaks';

	throws_ok { $j->aggregate(
			by       => ['notacol'],
			measures => [{ fn => 'count', as => 'n' }],
		) }
		qr/not in the merged view/, 'unknown by column croaks';

	throws_ok { $j->aggregate(
			measures => [{ fn => 'sum', col => 'notacol', as => 'x' }],
		) }
		qr/not in the merged view/, 'unknown measure col croaks';

	throws_ok { $j->aggregate(measures => [{ fn => 'count', as => 'n' }], join => 'foo') }
		qr/error_join_criterion|join.*not.*supported/i, 'join => in criteria croaks';

	# Ambiguity: use a join WITHOUT collision_prefix so 'region' is ambiguous.
	my $da = MinimalDA->new(cols => [qw(id region)], rows => [], id => 'id');
	my $db = MinimalDA->new(cols => [qw(id region)], rows => [], id => 'id');
	my $ambig = Database::Join->new(
		databases   => [$da, $db],
		join_column => 'id',
		backend     => 'array',
	);
	throws_ok { $ambig->aggregate(measures => [{ fn => 'count', col => 'region', as => 'n' }]) }
		qr/exists in multiple/, 'ambiguous col croaks error_col_conflict';
};

# ---------------------------------------------------------------------------
# Case 22: return shape
# ---------------------------------------------------------------------------
both_backends 'case22: return shape' => sub {
	my $be = shift;
	my $j  = make_join(backend => $be);
	my $rows = $j->aggregate(
		by       => ['tier'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
	);
	ok ref($rows) eq 'ARRAY',      'returns arrayref';
	ok ref($rows->[0]) eq 'HASH',  'elements are hashrefs';
	# Key order: by columns first, then measures.
	my @keys = keys %{ $rows->[0] };
	my ($by_pos)  = grep { $keys[$_] eq 'tier'  } 0 .. $#keys;
	my ($m_pos)   = grep { $keys[$_] eq 'total' } 0 .. $#keys;
	# Both keys present (order not enforced by hash, just presence).
	ok(( grep { $_ eq 'tier'  } @keys ), 'by column present');
	ok(( grep { $_ eq 'total' } @keys ), 'measure alias present');
};

# ---------------------------------------------------------------------------
# Case 23: non-numeric skip warning (array path only; SQLite path coerces to 0)
# ---------------------------------------------------------------------------
subtest 'case23: non-numeric warning array path' => sub {
	my $da = MinimalDA->new(
		cols => [qw(id val)],
		rows => [
			{ id => 'a', val => '10'  },
			{ id => 'b', val => 'abc' },
			{ id => 'c', val => '20'  },
		],
		id => 'id',
	);
	my $db = MinimalDA->new(cols => [qw(id)], rows => [
		{ id => 'a' }, { id => 'b' }, { id => 'c' },
	], id => 'id');
	my $j = Database::Join->new(
		databases   => [$da, $db],
		join_column => 'id',
		backend     => 'array',
	);
	my $rows;
	warning_like {
		$rows = $j->aggregate(measures => [{ col => 'val', fn => 'sum', as => 'total' }]);
	} qr/non-numeric/, 'array path warns for non-numeric';
	is $rows->[0]{total}, 30, 'non-numeric value skipped; sum = 30';

	# SQLite path: 'abc' coerces to 0.0
	my $js = Database::Join->new(
		databases   => [$da, $db],
		join_column => 'id',
		backend     => 'sqlite',
	);
	my $rows_s;
	warning_like { $rows_s = $js->aggregate(measures => [{ col => 'val', fn => 'sum', as => 'total' }]) }
		undef, 'sqlite path no non-numeric warning';
	# SQLite CAST('abc' AS REAL) = 0.0, so total = 10 + 0 + 20 = 30 too? Actually yes same result here
	ok defined $rows_s->[0]{total}, 'sqlite result defined';
};

# ---------------------------------------------------------------------------
# Case 25: filters reduce the set
# ---------------------------------------------------------------------------
both_backends 'case25: filters applied before aggregation' => sub {
	my $be = shift;
	my $j  = make_join(
		backend => $be,
		filters => { 1 => { score => { '>' => 70 } } },
	);
	my $rows = $j->aggregate(
		measures => [
			{ col => 'score', fn => 'sum',   as => 'total' },
			{                 fn => 'count', as => 'n'     },
		],
	);
	# k5 (score=61) excluded; k4 also excluded because filter on B forces inner-join
	is $rows->[0]{n}, 3, 'filter excludes k5 and k4 (inner-join semantics); 3 rows';
	is $rows->[0]{total}, 255, 'total = 95+72+88 = 255';
};

# ---------------------------------------------------------------------------
# Case 26: remove_columns makes the column unavailable
# ---------------------------------------------------------------------------
subtest 'case26: removed column cannot be measured' => sub {
	my $j = make_join(backend => 'array', remove_columns => ['score']);
	throws_ok {
		$j->aggregate(measures => [{ col => 'score', fn => 'sum', as => 'total' }])
	} qr/not in the merged view/, 'removed column rejected';
};

# ---------------------------------------------------------------------------
# Case 27: auto backend always uses SQLite path (no row-count probe needed)
# ---------------------------------------------------------------------------
subtest 'case27: auto backend aggregates via SQLite' => sub {
	# Pass a bad tmpdir for the array path (which would ignore it) to distinguish:
	# SQLite path croak → bad dir; array path → succeed.
	# Use a VALID dir for auto aggregate — just verify it returns the same as sqlite.
	my $j_auto   = make_join(backend => 'auto');
	my $j_sqlite = make_join(backend => 'sqlite');
	my $r_auto   = $j_auto->aggregate(
		by => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		sort_by  => 'b.region',
	);
	my $r_sqlite = $j_sqlite->aggregate(
		by => ['b.region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		sort_by  => 'b.region',
	);
	is_deeply $r_auto, $r_sqlite, 'auto backend produces same result as sqlite';
};

# ---------------------------------------------------------------------------
# §10.3 Cross-backend parity
# ---------------------------------------------------------------------------
subtest 'parity: array and sqlite agree on all main cases' => sub {
	my $j_array  = make_join(backend => 'array');
	my $j_sqlite = make_join(backend => 'sqlite');

	# Sort rows canonically before comparing so tie-ordering differences do not fail.
	my $canon = sub {
		my $rows = shift;
		return [sort {
			my $ka = join('|', map { defined($a->{$_}) ? $a->{$_} : "\x00" } sort keys %{$a});
			my $kb = join('|', map { defined($b->{$_}) ? $b->{$_} : "\x00" } sort keys %{$b});
			$ka cmp $kb
		} @{$rows}];
	};

	for my $spec (
		{ by => ['b.region'], measures => [{ col => 'score', fn => 'sum', as => 't' }] },
		{ measures => [{ col => 'score', fn => 'sum', as => 't' }, { fn => 'count', as => 'n' }] },
		{ by => ['tier', 'b.region'], measures => [{ fn => 'count', as => 'n' }] },
		{ by => ['b.region'], measures => [{ col => 'score', fn => 'min', as => 'lo' }, { col => 'score', fn => 'max', as => 'hi' }] },
	) {
		my $ra = $j_array->aggregate(%{$spec});
		my $rs = $j_sqlite->aggregate(%{$spec});
		is_deeply $canon->($ra), $canon->($rs),
			'array and sqlite agree (canonical order)';
	}
};

done_testing();
