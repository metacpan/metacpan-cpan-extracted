#!/usr/bin/env perl
use strict;
use warnings;

# MariaDB backend tests (no live server required).
# Pre-load DBI before any mock so lazy DBI->connect is intercepted cleanly.
use DBI;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;

# Skip if neither DBD::MariaDB nor DBD::mysql is installed.
BEGIN {
	my $have = eval { require DBD::MariaDB; 1 }
	        || eval { require DBD::mysql;   1 };
	plan skip_all => 'DBD::MariaDB or DBD::mysql required' unless $have;
}

plan tests => 15;

use lib 't/lib';
use Database::Abstraction;

# ---------------------------------------------------------------------------
# Inline test subclasses — class name → table name
# ---------------------------------------------------------------------------
{ package Database::mariadb_test; use base 'Database::Abstraction' }
{ package Database::mariadb_ne;   use base 'Database::Abstraction' }

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
use Readonly;
Readonly my $MARIADB_DSN => 'dbi:MariaDB:database=test;host=localhost';
Readonly my $MYSQL_DSN   => 'dbi:mysql:database=test;host=localhost';

my %FIXTURE = (
	row1 => { name => 'Alice', score => '10', active => '1' },
	row2 => { name => 'Bob',   score => '20', active => '1' },
	row3 => { name => 'Carol', score => '30', active => '0' },
);

# ---------------------------------------------------------------------------
# MockMariaDBSth — simulates a DBI statement handle
# ---------------------------------------------------------------------------
{
	package MockMariaDBSth;

	sub new {
		my ($class, %args) = @_;
		bless {
			_sql      => $args{sql}      // '',
			_all_rows => $args{all_rows} // [],
			_rows     => $args{pre_rows} // [],
			_pos      => 0,
			NAME      => $args{col_names} // [],
		}, $class;
	}

	sub execute {
		my ($self, @bind) = @_;
		my $sql = $self->{_sql};

		return 1 if $sql eq '_column_info';    # pre-built rows, nothing to do

		my $all = $self->{_all_rows};

		if($sql =~ /SELECT\s+COUNT\(([^)]+)\)/i) {
			my $col     = $1;
			my @matched = _filter($all, $sql, \@bind);
			$self->{_rows} = [{ "COUNT($col)" => scalar @matched }];

		} elsif($sql =~ /WHERE\s+1\s*=\s*0/i) {
			$self->{_rows} = [];                   # NAME was set in prepare_cached

		} elsif($sql =~ /\ASELECT\s+(?:DISTINCT\s+)?\*\s+FROM/i) {
			$self->{_rows} = [ _filter($all, $sql, \@bind) ];

		} else {
			# Single-column SELECT (AUTOLOAD path)
			my ($col) = $sql =~ /\ASELECT\s+(?:DISTINCT\s+)?(\w+)\s+FROM/i;
			$col //= 'entry';
			$self->{_rows} = [ map { [ $_->{$col} ] } _filter($all, $sql, \@bind) ];
		}

		$self->{_pos} = 0;
		return 1;
	}

	# Apply simple WHERE col = ? filters and a LIMIT clause.
	sub _filter {
		my ($all, $sql, $bind) = @_;
		my @rows      = @{$all};
		my @bind_copy = @{$bind};

		if($sql =~ /WHERE\s+((?:(?!ORDER\s+BY|LIMIT).)+)/is) {
			my $clause = $1;
			return () if $clause =~ /\A\s*1\s*=\s*0\s*\z/;
			for my $cond (split /\s+AND\s+/i, $clause) {
				if($cond =~ /\b(\w+)\s*(=|LIKE)\s*\?/i) {
					my ($col, $op) = ($1, uc($2));
					my $val = shift @bind_copy;
					if($op eq '=') {
						@rows = grep { defined $_->{$col} && "$_->{$col}" eq "$val" } @rows;
					} else {
						# LIKE: translate SQL wildcards to Perl regex
						my $pat = quotemeta($val);
						$pat =~ s/\\%/.*/g;
						$pat =~ s/\\_/./g;
						@rows = grep { defined $_->{$col} && "$_->{$col}" =~ /\A$pat\z/i } @rows;
					}
				}
			}
		}
		if($sql =~ /\bLIMIT\s+(\d+)/i && @rows > $1) {
			splice(@rows, $1);
		}
		return @rows;
	}

	sub fetchrow_arrayref {
		my $self = shift;
		return undef if $self->{_pos} >= scalar @{ $self->{_rows} };
		my $row = $self->{_rows}[ $self->{_pos}++ ];
		return ref($row) eq 'ARRAY' ? $row : [ values %{$row} ];
	}

	sub fetchrow_hashref {
		my $self = shift;
		return undef if $self->{_pos} >= scalar @{ $self->{_rows} };
		my $row = $self->{_rows}[ $self->{_pos}++ ];
		return ref($row) eq 'HASH' ? $row : undef;
	}

	sub fetchrow_array {
		my $self = shift;
		return () if $self->{_pos} >= scalar @{ $self->{_rows} };
		my $row = $self->{_rows}[ $self->{_pos}++ ];
		my @values = ref($row) eq 'ARRAY' ? @{$row} : values %{$row};
		return wantarray ? @values : $values[-1];
	}

	sub fetchall_arrayref {
		my ($self, $slice) = @_;
		# DBI fetchall_arrayref([0]) — return the pre-built [[$val], ...] rows as-is
		return $self->{_rows};
	}

	sub finish { 1 }
}

