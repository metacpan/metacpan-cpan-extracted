#!/usr/bin/env perl
use strict;
use warnings;

# Live Redis integration tests.
#
# Only run when REDIS_SERVER is set to a reachable Redis instance.
# REDIS_SERVER may be:
#   redis://localhost:6379         (full URL — passed directly)
#   redis://:password@host:6379    (with auth)
#   localhost:6379                 (host:port — redis:// is prepended)
#   localhost                      (host only — redis://host:6379 is used)
#
# All test keys are created under a PID-unique prefix and deleted in an
# END block, so the test is safe to run against a shared Redis instance.
#
# Example:
#   REDIS_SERVER=redis://localhost:6379 prove -l t/redis_live.t

use Test::Most;
use Test::Returns;

# Skip at compile time if REDIS_SERVER is unset or Redis module missing.
# (Test::NoWarnings is intentionally omitted — skip_all fired at runtime
# when the server is unreachable would cause a plan-count mismatch.)
BEGIN {
	plan skip_all => 'REDIS_SERVER not set (e.g. REDIS_SERVER=redis://localhost:6379)'
		unless $ENV{REDIS_SERVER};
	eval { require Redis::Fast } or eval { require Redis };
	plan skip_all => 'Redis or Redis::Fast required'
		unless defined $INC{'Redis/Fast.pm'} || defined $INC{'Redis.pm'};
}

use Readonly;
use Scalar::Util qw(refaddr);
use lib 't/lib';
use Database::Abstraction;

# ---------------------------------------------------------------------------
# Normalise the server URL
# ---------------------------------------------------------------------------
my $SERVER_URL = do {
	my $raw = $ENV{REDIS_SERVER};
	$raw =~ m{\Aredis://}i ? $raw : "redis://$raw";
};

# Extract host, port, and optional password from the URL
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

# Determine which Redis class to use
my $REDIS_CLASS = defined $INC{'Redis/Fast.pm'} ? 'Redis::Fast' : 'Redis';

# ---------------------------------------------------------------------------
# Test connectivity with a short timeout — skip all if unreachable
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
Readonly my $PREFIX   => sprintf 'dbabs_live_%d', $$;
Readonly my $TABLE    => "${PREFIX}_t";
Readonly my $TABLE_NE => "${PREFIX}_ne";
Readonly my $ALT_DB   => 15;

# ---------------------------------------------------------------------------
# Inline test subclasses — class names derive the table name via ref($self)
# ---------------------------------------------------------------------------
{
	no strict 'refs';
	@{"Database::${TABLE}::ISA"}    = ('Database::Abstraction');
	@{"Database::${TABLE_NE}::ISA"} = ('Database::Abstraction');
}

# ---------------------------------------------------------------------------
# Fixture data
# ---------------------------------------------------------------------------
my %FIXTURE = (
	row1 => { name => 'Alice',   score => '10', active => '1' },
	row2 => { name => 'Bob',     score => '20', active => '1' },
	row3 => { name => 'Charlie', score => '30', active => '0' },
);

for my $entry (keys %FIXTURE) {
	$redis->del("${TABLE}:${entry}");
	$redis->hset("${TABLE}:${entry}", %{ $FIXTURE{$entry} });
}

for my $i (1..3) {
	$redis->del("${TABLE_NE}:item${i}");
	$redis->hset("${TABLE_NE}:item${i}", label => "item$i", weight => $i * 5);
}

END {
	if($redis) {
		eval {
			for my $key ($redis->keys("${TABLE}:*"), $redis->keys("${TABLE_NE}:*")) {
				$redis->del($key);
			}
			$redis->select($ALT_DB);
			$redis->del($_) for $redis->keys("${TABLE}:*");
			$redis->select(0);
		};
	}
}

# ---------------------------------------------------------------------------
# Test plan  (no Test::NoWarnings — see comment at top)
# ---------------------------------------------------------------------------
plan tests => 23;

# Helpers
sub _db {
	my (%extra) = @_;
	return "Database::${TABLE}"->new(database => $SERVER_URL, %extra);
}

sub _db_ne {
	my (%extra) = @_;
	return "Database::${TABLE_NE}"->new(database => $SERVER_URL, no_entry => 1, %extra);
}

# ---------------------------------------------------------------------------
# Section 1 — connection and type
# ---------------------------------------------------------------------------
subtest 'L1: new() connects and type is Redis' => sub {
	plan tests => 2;
	my $db;
	lives_ok { $db = _db() } 'new() lives';
	$db->count();
	is($db->{'type'}, 'Redis', 'type attribute is Redis');
};

# ---------------------------------------------------------------------------
# Section 2 — count()
# ---------------------------------------------------------------------------
subtest 'L2: count() returns fixture row count' => sub {
	plan tests => 1;
	cmp_ok(_db()->count(), '==', 3, 'count() == 3');
};

subtest 'L3: count() with scalar criteria' => sub {
	plan tests => 1;
	cmp_ok(_db()->count(active => '1'), '==', 2, 'count(active=>1) == 2');
};

# ---------------------------------------------------------------------------
# Section 3 — selectall_arrayref
# ---------------------------------------------------------------------------
subtest 'L4: selectall_arrayref() returns all rows' => sub {
	plan tests => 1;
	my $rows = _db()->selectall_arrayref();
	returns_is($rows, { type => 'arrayref', min => 3, max => 3 }, 'L4 returns 3-row arrayref');
};

subtest 'L5: selectall_arrayref() with entry criteria' => sub {
	plan tests => 3;
	my $rows = _db()->selectall_arrayref(entry => 'row1');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'one-row arrayref for entry=row1');
	is($rows->[0]{'entry'}, 'row1',  'entry key correct');
	is($rows->[0]{'name'},  'Alice', 'name field correct');
};

