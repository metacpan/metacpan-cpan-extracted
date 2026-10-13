#!/usr/bin/env perl
use strict;
use warnings;

# Live Redis integration tests for Database::Join.
#
# Tests a join between a Redis-backed Database::Abstraction subclass and an
# in-memory DA against a real Redis server.
#
# Only run when REDIS_SERVER is set to a reachable Redis instance:
#   REDIS_SERVER=redis://localhost:6379 prove -l t/redis_live.t
#
# All test keys live under a PID-unique prefix and are cleaned up in END,
# so the test is safe to run against a shared Redis instance.

use Test::Most;
use Test::Returns;

BEGIN {
	plan skip_all => 'REDIS_SERVER not set (e.g. REDIS_SERVER=redis://localhost:6379)'
		unless $ENV{REDIS_SERVER};
	eval { require Redis::Fast } or eval { require Redis };
	plan skip_all => 'Redis or Redis::Fast required'
		unless defined $INC{'Redis/Fast.pm'} || defined $INC{'Redis.pm'};
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
	eval { require Database::Join };
	plan skip_all => 'Database::Join required' if $@;
}

use Readonly;
use Scalar::Util qw(refaddr);

# ---------------------------------------------------------------------------
# Normalise the server URL
# ---------------------------------------------------------------------------
my $SERVER_URL = do {
	my $raw = $ENV{REDIS_SERVER};
	$raw =~ m{\Aredis://}i ? $raw : "redis://$raw";
};

# Determine which Redis class to use
my $REDIS_CLASS = defined $INC{'Redis/Fast.pm'} ? 'Redis::Fast' : 'Redis';

# Extract host/port/password from URL
my ($REDIS_HOST, $REDIS_PORT, $REDIS_PASS) = do {
	my ($userinfo, $h, $p);
	if($SERVER_URL =~ m{\Aredis://([^@]*)@([^/:]+)(?::(\d+))?}i) {
		($userinfo, $h, $p) = ($1, $2, $3);
	} else {
		($h, $p) = $SERVER_URL =~ m{\Aredis://([^/:]+)(?::(\d+))?}i;
	}
	my $pw;
	if(defined $userinfo && length $userinfo) {
		$pw = ($userinfo =~ /:(.*)/) ? $1 : $userinfo;
	}
	($h // 'localhost', $p // 6379, $pw);
};

# ---------------------------------------------------------------------------
# Connect — skip if unreachable
# ---------------------------------------------------------------------------
my $redis;
my $connect_err;
eval {
	$redis = $REDIS_CLASS->new(
		server      => "${REDIS_HOST}:${REDIS_PORT}",
		reconnect   => 0,
		cnx_timeout => 5,
	);
	$redis->auth($REDIS_PASS) if defined $REDIS_PASS && length $REDIS_PASS;
};
$connect_err = "$@" if $@;

plan skip_all => "Cannot connect to Redis at $SERVER_URL: $connect_err"
	if $connect_err;

# ---------------------------------------------------------------------------
# PID-unique table prefix to avoid collisions on shared servers
# ---------------------------------------------------------------------------
Readonly my $PREFIX => sprintf 'djlive_%d', $$;
Readonly my $TABLE  => "${PREFIX}_redis";

# ---------------------------------------------------------------------------
# Inline test subclass — class name derives the table name via ref($self)
# ---------------------------------------------------------------------------
{
	no strict 'refs';
	@{"Database::${TABLE}::ISA"} = ('Database::Abstraction');
}

# ---------------------------------------------------------------------------
# Fixture data for the Redis-backed DA
# ---------------------------------------------------------------------------
my %REDIS_FIXTURE = (
	row1 => { name => 'Alice', score => '10' },
	row2 => { name => 'Bob',   score => '20' },
	row3 => { name => 'Carol', score => '30' },
	row4 => { name => 'Dave',  score => '40' },
);

for my $entry (keys %REDIS_FIXTURE) {
	$redis->del("${TABLE}:${entry}");
	$redis->hset("${TABLE}:${entry}", %{ $REDIS_FIXTURE{$entry} });
}

# ---------------------------------------------------------------------------
# Fixture data for the in-memory (non-Redis) DA
# InlineDA covers row1-row3; row4 is absent (left join fills with undef)
# ---------------------------------------------------------------------------
my @INLINE_ROWS = (
	{ entry => 'row1', tier => 'gold',   region => 'east'  },
	{ entry => 'row2', tier => 'silver', region => 'west'  },
	{ entry => 'row3', tier => 'bronze', region => 'north' },
);

# ---------------------------------------------------------------------------
# InlineDA — minimal blessed stub for the non-Redis side
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

sub _inline_da {
	return InlineDA->new(
		cols => [qw(entry tier region)],
		rows => [@INLINE_ROWS],
	);
}

# ---------------------------------------------------------------------------
# Clean up all test keys from Redis when done
# ---------------------------------------------------------------------------
END {
	if($redis) {
		eval {
			$redis->del($_) for $redis->keys("${TABLE}:*");
		};
	}
}

# ---------------------------------------------------------------------------
# Test plan
# ---------------------------------------------------------------------------
plan tests => 14;

# Helpers
sub _redis_da {
	return "Database::${TABLE}"->new(database => $SERVER_URL);
}

sub _join {
	my (%extra) = @_;
	return Database::Join->new(
		databases   => [_redis_da(), _inline_da()],
		join_column => 'entry',
		%extra,
	);
}

# ---------------------------------------------------------------------------
# Section 1 — connection and type
# ---------------------------------------------------------------------------
subtest 'L1: new() with Redis-backed DA connects successfully' => sub {
	plan tests => 2;
	my $join;
	lives_ok { $join = _join() } 'new() lives';
	cmp_ok($join->count(), '>=', 1, 'count() >= 1 after connecting');
};

# ---------------------------------------------------------------------------
# Section 2 — columns()
# ---------------------------------------------------------------------------
subtest 'L2: columns() returns merged columns from both DAs' => sub {
	plan tests => 3;
	my $join = _join();
	my $cols = $join->columns();
	returns_is($cols, { type => 'arrayref' }, 'columns() returns arrayref');
	my %col_set = map { $_ => 1 } @{$cols};
	ok($col_set{name},   'Redis column name in merged columns()');
	ok($col_set{tier},   'InlineDA column tier in merged columns()');
};

# ---------------------------------------------------------------------------
# Section 3 — count()
# ---------------------------------------------------------------------------
subtest 'L3: count() correct for left join (4 Redis rows)' => sub {
	plan tests => 1;
	cmp_ok(_join()->count(), '==', 4, 'count() == 4 for left join');
};

subtest 'L4: count() correct for inner join (3 shared rows)' => sub {
	plan tests => 1;
	cmp_ok(_join(join_type => 'inner')->count(), '==', 3, 'count() == 3 for inner join');
};

# ---------------------------------------------------------------------------
# Section 4 — selectall_arrayref
# ---------------------------------------------------------------------------
subtest 'L5: selectall_arrayref() returns all rows for left join' => sub {
	plan tests => 1;
	returns_is(_join()->selectall_arrayref(), { type => 'arrayref', min => 4, max => 4 },
		'selectall_arrayref() returns 4-row arrayref');
};

subtest 'L6: selectall_arrayref(entry) returns correct merged row' => sub {
	plan tests => 4;
	my $rows = _join()->selectall_arrayref(entry => 'row1');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'one row for entry=row1');
	is($rows->[0]{entry},  'row1',  'entry correct');
	is($rows->[0]{name},   'Alice', 'name from Redis DA');
	is($rows->[0]{tier},   'gold',  'tier from InlineDA');
};

subtest 'L7: left join — Redis-only row has undef for InlineDA columns' => sub {
	plan tests => 2;
	my $rows = _join()->selectall_arrayref(entry => 'row4');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'row4 present in left join');
	ok(!defined $rows->[0]{tier}, 'tier undef for Redis-only row4');
};

subtest 'L8: inner join returns only rows present in both DAs' => sub {
	plan tests => 1;
	returns_is(_join(join_type => 'inner')->selectall_arrayref(),
		{ type => 'arrayref', min => 3, max => 3 },
		'inner join returns 3-row arrayref');
};

# ---------------------------------------------------------------------------
# Section 5 — criteria routing
# ---------------------------------------------------------------------------
subtest 'L9: criteria on Redis column (name) routed to Redis DA' => sub {
	plan tests => 2;
	my $rows = _join()->selectall_arrayref(name => 'Alice');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'name=Alice returns 1 row');
	is($rows->[0]{name}, 'Alice', 'correct row returned');
};

subtest 'L10: criteria on InlineDA column (tier) routed to InlineDA' => sub {
	plan tests => 2;
	my $rows = _join()->selectall_arrayref(tier => 'gold');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'tier=gold returns 1 row');
	is($rows->[0]{tier}, 'gold', 'correct row returned');
};

