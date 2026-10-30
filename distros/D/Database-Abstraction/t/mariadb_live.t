#!/usr/bin/env perl
use strict;
use warnings;

# Live MariaDB integration tests.
#
# Only run when MARIADB_SERVER is set to a reachable MariaDB/MySQL instance.
# MARIADB_SERVER may be:
#   mariadb://user:pass@host:port/database   (full URL)
#   mariadb://host/database                  (no auth)
#   host                                     (uses root, no password, 'test' database)
#   host:port                                (host + port)
#   host/database                            (host + database name)
#   dbi:MariaDB:database=db;host=host        (direct DSN)
#   dbi:mysql:database=db;host=host          (MySQL-compatible DSN)
#
# The test creates a PID-unique table, runs queries, then drops it in an END block.
# Example:
# On the client:
#   MARIADB_SERVER=mariadb://dbtest@server/test prove -l t/mariadb_live.t
#
# On the server, run these commands to set up a test database that the
# client can test against:
#   CREATE DATABASE test;
#   GRANT ALL ON test.* TO 'dbtest'@'client';
#   FLUSH PRIVILEGES;

use Test::Most;
use Test::Returns;

BEGIN {
	plan skip_all => 'MARIADB_SERVER not set (e.g. MARIADB_SERVER=mariadb://root:pass@host/test)'
		unless $ENV{MARIADB_SERVER};
	eval { require DBD::MariaDB } or eval { require DBD::mysql };
	plan skip_all => 'DBD::MariaDB or DBD::mysql required'
		unless defined $INC{'DBD/MariaDB.pm'} || defined $INC{'DBD/mysql.pm'};
}

use Readonly;
use Scalar::Util qw(refaddr);
use lib 't/lib';
use Database::Abstraction;

# ---------------------------------------------------------------------------
# Parse MARIADB_SERVER into connection parameters and a DSN
# ---------------------------------------------------------------------------
my ($DSN, $DB_USER, $DB_PASS) = _parse_server($ENV{MARIADB_SERVER});

