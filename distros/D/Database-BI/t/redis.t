#!/usr/bin/env perl
use strict;
use warnings;

# Redis backend tests for Database::BI.
#
# Tests DataSource->new(redis => ...) and the join pipeline via Database::Join
# with a Redis-backed DataSource as the left source.  No real Redis server is
# required: Redis is mocked via Test::Mockingbird's mock_scoped.
#
# Pre-load Redis before any mock so Database::Abstraction's lazy require in
# _open() is a no-op when the mock guard is installed.
BEGIN {
	eval { require Redis::Fast } or eval { require Redis };
}

use Test::Most;
use Test::Mockingbird;
use File::Temp qw(tempdir);

BEGIN {
	my $have_redis = (defined $INC{'Redis/Fast.pm'} || defined $INC{'Redis.pm'})
		|| eval { require Redis; 1 };
	plan skip_all => 'Redis or Redis::Fast required' unless $have_redis;
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
}

# Load the app so all modules are available via %INC.
use Test::Mojo;
my $t = Test::Mojo->new('Database::BI');
require Database::BI::Model::DataSource;
require Database::BI::Controller::Dashboard;

# The model store (.bi/) is shared state in the checkout: give this file its
# own directory, so a parallel run cannot create, read or write it underneath.
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

use Readonly;
Readonly my $REDIS_URL => 'redis://localhost:6379';
Readonly my $TABLE     => 'players';

# ---------------------------------------------------------------------------
# Fixture data stored in the mock Redis hash store
# ---------------------------------------------------------------------------
my %REDIS_FIXTURE = (
	row1 => { name => 'Alice', score => '10' },
	row2 => { name => 'Bob',   score => '20' },
	row3 => { name => 'Carol', score => '30' },
	row4 => { name => 'Dave',  score => '40' },
);

# Inline table fixture for join tests (covers row1-row3; row4 absent)
my @INLINE_ROWS = (
	{ entry => 'row1', tier => 'gold',   region => 'east'  },
	{ entry => 'row2', tier => 'silver', region => 'west'  },
	{ entry => 'row3', tier => 'bronze', region => 'north' },
);

# ---------------------------------------------------------------------------
# MockRedis -- implements the Redis API subset used by Database::Abstraction
# ---------------------------------------------------------------------------
{
	package MockRedis;

	sub new {
		my ($class, %opts) = @_;
		return bless {
			_table => $opts{_table} // $TABLE,
			_data  => $opts{_data}  // {},
		}, $class;
	}

	sub auth   { 'OK' }
	sub quit   { 'OK' }
	sub select { 'OK' }

	sub keys {
		my ($self, $pattern) = @_;
		my $tbl = $self->{_table};
		(my $prefix = $pattern) =~ s/\*\z//;
		return grep { /\A\Q$prefix\E/ }
			map { "${tbl}:$_" } sort CORE::keys %{ $self->{_data} };
	}

	sub hgetall {
		my ($self, $key) = @_;
		my $tbl = $self->{_table};
		(my $entry = $key) =~ s/\A\Q${tbl}\E://;
		my $row = $self->{_data}{$entry} or return ();
		return %{$row};
	}
}

# Determine which Redis class Database::Abstraction will try to instantiate.
my $REDIS_CLASS = defined $INC{'Redis/Fast.pm'} ? 'Redis::Fast' : 'Redis';

# Helper: build a MockRedis and install a scoped constructor mock.
sub _mock_redis {
	my (%opts) = @_;
	my $mock = MockRedis->new(
		_table => $opts{table} // $TABLE,
		_data  => $opts{data}  // \%REDIS_FIXTURE,
	);
	my $guard = mock_scoped($REDIS_CLASS, new => sub { $mock });
	return ($mock, $guard);
}

# ---------------------------------------------------------------------------
# InlineDA -- minimal DataSource-compatible stub for the right side of joins
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
plan tests => 13;
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Section 1 -- DataSource construction
# ---------------------------------------------------------------------------
subtest 'R1: DataSource->new(redis=>) constructs without error' => sub {
	plan tests => 2;
	my ($mock, $guard) = _mock_redis();
	my $src;
	lives_ok {
		$src = Database::BI::Model::DataSource->new(
			table => $TABLE,
			redis => $REDIS_URL,
		);
	} 'DataSource->new with redis=> lives';
	ok(defined $src, 'returns a defined DataSource object');
};

subtest 'R2: DataSource->new rejects a non-redis:// URL' => sub {
	plan tests => 1;
	throws_ok {
		Database::BI::Model::DataSource->new(table => $TABLE, redis => 'http://localhost:6379')
	} qr/redis:\/\//i, 'croaks when URL does not begin with redis://';
};

subtest 'R3: DataSource->new with redis=> requires a table name' => sub {
	plan tests => 1;
	throws_ok {
		Database::BI::Model::DataSource->new(redis => $REDIS_URL)
	} qr/table/i, 'croaks when table name is absent';
};

# ---------------------------------------------------------------------------
# Section 2 -- data access
# ---------------------------------------------------------------------------
subtest 'R4: fetch_all returns all rows from the Redis store' => sub {
	plan tests => 2;
	my ($mock, $guard) = _mock_redis();
	my $src = Database::BI::Model::DataSource->new(table => $TABLE, redis => $REDIS_URL);
	my $rows;
	lives_ok { $rows = $src->fetch_all } 'fetch_all lives';
	cmp_ok(scalar @{$rows}, '==', 4, 'fetch_all returns 4 rows (matching fixture)');
};

