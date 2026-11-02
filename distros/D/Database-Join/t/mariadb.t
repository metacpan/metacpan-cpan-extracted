#!/usr/bin/env perl
use strict;
use warnings;

# MariaDB backend tests for Database::Join.
#
# Tests a join between a MariaDB-backed Database::Abstraction subclass (dj_mA)
# and a static in-memory DA (InlineDA) with no real MariaDB server needed.
# MariaDB is mocked via Test::Mockingbird's mock_scoped on DBI->connect.
#
# Pre-load DBI before any mock so lazy DBI->connect is intercepted cleanly.
use DBI;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;

BEGIN {
	my $have = eval { require DBD::MariaDB; 1 }
	        || eval { require DBD::mysql;   1 };
	plan skip_all => 'DBD::MariaDB or DBD::mysql required' unless $have;
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
	eval { require Database::Join };
	plan skip_all => 'Database::Join required' if $@;
}

plan tests => 13;

# ---------------------------------------------------------------------------
# DA stub: table name derived from class => dj_mA (columns: entry/name/score/active)
# ---------------------------------------------------------------------------
{ package Database::dj_mA; use base 'Database::Abstraction' }

use Readonly;
Readonly my $MARIADB_DSN => 'dbi:MariaDB:database=test;host=localhost';

# Fixture for the MariaDB-backed DA: entry => { name, score, active }
# row4 is absent from InlineDA to create a left-join gap.
my %MARIADB_FIXTURE = (
	row1 => { name => 'Alice', score => '10', active => '1' },
	row2 => { name => 'Bob',   score => '20', active => '1' },
	row3 => { name => 'Carol', score => '30', active => '0' },
	row4 => { name => 'Dave',  score => '40', active => '1' },
);

# Fixture for the in-memory DA: covers row1-row3 only (row4 absent → left join gap)
my @INLINE_ROWS = (
	{ entry => 'row1', tier => 'gold',   region => 'east'  },
	{ entry => 'row2', tier => 'silver', region => 'west'  },
	{ entry => 'row3', tier => 'bronze', region => 'north' },
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

		return 1 if $sql eq '_column_info';

		my $all = $self->{_all_rows};

		if ($sql =~ /SELECT\s+COUNT\(([^)]+)\)/i) {
			my $col     = $1;
			my @matched = _filter($all, $sql, \@bind);
			$self->{_rows} = [{ "COUNT($col)" => scalar @matched }];
		} elsif ($sql =~ /WHERE\s+1\s*=\s*0/i) {
			$self->{_rows} = [];
		} elsif ($sql =~ /\ASELECT\s+(?:DISTINCT\s+)?\*\s+FROM/i) {
			$self->{_rows} = [ _filter($all, $sql, \@bind) ];
		} else {
			my ($col) = $sql =~ /\ASELECT\s+(?:DISTINCT\s+)?(\w+)\s+FROM/i;
			$col //= 'entry';
			$self->{_rows} = [ map { [ $_->{$col} ] } _filter($all, $sql, \@bind) ];
		}

		$self->{_pos} = 0;
		return 1;
	}

	sub _filter {
		my ($all, $sql, $bind) = @_;
		my @rows      = @{$all};
		my @bind_copy = @{$bind};

		if ($sql =~ /WHERE\s+((?:(?!ORDER\s+BY|LIMIT).)+)/is) {
			my $clause = $1;
			return () if $clause =~ /\A\s*1\s*=\s*0\s*\z/;
			for my $cond (split /\s+AND\s+/i, $clause) {
				if ($cond =~ /\b(\w+)\s*(=|LIKE)\s*\?/i) {
					my ($col, $op) = ($1, uc($2));
					my $val = shift @bind_copy;
					if ($op eq '=') {
						@rows = grep { defined $_->{$col} && "$_->{$col}" eq "$val" } @rows;
					} else {
						my $pat = quotemeta($val);
						$pat =~ s/\\%/.*/g;
						$pat =~ s/\\_/./g;
						@rows = grep { defined $_->{$col} && "$_->{$col}" =~ /\A$pat\z/i } @rows;
					}
				}
			}
		}
		if ($sql =~ /\bLIMIT\s+(\d+)/i && @rows > $1) {
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
			_fixture    => $args{fixture},
			_disconnect => 0,
		}, $class;
	}

	sub _build_rows {
		my $self = shift;
		return [
			map { { entry => $_, %{ $self->{_fixture}{$_} } } }
			sort keys %{ $self->{_fixture} }
		];
	}

	sub _col_names {
		my $self  = shift;
		my $first = (values %{ $self->{_fixture} })[0];
		return [ sort('entry', keys %{$first}) ];
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

# Helper: build a mock DBH and a mock_scoped guard on DBI->connect
sub _mock_dbh {
	my (%opts) = @_;
	my $dbh = MockMariaDBDbh->new(
		fixture     => $opts{fixture}     // \%MARIADB_FIXTURE,
		driver_name => $opts{driver_name} // 'MariaDB',
	);
	my $guard = mock_scoped('DBI', 'connect' => sub { $dbh });
	return ($dbh, $guard);
}

# ---------------------------------------------------------------------------
# InlineDA — minimal blessed stub for the non-MariaDB side of the join.
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

sub _inline_da {
	return InlineDA->new(
		cols => [qw(entry tier region)],
		rows => [@INLINE_ROWS],
	);
}

# ---------------------------------------------------------------------------
# M1 — constructor
# ---------------------------------------------------------------------------
subtest 'M1: Database::Join accepts a MariaDB-backed DA' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	lives_ok {
		Database::Join->new(
			databases   => [$mariadb_da, _inline_da()],
			join_column => 'entry',
		);
	} 'new() with MariaDB DA lives';
};