subtest 'L6: selectall_arrayref() with scalar field criteria' => sub {
	plan tests => 2;
	my $rows = _db()->selectall_arrayref(active => '0');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'one inactive row returned');
	is($rows->[0]{'name'}, 'Charlie', 'correct inactive row');
};

subtest 'L7: selectall_arrayref() returns empty for no match' => sub {
	plan tests => 1;
	my $rows = _db()->selectall_arrayref(entry => 'nonexistent');
	returns_is($rows, { type => 'arrayref', min => 0, max => 0 }, 'empty arrayref for missing entry');
};

# ---------------------------------------------------------------------------
# Section 4 — fetchrow_hashref
# ---------------------------------------------------------------------------
subtest 'L8: fetchrow_hashref() returns correct row' => sub {
	plan tests => 3;
	my $row = _db()->fetchrow_hashref('row2');
	returns_is($row, { type => 'hashref' }, 'fetchrow_hashref returns hashref');
	is($row->{'name'},  'Bob',  'name is Bob');
	is($row->{'score'}, '20',   'score is 20');
};

subtest 'L9: fetchrow_hashref() returns undef for missing key' => sub {
	plan tests => 1;
	returns_is(_db()->fetchrow_hashref('no_such_key'), { type => 'void' }, 'undef for missing key');
};

# ---------------------------------------------------------------------------
# Section 5 — AUTOLOAD
# ---------------------------------------------------------------------------
subtest 'L10: AUTOLOAD scalar lookup' => sub {
	plan tests => 1;
	is(_db()->name(entry => 'row3'), 'Charlie', 'AUTOLOAD returns Charlie');
};

subtest 'L11: AUTOLOAD list context returns all column values' => sub {
	plan tests => 1;
	my $db = _db();
	my @names = sort $db->name();
	is_deeply(\@names, [sort map { $FIXTURE{$_}{name} } keys %FIXTURE],
		'AUTOLOAD list returns all names');
};

# ---------------------------------------------------------------------------
# Section 6 — no_entry mode
# ---------------------------------------------------------------------------
subtest 'L12: no_entry count()' => sub {
	plan tests => 1;
	cmp_ok(_db_ne()->count(), '==', 3, 'count() == 3 in no_entry mode');
};

subtest 'L13: no_entry rows have no injected entry key' => sub {
	plan tests => 2;
	my $rows = _db_ne()->selectall_arrayref();
	returns_is($rows, { type => 'arrayref', min => 3, max => 3 }, '3-row arrayref in no_entry mode');
	ok(!exists $rows->[0]{'entry'}, 'no entry key injected in no_entry mode');
};