# ---------------------------------------------------------------------------
# MockMariaDBDbh — simulates a DBI database handle
# ---------------------------------------------------------------------------
{
	package MockMariaDBDbh;

	sub new {
		my ($class, %args) = @_;
		bless {
			Driver      => { Name => $args{driver_name} // 'MariaDB' },
			_fixture    => $args{fixture},    # hashref: entry => {col => val, ...}
			_no_entry   => $args{no_entry} // 0,
			_disconnect => 0,
		}, $class;
	}

	sub _build_rows {
		my $self = shift;
		if($self->{_no_entry}) {
			return [ values %{ $self->{_fixture} } ];
		}
		return [
			map { { entry => $_, %{ $self->{_fixture}{$_} } } }
			sort keys %{ $self->{_fixture} }
		];
	}

	sub _col_names {
		my $self = shift;
		my $first = (values %{ $self->{_fixture} })[0];
		return $self->{_no_entry}
			? [ sort keys %{$first} ]
			: [ sort('entry', keys %{$first}) ];
	}

	sub prepare_cached {
		my ($self, $sql) = @_;
		my $all_rows  = $self->_build_rows();
		my $col_names = $self->_col_names();
		return MockMariaDBSth->new(
			sql       => $sql,
			all_rows  => $all_rows,
			col_names => $col_names,
		);
	}

	sub column_info {
		my $self      = shift;
		my $col_names = $self->_col_names();
		my @rows      = map {
			{ COLUMN_NAME => $_, TYPE_NAME => 'VARCHAR', NULLABLE => 1, COLUMN_DEF => undef }
		} @{$col_names};
		return MockMariaDBSth->new(sql => '_column_info', pre_rows => \@rows);
	}

	sub disconnect { $_[0]->{_disconnect}++; 1 }
	sub quote_identifier { qq{"$_[1]"} }
}

# ---------------------------------------------------------------------------
# Helper: build a mock DBH and a mock_scoped guard on DBI->connect
# ---------------------------------------------------------------------------
sub _mock_dbh {
	my (%opts) = @_;
	my $dbh = MockMariaDBDbh->new(
		fixture    => $opts{fixture}  // \%FIXTURE,
		no_entry   => $opts{no_entry} // 0,
		driver_name => $opts{driver_name} // 'MariaDB',
	);
	my $guard = mock_scoped('DBI', 'connect' => sub { $dbh });
	return ($dbh, $guard);
}

# ---------------------------------------------------------------------------
# M1 — dbi:MariaDB: sets dialect to 'mysql'
# ---------------------------------------------------------------------------
subtest 'M1: dbi:MariaDB: DSN sets dialect to mysql' => sub {
	plan tests => 3;
	my ($dbh, $guard) = _mock_dbh();
	my $db;
	lives_ok { $db = Database::mariadb_test->new(dsn => $MARIADB_DSN) } 'new() lives';
	$db->count();
	is($db->{'type'},     'DBI',   'type is DBI');
	is($db->{'_dialect'}, 'mysql', 'dialect is mysql for dbi:MariaDB:');
};

# ---------------------------------------------------------------------------
# M2 — dbi:mysql: also sets dialect to 'mysql'
# ---------------------------------------------------------------------------
subtest 'M2: dbi:mysql: DSN also sets dialect to mysql' => sub {
	plan tests => 2;
	my ($dbh, $guard) = _mock_dbh();
	my $db = Database::mariadb_test->new(dsn => $MYSQL_DSN);
	$db->count();
	is($db->{'type'},     'DBI',   'type is DBI for dbi:mysql:');
	is($db->{'_dialect'}, 'mysql', 'dialect is mysql for dbi:mysql:');
};

# ---------------------------------------------------------------------------
# M3 — no data source croaks
# ---------------------------------------------------------------------------
subtest 'M3: constructor requires a data source' => sub {
	plan tests => 1;
	throws_ok { Database::mariadb_test->new() }
		qr/where are the files/i, 'no connection source croaks';
};

# ---------------------------------------------------------------------------
# M4 — count()
# ---------------------------------------------------------------------------
subtest 'M4: count() returns correct row count' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $db = Database::mariadb_test->new(dsn => $MARIADB_DSN);
	cmp_ok($db->count(), '==', 3, 'count() == 3');
};