# ---------------------------------------------------------------------------
# M2 — columns() and schema()
# ---------------------------------------------------------------------------
subtest 'M2: columns() returns merged columns from both DAs' => sub {
	plan tests => 3;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	my $join = Database::Join->new(
		databases   => [$mariadb_da, _inline_da()],
		join_column => 'entry',
	);
	my $cols = $join->columns();
	returns_is($cols, { type => 'arrayref' }, 'columns() returns arrayref');
	my %col_set = map { $_ => 1 } @{$cols};
	ok($col_set{name}, 'columns() includes MariaDB column name');
	ok($col_set{tier}, 'columns() includes InlineDA column tier');
};

# ---------------------------------------------------------------------------
# M3–M4 — count()
# ---------------------------------------------------------------------------
subtest 'M3: count() == 4 for left join (primary is MariaDB, 4 rows)' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	my $join = Database::Join->new(
		databases   => [$mariadb_da, _inline_da()],
		join_column => 'entry',
	);
	cmp_ok($join->count(), '==', 4, 'count() == 4 for left join');
};

subtest 'M4: count() == 3 for inner join (intersection of MariaDB and InlineDA keys)' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	my $join = Database::Join->new(
		databases   => [$mariadb_da, _inline_da()],
		join_column => 'entry',
		join_type   => 'inner',
	);
	cmp_ok($join->count(), '==', 3, 'count() == 3 for inner join');
};

# ---------------------------------------------------------------------------
# M5–M9 — selectall_arrayref
# ---------------------------------------------------------------------------
subtest 'M5: selectall_arrayref() returns all rows for left join' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	my $join = Database::Join->new(
		databases   => [$mariadb_da, _inline_da()],
		join_column => 'entry',
	);
	returns_is($join->selectall_arrayref(), { type => 'arrayref', min => 4, max => 4 },
		'selectall_arrayref() returns 4-row arrayref');
};