# ---------------------------------------------------------------------------
# Section 7 — columns()
# ---------------------------------------------------------------------------
subtest 'L14: columns() returns sorted list' => sub {
	plan tests => 2;
	my $cols = _db()->columns();
	returns_is($cols, { type => 'arrayref' }, 'columns() returns arrayref');
	is_deeply([sort @{$cols}], $cols, 'columns() in alphabetical order');
};

# ---------------------------------------------------------------------------
# Section 8 — select() switches Redis database
# ---------------------------------------------------------------------------
subtest 'L15: select() switches database and re-slurps' => sub {
	plan tests => 3;
	my $db = _db();
	$db->count();

	# Populate alt DB via the direct connection
	$redis->select($ALT_DB);
	for my $entry (keys %FIXTURE) {
		$redis->del("${TABLE}:${entry}");
		$redis->hset("${TABLE}:${entry}", %{ $FIXTURE{$entry} });
	}
	$redis->select(0);

	lives_ok { $db->select($ALT_DB) } "select($ALT_DB) lives";
	cmp_ok($db->count(), '==', 3, 'data readable in alt DB after select()');

	$db->select(0);
	cmp_ok($db->count(), '==', 3, 'data readable again in DB 0 after select(0)');
};

subtest 'L16: select() returns $self for chaining' => sub {
	plan tests => 2;
	my $db = _db();
	$db->count();
	is(refaddr($db->select(0)), refaddr($db), 'select() returns $self');
	cmp_ok($db->select(0)->count(), '==', 3, 'chained select()->count() works');
};

subtest 'L17: select() clears cached data' => sub {
	plan tests => 2;
	my $db = _db();
	$db->count();
	ok(defined $db->{'data'}, 'data populated before select()');
	$db->select(1);
	ok(!defined $db->{'data'}, 'data cleared immediately after select()');
	$db->select(0);
};

# ---------------------------------------------------------------------------
# Section 9 — idempotency
# ---------------------------------------------------------------------------
subtest 'L18: repeated count() is idempotent' => sub {
	plan tests => 2;
	my $db = _db();
	cmp_ok($db->count(), '==', 3, 'first count() == 3');
	cmp_ok($db->count(), '==', 3, 'second count() == 3');
};

subtest 'L19: repeated fetchrow_hashref() returns identical row' => sub {
	plan tests => 2;
	my $db = _db();
	my $r1 = $db->fetchrow_hashref('row1');
	my $r2 = $db->fetchrow_hashref('row1');
	returns_is($r1, { type => 'hashref' }, 'first call returns hashref');
	is_deeply($r1, $r2, 'second call returns identical row');
};

# ---------------------------------------------------------------------------
# Section 10 — sort_by and limit
# ---------------------------------------------------------------------------
subtest 'L20: selectall_arrayref sort_by ascending' => sub {
	plan tests => 1;
	my $rows = _db()->selectall_arrayref(sort_by => 'name');
	my @names = map { $_->{'name'} } @{$rows};
	is_deeply(\@names, [sort @names], 'rows sorted by name ascending');
};

subtest 'L21: selectall_arrayref limit' => sub {
	plan tests => 1;
	my $rows = _db()->selectall_arrayref(sort_by => 'entry', limit => 2);
	returns_is($rows, { type => 'arrayref', min => 2, max => 2 }, 'limit => 2 returns 2-row arrayref');
};

# ---------------------------------------------------------------------------
# Section 11 — multi-instance isolation
# ---------------------------------------------------------------------------
subtest 'L22: two independent objects have independent data refs' => sub {
	plan tests => 3;
	my $db1 = _db();
	my $db2 = _db();
	$db1->count();
	$db2->count();
	pass('independent objects instantiated without error');
	isnt(refaddr($db1->{'data'}), refaddr($db2->{'data'}),
		'data refs are distinct between objects');
	cmp_ok($db2->count(), '==', $db1->count(), 'both objects return same count');
};

# ---------------------------------------------------------------------------
# Section 12 — DESTROY
# ---------------------------------------------------------------------------
subtest 'L23: DESTROY does not croak' => sub {
	plan tests => 1;
	{
		my $db = _db();
		$db->count();
	}
	pass('DESTROY completes without error');
};
