#!/usr/bin/env perl
use strict;
use warnings;

# Redis backend tests for Database::Join.
#
# Tests a join between a Redis-backed Database::Abstraction subclass (dj_rA)
# and a static in-memory DA (InlineDA) with no real Redis server needed.
# Redis is mocked via Test::Mockingbird's mock_scoped.
#
# Pre-load Redis before any mock so lazy require in DA's _open() is a no-op.
BEGIN {
	eval { require Redis::Fast } or eval { require Redis };
}

use Test::Most;
use Test::Mockingbird;
use Test::Returns;

# Skip the whole file if neither Redis::Fast nor Redis is installed.
BEGIN {
	my $have_redis = (defined $INC{'Redis/Fast.pm'} || defined $INC{'Redis.pm'})
		|| eval { require Redis; 1 };
	plan skip_all => 'Redis or Redis::Fast required' unless $have_redis;
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
	eval { require Database::Join };
	plan skip_all => 'Database::Join required' if $@;
}

plan tests => 13;

# ---------------------------------------------------------------------------
# DA stub: table name derived from class => dj_rA (columns: entry/name/score)
# ---------------------------------------------------------------------------
{ package Database::dj_rA; use base 'Database::Abstraction' }

use Readonly;
Readonly my $REDIS_URL => 'redis://localhost:6379';

# Fixture for the Redis-backed DA: entry => { name => ..., score => ... }
my %REDIS_FIXTURE = (
	row1 => { name => 'Alice', score => '10' },
	row2 => { name => 'Bob',   score => '20' },
	row3 => { name => 'Carol', score => '30' },
	row4 => { name => 'Dave',  score => '40' },
);

# Fixture for the in-memory DA: covers row1-row3 only (row4 absent → left join gap)
my @INLINE_ROWS = (
	{ entry => 'row1', tier => 'gold',   region => 'east'  },
	{ entry => 'row2', tier => 'silver', region => 'west'  },
	{ entry => 'row3', tier => 'bronze', region => 'north' },
);

# ---------------------------------------------------------------------------
# MockRedis — implements the subset of Redis API used by DA's _open()
# ---------------------------------------------------------------------------
{
	package MockRedis;

	sub new {
		my ($class, %opts) = @_;
		return bless {
			_table        => $opts{_table} // 'dj_rA',
			_data         => $opts{_data}  // {},
			_select_calls => 0,
			_auth_calls   => 0,
			_quit_calls   => 0,
		}, $class;
	}

	sub auth   { my $self = shift; $self->{_auth_calls}++;  return 'OK' }
	sub quit   { my $self = shift; $self->{_quit_calls}++;  return 'OK' }
	sub select { my ($self, $idx) = @_; $self->{_select_calls}++; return 'OK' }

	sub keys {
		my ($self, $pattern) = @_;
		my $table = $self->{_table};
		(my $prefix = $pattern) =~ s/\*\z//;
		return grep { /\A\Q$prefix\E/ }
			map { "${table}:$_" } sort CORE::keys %{ $self->{_data} };
	}

	sub hgetall {
		my ($self, $key) = @_;
		my $table = $self->{_table};
		(my $entry = $key) =~ s/\A\Q${table}\E://;
		my $row = $self->{_data}{$entry} or return ();
		return %{$row};
	}
}

# Determine which Redis class DA's _open() will actually use
my $REDIS_CLASS = defined $INC{'Redis/Fast.pm'} ? 'Redis::Fast' : 'Redis';

# Helper: return a fresh MockRedis and a mock_scoped guard
sub _mock_redis {
	my (%opts) = @_;
	my $mock = MockRedis->new(
		_table => $opts{table} // 'dj_rA',
		_data  => $opts{data}  // \%REDIS_FIXTURE,
	);
	my $guard = mock_scoped($REDIS_CLASS, new => sub { $mock });
	return ($mock, $guard);
}

# ---------------------------------------------------------------------------
# InlineDA — minimal blessed stub for the non-Redis side of the join.
# Must implement columns(), selectall_arrayref(), schema(), updated(),
# set_logger() to satisfy Database::Join's component contract.
# ---------------------------------------------------------------------------
{
	package InlineDA;

	sub new {
		my ($class, %args) = @_;
		return bless {
			_cols => $args{cols} // [],
			_rows => $args{rows} // [],
		}, $class;
	}

	sub columns { return $_[0]->{_cols} }
	sub schema  { return {} }
	sub updated { return 1 }
	sub set_logger { return $_[0] }

	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		my @rows = @{ $self->{_rows} };
		for my $col (CORE::keys %{ $criteria // {} }) {
			my $val = $criteria->{$col};
			next if ref $val;
			@rows = grep { defined $_->{$col} && $_->{$col} eq $val } @rows;
		}
		return \@rows;
	}
}

# Build a fresh InlineDA with the standard fixture columns
sub _inline_da {
	return InlineDA->new(
		cols => [qw(entry tier region)],
		rows => [@INLINE_ROWS],
	);
}

# ---------------------------------------------------------------------------
# Section 1 — constructor
# ---------------------------------------------------------------------------
subtest 'R1: Database::Join accepts a Redis-backed DA' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	lives_ok {
		Database::Join->new(
			databases    => [$redis_da, _inline_da()],
			join_column  => 'entry',
		);
	} 'new() with Redis DA lives';
};