sub _parse_server {
	my ($raw) = @_;

	# Direct DSN
	return ($raw, undef, undef) if $raw =~ /\Adbi:/i;

	# Normalise to mariadb:// URL
	$raw = "mariadb://$raw" unless $raw =~ m{\A[a-z]+://}i;

	my ($user, $pass, $host, $port, $db);
	if ($raw =~ m{\Amariadb://([^:@]+):([^@]*)@([^/:]+)(?::(\d+))?(?:/(\S*))?}i) {
		($user, $pass, $host, $port, $db) = ($1, $2, $3, $4, $5);
	} elsif ($raw =~ m{\Amariadb://([^@]+)@([^/:]+)(?::(\d+))?(?:/(\S*))?}i) {
		($user, $host, $port, $db) = ($1, $2, $3, $4);
	} elsif ($raw =~ m{\Amariadb://([^/:]+)(?::(\d+))?(?:/(\S*))?}i) {
		($host, $port, $db) = ($1, $2, $3);
	}
	$host //= 'localhost';
	$port //= 3306;
	$db   //= 'test';
	$db     =~ s{/}{}g;

	# Prefer DBD::MariaDB, fall back to DBD::mysql
	my $driver = defined $INC{'DBD/MariaDB.pm'} ? 'MariaDB' : 'mysql';

	my $dsn = "dbi:${driver}:database=${db};host=${host};port=${port}";
	return ($dsn, $user, $pass);
}

# ---------------------------------------------------------------------------
# PID-unique table name to avoid collisions on a shared server
# ---------------------------------------------------------------------------
Readonly my $TABLE => sprintf 'dbabs_live_%d', $$;

# ---------------------------------------------------------------------------
# Set up a raw DBI connection to create/drop the test table
# ---------------------------------------------------------------------------
my $setup_dbh;
eval {
	$setup_dbh = DBI->connect(
		$DSN, $DB_USER, $DB_PASS,
		{ RaiseError => 1, PrintError => 0, AutoCommit => 1 },
	);
};
if ($@) {
	plan skip_all => "Cannot connect to MariaDB ($DSN): $@";
}

# Test connectivity with a simple ping
eval { $setup_dbh->ping() };
if ($@) {
	plan skip_all => "MariaDB connection not alive: $@";
}

# ---------------------------------------------------------------------------
# Create the test table and populate fixture rows
# ---------------------------------------------------------------------------
$setup_dbh->do("DROP TABLE IF EXISTS `$TABLE`");
$setup_dbh->do(<<"SQL");
CREATE TABLE `$TABLE` (
	entry   VARCHAR(64)  NOT NULL PRIMARY KEY,
	name    VARCHAR(128) NOT NULL,
	score   INT          NOT NULL DEFAULT 0,
	active  TINYINT      NOT NULL DEFAULT 1
)
SQL

my %FIXTURE = (
	row1 => { name => 'Alice',   score => 10, active => 1 },
	row2 => { name => 'Bob',     score => 20, active => 1 },
	row3 => { name => 'Charlie', score => 30, active => 0 },
);

for my $entry (sort keys %FIXTURE) {
	my $f = $FIXTURE{$entry};
	$setup_dbh->do(
		"INSERT INTO `$TABLE` (entry, name, score, active) VALUES (?, ?, ?, ?)",
		undef, $entry, $f->{name}, $f->{score}, $f->{active},
	);
}

END {
	if ($setup_dbh) {
		eval { $setup_dbh->do("DROP TABLE IF EXISTS `$TABLE`") };
		eval { $setup_dbh->disconnect() };
	}
}

# ---------------------------------------------------------------------------
# Inline test subclass — class name derives the table name
# ---------------------------------------------------------------------------
{
	no strict 'refs';
	@{"Database::${TABLE}::ISA"} = ('Database::Abstraction');
}

plan tests => 17;

# Helper: open a fresh Database::Abstraction object for each subtest
sub _db {
	my (%extra) = @_;
	return "Database::${TABLE}"->new(
		dsn      => $DSN,
		username => $DB_USER,
		password => $DB_PASS,
		no_entry => 0,
		%extra,
	);
}

# ---------------------------------------------------------------------------
# L1 — connection, type and dialect
# ---------------------------------------------------------------------------
subtest 'L1: new() connects and type/dialect is correct' => sub {
	plan tests => 3;
	my $db;
	lives_ok { $db = _db() } 'new() lives';
	$db->count();
	is($db->{'type'},     'DBI',   'type attribute is DBI');
	is($db->{'_dialect'}, 'mysql', 'dialect is mysql');
};

# ---------------------------------------------------------------------------
# L2 — count()
# ---------------------------------------------------------------------------
subtest 'L2: count() returns fixture row count' => sub {
	plan tests => 1;
	cmp_ok(_db()->count(), '==', 3, 'count() == 3');
};

subtest 'L3: count() with scalar criteria' => sub {
	plan tests => 1;
	cmp_ok(_db()->count(active => 1), '==', 2, 'count(active=>1) == 2');
};

# ---------------------------------------------------------------------------
# L4–L7 — selectall_arrayref
# ---------------------------------------------------------------------------
subtest 'L4: selectall_arrayref() returns all rows' => sub {
	plan tests => 1;
	my $rows = _db()->selectall_arrayref();
	returns_is($rows, { type => 'arrayref', min => 3, max => 3 }, '3-row arrayref');
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
	my $rows = _db()->selectall_arrayref(active => 0);
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'one inactive row returned');
	is($rows->[0]{'name'}, 'Charlie', 'correct inactive row');
};

subtest 'L7: selectall_arrayref() returns empty for no match' => sub {
	plan tests => 1;
	my $rows = _db()->selectall_arrayref(entry => 'nonexistent');
	returns_is($rows, { type => 'arrayref', min => 0, max => 0 }, 'empty arrayref for missing entry');
};

# ---------------------------------------------------------------------------
# L8–L9 — fetchrow_hashref
# ---------------------------------------------------------------------------
subtest 'L8: fetchrow_hashref() returns correct row' => sub {
	plan tests => 3;
	my $row = _db()->fetchrow_hashref('row2');
	returns_is($row, { type => 'hashref' }, 'returns hashref');
	is($row->{'name'},  'Bob', 'name is Bob');
	is($row->{'score'}, 20,    'score is 20');
};

subtest 'L9: fetchrow_hashref() returns undef for missing key' => sub {
	plan tests => 1;
	returns_is(_db()->fetchrow_hashref('no_such_key'), { type => 'void' }, 'undef for missing key');
};

# ---------------------------------------------------------------------------
# L10–L11 — AUTOLOAD
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
# L12 — columns() returns sorted list
# ---------------------------------------------------------------------------
subtest 'L12: columns() returns sorted list' => sub {
	plan tests => 2;
	my $cols = _db()->columns();
	returns_is($cols, { type => 'arrayref' }, 'columns() returns arrayref');
	is_deeply([sort @{$cols}], $cols, 'columns() in alphabetical order');
};

# ---------------------------------------------------------------------------
# L13 — schema() introspection
# ---------------------------------------------------------------------------
subtest 'L13: schema() returns column metadata' => sub {
	plan tests => 3;
	my $schema = _db()->schema();
	returns_is($schema, { type => 'hashref' }, 'schema() returns hashref');
	ok(exists $schema->{'name'},  'schema has name column');
	ok(exists $schema->{'score'}, 'schema has score column');
};

# ---------------------------------------------------------------------------
# L14 — sort_by and limit
# ---------------------------------------------------------------------------
subtest 'L14: selectall_arrayref sort_by ascending' => sub {
	plan tests => 1;
	my $rows = _db()->selectall_arrayref(sort_by => 'name');
	my @names = map { $_->{'name'} } @{$rows};
	is_deeply(\@names, [sort @names], 'rows sorted by name ascending');
};

subtest 'L15: selectall_arrayref limit' => sub {
	plan tests => 1;
	my $rows = _db()->selectall_arrayref(sort_by => 'entry', limit => 2);
	returns_is($rows, { type => 'arrayref', min => 2, max => 2 }, 'limit => 2 returns 2-row arrayref');
};

# ---------------------------------------------------------------------------
# L16 — idempotency
# ---------------------------------------------------------------------------
subtest 'L16: repeated count() is idempotent' => sub {
	plan tests => 2;
	my $db = _db();
	cmp_ok($db->count(), '==', 3, 'first count() == 3');
	cmp_ok($db->count(), '==', 3, 'second count() == 3');
};

# ---------------------------------------------------------------------------
# L17 — multi-instance isolation
# ---------------------------------------------------------------------------
subtest 'L17: two independent objects return the same data' => sub {
	plan tests => 2;
	my $db1 = _db();
	my $db2 = _db();
	pass('independent objects instantiated without error');
	cmp_ok($db2->count(), '==', $db1->count(), 'both objects return same count');
};