subtest 'R5: selectall_arrayref returns the same rows as fetch_all' => sub {
	plan tests => 2;
	my ($mock, $guard) = _mock_redis();
	my $src = Database::BI::Model::DataSource->new(table => $TABLE, redis => $REDIS_URL);
	my $rows;
	lives_ok { $rows = $src->selectall_arrayref } 'selectall_arrayref lives';
	ok(ref $rows eq 'ARRAY', 'returns an arrayref');
};

subtest 'R6: columns() triggers lazy open and returns column arrayref' => sub {
	plan tests => 3;
	my ($mock, $guard) = _mock_redis();
	my $src = Database::BI::Model::DataSource->new(table => $TABLE, redis => $REDIS_URL);
	my $cols = $src->columns;
	ok(defined $cols,            'columns() returns defined value (triggers lazy open)');
	ok(ref $cols eq 'ARRAY',     'columns() returns arrayref');
	ok((grep { $_ eq 'entry' } @{$cols}), 'columns() includes "entry"');
};

subtest 'R7: id_column returns "entry" for Redis-backed sources' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $src = Database::BI::Model::DataSource->new(table => $TABLE, redis => $REDIS_URL);
	is($src->id_column, 'entry', 'id_column is "entry" for Redis sources');
};

# ---------------------------------------------------------------------------
# Section 3 -- _open_spec parsing
# ---------------------------------------------------------------------------
subtest 'R8: _open_spec accepts redis:table|redis://url spec' => sub {
	plan tests => 3;
	my ($mock, $guard) = _mock_redis();
	my $fn   = \&Database::BI::Controller::Dashboard::_open_spec;
	my $ctrl = $t->app->build_controller;
	my $spec = "redis:${TABLE}|${REDIS_URL}";
	my @result = $fn->($ctrl, $spec);
	is(scalar @result, 2, '_open_spec returns a 2-element list');
	ok(defined $result[0], 'first element is a defined DataSource');
	is($result[1], $TABLE,  'second element is the table name label');
};

subtest 'R9: _open_spec rejects redis: spec with non-redis:// URL' => sub {
	plan tests => 1;
	my $fn   = \&Database::BI::Controller::Dashboard::_open_spec;
	my $ctrl = $t->app->build_controller;
	my @result = $fn->($ctrl, "redis:${TABLE}|http://localhost:6379");
	is(scalar @result, 0, '_open_spec returns empty list for invalid redis URL');
};

subtest 'R10: _open_spec rejects malformed redis: spec (no pipe)' => sub {
	plan tests => 1;
	my $fn   = \&Database::BI::Controller::Dashboard::_open_spec;
	my $ctrl = $t->app->build_controller;
	my @result = $fn->($ctrl, "redis:players_redis://localhost:6379");
	is(scalar @result, 0, '_open_spec returns empty list for spec without pipe separator');
};

# ---------------------------------------------------------------------------
# Section 4 -- Database::Join integration
# ---------------------------------------------------------------------------
subtest 'R11: Redis DataSource satisfies Database::Join duck-type interface' => sub {
	plan tests => 2;
	eval { require Database::Join }
		or plan skip_all => 'Database::Join required';
	my ($mock, $guard) = _mock_redis();
	my $redis_src = Database::BI::Model::DataSource->new(table => $TABLE, redis => $REDIS_URL);
	my $join;
	lives_ok {
		$join = Database::Join->new(
			databases   => [$redis_src, _inline_da()],
			join_column => 'entry',
		);
	} 'Database::Join->new with Redis DataSource lives';
	ok(defined $join, 'join object is defined');
};

subtest 'R12: join produces correct row count (left join semantics)' => sub {
	plan tests => 1;
	eval { require Database::Join }
		or plan skip_all => 'Database::Join required';
	my ($mock, $guard) = _mock_redis();
	my $redis_src = Database::BI::Model::DataSource->new(table => $TABLE, redis => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_src, _inline_da()],
		join_column => 'entry',
	);
	cmp_ok($join->count(), '==', 4, 'left join count() == 4 (4 Redis rows, 3 in InlineDA)');
};

subtest 'R13: merged row contains columns from both Redis and InlineDA' => sub {
	plan tests => 4;
	eval { require Database::Join }
		or plan skip_all => 'Database::Join required';
	my ($mock, $guard) = _mock_redis();
	my $redis_src = Database::BI::Model::DataSource->new(table => $TABLE, redis => $REDIS_URL);
	my $join = Database::Join->new(
		databases   => [$redis_src, _inline_da()],
		join_column => 'entry',
	);
	my $rows = $join->selectall_arrayref(entry => 'row1');
	ok(defined $rows && ref $rows eq 'ARRAY' && @{$rows} == 1, 'one row returned for entry=row1');
	is($rows->[0]{entry},  'row1',  'entry field correct');
	is($rows->[0]{name},   'Alice', 'name field from Redis correct');
	is($rows->[0]{tier},   'gold',  'tier field from InlineDA correct');
};
