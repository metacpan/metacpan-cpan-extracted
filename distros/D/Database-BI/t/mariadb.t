#!/usr/bin/env perl
use strict;
use warnings;

# MariaDB backend tests for Database::BI, with no server: DBI->connect is mocked
# through Test::Mockingbird's mock_scoped.  See t/mariadb_live.t for a real one.
#
# The server is reached as a reader reaches it, through a mariadb_servers entry
# and mariadb:server/table.  t/mariadb_live.t runs the same against a real one.

# Pre-load DBI before any mock, so its lazy connect is intercepted cleanly.
use DBI;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use File::Temp qw(tempdir);
use Mojo::File;
use Mojo::JSON qw(decode_json);
use Mojo::Util;

BEGIN {
	my $have = eval { require DBD::MariaDB; 1 }
	        || eval { require DBD::mysql;   1 };
	plan skip_all => 'DBD::MariaDB or DBD::mysql required' unless $have;
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
	eval { require Database::Join };
	plan skip_all => 'Database::Join required' if $@;
}

use Test::Mojo;
use Readonly;

Readonly my $MARIADB_DSN => 'dbi:MariaDB:database=test;host=localhost';
Readonly my $TABLE       => 'orders';
Readonly my $SPEC        => "mariadb:mock/$TABLE";

my $data_dir = tempdir(CLEANUP => 1);
Mojo::File->new($data_dir)->child('tiers.csv')->spew(join("\n",
	'entry,tier',
	'row1,gold',
	'row2,silver',
	'row3,bronze',
) . "\n");


my $t = Test::Mojo->new('Database::BI', {
	data_dir  => $data_dir,
	mariadb_servers => { mock => { database => 'test', password => 'the-mock-password' } },
	model_dir => tempdir(CLEANUP => 1),
});
require Database::BI::Model::DataSource;
require Database::BI::Controller::Dashboard;

# ---------------------------------------------------------------------------
# Fixture: row4 is absent from tiers.csv and from InlineDA, for the join gaps
# ---------------------------------------------------------------------------
my %MARIADB_FIXTURE = (
	row1 => { region => 'North', amount => '10' },
	row2 => { region => 'South', amount => '20' },
	row3 => { region => 'North', amount => '5'  },
	row4 => { region => 'West',  amount => '40' },
);

my @INLINE_ROWS = (
	{ entry => 'row1', tier => 'gold'   },
	{ entry => 'row2', tier => 'silver' },
	{ entry => 'row3', tier => 'bronze' },
);

