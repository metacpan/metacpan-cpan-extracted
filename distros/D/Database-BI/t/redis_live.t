#!/usr/bin/env perl
use strict;
use warnings;

# Live Redis integration tests for Database::BI.
#
# Tests DataSource->new(redis => ...) and the join pipeline against a real
# Redis server.  Only run when REDIS_SERVER is set:
#
#   REDIS_SERVER=redis://localhost:6379 prove -lv t/redis_live.t
#
# All test keys are stored under a PID-unique prefix and cleaned up in END,
# so this test is safe to run against a shared Redis instance.

use Test::Most;
use Test::Returns;
use File::Temp qw(tempdir);

BEGIN {
	plan skip_all => 'REDIS_SERVER not set (e.g. REDIS_SERVER=redis://localhost:6379)'
		unless $ENV{REDIS_SERVER};
	eval { require Redis::Fast } or eval { require Redis };
	plan skip_all => 'Redis or Redis::Fast required'
		unless defined $INC{'Redis/Fast.pm'} || defined $INC{'Redis.pm'};
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
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

my $REDIS_CLASS = defined $INC{'Redis/Fast.pm'} ? 'Redis::Fast' : 'Redis';

my ($REDIS_HOST, $REDIS_PORT, $REDIS_PASS) = do {
	my ($userinfo, $h, $p);
	if ($SERVER_URL =~ m{\Aredis://([^@]*)@([^/:]+)(?::(\d+))?}i) {
		($userinfo, $h, $p) = ($1, $2, $3);
	} else {
		($h, $p) = $SERVER_URL =~ m{\Aredis://([^/:]+)(?::(\d+))?}i;
	}
	my $pw;
	if (defined $userinfo && length $userinfo) {
		$pw = ($userinfo =~ /:(.*)/) ? $1 : $userinfo;
	}
	($h // 'localhost', $p // 6379, $pw);
};

# ---------------------------------------------------------------------------
# Connect -- skip if unreachable
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
Readonly my $PREFIX => sprintf 'bilive_%d', $$;
Readonly my $TABLE  => "${PREFIX}_players";

# ---------------------------------------------------------------------------
# Fixture data
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
# InlineDA -- minimal stub for join right-side
# ---------------------------------------------------------------------------
my @INLINE_ROWS = (
	{ entry => 'row1', tier => 'gold',   region => 'east'  },
	{ entry => 'row2', tier => 'silver', region => 'west'  },
	{ entry => 'row3', tier => 'bronze', region => 'north' },
);

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
	if ($redis) {
		eval { $redis->del($_) for $redis->keys("${TABLE}:*") };
	}
}

# Load the BI app
use Test::Mojo;
my $t = Test::Mojo->new('Database::BI');
require Database::BI::Model::DataSource;
require Database::BI::Controller::Dashboard;

# The model store (.bi/) is shared state in the checkout: give this file its
# own directory, so a parallel run cannot create, read or write it underneath.
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

# ---------------------------------------------------------------------------
plan tests => 14;
# ---------------------------------------------------------------------------

sub _redis_src {
	return Database::BI::Model::DataSource->new(table => $TABLE, redis => $SERVER_URL);
}

sub _join {
	my (%extra) = @_;
	eval { require Database::Join }
		or die 'Database::Join required';
	return Database::Join->new(
		databases   => [_redis_src(), _inline_da()],
		join_column => 'entry',
		%extra,
	);
}

# ---------------------------------------------------------------------------
# Section 1 -- connection
# ---------------------------------------------------------------------------
subtest 'L1: DataSource->new(redis=>) connects successfully' => sub {
	plan tests => 2;
	my $src;
	lives_ok { $src = _redis_src() } 'DataSource->new lives';
	cmp_ok($src->count(), '>=', 1, 'count() >= 1 after connecting');
};

# ---------------------------------------------------------------------------
# Section 2 -- columns()
# ---------------------------------------------------------------------------
subtest 'L2: columns() triggers lazy open and returns column arrayref' => sub {
	plan tests => 3;
	my $cols = _redis_src()->columns;
	ok(defined $cols,            'columns() returns defined value (triggers lazy open)');
	ok(ref $cols eq 'ARRAY',     'columns() returns arrayref');
	ok((grep { $_ eq 'entry' } @{$cols}), 'columns() includes "entry"');
};

# ---------------------------------------------------------------------------
# Section 3 -- count()
# ---------------------------------------------------------------------------
subtest 'L3: count() equals number of keys seeded in Redis' => sub {
	plan tests => 1;
	cmp_ok(_redis_src()->count(), '==', 4, 'count() == 4 matching seeded fixture');
};

# ---------------------------------------------------------------------------
# Section 4 -- fetch_all / selectall_arrayref
# ---------------------------------------------------------------------------
subtest 'L4: fetch_all returns all rows' => sub {
	plan tests => 1;
	my $rows = _redis_src()->fetch_all;
	returns_is($rows, { type => 'arrayref', min => 4, max => 4 },
		'fetch_all returns 4-row arrayref');
};

subtest 'L5: selectall_arrayref returns all rows' => sub {
	plan tests => 1;
	my $rows = _redis_src()->selectall_arrayref;
	returns_is($rows, { type => 'arrayref', min => 4, max => 4 },
		'selectall_arrayref returns 4-row arrayref');
};

# ---------------------------------------------------------------------------
# Section 5 -- _open_spec
# ---------------------------------------------------------------------------
subtest 'L6: _open_spec redis: spec returns DataSource and table label' => sub {
	plan tests => 3;
	my $fn   = \&Database::BI::Controller::Dashboard::_open_spec;
	my $ctrl = $t->app->build_controller;
	my $spec = "redis:${TABLE}|${SERVER_URL}";
	my @res  = $fn->($ctrl, $spec);
	is(scalar @res, 2, '_open_spec returns 2-element list');
	ok(defined $res[0], 'first element is defined DataSource');
	is($res[1], $TABLE, 'second element is the table label');
};

# ---------------------------------------------------------------------------
# Section 6 -- Database::Join integration
# ---------------------------------------------------------------------------
subtest 'L7: Database::Join with Redis DataSource left source' => sub {
	eval { require Database::Join }
		or plan skip_all => 'Database::Join required';
	plan tests => 2;
	my $join;
	lives_ok { $join = _join() } 'Database::Join->new with Redis DataSource lives';
	ok(defined $join, 'join is defined');
};

subtest 'L8: count() == 4 for left join (4 Redis rows)' => sub {
	eval { require Database::Join }
		or plan skip_all => 'Database::Join required';
	plan tests => 1;
	cmp_ok(_join()->count(), '==', 4, 'count() == 4 for left join');
};

subtest 'L9: count() == 3 for inner join (3 shared rows)' => sub {
	eval { require Database::Join }
		or plan skip_all => 'Database::Join required';
	plan tests => 1;
	cmp_ok(_join(join_type => 'inner')->count(), '==', 3, 'count() == 3 for inner join');
};

subtest 'L10: selectall_arrayref returns merged row with correct fields' => sub {
	eval { require Database::Join }
		or plan skip_all => 'Database::Join required';
	plan tests => 4;
	my $rows = _join()->selectall_arrayref(entry => 'row1');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'one row for entry=row1');
	is($rows->[0]{entry},  'row1',  'entry correct');
	is($rows->[0]{name},   'Alice', 'name from Redis correct');
	is($rows->[0]{tier},   'gold',  'tier from InlineDA correct');
};

subtest 'L11: left join row4 present with undef InlineDA fields' => sub {
	eval { require Database::Join }
		or plan skip_all => 'Database::Join required';
	plan tests => 2;
	my $rows = _join()->selectall_arrayref(entry => 'row4');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'row4 present in left join');
	ok(!defined $rows->[0]{tier}, 'tier undef for Redis-only row4');
};

subtest 'L12: inner join returns only rows in both sources' => sub {
	eval { require Database::Join }
		or plan skip_all => 'Database::Join required';
	plan tests => 1;
	returns_is(_join(join_type => 'inner')->selectall_arrayref(),
		{ type => 'arrayref', min => 3, max => 3 },
		'inner join returns 3-row arrayref');
};

# ---------------------------------------------------------------------------
# Section 7 -- sort and limit
# ---------------------------------------------------------------------------
subtest 'L13: selectall_arrayref(sort_by => name) returns rows in name order' => sub {
	eval { require Database::Join }
		or plan skip_all => 'Database::Join required';
	plan tests => 1;
	my $rows  = _join(join_type => 'inner')->selectall_arrayref(sort_by => 'name');
	my @names = map { $_->{name} } @{$rows};
	is_deeply(\@names, [sort @names], 'rows sorted by name ascending');
};

# ---------------------------------------------------------------------------
# Section 8 -- idempotency
# ---------------------------------------------------------------------------
subtest 'L14: two DataSource objects have independent state' => sub {
	plan tests => 3;
	my $s1 = _redis_src();
	my $s2 = _redis_src();
	cmp_ok($s1->count(), '==', 4, 's1 count() == 4');
	cmp_ok($s2->count(), '==', 4, 's2 count() == 4');
	isnt(refaddr($s1), refaddr($s2), 's1 and s2 are distinct objects');
};