subtest 'M5: count() with scalar criteria' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $db = Database::mariadb_test->new(dsn => $MARIADB_DSN);
	cmp_ok($db->count(active => '1'), '==', 2, 'count(active=>1) == 2');
};

# ---------------------------------------------------------------------------
# M6–M8 — selectall_arrayref
# ---------------------------------------------------------------------------
subtest 'M6: selectall_arrayref() returns all rows' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $db   = Database::mariadb_test->new(dsn => $MARIADB_DSN);
	my $rows = $db->selectall_arrayref();
	returns_is($rows, { type => 'arrayref', min => 3, max => 3 }, '3-row arrayref');
};

subtest 'M7: selectall_arrayref() with entry criteria' => sub {
	plan tests => 3;
	my ($dbh, $guard) = _mock_dbh();
	my $db   = Database::mariadb_test->new(dsn => $MARIADB_DSN);
	my $rows = $db->selectall_arrayref(entry => 'row1');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'one-row arrayref');
	is($rows->[0]{'entry'}, 'row1',  'entry key correct');
	is($rows->[0]{'name'},  'Alice', 'name field correct');
};

subtest 'M8: selectall_arrayref() returns empty for no match' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $db   = Database::mariadb_test->new(dsn => $MARIADB_DSN);
	my $rows = $db->selectall_arrayref(entry => 'nonexistent');
	returns_is($rows, { type => 'arrayref', min => 0, max => 0 }, 'empty arrayref for no match');
};

# ---------------------------------------------------------------------------
# M9–M10 — fetchrow_hashref
# ---------------------------------------------------------------------------
subtest 'M9: fetchrow_hashref() returns correct row' => sub {
	plan tests => 2;
	my ($dbh, $guard) = _mock_dbh();
	my $db  = Database::mariadb_test->new(dsn => $MARIADB_DSN);
	my $row = $db->fetchrow_hashref('row2');
	returns_is($row, { type => 'hashref' }, 'returns hashref');
	is($row->{'name'}, 'Bob', 'name is Bob');
};

subtest 'M10: fetchrow_hashref() returns undef for missing key' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $db = Database::mariadb_test->new(dsn => $MARIADB_DSN);
	returns_is($db->fetchrow_hashref('no_such_key'), { type => 'void' }, 'undef for missing key');
};

# ---------------------------------------------------------------------------
# M11 — AUTOLOAD scalar lookup
# ---------------------------------------------------------------------------
subtest 'M11: AUTOLOAD scalar lookup' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $db = Database::mariadb_test->new(dsn => $MARIADB_DSN);
	is($db->name(entry => 'row3'), 'Carol', 'AUTOLOAD scalar lookup returns Carol');
};

# ---------------------------------------------------------------------------
# M12 — columns()
# ---------------------------------------------------------------------------
subtest 'M12: columns() returns sorted column names' => sub {
	plan tests => 2;
	my ($dbh, $guard) = _mock_dbh();
	my $db   = Database::mariadb_test->new(dsn => $MARIADB_DSN);
	my $cols = $db->columns();
	returns_is($cols, { type => 'arrayref' }, 'columns() returns arrayref');
	is_deeply([sort @{$cols}], $cols, 'columns() in alphabetical order');
};

# ---------------------------------------------------------------------------
# M13 — schema() via column_info
# ---------------------------------------------------------------------------
subtest 'M13: schema() returns column metadata' => sub {
	plan tests => 3;
	my ($dbh, $guard) = _mock_dbh();
	my $db     = Database::mariadb_test->new(dsn => $MARIADB_DSN);
	my $schema = $db->schema();
	returns_is($schema, { type => 'hashref' }, 'schema() returns hashref');
	ok(exists $schema->{'name'},  'schema has name column');
	ok(exists $schema->{'score'}, 'schema has score column');
};

# ---------------------------------------------------------------------------
# M14 — no_entry mode
# ---------------------------------------------------------------------------
subtest 'M14: no_entry mode count and rows' => sub {
	plan tests => 3;
	my ($dbh, $guard) = _mock_dbh(no_entry => 1);
	my $db   = Database::mariadb_ne->new(dsn => $MARIADB_DSN, no_entry => 1);
	cmp_ok($db->count(), '==', 3, 'count() == 3 in no_entry mode');
	my $rows = $db->selectall_arrayref();
	returns_is($rows, { type => 'arrayref', min => 3, max => 3 }, '3-row arrayref in no_entry mode');
	ok(!exists $rows->[0]{'entry'}, 'no injected entry key in no_entry mode');
};

# ---------------------------------------------------------------------------
# M15 — idempotency
# ---------------------------------------------------------------------------
subtest 'M15: repeated count() is idempotent' => sub {
	plan tests => 2;
	my ($dbh, $guard) = _mock_dbh();
	my $db = Database::mariadb_test->new(dsn => $MARIADB_DSN);
	cmp_ok($db->count(), '==', 3, 'first count() == 3');
	cmp_ok($db->count(), '==', 3, 'second count() == 3');
};