subtest 'M6: selectall_arrayref(entry) returns correct merged row' => sub {
	plan tests => 4;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	my $join = Database::Join->new(
		databases   => [$mariadb_da, _inline_da()],
		join_column => 'entry',
	);
	my $rows = $join->selectall_arrayref(entry => 'row1');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'one row for entry=row1');
	is($rows->[0]{entry}, 'row1',  'entry field correct');
	is($rows->[0]{name},  'Alice', 'name from MariaDB correct');
	is($rows->[0]{tier},  'gold',  'tier from InlineDA correct');
};

subtest 'M7: left join — MariaDB-only row has undef for InlineDA columns' => sub {
	plan tests => 2;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	my $join = Database::Join->new(
		databases   => [$mariadb_da, _inline_da()],
		join_column => 'entry',
	);
	my $rows = $join->selectall_arrayref(entry => 'row4');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'row4 present in left join');
	ok(!defined $rows->[0]{tier}, 'tier undef for MariaDB-only row4');
};

subtest 'M8: inner join returns only rows present in both DAs' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	my $join = Database::Join->new(
		databases   => [$mariadb_da, _inline_da()],
		join_column => 'entry',
		join_type   => 'inner',
	);
	returns_is($join->selectall_arrayref(), { type => 'arrayref', min => 3, max => 3 },
		'inner join returns 3-row arrayref');
};

subtest 'M9: outer join returns all rows from both DAs' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	my $join = Database::Join->new(
		databases   => [$mariadb_da, _inline_da()],
		join_column => 'entry',
		join_type   => 'outer',
	);
	# InlineDA only has row1-row3; MariaDB has row1-row4 → outer union = row1-row4
	returns_is($join->selectall_arrayref(), { type => 'arrayref', min => 4, max => 4 },
		'outer join returns 4-row arrayref');
};

# ---------------------------------------------------------------------------
# M10–M11 — criteria routing
# ---------------------------------------------------------------------------
subtest 'M10: criteria on MariaDB column routed to MariaDB DA' => sub {
	plan tests => 2;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	my $join = Database::Join->new(
		databases   => [$mariadb_da, _inline_da()],
		join_column => 'entry',
	);
	my $rows = $join->selectall_arrayref(name => 'Alice');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 },
		'name=Alice returns 1 row');
	is($rows->[0]{name}, 'Alice', 'correct row returned for MariaDB column criterion');
};

subtest 'M11: criteria on InlineDA column routed to InlineDA' => sub {
	plan tests => 2;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	my $join = Database::Join->new(
		databases   => [$mariadb_da, _inline_da()],
		join_column => 'entry',
	);
	my $rows = $join->selectall_arrayref(tier => 'gold');
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 },
		'tier=gold returns 1 row');
	is($rows->[0]{tier}, 'gold', 'correct row returned for InlineDA column criterion');
};

# ---------------------------------------------------------------------------
# M12 — fetchrow_hashref
# ---------------------------------------------------------------------------
subtest 'M12: fetchrow_hashref() returns merged row from MariaDB + InlineDA' => sub {
	plan tests => 3;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	my $join = Database::Join->new(
		databases   => [$mariadb_da, _inline_da()],
		join_column => 'entry',
	);
	my $row = $join->fetchrow_hashref('row2');
	returns_is($row, { type => 'hashref' }, 'fetchrow_hashref returns hashref');
	is($row->{name}, 'Bob',    'name from MariaDB');
	is($row->{tier}, 'silver', 'tier from InlineDA');
};

# ---------------------------------------------------------------------------
# M13 — set_logger propagation
# ---------------------------------------------------------------------------
subtest 'M13: set_logger propagated to MariaDB DA without error' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	my $mariadb_da = Database::dj_mA->new(dsn => $MARIADB_DSN);
	my $join = Database::Join->new(
		databases   => [$mariadb_da, _inline_da()],
		join_column => 'entry',
	);
	lives_ok { $join->set_logger('debug') } 'set_logger lives with MariaDB DA';
};