# ---------------------------------------------------------------------------
# Section 6 — fetchrow_hashref
# ---------------------------------------------------------------------------
subtest 'L11: fetchrow_hashref() returns merged row' => sub {
	plan tests => 3;
	my $row = _join()->fetchrow_hashref('row2');
	returns_is($row, { type => 'hashref' }, 'fetchrow_hashref returns hashref');
	is($row->{name},  'Bob',    'name from Redis DA');
	is($row->{tier},  'silver', 'tier from InlineDA');
};

# ---------------------------------------------------------------------------
# Section 7 — sort_by and limit
# ---------------------------------------------------------------------------
subtest 'L12: selectall_arrayref(sort_by => name) returns rows in name order' => sub {
	plan tests => 1;
	my $rows = _join(join_type => 'inner')->selectall_arrayref(sort_by => 'name');
	my @names = map { $_->{name} } @{$rows};
	is_deeply(\@names, [sort @names], 'rows sorted by name ascending');
};

subtest 'L13: selectall_arrayref(limit => 2) returns at most 2 rows' => sub {
	plan tests => 1;
	returns_is(_join()->selectall_arrayref(sort_by => 'entry', limit => 2),
		{ type => 'arrayref', min => 2, max => 2 },
		'limit => 2 returns 2-row arrayref');
};

# ---------------------------------------------------------------------------
# Section 8 — idempotency and isolation
# ---------------------------------------------------------------------------
subtest 'L14: two independent join objects have independent data refs' => sub {
	plan tests => 3;
	my $j1 = _join();
	my $j2 = _join();
	cmp_ok($j1->count(), '==', 4, 'j1 count() == 4');
	cmp_ok($j2->count(), '==', 4, 'j2 count() == 4');
	isnt(refaddr($j1), refaddr($j2), 'j1 and j2 are distinct objects');
};
