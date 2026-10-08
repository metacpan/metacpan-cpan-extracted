#!/usr/bin/env perl
use strict;
use warnings;

# Redis backend tests.
# Pre-load Redis before any mock so lazy require in _open() is a no-op.
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
}

plan tests => 20;

# ---------------------------------------------------------------------------
# Inline test subclasses
# ---------------------------------------------------------------------------
{ package Database::redis_test;  use base 'Database::Abstraction' }
{ package Database::redis_ne;    use base 'Database::Abstraction' }

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
use Readonly;
Readonly my $REDIS_URL   => 'redis://localhost:6379';
Readonly my $ENTRY_ONE   => 'row1';
Readonly my $ENTRY_TWO   => 'row2';
Readonly my $ENTRY_THREE => 'row3';

my %FIXTURE = (
	$ENTRY_ONE   => { name => 'Alice', score => '10' },
	$ENTRY_TWO   => { name => 'Bob',   score => '20' },
	$ENTRY_THREE => { name => 'Carol', score => '30' },
);

# ---------------------------------------------------------------------------
# MockRedis — implements the subset of Redis API used by _open() and select()
# ---------------------------------------------------------------------------
{
	package MockRedis;

	sub new {
		my ($class, %opts) = @_;
		return bless {
			_table         => $opts{_table}  // 'redis_test',
			_data          => $opts{_data}   // {},
			_select_calls  => 0,
			_quit_calls    => 0,
			_auth_calls    => 0,
		}, $class;
	}

	sub auth   { my $self = shift; $self->{_auth_calls}++;   return 'OK' }
	sub quit   { my $self = shift; $self->{_quit_calls}++;   return 'OK' }

	sub select {
		my ($self, $idx) = @_;
		$self->{_select_calls}++;
		return 'OK';
	}

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

# Determine which Redis class _open() will actually use
my $REDIS_CLASS = defined $INC{'Redis/Fast.pm'} ? 'Redis::Fast' : 'Redis';

# Helper: return a fresh MockRedis and a mock_scoped guard
sub _mock_redis {
	my (%opts) = @_;
	my $mock = MockRedis->new(_table => $opts{table} // 'redis_test',
	                          _data  => $opts{data}  // \%FIXTURE);
	my $guard = mock_scoped($REDIS_CLASS, new => sub { $mock });
	return ($mock, $guard);
}

# ---------------------------------------------------------------------------
# Section 1 — constructor validation
# ---------------------------------------------------------------------------
subtest 'R1: constructor accepts redis:// database URL' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	lives_ok {
		Database::redis_test->new(database => $REDIS_URL)
	} 'new() with database => redis://... lives';
};

subtest 'R2: constructor rejects non-redis database URL' => sub {
	plan tests => 2;
	throws_ok {
		Database::redis_test->new(database => 'ftp://bad')
	} qr/unsafe database/i, 'ftp:// rejected';

	throws_ok {
		Database::redis_test->new(database => 'file:///tmp/foo')
	} qr/unsafe database/i, 'file:// rejected';
};

subtest 'R3: constructor requires database or directory/dsn/url' => sub {
	plan tests => 1;
	throws_ok {
		Database::redis_test->new()
	} qr/where are the files/i, 'no connection source croaks';
};

# ---------------------------------------------------------------------------
# Section 2 — basic queries (keyed mode)
# ---------------------------------------------------------------------------
subtest 'R4: count() returns correct row count' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => $REDIS_URL);
	cmp_ok($db->count(), '==', 3, 'count() == 3');
};

subtest 'R5: selectall_arrayref() returns all rows' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => $REDIS_URL);
	my $rows = $db->selectall_arrayref();
	returns_is($rows, { type => 'arrayref', min => 3, max => 3 }, 'R5 returns 3-row arrayref');
};

subtest 'R6: selectall_arrayref() with entry criteria returns one row' => sub {
	plan tests => 3;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => $REDIS_URL);
	my $rows = $db->selectall_arrayref(entry => $ENTRY_ONE);
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'one-row arrayref for entry criteria');
	is($rows->[0]{'entry'}, $ENTRY_ONE, 'entry key matches');
	is($rows->[0]{'name'},  'Alice',    'name field correct');
};

subtest 'R7: fetchrow_hashref() returns a single row' => sub {
	plan tests => 2;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => $REDIS_URL);
	my $row = $db->fetchrow_hashref($ENTRY_TWO);
	returns_is($row, { type => 'hashref' }, 'fetchrow_hashref returns hashref');
	is($row->{'name'}, 'Bob', 'correct name for row2');
};

subtest 'R8: fetchrow_hashref() returns undef for missing entry' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => $REDIS_URL);
	returns_is($db->fetchrow_hashref('nonexistent'), { type => 'void' }, 'undef for missing key');
};

# ---------------------------------------------------------------------------
# Section 3 — AUTOLOAD column lookup
# ---------------------------------------------------------------------------
subtest 'R9: AUTOLOAD scalar lookup' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => $REDIS_URL);
	is($db->name(entry => $ENTRY_THREE), 'Carol', 'AUTOLOAD scalar lookup');
};

