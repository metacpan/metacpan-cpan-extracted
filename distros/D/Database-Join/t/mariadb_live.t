#!/usr/bin/env perl
use strict;
use warnings;

# Live MariaDB integration tests for Database::Join.
#
# Tests joins between MariaDB-backed Database::Abstraction subclasses and
# between a MariaDB-backed DA and a static in-memory DA.
#
# Only run when MARIADB_SERVER is set to a reachable MariaDB/MySQL instance:
#   MARIADB_SERVER=mariadb://user:pass@host/test prove -l t/mariadb_live.t
#
# MARIADB_SERVER formats accepted:
#   mariadb://user:pass@host:port/database
#   mariadb://user@host/database
#   mariadb://host/database
#   host
#   host:port
#   host/database
#   dbi:MariaDB:database=db;host=host
#   dbi:mysql:database=db;host=host
#
# Two PID-unique tables are created (primary + secondary) and dropped in END.
# Safe to run against a shared MariaDB instance.
#
# On the server:
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
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
	eval { require Database::Join };
	plan skip_all => 'Database::Join required' if $@;
}

use Readonly;
use Scalar::Util qw(refaddr);

# ---------------------------------------------------------------------------
# Parse MARIADB_SERVER into DSN + credentials
# ---------------------------------------------------------------------------
my ($DSN, $DB_USER, $DB_PASS) = _parse_server($ENV{MARIADB_SERVER});

sub _parse_server {
	my ($raw) = @_;

	return ($raw, undef, undef) if $raw =~ /\Adbi:/i;

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

	my $driver = defined $INC{'DBD/MariaDB.pm'} ? 'MariaDB' : 'mysql';
	my $dsn = "dbi:${driver}:database=${db};host=${host};port=${port}";
	return ($dsn, $user, $pass);
}

# ---------------------------------------------------------------------------
# Connect to MariaDB — skip all if unreachable
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

eval { $setup_dbh->ping() };
if ($@) {
	plan skip_all => "MariaDB connection not alive: $@";
}

# ---------------------------------------------------------------------------
# PID-unique table names to avoid collisions on shared servers
# ---------------------------------------------------------------------------
Readonly my $TABLE_A => sprintf 'djlive_%d_mA', $$;   # primary: entry/name/score/active
Readonly my $TABLE_B => sprintf 'djlive_%d_mB', $$;   # secondary: entry/tier/region

# ---------------------------------------------------------------------------
# Create test tables and populate fixture rows
# ---------------------------------------------------------------------------
$setup_dbh->do("DROP TABLE IF EXISTS `$TABLE_A`");
$setup_dbh->do(<<"SQL");
CREATE TABLE `$TABLE_A` (
	entry   VARCHAR(64)  NOT NULL PRIMARY KEY,
	name    VARCHAR(128) NOT NULL,
	score   INT          NOT NULL DEFAULT 0,
	active  TINYINT      NOT NULL DEFAULT 1
)
SQL

$setup_dbh->do("DROP TABLE IF EXISTS `$TABLE_B`");
$setup_dbh->do(<<"SQL");
CREATE TABLE `$TABLE_B` (
	entry   VARCHAR(64)  NOT NULL PRIMARY KEY,
	tier    VARCHAR(32)  NOT NULL,
	region  VARCHAR(32)  NOT NULL
)
SQL

# Primary fixture: 4 rows; row4 is absent from TABLE_B to create a left-join gap
my %FIXTURE_A = (
	row1 => { name => 'Alice', score => 10, active => 1 },
	row2 => { name => 'Bob',   score => 20, active => 1 },
	row3 => { name => 'Carol', score => 30, active => 0 },
	row4 => { name => 'Dave',  score => 40, active => 1 },
);

# Secondary fixture: 3 rows (row4 absent)
my %FIXTURE_B = (
	row1 => { tier => 'gold',   region => 'east'  },
	row2 => { tier => 'silver', region => 'west'  },
	row3 => { tier => 'bronze', region => 'north' },
);

for my $entry (sort keys %FIXTURE_A) {
	my $f = $FIXTURE_A{$entry};
	$setup_dbh->do(
		"INSERT INTO `$TABLE_A` (entry, name, score, active) VALUES (?, ?, ?, ?)",
		undef, $entry, $f->{name}, $f->{score}, $f->{active},
	);
}

for my $entry (sort keys %FIXTURE_B) {
	my $f = $FIXTURE_B{$entry};
	$setup_dbh->do(
		"INSERT INTO `$TABLE_B` (entry, tier, region) VALUES (?, ?, ?)",
		undef, $entry, $f->{tier}, $f->{region},
	);
}

END {
	if ($setup_dbh) {
		eval { $setup_dbh->do("DROP TABLE IF EXISTS `$TABLE_A`") };
		eval { $setup_dbh->do("DROP TABLE IF EXISTS `$TABLE_B`") };
		eval { $setup_dbh->disconnect() };
	}
}

# ---------------------------------------------------------------------------
# Inline test subclasses — class name derives the table name
# ---------------------------------------------------------------------------
{
	no strict 'refs';
	@{"Database::${TABLE_A}::ISA"} = ('Database::Abstraction');
	@{"Database::${TABLE_B}::ISA"} = ('Database::Abstraction');
}

# ---------------------------------------------------------------------------
# InlineDA — minimal stub for the non-MariaDB side in some join tests
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

my @INLINE_ROWS = (
	{ entry => 'row1', tier => 'gold',   region => 'east'  },
	{ entry => 'row2', tier => 'silver', region => 'west'  },
	{ entry => 'row3', tier => 'bronze', region => 'north' },
);