# ---------------------------------------------------------------------------
# Section 2 — columns() and schema()
# ---------------------------------------------------------------------------
subtest 'R2: columns() returns merged columns from both DAs' => sub {
	plan tests => 3;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	$redis_da->count();    # trigger Redis _open() while guard is active
	my $join = Database::Join->new(
		databases   => [$redis_da, _inline_da()],
		join_column => 'entry',
	);
	my $cols = $join->columns();
	returns_is($cols, { type => 'arrayref' }, 'columns() returns arrayref');
	my %col_set = map { $_ => 1 } @{$cols};
	ok($col_set{name},   'columns() includes Redis column name');
	ok($col_set{tier},   'columns() includes InlineDA column tier');
};

# ---------------------------------------------------------------------------
# Section 3 — count()
# ---------------------------------------------------------------------------
subtest 'R3: count() == 4 for left join (primary is Redis, 4 Redis rows)' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_da, _inline_da()],
		join_column => 'entry',
	);
	cmp_ok($join->count(), '==', 4, 'count() == 4 for left join');
};

subtest 'R4: count() == 3 for inner join (intersection of Redis and InlineDA keys)' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_da, _inline_da()],
		join_column => 'entry',
		join_type   => 'inner',
	);
	cmp_ok($join->count(), '==', 3, 'count() == 3 for inner join');
};

# ---------------------------------------------------------------------------
# Section 4 — selectall_arrayref
# ---------------------------------------------------------------------------
subtest 'R5: selectall_arrayref() returns all rows for left join' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_da, _inline_da()],
		join_column => 'entry',
	);
	returns_is($join->selectall_arrayref(), { type => 'arrayref', min => 4, max => 4 },
		'selectall_arrayref() returns 4-row arrayref');
};

subtest 'R6: selectall_arrayref(entry) returns correct merged row' => sub {
	plan tests => 4;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_da, _inline_da()],
		join_column => 'entry',
	);
	my $rows = $join->selectall_arrayref(entry => 'row1');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'one row for entry=row1');
	is($rows->[0]{entry},  'row1',  'entry field correct');
	is($rows->[0]{name},   'Alice', 'name from Redis correct');
	is($rows->[0]{tier},   'gold',  'tier from InlineDA correct');
};

subtest 'R7: left join — Redis-only row has undef for InlineDA columns' => sub {
	plan tests => 2;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_da, _inline_da()],
		join_column => 'entry',
	);
	my $rows = $join->selectall_arrayref(entry => 'row4');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'row4 present in left join');
	ok(!defined $rows->[0]{tier}, 'tier undef for Redis-only row4');
};

subtest 'R8: inner join returns only rows present in both DAs' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_da, _inline_da()],
		join_column => 'entry',
		join_type   => 'inner',
	);
	returns_is($join->selectall_arrayref(), { type => 'arrayref', min => 3, max => 3 },
		'inner join returns 3-row arrayref');
};

subtest 'R9: outer join returns all rows from both DAs' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_da, _inline_da()],
		join_column => 'entry',
		join_type   => 'outer',
	);
	# InlineDA only has row1-row3, Redis has row1-row4; outer gives row1-row4
	returns_is($join->selectall_arrayref(), { type => 'arrayref', min => 4, max => 4 },
		'outer join returns 4-row arrayref');
};

# ---------------------------------------------------------------------------
# Section 5 — criteria routing
# ---------------------------------------------------------------------------
subtest 'R10: criteria on Redis column routed to Redis DA' => sub {
	plan tests => 2;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_da, _inline_da()],
		join_column => 'entry',
	);
	my $rows = $join->selectall_arrayref(name => 'Alice');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 },
		'name=Alice returns 1 row');
	is($rows->[0]{name}, 'Alice', 'correct row returned for Redis column criterion');
};

subtest 'R11: criteria on InlineDA column routed to InlineDA' => sub {
	plan tests => 2;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_da, _inline_da()],
		join_column => 'entry',
	);
	my $rows = $join->selectall_arrayref(tier => 'gold');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 },
		'tier=gold returns 1 row');
	is($rows->[0]{tier}, 'gold', 'correct row returned for InlineDA column criterion');
};

# ---------------------------------------------------------------------------
# Section 6 — fetchrow_hashref
# ---------------------------------------------------------------------------
subtest 'R12: fetchrow_hashref() returns merged row from Redis + InlineDA' => sub {
	plan tests => 3;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_da, _inline_da()],
		join_column => 'entry',
	);
	my $row = $join->fetchrow_hashref('row2');
	returns_is($row, { type => 'hashref' }, 'fetchrow_hashref returns hashref');
	is($row->{name},  'Bob',    'name from Redis');
	is($row->{tier},  'silver', 'tier from InlineDA');
};

# ---------------------------------------------------------------------------
# Section 7 — set_logger propagation
# ---------------------------------------------------------------------------
subtest 'R13: set_logger propagated to Redis DA without error' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $redis_da = Database::dj_rA->new(database => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_da, _inline_da()],
		join_column => 'entry',
	);
	lives_ok { $join->set_logger('debug') } 'set_logger lives with Redis DA';
};