# ---------------------------------------------------------------------------
# Section 4 — no_entry mode
# ---------------------------------------------------------------------------
subtest 'R10: no_entry mode — selectall_arrayref returns rows without entry key' => sub {
	plan tests => 2;
	my ($mock, $guard) = _mock_redis(table => 'redis_ne');
	my $db = Database::redis_ne->new(database => $REDIS_URL, no_entry => 1);
	my $rows = $db->selectall_arrayref();
	returns_is($rows, { type => 'arrayref', min => 3, max => 3 }, '3-row arrayref in no_entry mode');
	ok(!exists $rows->[0]{'entry'}, 'no injected entry key in no_entry mode');
};

# ---------------------------------------------------------------------------
# Section 5 — select() method
# ---------------------------------------------------------------------------
subtest 'R11: select() switches Redis database' => sub {
	plan tests => 3;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => $REDIS_URL);
	$db->count();	# ensure connection is open

	lives_ok { $db->select(1) } 'select(1) lives';
	cmp_ok($mock->{_select_calls}, '>=', 1, 'Redis SELECT called at least once');
	ok(!defined $db->{'data'}, 'data cache cleared after select()');
};

subtest 'R12: select() returns $self for chaining' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => $REDIS_URL);
	$db->count();
	my $ret = $db->select(2);
	is(refaddr($ret), refaddr($db), 'select() returns $self');
};

use Scalar::Util qw(refaddr);

subtest 'R13: select() with non-integer croaks' => sub {
	plan tests => 2;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => $REDIS_URL);
	$db->count();
	throws_ok { $db->select('foo') }
		qr/db number must be a non-negative integer/i, 'string arg croaks';
	throws_ok { $db->select(-1) }
		qr/db number must be a non-negative integer/i, 'negative int croaks';
};

subtest 'R14: select() croaks on non-Redis connection' => sub {
	plan tests => 1;
	unless(eval { require DBD::SQLite; 1 }) {
		pass('skip — DBD::SQLite not available');
		return;
	}
	{ package Database::redis_sq; use base 'Database::Abstraction' }
	require File::Temp;
	require File::Spec;
	my $tmpdir = File::Temp->newdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile("$tmpdir", 'redis_sq.sql');
	my $setup  = DBI->connect("dbi:SQLite:dbname=$dbfile", undef, undef, { RaiseError => 1 });
	$setup->do('CREATE TABLE redis_sq (entry TEXT PRIMARY KEY, name TEXT)');
	$setup->do("INSERT INTO redis_sq VALUES ('a', 'alpha')");
	$setup->disconnect();
	my $db = Database::redis_sq->new(dsn => "dbi:SQLite:dbname=$dbfile");
	$db->count();
	throws_ok { $db->select(0) }
		qr/not a Redis connection/i, 'select() on DBI backend croaks';
};

# ---------------------------------------------------------------------------
# Section 6 — DB index in URL
# ---------------------------------------------------------------------------
subtest 'R15: database URL /db_index triggers SELECT on open' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => 'redis://localhost:6379/3');
	$db->count();	# triggers _open()
	cmp_ok($mock->{_select_calls}, '==', 1, 'SELECT called once for /3 in URL');
};

# ---------------------------------------------------------------------------
# Section 7 — DESTROY disconnects Redis
# ---------------------------------------------------------------------------
subtest 'R16: DESTROY calls quit() on Redis connection' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	{
		my $db = Database::redis_test->new(database => $REDIS_URL);
		$db->count();
	}	# $db goes out of scope → DESTROY
	cmp_ok($mock->{_quit_calls}, '==', 1, 'quit() called once on DESTROY');
};

# ---------------------------------------------------------------------------
# Section 8 — type and idempotency
# ---------------------------------------------------------------------------
subtest 'R17: type is set to Redis' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => $REDIS_URL);
	$db->count();
	is($db->{'type'}, 'Redis', 'type attribute is Redis');
};

subtest 'R18: repeated count() calls return consistent result' => sub {
	plan tests => 2;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => $REDIS_URL);
	my $c1 = $db->count();
	my $c2 = $db->count();
	cmp_ok($c1, '==', 3, 'first count() == 3');
	cmp_ok($c1, '==', $c2, 'second count() matches first');
};

# ---------------------------------------------------------------------------
# Section 9 — password in URL
# ---------------------------------------------------------------------------
subtest 'R19: auth() called when password present in URL' => sub {
	plan tests => 1;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => 'redis://s3cr3t@localhost:6379');
	$db->count();
	cmp_ok($mock->{_auth_calls}, '==', 1, 'auth() called once for password URL');
};

# ---------------------------------------------------------------------------
# Section 10 — columns()
# ---------------------------------------------------------------------------
subtest 'R20: columns() returns sorted column names' => sub {
	plan tests => 2;
	my ($mock, $guard) = _mock_redis();
	my $db = Database::redis_test->new(database => $REDIS_URL);
	my $cols = $db->columns();
	returns_is($cols, { type => 'arrayref' }, 'columns() returns arrayref');
	is_deeply([sort @{$cols}], $cols, 'columns() in alphabetical order');
};