# ---------------------------------------------------------------------------
# MockMariaDBSth -- simulates a DBI statement handle
# ---------------------------------------------------------------------------
{
	package MockMariaDBSth;

	sub new {
		my ($class, %args) = @_;
		return bless {
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

		if ($sql =~ /GROUP\s+BY/i) {
			$self->{_rows} = _group($all, $sql);
		} elsif ($sql =~ /SELECT\s+COUNT\(([^)]+)\)/i) {
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

	# Database::Abstraction pushes aggregate() to any DBI handle, not only SQLite.
	# This reads the one shape it builds for a single measure over one column.
	sub _group {
		my ($all, $sql) = @_;
		my ($by, $fn, $col, $as) = $sql =~ /\ASELECT\s+(\w+),\s*(\w+)\(\s*(\w+|\*)\s*\)\s+AS\s+(\w+)\s+FROM/i
			or die "the mock cannot read: $sql\n";
		my %total;
		for my $row (@{$all}) {
			$total{ $row->{$by} } += uc($fn) eq 'COUNT' ? 1 : $row->{$col};
		}
		return [ map { { $by => $_, $as => $total{$_} } } sort keys %total ];
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
		return ref($row) eq 'HASH' ? { %{$row} } : undef;
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

	sub finish { return 1 }
}

# ---------------------------------------------------------------------------
# MockMariaDBDbh -- simulates a DBI database handle
# ---------------------------------------------------------------------------
{
	package MockMariaDBDbh;

	sub new {
		my ($class, %args) = @_;
		return bless {
			Driver   => { Name => 'MariaDB' },
			_fixture => $args{fixture},
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

	sub primary_key { return 'entry' }

	# What DataSource->mariadb_tables asks of information_schema.
	sub selectall_arrayref {
		my $self = shift;
		return [ map { [ 'orders', $_ ] } @{ $self->_col_names() } ];
	}

	sub prepare { my $self = shift; return $self->prepare_cached(@_) }

	sub prepare_cached {
		my ($self, $sql) = @_;
		return MockMariaDBSth->new(
			sql       => $sql,
			all_rows  => $self->_build_rows(),
			col_names => $self->_col_names(),
		);
	}

	sub column_info {
		my $self = shift;
		my @rows = map {
			{ COLUMN_NAME => $_, TYPE_NAME => 'VARCHAR', NULLABLE => 1, COLUMN_DEF => undef }
		} @{ $self->_col_names() };
		return MockMariaDBSth->new(sql => '_column_info', pre_rows => \@rows);
	}

	sub disconnect { return 1 }
	sub quote_identifier { return qq{"$_[1]"} }
}

sub _mock_dbh {
	my $dbh = MockMariaDBDbh->new(fixture => \%MARIADB_FIXTURE);
	return ($dbh, mock_scoped('DBI', connect => sub { $dbh }));
}

# ---------------------------------------------------------------------------
# InlineDA -- the non-MariaDB side of a join
# ---------------------------------------------------------------------------
{
	package InlineDA;

	sub new {
		my ($class, %args) = @_;
		return bless { _cols => $args{cols} // [], _rows => $args{rows} // [] }, $class;
	}

	sub columns    { return $_[0]->{_cols} }
	sub schema     { return {} }
	sub updated    { return 1 }
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
	return InlineDA->new(cols => [qw(entry tier)], rows => [@INLINE_ROWS]);
}

# A DataSource over the mocked server, as _open_spec builds it.
sub _maria_source {
	return Database::BI::Model::DataSource->new(table => $TABLE, server => 'mock', mariadb => { database => 'test' });
}

# The rows behind a page, without reading them back out of its markup.
sub _export_rows {
	my ($query) = @_;
	$t->get_ok("/export?$query&format=json")->status_is(200);
	return decode_json($t->tx->res->body);
}

plan tests => 23;

# ---------------------------------------------------------------------------
# The DataSource methods
# ---------------------------------------------------------------------------
subtest 'M1: a DataSource holds a MariaDB-backed backend' => sub {
	plan tests => 3;
	my ($dbh, $guard) = _mock_dbh();
	my $src;
	lives_ok { $src = _maria_source() } 'it can be built';
	is($src->table_name, $TABLE, 'table_name');
	is($src->id_column, 'entry', 'id_column');
};

subtest 'M2: columns() lists the columns' => sub {
	plan tests => 2;
	my ($dbh, $guard) = _mock_dbh();
	my $cols = _maria_source()->columns;
	returns_is($cols, { type => 'arrayref' }, 'an arrayref');
	is_deeply([ sort @{$cols} ], [qw(amount entry region)], 'with every column');
};

subtest 'M3: fetch_all and selectall_arrayref return the rows' => sub {
	plan tests => 4;
	my ($dbh, $guard) = _mock_dbh();
	my $src = _maria_source();
	my $all = $src->fetch_all;
	returns_is($all, { type => 'arrayref', min => 4, max => 4 }, 'fetch_all: 4 rows');
	my ($row1) = grep { $_->{entry} eq 'row1' } @{$all};
	is($row1->{region}, 'North', 'with their values');
	returns_is($src->selectall_arrayref, { type => 'arrayref', min => 4, max => 4 }, 'selectall_arrayref: 4 rows');
	cmp_ok($src->count, '==', 4, 'count');
};

subtest 'M4: selectall_arrayref takes criteria as a hashref, as Database::Join sends them' => sub {
	plan tests => 2;
	my ($dbh, $guard) = _mock_dbh();
	my $rows = _maria_source()->selectall_arrayref({ entry => 'row2' });
	returns_is($rows, { type => 'arrayref', min => 1, max => 1 }, 'one row');
	is($rows->[0]{region}, 'South', 'the right one');
};

subtest 'M5: dbi_source() does not claim a SQL backend the application can push to' => sub {
	plan tests => 1;
	my ($dbh, $guard) = _mock_dbh();
	is(_maria_source()->dbi_source, undef, 'only SQLite answers');
};

# ---------------------------------------------------------------------------
# Database::Join
# ---------------------------------------------------------------------------
sub _join {
	my (%extra) = @_;
	return Database::Join->new(
		databases   => [ _maria_source(), _inline_da() ],
		join_column => 'entry',
		%extra,
	);
}

subtest 'M6: Database::Join takes the DataSource, and merges its columns' => sub {
	plan tests => 2;
	my ($dbh, $guard) = _mock_dbh();
	my $cols = _join()->columns;
	returns_is($cols, { type => 'arrayref' }, 'columns() is an arrayref');
	my %have = map { $_ => 1 } @{$cols};
	ok($have{region} && $have{tier}, 'with a column from each side');
};

subtest 'M7: left, inner and outer joins count the right rows' => sub {
	plan tests => 3;
	my ($dbh, $guard) = _mock_dbh();
	cmp_ok(_join()->count, '==', 4, 'left: every MariaDB row');
	cmp_ok(_join(join_type => 'inner')->count, '==', 3, 'inner: the rows on both sides');
	cmp_ok(scalar @{ _join(join_type => 'outer')->selectall_arrayref }, '==', 4, 'outer: the union');
};

subtest 'M8: a merged row holds both sides, and a gap on the right is undef' => sub {
	plan tests => 4;
	my ($dbh, $guard) = _mock_dbh();
	my $rows = _join()->selectall_arrayref;
	my %by = map { $_->{entry} => $_ } @{$rows};
	is($by{row1}{region}, 'North', 'the MariaDB value');
	is($by{row1}{tier},   'gold',  'the other value');
	ok(exists $by{row4}, 'a row with no match stays in a left join');
	ok(!defined $by{row4}{tier}, 'with nothing from the right');
};

# ---------------------------------------------------------------------------
# Through the routes
# ---------------------------------------------------------------------------
subtest 'M9: /join and /view draw the table' => sub {
	plan tests => 9;
	my ($dbh, $guard) = _mock_dbh();
	for my $url ("/join?l=$SPEC", "/open?path=$SPEC") {
		$t->get_ok($url)->status_is(200);
		my $body = $t->tx->res->body;
		unlike($body, qr/\Qdbi:MariaDB\E/, "$url does not show the DSN");
		like($body, qr{<td[^>]*>North</td>}, "$url shows a value");
	}
	like($t->tx->res->body, qr{<td[^>]*>row4</td>}, 'and the last row');
};

subtest 'M10: /export gives every row' => sub {
	plan tests => 4;
	my ($dbh, $guard) = _mock_dbh();
	my $rows = _export_rows("l=$SPEC");
	is(scalar @{$rows}, 4, 'all of them');
	is_deeply([ sort map { $_->{entry} } @{$rows} ], [qw(row1 row2 row3 row4)], 'each one once');
};

subtest 'M11: a filter is applied, case-insensitively' => sub {
	plan tests => 3;
	my ($dbh, $guard) = _mock_dbh();
	my $rows = _export_rows("l=$SPEC&f=region:eq:north");
	is_deeply([ sort map { $_->{entry} } @{$rows} ], [qw(row1 row3)], 'only the North rows');
};

subtest 'M19: every way of paging leaves the read-only array alone' => sub {
	plan tests => 12;
	my ($dbh, $guard) = _mock_dbh();
	for my $query ("/open?path=$SPEC&per_page=2", "/open?path=$SPEC&per_page=2&page=2", "/open?path=$SPEC&d=1", "/open?path=$SPEC&page=9",
		"/join?l=$SPEC&per_page=2", "/combine?l=$SPEC&c=table:tiers") {
		$t->get_ok($query);
		unlike($t->tx->res->body, qr/Modification of a read-only/, "$query is not refused");
	}
};

subtest 'M12: /bar totals by category, in Perl and with the fold forced' => sub {
	plan tests => 7;
	my ($dbh, $guard) = _mock_dbh();
	my $url = "/bar?l=$SPEC&cat=region&val=amount";
	$t->get_ok($url)->status_is(200);
	my $default = $t->tx->res->body;
	like($default, qr/North/, 'the category is drawn');
	like($default, qr/\b15\b/, 'North is 10 + 5');
	{
		local $ENV{BI_FORCE_PERL_AGG} = 1;
		$t->get_ok($url)->status_is(200);
		like($t->tx->res->body, qr/\b15\b/, 'the forced path agrees');
	}
};

subtest 'M13: /pivot draws the backend' => sub {
	plan tests => 3;
	my ($dbh, $guard) = _mock_dbh();
	$t->get_ok("/pivot?l=$SPEC&rows=region&m=" . Mojo::Util::url_escape('amount:sum:total'))->status_is(200);
	like($t->tx->res->body, qr/North/, 'a row of the pivot');
};

subtest 'M14: a Merge with a CSV file runs the whole pipeline' => sub {
	plan tests => 9;
	my ($dbh, $guard) = _mock_dbh();
	my $rows = _export_rows("l=$SPEC&j=table:tiers|entry|entry");
	is(scalar @{$rows}, 4, 'left: every MariaDB row');
	my %by = map { $_->{entry} => $_ } @{$rows};
	is($by{row1}{tier}, 'gold', 'a value from the file');
	is($by{row1}{region}, 'North', 'beside a value from the backend');
	ok(!defined $by{row4}{tier} || !length $by{row4}{tier}, 'and a gap where the file has no row');

	$rows = _export_rows("l=$SPEC&j=table:tiers|entry|entry&jtype=inner");
	is(scalar @{$rows}, 3, 'inner: only the rows on both sides');
};

# ---------------------------------------------------------------------------
# What a reader cannot do
# ---------------------------------------------------------------------------
subtest 'M15: a spec names a configured server, and never an address' => sub {
	plan tests => 11;
	my $ctrl = $t->app->build_controller;
	my $open = \&Database::BI::Controller::Dashboard::_open_spec;
	my $connected = 0;
	my $guard = mock_scoped('DBI', connect => sub { $connected++; return });
	for my $spec ('mariadb:orders|mariadb://root:secret@db/test', 'mariadb://root:secret@db/test',
		'mariadb:shop/a;b', 'mariadb:../orders', 'dbi:MariaDB:database=test;host=db') {
		my @got = $open->($ctrl, $spec);
		is(scalar @got, 0, "_open_spec opens nothing for $spec");
	}
	is($connected, 0, 'and nothing connected');

	$t->post_ok('/api/analyses' => json => {
		name     => 'Maria',
		datasets => [ { spec => 'mariadb:orders|mariadb://root:secret@db/test' } ],
	})->status_is(400);
	like($t->tx->res->body, qr/not a valid spec/, 'a canvas cannot save an address either');

	$t->post_ok('/api/analyses' => json => { name => 'Maria', datasets => [ { spec => $SPEC } ] })->status_is(201);
};

subtest 'M20: a server that is not configured says so' => sub {
	plan tests => 6;
	my $connected = 0;
	my $guard = mock_scoped('DBI', connect => sub { $connected++; return });
	$t->get_ok('/open?path=mariadb:nosuch/orders')->status_is(200)
	  ->content_like(qr/no MariaDB server is called/, 'the page says what is wrong');
	$t->get_ok('/tables?l=mariadb:nosuch')
	  ->content_like(qr/no MariaDB server is called/, 'the list says so too');
	is($connected, 0, 'and nothing connected');
};

subtest 'M21: the home page names servers, and keeps their settings to itself' => sub {
	plan tests => 7;
	$t->get_ok('/')->status_is(200)
	  ->content_like(qr{href="/tables\?l=mariadb:mock"}, 'a link to the server')
	  ->content_unlike(qr/the-mock-password/, 'but not its password');
	my ($dbh, $guard) = _mock_dbh();
	$t->get_ok('/tables?l=mariadb:mock')->content_like(qr/table-card-name/, 'the list has a card');
	$t->tx->res->body =~ /the-mock-password/ ? fail('the password is on the list') : pass('with no password');
};

subtest 'M22: the columns API and every source field know the spec' => sub {
	plan tests => 6;
	my ($dbh, $guard) = _mock_dbh();
	$t->get_ok("/api/columns?spec=$SPEC")->status_is(200)
	  ->json_is('/columns/0' => 'amount', 'the Merge panel can read its columns');
	my $rows = _export_rows("l=$SPEC&c=$SPEC");
	ok(scalar @{$rows}, 'and c= stacks it, rather than taking it for a calculated field');
};

subtest 'M16: a server that cannot be reached is a page, not an exception' => sub {
	plan tests => 3;
	my $guard = mock_scoped('DBI', connect => sub { return });
	$t->get_ok("/open?path=$SPEC");
	cmp_ok($t->tx->res->code, '<', 500, 'no 500');
	unlike($t->tx->res->body, qr/\.pm line \d+/, 'and no source location in the message');
};

subtest 'M17: a query that fails reports the table, not a stack' => sub {
	plan tests => 2;
	my ($dbh, $guard) = _mock_dbh();
	my $src = _maria_source();
	my $bad = mock_scoped('MockMariaDBSth', execute => sub { die "Table 'test.orders' doesn't exist\n" });
	throws_ok { $src->fetch_all } qr/\Q$TABLE\E/, 'fetch_all names the table';
	throws_ok { $src->selectall_arrayref } qr/./, 'selectall_arrayref does not swallow it';
};

subtest 'M18: rows that come back from the backend can be extended' => sub {
	plan tests => 4;
	my ($dbh, $guard) = _mock_dbh();
	# A calculated column writes to each row: on a locked hash that must go
	# through _extend_row, or the page is a 500.
	my $rows = _export_rows("l=$SPEC&c=" . Mojo::Util::url_escape('double:amount*2'));
	my ($row1) = grep { $_->{entry} eq 'row1' } @{$rows};
	is($row1->{double}, 20, 'the new column is there');
	is($row1->{amount}, 10, 'beside the old one');
};

subtest 'M23: /open on a server draws a calculated field, and can filter on it' => sub {
	plan tests => 9;
	my ($dbh, $guard) = _mock_dbh();
	$t->get_ok("/open?path=$SPEC&c=double:amount*2")->status_is(200)
		->content_like(qr{<td[^>]*>\s*20\s*</td>}, 'the column is on the page');
	$t->get_ok("/open?path=$SPEC&c=double:amount*2&f=double:gt:1000000")->status_is(200)
		->content_unlike(qr{<td[^>]*>\s*20\s*</td>}, 'and a filter on it selects');
	$t->get_ok("/open?path=$SPEC&c=double:nosuch*2")->status_is(400)
		->content_like(qr/Unknown column 'nosuch'/, 'a field that cannot run is a 400');
};