# ---------------------------------------------------------------------------
# Test plan
# ---------------------------------------------------------------------------
plan tests => 15;

# Helpers
sub _da_a {
	return "Database::${TABLE_A}"->new(
		dsn      => $DSN,
		username => $DB_USER,
		password => $DB_PASS,
		no_entry => 0,
	);
}

sub _da_b {
	return "Database::${TABLE_B}"->new(
		dsn      => $DSN,
		username => $DB_USER,
		password => $DB_PASS,
		no_entry => 0,
	);
}

sub _inline_da {
	return InlineDA->new(
		cols => [qw(entry tier region)],
		rows => [@INLINE_ROWS],
	);
}

sub _join {
	my (%extra) = @_;
	return Database::Join->new(
		databases   => [_da_a(), _inline_da()],
		join_column => 'entry',
		%extra,
	);
}

# ---------------------------------------------------------------------------
# L1 — connection and type
# ---------------------------------------------------------------------------
subtest 'L1: new() with MariaDB-backed DA connects successfully' => sub {
	plan tests => 2;
	my $join;
	lives_ok { $join = _join() } 'new() lives';
	cmp_ok($join->count(), '>=', 1, 'count() >= 1 after connecting');
};

# ---------------------------------------------------------------------------
# L2 — columns()
# ---------------------------------------------------------------------------
subtest 'L2: columns() returns merged columns from both DAs' => sub {
	plan tests => 3;
	my $join = _join();
	my $cols = $join->columns();
	returns_is($cols, { type => 'arrayref' }, 'columns() returns arrayref');
	my %col_set = map { $_ => 1 } @{$cols};
	ok($col_set{name}, 'MariaDB column name in merged columns()');
	ok($col_set{tier}, 'InlineDA column tier in merged columns()');
};

# ---------------------------------------------------------------------------
# L3–L4 — count()
# ---------------------------------------------------------------------------
subtest 'L3: count() correct for left join (4 MariaDB rows)' => sub {
	plan tests => 1;
	cmp_ok(_join()->count(), '==', 4, 'count() == 4 for left join');
};

subtest 'L4: count() correct for inner join (3 shared rows)' => sub {
	plan tests => 1;
	cmp_ok(_join(join_type => 'inner')->count(), '==', 3, 'count() == 3 for inner join');
};

# ---------------------------------------------------------------------------
# L5–L8 — selectall_arrayref
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
	is($rows->[0]{entry}, 'row1',  'entry correct');
	is($rows->[0]{name},  'Alice', 'name from MariaDB DA');
	is($rows->[0]{tier},  'gold',  'tier from InlineDA');
};

subtest 'L7: left join — MariaDB-only row has undef for InlineDA columns' => sub {
	plan tests => 2;
	my $rows = _join()->selectall_arrayref(entry => 'row4');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'row4 present in left join');
	ok(!defined $rows->[0]{tier}, 'tier undef for MariaDB-only row4');
};

subtest 'L8: inner join returns only rows present in both DAs' => sub {
	plan tests => 1;
	returns_is(_join(join_type => 'inner')->selectall_arrayref(),
		{ type => 'arrayref', min => 3, max => 3 },
		'inner join returns 3-row arrayref');
};

# ---------------------------------------------------------------------------
# L9–L10 — criteria routing
# ---------------------------------------------------------------------------
subtest 'L9: criteria on MariaDB column (name) routed to MariaDB DA' => sub {
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
# L11 — fetchrow_hashref
# ---------------------------------------------------------------------------
subtest 'L11: fetchrow_hashref() returns merged row' => sub {
	plan tests => 3;
	my $row = _join()->fetchrow_hashref('row2');
	returns_is($row, { type => 'hashref' }, 'fetchrow_hashref returns hashref');
	is($row->{name}, 'Bob',    'name from MariaDB DA');
	is($row->{tier}, 'silver', 'tier from InlineDA');
};

# ---------------------------------------------------------------------------
# L12–L13 — sort_by and limit
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
# L14 — idempotency and isolation
# ---------------------------------------------------------------------------
subtest 'L14: two independent join objects have independent data refs' => sub {
	plan tests => 3;
	my $j1 = _join();
	my $j2 = _join();
	cmp_ok($j1->count(), '==', 4, 'j1 count() == 4');
	cmp_ok($j2->count(), '==', 4, 'j2 count() == 4');
	isnt(refaddr($j1), refaddr($j2), 'j1 and j2 are distinct objects');
};

# ---------------------------------------------------------------------------
# L15 — join between two MariaDB-backed DAs (MariaDB + MariaDB)
# ---------------------------------------------------------------------------
subtest 'L15: join between two MariaDB-backed DAs works correctly' => sub {
	plan tests => 6;

	my $join = Database::Join->new(
		databases   => [_da_a(), _da_b()],
		join_column => 'entry',
	);

	# Left join: TABLE_A defines key set (4 rows); TABLE_B has row1-row3 only
	cmp_ok($join->count(), '==', 4, 'left join of two MariaDB DAs: count() == 4');

	my $cols = $join->columns();
	my %col_set = map { $_ => 1 } @{$cols};
	ok($col_set{name}, 'columns() includes TABLE_A column name');
	ok($col_set{tier}, 'columns() includes TABLE_B column tier');

	# row1 should have data from both tables
	my $row1 = $join->fetchrow_hashref('row1');
	returns_is($row1, { type => 'hashref' }, 'fetchrow_hashref returns hashref for row1');
	is($row1->{name}, 'Alice', 'name from TABLE_A');
	is($row1->{tier}, 'gold',  'tier from TABLE_B');
};
