use strict;
use warnings;
use Test::Most;
use Test::Mojo;
use Test::Mockingbird	qw(mock restore_all);
use Readonly;
use File::Spec		();
use File::Temp		qw(tempdir);
use Mojo::File		();
use Encode		qw(decode);
use Scalar::Util	qw(blessed);

# ------------------------------------------------------------------
# Bootstrap: app loaded FIRST so modules enter %INC via require
# (post-CHECK), keeping :Private stash entries intact for direct calls.
# ------------------------------------------------------------------
my $t = Test::Mojo->new('Database::BI');
require Database::BI::Model::DataSource;
require Database::BI::Controller::Dashboard;
require Database::BI::Model::Geocode;

# The model store (.bi/) is shared state in the checkout: give this file its
# own directory, so a parallel run cannot create, read or write it underneath.
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

# Direct references to :Private package functions (intact post-CHECK).
my $DETECT_INFO  = \&Database::BI::Model::DataSource::_detect_file_info;
my $URL_LABEL    = \&Database::BI::Model::DataSource::_url_label;
my $CACHE_KEY    = \&Database::BI::Model::DataSource::_cache_key;
my $VALUES_LIKE  = \&Database::BI::Model::DataSource::_values_are_data_like;
my $SYNTH_COLS   = \&Database::BI::Model::DataSource::_synthesize_col_names;
my $WRITE_SQLITE = \&Database::BI::Controller::Dashboard::_write_sqlite_db;
my $SERIALIZE    = \&Database::BI::Controller::Dashboard::_serialize_csv;
my $FILTER       = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
my $CSV_ROW      = \&Database::BI::Controller::Dashboard::_csv_row;
my $DEDUP        = \&Database::BI::Controller::Dashboard::_dedup_records;
my $COMBINE      = \&Database::BI::Controller::Dashboard::_combine_tables;
my $GET_COLS     = \&Database::BI::Controller::Dashboard::_get_columns;
my $BUILD_URL    = \&Database::BI::Controller::Dashboard::_build_export_url;
my $IS_SAFE      = \&Database::BI::Controller::Dashboard::_is_safe_url;
my $SAFE_BACK    = \&Database::BI::Controller::Dashboard::_safe_back_url;
my $HAS_POSITION = \&Database::BI::Model::Geocode::_has_position;
my $COORDINATES  = \&Database::BI::Model::Geocode::_coordinates;
my $BACKEND_OF   = \&Database::BI::Model::Geocode::_backend_of;

Readonly my $DIR  => tempdir(CLEANUP => 1);

# Fixed sample dataset -- column order matters for header assertions.
Readonly my @RECS => (
	{ name => 'Alice', amount => '500', region => 'North' },
	{ name => 'Bob',   amount => '100', region => 'South' },
	{ name => 'Carol', amount => '300', region => 'North' },
);
Readonly my @COLS => qw(name amount region);

# ======================================================================
# Geocode stub packages (duck-typed; no Geo::Coder::Free needed).
# Used by sections 22-34.
# ======================================================================

{
	package DF::GeoPoint;
	# Minimal Geo::Location::Point-like object providing lat/lon/database.
	sub new {
		my ($class, %args) = @_;
		return bless \%args, $class;
	}
	sub latitude  { return $_[0]->{lat} }
	sub longitude { return $_[0]->{lon} }
	sub database  { return $_[0]->{database} }
}

{
	package DF::Geocoder;
	# Known-answers geocoder: returns DF::GeoPoint for recognised cities.
	# Increments $self->{calls} on each geocode_many invocation.
	sub new {
		my ($class, %known) = @_;
		return bless { known => \%known, calls => 0 }, $class;
	}
	sub valid_location {
		my ($self, $v) = @_;
		return 0 unless defined($v) && length($v);
		return 0 if $v =~ /\A\d+\z/;
		return 1;
	}
	sub geocode_many {
		my ($self, $places, %opts) = @_;
		$self->{calls}++;
		my %batch;
		for my $p (@{$places}) {
			$batch{$p} = $self->{known}{$p} if exists $self->{known}{$p};
		}
		return \%batch;
	}
}

{
	package DF::MissGeocoder;
	# All-miss geocoder: valid_location is permissive; geocode_many returns {}.
	sub new            { return bless { calls => 0 }, shift }
	sub valid_location {
		my ($self, $v) = @_;
		return defined($v) && length($v) && $v !~ /\A\d+\z/ ? 1 : 0;
	}
	sub geocode_many {
		my ($self, $places, %opts) = @_;
		$self->{calls}++;
		return {};
	}
}

{
	package DF::CountGeocoder;
	# Reports a custom 'lookups' integer; all values are misses (no position).
	sub new            { return bless { report_lookups => $_[1] }, $_[0] }
	sub valid_location { return 1 }
	sub geocode_many {
		my ($self, $places, %opts) = @_;
		return { lookups => $self->{report_lookups} };
	}
}

# Coordinates for two known English seaside towns, used throughout sections 22-34.
Readonly my $RAM_LAT =>  51.336;
Readonly my $RAM_LON =>   1.416;
Readonly my $MAR_LAT =>  51.384;
Readonly my $MAR_LON =>   1.386;

# _fresh_geo() -> ($geo, $gc)
#
# Creates a fresh Geocode object and its DF::Geocoder each call, so that the
# geocoder's call counter ($gc->{calls}) starts at 0 for every subtest.
sub _fresh_geo {
	my $gc = DF::Geocoder->new(
		Ramsgate => DF::GeoPoint->new(lat => $RAM_LAT, lon => $RAM_LON, database => 'stub'),
		Margate  => DF::GeoPoint->new(lat => $MAR_LAT, lon => $MAR_LON, database => 'stub'),
	);
	my $geo = Database::BI::Model::Geocode->new(geocoder => $gc, openaddr => 'test');
	return ($geo, $gc);
}

# ======================================================================
# Section 1: _detect_file_info -- file handle Open-Use-Close lifecycle
#
# DU chain: $fh D:270(declare) -> D:271(open) -> U:272(readline) ->
#           U:273(close) -> [next] -> no further use.
# close(273) is unconditional and precedes any "next" guard, so the
# handle is never left open even when readline returns undef.
# ======================================================================

subtest '_detect_file_info -- returns {} when no CSV or PSV file exists' => sub {
	my $info = $DETECT_INFO->($DIR, 'nosuchfile');
	is_deeply $info, {}, 'empty hashref for table with no csv/psv file';
};

subtest '_detect_file_info -- CSV header: sep_char, id, and columns populated' => sub {
	Mojo::File->new("$DIR/alpha.csv")->spew("id,name,amount\n1,Alice,500\n");
	my $info = $DETECT_INFO->($DIR, 'alpha');
	is   $info->{sep_char},  ',',                    'sep_char is comma for CSV';
	is   $info->{id},        'id',                   'id is first column name';
	is_deeply $info->{columns}, [qw(id name amount)], 'columns in header order';
};

subtest '_detect_file_info -- PSV header: sep_char forced to pipe, not sniffed' => sub {
	Mojo::File->new("$DIR/beta.psv")->spew("id|name|amount\n1|Alice|500\n");
	my $info = $DETECT_INFO->($DIR, 'beta');
	is $info->{sep_char}, '|', 'sep_char is pipe for PSV (assigned, not sniffed)';
	is $info->{id},       'id', 'id taken from PSV header';
};

subtest '_detect_file_info -- D::A native !-separator sniffed from .csv extension' => sub {
	# D::A stores data with "!" separator but uses .csv extension.
	# If splitting on comma yields one field that contains "!", sniff switches to "!".
	Mojo::File->new("$DIR/native.csv")->spew("entry!number!product\n1!42!Widget\n");
	my $info = $DETECT_INFO->($DIR, 'native');
	is $info->{sep_char}, '!', 'sep_char sniffed as ! for D::A native format';
	is $info->{id},  'entry', 'id = first column name from !-sep header';
	is_deeply $info->{columns}, [qw(entry number product)],
		'columns split correctly on ! separator';
};

subtest '_detect_file_info -- surrounding quotes and whitespace stripped from column names' => sub {
	Mojo::File->new("$DIR/quoted.csv")->spew(
		qq{"id"," name " ,"amount"\n1,Alice,500\n}
	);
	my $info = $DETECT_INFO->($DIR, 'quoted');
	is_deeply $info->{columns}, [qw(id name amount)],
		'quotes and whitespace stripped from each column name';
};

subtest '_detect_file_info -- FD lifecycle: no handle accumulation over repeated calls' => sub {
	SKIP: {
		skip '/proc/self/fd not available (non-Linux)', 1
			unless -d '/proc/self/fd';
		Mojo::File->new("$DIR/fdtest.csv")->spew("id,val\n1,x\n");
		my @before = glob('/proc/self/fd/*');
		$DETECT_INFO->($DIR, 'fdtest') for 1..10;
		my @after = glob('/proc/self/fd/*');
		is scalar(@after), scalar(@before),
			'no FD accumulation after 10 _detect_file_info calls';
	}
};

subtest '_detect_file_info -- FD lifecycle: handle closed when file is empty (no header)' => sub {
	# A 0-byte file returns the _file_is_empty sentinel (not {}); the handle
	# is explicitly closed before returning so there is no FD leak.
	Mojo::File->new("$DIR/empty_hdr.csv")->spew('');
	my $info = $DETECT_INFO->($DIR, 'empty_hdr');
	ok $info->{_file_is_empty}, 'empty file returns _file_is_empty sentinel';
	SKIP: {
		skip '/proc/self/fd not available (non-Linux)', 1
			unless -d '/proc/self/fd';
		my @before = glob('/proc/self/fd/*');
		$DETECT_INFO->($DIR, 'empty_hdr') for 1..5;
		my @after = glob('/proc/self/fd/*');
		is scalar(@after), scalar(@before), 'no FD leak for empty CSV file';
	}
};

# ======================================================================
# Section 2: DataSource new() -- DU chains in _init_backend
#
# $id_col D:331 (info->{id}//entry) -> U:332 (self->{_id_col})
#                                   -> U:339 (D::A constructor id arg)
# Both uses must receive the same value; verify via object introspection.
# ======================================================================

subtest 'DataSource::new -- _id_col and _columns set from CSV header' => sub {
	Mojo::File->new("$DIR/alpha.csv")->spew("id,name,amount\n1,Alice,500\n");
	my $ds = Database::BI::Model::DataSource->new(directory => $DIR, table => 'alpha');
	is   $ds->{_id_col}, 'id',                    '_id_col flows from detect_file_info';
	is_deeply $ds->{_columns}, [qw(id name amount)], '_columns holds header order';
};

subtest 'DataSource::new -- _id_col defaults to "entry" for SQLite (no CSV header)' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 2;
		require DBI;
		my $dbh = DBI->connect(
			"dbi:SQLite:dbname=$DIR/sqltest.sql", '', '',
			{ RaiseError => 1 },
		);
		$dbh->do('CREATE TABLE IF NOT EXISTS sqltest (name TEXT, val TEXT)');
		$dbh->disconnect;
		my $ds = Database::BI::Model::DataSource->new(
			directory => $DIR, table => 'sqltest',
		);
		is $ds->{_id_col},  'entry', '_id_col defaults to "entry" when no CSV/PSV header';
		is $ds->{_columns}, undef,   '_columns is undef for SQLite (no header sniff)';
	}
};

subtest 'DataSource::new -- synthesized _db object inherits Database::Abstraction' => sub {
	Mojo::File->new("$DIR/alpha.csv")->spew("id,name,amount\n1,Alice,500\n");
	my $ds = Database::BI::Model::DataSource->new(directory => $DIR, table => 'alpha');
	ok blessed($ds->{_db}),                         '_db is a blessed object';
	ok $ds->{_db}->isa('Database::Abstraction'), '_db inherits Database::Abstraction';
};

# ======================================================================
# Section 3: fetch_all -- DU chain for $data normalization
#
# $data D:469 -> U:474 (defined guard) -> U:480 (ref HASH check) ->
#     U+D:482 (normalize hashref to arrayref) -> U:485 (empty check) ->
#     U:489 (return)
# Each branch must be reachable and correct.
# ======================================================================

{
	Mojo::File->new("$DIR/dftest.csv")->spew("id,name\n1,Alice\n2,Bob\n");
	my ($ds_shared, $ds_err);
	eval {
		$ds_shared = Database::BI::Model::DataSource->new(
			directory => $DIR, table => 'dftest',
		);
	};
	$ds_err = $@;

	subtest 'fetch_all -- undef backend result normalised to []' => sub {
		skip 'DataSource construction failed', 2 if $ds_err;
		mock 'Database::Abstraction::selectall_hashref' => sub { return undef };
		my $result = $ds_shared->fetch_all;
		restore_all();
		is ref($result), 'ARRAY', 'undef from backend becomes an arrayref';
		is scalar(@$result), 0,  'empty arrayref (not undef) returned for undef backend';
	};

	subtest 'fetch_all -- arrayref backend result returned as-is' => sub {
		skip 'DataSource construction failed', 2 if $ds_err;
		my @expected = (
			{ id => '1', name => 'Alice' },
			{ id => '2', name => 'Bob' },
		);
		mock 'Database::Abstraction::selectall_hashref' => sub { return \@expected };
		my $result = $ds_shared->fetch_all;
		restore_all();
		is ref($result), 'ARRAY',   'arrayref returned for arrayref backend result';
		is_deeply $result, \@expected, 'arrayref values unchanged (no copy, same data)';
	};

	subtest 'fetch_all -- hashref backend result normalised to arrayref with carp' => sub {
		skip 'DataSource construction failed', 3 if $ds_err;
		my %hash_data = ( a => { id => 'a', name => 'Alice' } );
		mock 'Database::Abstraction::selectall_hashref' => sub { return \%hash_data };
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		my $result = $ds_shared->fetch_all;
		restore_all();
		is   ref($result), 'ARRAY', 'hashref normalised to arrayref';
		is   scalar(@$result), 1,   'one element after values() normalization';
		like $warnings[0], qr/hashref|converted/i, 'warn_data_normalised carp emitted';
	};

	subtest 'fetch_all -- empty arrayref result triggers warn_empty_result carp' => sub {
		skip 'DataSource construction failed', 2 if $ds_err;
		mock 'Database::Abstraction::selectall_hashref' => sub { return [] };
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		my $result = $ds_shared->fetch_all;
		restore_all();
		is_deeply $result, [], 'empty arrayref returned for empty backend result';
		like $warnings[0], qr/no records/i, 'warn_empty_result carp emitted';
	};

	subtest 'fetch_all -- backend exception converted to croak via error_fetch_failed' => sub {
		skip 'DataSource construction failed', 1 if $ds_err;
		mock 'Database::Abstraction::selectall_hashref' => sub {
			die "simulated backend failure\n";
		};
		throws_ok { $ds_shared->fetch_all } qr/simulated backend failure/,
			'backend die propagated as croak from fetch_all';
		restore_all();
	};
}

# ======================================================================
# Section 4: _url_label -- DU chain for $last
#
# $last D:56 (path component or '') -> U+D:57-59 (3 s/// mutations) ->
#   fallback? D+U:63-65 (hostname extraction) -> U:66 (lc return)
# The fallback branch fires when $last is empty or digit-leading.
# ======================================================================

subtest '_url_label -- path stem extracted and extension stripped' => sub {
	is $URL_LABEL->('http://example.com/data/sales.csv'), 'sales',
		'path stem used as label; extension stripped';
};

subtest '_url_label -- query string stripped before returning label' => sub {
	is $URL_LABEL->('http://example.com/report?q=2024'), 'report',
		'query string portion stripped from stem';
};

subtest '_url_label -- fragment stripped and non-alphanumeric sanitized' => sub {
	is $URL_LABEL->('http://example.com/my-report.csv#top'), 'my_report',
		'fragment stripped; hyphen sanitized to underscore';
};

subtest '_url_label -- digit-leading stem falls back to hostname (TABLE_NAME_RE safety)' => sub {
	# A stem like "2024data" starts with digit; the controller TABLE_NAME_RE
	# requires [A-Za-z_] at the start.  _url_label falls back to the hostname.
	my $label = $URL_LABEL->('http://example.com/2024data.csv');
	like $label, qr/\A[a-z_]/,
		'digit-leading stem replaced by hostname (letter/underscore start)';
};

subtest '_url_label -- no path component: hostname used as label' => sub {
	my $label = $URL_LABEL->('http://example.com/');
	like $label, qr/\Aexample/i, 'empty path yields hostname-derived label';
};

# ======================================================================
# Section 5: _write_sqlite_db -- resource lifecycle
#
# O~ anomaly (fixed): mid-flight DBI failure now triggers disconnect + unlink
# inside an eval wrapper in _write_sqlite_db, so no temp file is orphaned.
#
# D~ anomaly (not guarded): @quoted is empty when @$columns is empty, producing
# "CREATE TABLE data ()" which is invalid SQLite syntax.  In practice the
# controller always passes at least one column, so this path is never reached,
# but the code has no explicit guard for the empty-column edge case.
# ======================================================================

subtest '_write_sqlite_db -- returns valid SQLite3 binary on success' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 2;
		my $bytes = $WRITE_SQLITE->(undef, \@RECS, \@COLS);
		ok length($bytes) > 100, 'returns non-trivial byte string';
		is substr($bytes, 0, 15), 'SQLite format 3', 'starts with SQLite3 magic header';
	}
};

subtest '_write_sqlite_db -- tmpfile is unlinked after successful write' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 1;
		my $captured_path;
		# Mock the imported tempfile() alias so we can capture the temp path.
		mock 'Database::BI::Controller::Dashboard::tempfile' => sub {
			require File::Temp;
			my ($fh, $path) = File::Temp::tempfile(@_);
			$captured_path = $path;
			return ($fh, $path);
		};
		eval { $WRITE_SQLITE->(undef, \@RECS, \@COLS) };
		restore_all();
		ok defined($captured_path) && !-e $captured_path,
			'tmpfile unlinked after successful _write_sqlite_db';
	}
};

subtest '_write_sqlite_db -- DBI connect failure produces croak' => sub {
	SKIP: {
		eval { require DBI } or skip 'DBI not available', 1;
		mock 'DBI::connect' => sub { return undef };
		my $err;
		eval { $WRITE_SQLITE->(undef, \@RECS, \@COLS) };
		$err = $@;
		restore_all();
		like $err, qr/DBI connect failed/,
			'croak message contains "DBI connect failed" when connect returns undef';
	}
};

subtest '_write_sqlite_db -- empty records produce schema-only SQLite (no rows)' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 2;
		my $bytes;
		lives_ok { $bytes = $WRITE_SQLITE->(undef, [], \@COLS) }
			'no exception for empty record set with non-empty column list';
		is substr($bytes, 0, 15), 'SQLite format 3', 'valid SQLite header for schema-only file';
	}
};

subtest '_write_sqlite_db -- empty column list croaks before touching filesystem' => sub {
	SKIP: {
		eval { require DBI } or skip 'DBI not available', 2;
		my $err;
		eval { $WRITE_SQLITE->(undef, \@RECS, []) };
		$err = $@;
		like $err, qr/no columns/i, 'croak message mentions "no columns"';
		# Verify no tmpfile was leaked: the guard fires before tempfile() is called.
		# We verify indirectly by confirming no exception path was taken via the
		# tmpfile mock (no path captured means tempfile was never reached).
		my $called;
		mock 'Database::BI::Controller::Dashboard::tempfile' => sub { $called = 1 };
		eval { $WRITE_SQLITE->(undef, \@RECS, []) };
		restore_all();
		ok !$called, 'tempfile() not called when column list is empty (D~ guard fires first)';
	}
};

subtest '_write_sqlite_db -- tmpfile unlinked even when DBI work throws (O~ fix)' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 2;
		my $captured_path;
		mock 'Database::BI::Controller::Dashboard::tempfile' => sub {
			require File::Temp;
			my ($fh, $path) = File::Temp::tempfile(@_);
			$captured_path = $path;
			return ($fh, $path);
		};
		# Force $dbh->do() to throw by injecting a bad column name that SQLite rejects.
		# We use Test::Mockingbird to make do() die after the DBI connect succeeds.
		mock 'DBI::db::do' => sub { die "simulated do() failure\n" };
		my $err;
		eval { $WRITE_SQLITE->(undef, \@RECS, \@COLS) };
		$err = $@;
		restore_all();
		like $err, qr/simulated do\(\) failure/, 'exception from do() propagates via croak';
		ok defined($captured_path) && !-e $captured_path,
			'tmpfile unlinked even when DBI do() throws (O~ fix)';
	}
};

subtest '_write_sqlite_db -- double-quotes in column names are escaped in SQL' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 1;
		my @tricky_cols = ('col"one', 'col_two');
		my @tricky_recs = ({ 'col"one' => 'val1', 'col_two' => 'val2' });
		lives_ok { $WRITE_SQLITE->(undef, \@tricky_recs, \@tricky_cols) }
			'double-quote in column name escaped via s/"/""/g without SQL error';
	}
};

# ======================================================================
# Section 6: _serialize_csv -- DU chain for @lines
#
# @lines D:561 (header row) -> U:562-564 (push body rows) ->
#         U:565 (join in one O(total_bytes) allocation, not per-row concat)
# ======================================================================

subtest '_serialize_csv -- header row emitted first, in column order' => sub {
	my $csv = $SERIALIZE->(\@RECS, \@COLS);
	my ($header) = $csv =~ /\A([^\r\n]+\r\n)/;
	is $header, "name,amount,region\r\n", 'header matches column list order';
};

subtest '_serialize_csv -- data rows emitted in record array order' => sub {
	my $csv   = $SERIALIZE->(\@RECS, \@COLS);
	my @lines = split /\r\n/, $csv;
	is $lines[1], 'Alice,500,North', 'first data row is Alice';
	is $lines[2], 'Bob,100,South',   'second data row is Bob';
	is $lines[3], 'Carol,300,North', 'third data row is Carol';
};

subtest '_serialize_csv -- empty record set produces header-only output' => sub {
	my $csv   = $SERIALIZE->([], \@COLS);
	my @lines = split /\r\n/, $csv;
	is scalar(@lines), 1,              'exactly one line (header only)';
	is $lines[0], 'name,amount,region', 'header line matches columns';
};

subtest '_serialize_csv -- output is valid UTF-8' => sub {
	my $csv = $SERIALIZE->(\@RECS, \@COLS);
	my $decoded;
	lives_ok { $decoded = decode('UTF-8', $csv, Encode::FB_CROAK) }
		'output decodes as valid UTF-8 without error';
};

# ======================================================================
# Section 7: Database::Join DU chains (replaces former _left_join tests)
#
# Joins are now delegated to Database::Join via DataSource wrappers.
# Verify the key DU properties using CSV-backed DataSource objects:
#   all left rows preserved, right values merged, undef for no-match,
#   column collision prefix, first-match wins for duplicate right keys.
# ======================================================================

SKIP: {
	my $left_csv  = "$DIR/dflow_left.csv";
	my $right_csv = "$DIR/dflow_right.csv";
	Mojo::File->new($left_csv)->spew("emp,dept_id\nAlice,10\nBob,20\nCarol,99\n");
	Mojo::File->new($right_csv)->spew("dept_id,dept_name\n10,Engineering\n20,Marketing\n");

	require Database::Join;
	my ($left_ds, $right_ds);
	eval {
		$left_ds  = Database::BI::Model::DataSource->new(directory => $DIR, table => 'dflow_left');
		$right_ds = Database::BI::Model::DataSource->new(directory => $DIR, table => 'dflow_right');
	};
	skip 'DataSource construction failed for join DU tests', 5 if $@;

	subtest 'Database::Join -- all left rows preserved regardless of match (outer join)' => sub {
		my $join = Database::Join->new(databases => [$left_ds, $right_ds], join_column => 'dept_id');
		my $merged = $join->selectall_arrayref;
		is scalar(@$merged), 3, 'all 3 left rows present in merged output';
	};

	subtest 'Database::Join -- matching rows receive right column values' => sub {
		my $join   = Database::Join->new(databases => [$left_ds, $right_ds], join_column => 'dept_id');
		my $merged = $join->selectall_arrayref;
		is $merged->[0]{dept_name}, 'Engineering', 'Alice (dept 10) -> Engineering';
		is $merged->[1]{dept_name}, 'Marketing',   'Bob (dept 20) -> Marketing';
	};

	subtest 'Database::Join -- non-matching rows get undef for right columns' => sub {
		my $join   = Database::Join->new(databases => [$left_ds, $right_ds], join_column => 'dept_id');
		my $merged = $join->selectall_arrayref;
		ok !defined $merged->[2]{dept_name},
			'Carol (dept 99, no match) has undef for right columns';
	};

	subtest 'Database::Join -- column name collision prefixed with right table label' => sub {
		# Right table also has an "emp" column — collides with left "emp".
		Mojo::File->new("$DIR/dflow_right2.csv")->spew("dept_id,dept_name,emp\n10,Engineering,Mgr-E\n");
		my $right_ds2 = Database::BI::Model::DataSource->new(directory => $DIR, table => 'dflow_right2');
		my $join = Database::Join->new(
			databases        => [$left_ds, $right_ds2],
			join_column      => 'dept_id',
			collision_prefix => { 1 => 'dept' },
		);
		my $merged = $join->selectall_arrayref;
		ok  exists $merged->[0]{'dept.emp'}, 'colliding right column prefixed as label.col';
		is  $merged->[0]{'dept.emp'}, 'Mgr-E', 'prefixed column holds right-table value';
		is  $merged->[0]{'emp'}, 'Alice', 'original left emp column is preserved';
	};

	subtest 'Database::Join -- duplicate right keys: last match wins' => sub {
		Mojo::File->new("$DIR/dflow_dup.csv")->spew("dept_id,dept_name\n10,First\n10,Second\n");
		my $dup_ds = Database::BI::Model::DataSource->new(directory => $DIR, table => 'dflow_dup');
		my $join   = Database::Join->new(databases => [$left_ds, $dup_ds], join_column => 'dept_id');
		my $merged = $join->selectall_arrayref;
		# Database::Join uses last-wins semantics for duplicate right keys (unlike the
		# former _left_join helper which used first-wins via //=).
		is $merged->[0]{dept_name}, 'Second', 'last right row for duplicate key wins';
	};
}

# ======================================================================
# Section 8: Global state integrity
#
# Perl's grep, map, and for loops localize $_ during iteration.
# eval { } always sets $@ on exit (to '' on success, to error on failure).
# Verify these invariants hold across the data-transformation functions.
# ======================================================================

subtest 'global state -- $_ not leaked by _apply_filter_spec (grep internals)' => sub {
	local $_ = 'sentinel_filter';
	$FILTER->(\@RECS, 'name:eq:alice');
	is $_, 'sentinel_filter', '$_ unchanged after _apply_filter_spec';
};

subtest 'global state -- $_ not leaked by _csv_row (map internals)' => sub {
	local $_ = 'sentinel_csv';
	$CSV_ROW->('a', 'b', 'c');
	is $_, 'sentinel_csv', '$_ unchanged after _csv_row';
};

subtest 'global state -- $@ cleared to empty string after successful fetch_all' => sub {
	# eval { } always sets $@ on exit: '' for success, error for failure.
	# This is a documented Perl side-effect; callers must not rely on $@
	# being preserved across a fetch_all call.
	Mojo::File->new("$DIR/gstate.csv")->spew("id,name\n1,Alice\n");
	my ($ds, $err);
	eval { $ds = Database::BI::Model::DataSource->new(directory => $DIR, table => 'gstate') };
	$err = $@;
	skip 'DataSource construction failed', 1 if $err;
	mock 'Database::Abstraction::selectall_hashref' => sub {
		return [{ id => '1', name => 'Alice' }];
	};
	$@ = 'prior error state';
	eval { $ds->fetch_all };	# capture croak if any
	restore_all();
	is $@, '', '$@ cleared to "" by successful fetch_all (eval side-effect)';
};

subtest 'global state -- $! not modified by _detect_file_info' => sub {
	require POSIX;
	local $! = POSIX::ENOENT();
	my $expected_errno_string = "$!";
	$DETECT_INFO->($DIR, 'nonexistent_state_test');
	is "$!", $expected_errno_string, '$! unchanged after _detect_file_info';
};

# ======================================================================
# Section 9: _apply_filter_spec -- exhaustive operator DU chains
#
# DU chain for the key optimization:
#   D:384  $lval = lc $val    (computed once before grep)
#   U:387  eq   branch        (used)
#   U:388  ne   branch        (used)
#   U:389  contains branch    (used)
#   U:390  starts branch      (used)
#   D~     lt/le/gt/ge/empty/notempty branches ($lval defined but not read)
#          This is an intentional D~ for code simplicity -- $lval is always
#          computed regardless of operator to avoid a conditional compute.
#          Documented here, not flagged as a code defect.
#
# $col/$op/$val DU chain: split(/:/, $spec, 3) D -> guard U -> filter-body U.
# ======================================================================

Readonly my @FILTER_RECS => (
	{ name => 'Alice', score => '90',  city => 'London'   },
	{ name => 'bob',   score => '75',  city => 'New York' },
	{ name => 'Carol', score => '100', city => 'London'   },
	{ name => '',      score => '50',  city => ''          },
);

subtest '_apply_filter_spec -- eq (case-insensitive, $lval precompute D)' => sub {
	# D: $lval = lc('alice'); U: lc($cell) eq $lval inside grep for each record
	my $r = $FILTER->(\@FILTER_RECS, 'name:eq:alice');
	is scalar(@$r), 1, 'eq matches one record case-insensitively';
	is $r->[0]{name}, 'Alice', 'matched record is Alice';
};

subtest '_apply_filter_spec -- ne (case-insensitive)' => sub {
	my $r = $FILTER->(\@FILTER_RECS, 'name:ne:alice');
	is scalar(@$r), 3, 'ne excludes the matching record';
	ok !(grep { $_->{name} eq 'Alice' } @$r), 'Alice not in ne result';
};

subtest '_apply_filter_spec -- contains (case-insensitive substring)' => sub {
	my $r = $FILTER->(\@FILTER_RECS, 'city:contains:lon');
	is scalar(@$r), 2, 'contains matches both London records';
};

subtest '_apply_filter_spec -- contains with empty val matches all (index always 0)' => sub {
	# Empty $val -> $lval = ''; index(lc($cell), '') is always 0, so all rows pass.
	my $r = $FILTER->(\@FILTER_RECS, 'name:contains:');
	is scalar(@$r), scalar(@FILTER_RECS), 'empty contains val passes all records';
};

subtest '_apply_filter_spec -- starts (prefix match)' => sub {
	my $r = $FILTER->(\@FILTER_RECS, 'name:starts:c');
	is scalar(@$r), 1, 'starts matches Carol only (case-insensitive)';
	is $r->[0]{name}, 'Carol', 'Carol matched';
};

subtest '_apply_filter_spec -- lt / le numeric comparison' => sub {
	# $lval is D~ (dead store) for numeric operators -- computed but never read.
	my $lt = $FILTER->(\@FILTER_RECS, 'score:lt:75');
	is scalar(@$lt), 1, 'lt 75: only score=50 passes (strict boundary)';
	is $lt->[0]{score}, '50', 'strict lt excludes boundary';

	my $le = $FILTER->(\@FILTER_RECS, 'score:le:75');
	is scalar(@$le), 2, 'le 75: score=75 and score=50 pass (inclusive boundary)';
};

subtest '_apply_filter_spec -- gt / ge numeric comparison' => sub {
	my $gt = $FILTER->(\@FILTER_RECS, 'score:gt:90');
	is scalar(@$gt), 1, 'gt 90: only score=100 passes';

	my $ge = $FILTER->(\@FILTER_RECS, 'score:ge:90');
	is scalar(@$ge), 2, 'ge 90: score=90 and score=100 pass';
};

subtest '_apply_filter_spec -- empty / notempty unary operators ($val ignored)' => sub {
	my $empty = $FILTER->(\@FILTER_RECS, 'name:empty:irrelevant_val');
	is scalar(@$empty), 1, 'empty matches the one record with blank name';
	is $empty->[0]{city}, '', 'the empty-name record has blank city too';

	my $notempty = $FILTER->(\@FILTER_RECS, 'city:notempty:');
	is scalar(@$notempty), 3, 'notempty excludes the blank-city record';
};

subtest '_apply_filter_spec -- unknown operator passes all records (open-closed principle)' => sub {
	# Unknown operators fall through to `1` so future operators do not break
	# callers.  All records pass unchanged.
	my $r = $FILTER->(\@FILTER_RECS, 'name:xyzzy:alice');
	is scalar(@$r), scalar(@FILTER_RECS), 'unknown op passes all records unfiltered';
};

subtest '_apply_filter_spec -- missing column returns empty string (undef coalesced to "")' => sub {
	# $cell = $_->{$col} // '' -- a column that does not exist in a record
	# yields '' (never undef), so string ops compare '' and numeric ops compare 0.
	my $r = $FILTER->(\@FILTER_RECS, 'nonexistent:eq:');
	is scalar(@$r), scalar(@FILTER_RECS),
		'missing column coerced to "" matches empty eq filter for all records';
};

subtest '_apply_filter_spec -- malformed spec (no colon) returns input unchanged' => sub {
	my $r = $FILTER->(\@FILTER_RECS, 'justonetoken');
	is $r, \@FILTER_RECS, 'malformed spec returns the same arrayref (no-op)';
};

subtest '_apply_filter_spec -- original arrayref not mutated' => sub {
	my @orig = ({ name => 'Alice' }, { name => 'Bob' });
	my $in   = \@orig;
	my $out  = $FILTER->($in, 'name:eq:alice');
	is scalar(@orig), 2, 'original @orig still has 2 elements';
	isnt $out, $in,       'returned a new arrayref (not the same reference)';
};

# ======================================================================
# Section 10: _apply_filters HTTP pipeline DU
#
# _apply_filters uses $self->every_param('f'), so must be tested via HTTP.
# DU chain: @specs D (from HTTP) -> @parsed D (loop) -> $json D (encode_json)
#           $json U (escaping </script>) -> return U
# ======================================================================

subtest '_apply_filters pipeline -- f= params produce correct filtered view' => sub {
	$t->get_ok('/view/sales?f=region:eq:North')
	  ->status_is(200)
	  ->content_like(qr/North/, 'North region records visible after eq filter');
};

subtest '_apply_filters -- </script> in JSON is escaped to <\/ (XSS guard)' => sub {
	# The template emits window.__biFilters on a single line:
	#   <script>window.__biFilters = [% filters_json %];</script>
	# If a filter value contained </script>, an unescaped JSON string would
	# close the <script> block.  _apply_filters applies s{</}{<\\/}g so
	# the HTML parser sees <\/script> (valid JSON, harmless to HTML).
	# Verify: send a filter whose value is </script> and check the emitted
	# JSON line has <\/ (escaped), not the raw </ sequence.
	use Mojo::Util qw(url_escape);
	$t->get_ok('/view/sales?f=region:eq:' . url_escape('</script>'))
	  ->status_is(200)
	  # The raw val="</script>" must not appear inside the script block's JSON
	  ->content_unlike(
		qr{"val":"</script>"},
		'bare </script> not present as val in __biFilters JSON',
	  )
	  # The escaped form <\/ must appear (single backslash in source = <\/ in JSON)
	  ->content_like(
		qr{window\.__biFilters[^\n]*<\\/},
		'</ escaped to <\/ on the __biFilters line',
	  );
};

# ======================================================================
# Section 11: _dedup_records DU chain
#
# $key D (join NUL-separated values) -> U (%seen hash key)
# %seen D (empty) -> U+D (in loop: key++ tracks first-seen order)
# @out D (empty) -> U (push when !$seen{$key}++) -> U (return)
# ======================================================================

subtest '_dedup_records -- all-unique records returns unchanged count' => sub {
	my @recs = (
		{ name => 'Alice', score => '90' },
		{ name => 'Bob',   score => '75' },
	);
	my $out = $DEDUP->(\@recs, [qw(name score)]);
	is scalar(@$out), 2, 'no dups: output count matches input count';
};

subtest '_dedup_records -- duplicate rows: only first occurrence kept' => sub {
	my @recs = (
		{ name => 'Alice', score => '90' },
		{ name => 'Alice', score => '90' },  # dup
		{ name => 'Bob',   score => '75' },
	);
	my $out = $DEDUP->(\@recs, [qw(name score)]);
	is scalar(@$out), 2, 'one duplicate removed';
	is $out->[0]{name}, 'Alice', 'first Alice preserved (order maintained)';
	is $out->[1]{name}, 'Bob',   'Bob preserved';
};

subtest '_dedup_records -- NUL separator prevents cross-column collisions' => sub {
	# Without NUL separator, "AB" + "C" would hash the same as "A" + "BC".
	# With NUL: "AB\x00C" != "A\x00BC"
	my @recs = (
		{ col1 => 'AB', col2 => 'C'  },
		{ col1 => 'A',  col2 => 'BC' },
	);
	my $out = $DEDUP->(\@recs, [qw(col1 col2)]);
	is scalar(@$out), 2, 'NUL separator prevents cross-column hash collision';
};

subtest '_dedup_records -- undef values treated as empty string for key' => sub {
	my @recs = (
		{ name => undef, score => '90' },
		{ name => '',    score => '90' },  # undef and '' produce same key
	);
	my $out = $DEDUP->(\@recs, [qw(name score)]);
	is scalar(@$out), 1, 'undef and empty string treated identically in dedup key';
};

subtest '_dedup_records -- empty input returns empty arrayref' => sub {
	my $out = $DEDUP->([], [qw(name score)]);
	is ref($out), 'ARRAY', 'empty input returns arrayref';
	is scalar(@$out), 0,   'empty output for empty input';
};

subtest '_dedup_records -- input arrayref not mutated' => sub {
	my @orig = ({ name => 'Alice' }, { name => 'Alice' });
	$DEDUP->(\@orig, ['name']);
	is scalar(@orig), 2, 'original arrayref not modified by dedup';
};

# ======================================================================
# Section 12: _combine_tables DU chain
#
# @all_cols D (empty) -> U+D in first loop (column union built in order)
# %seen D (empty) -> U+D (guards duplicate column names in union)
# @merged D (empty) -> U+D in second loop (new row hashrefs appended)
# %has_col D (per source) -> U (membership test for each column per row)
# ======================================================================

subtest '_combine_tables -- left columns appear first in union order' => sub {
	my @left_recs  = ({ a => '1', b => '2' });
	my @right_recs = ({ b => '3', c => '4' });
	my ($merged, $cols) = $COMBINE->([
		[\@left_recs,  [qw(a b)]],
		[\@right_recs, [qw(b c)]],
	]);
	is $cols->[0], 'a', 'first source column a appears first';
	is $cols->[1], 'b', 'shared column b appears second (from first source position)';
	is $cols->[2], 'c', 'new column c from second source appended last';
};

subtest '_combine_tables -- all rows from both sources present in merged output' => sub {
	my @l = ({ x => '1' });
	my @r = ({ x => '2' }, { x => '3' });
	my ($merged, $cols) = $COMBINE->([[\@l, ['x']], [\@r, ['x']]]);
	is scalar(@$merged), 3, 'all 3 rows present (1 left + 2 right)';
};

subtest '_combine_tables -- missing columns filled with empty string (not undef)' => sub {
	# Right source has column c not present in left source.
	# Left rows must receive '' (not undef) for c.
	my @l = ({ a => 'left-val' });
	my @r = ({ c => 'right-val' });
	my ($merged, $cols) = $COMBINE->([[\@l, ['a']], [\@r, ['c']]]);
	is $merged->[0]{c}, '', 'left row gets empty string for missing right column';
	is $merged->[1]{a}, '', 'right row gets empty string for missing left column';
	ok defined($merged->[0]{c}), 'missing column value is "" (defined), not undef';
};

subtest '_combine_tables -- column overlap deduplicated (only one entry)' => sub {
	# Shared column b must appear exactly once in @all_cols.
	my @l = ({ b => '1' });
	my @r = ({ b => '2' });
	my ($merged, $cols) = $COMBINE->([[\@l, ['b']], [\@r, ['b']]]);
	is scalar(@$cols), 1, 'shared column b appears only once in merged column list';
};

subtest '_combine_tables -- single source: no allocation beyond column copy' => sub {
	my @recs = ({ x => 'a' }, { x => 'b' });
	my ($merged, $cols) = $COMBINE->([[\@recs, ['x']]]);
	is scalar(@$merged), 2,  'single source: all rows present';
	is $cols->[0], 'x',      'single source: column list is correct';
	is $merged->[0]{x}, 'a', 'first row value preserved';
};

subtest '_combine_tables -- original row hashrefs not mutated' => sub {
	my %orig = (a => 'original');
	my @recs = (\%orig);
	$COMBINE->([[\@recs, ['a']]]);
	is $orig{a}, 'original', 'original hashref keys unchanged after combine';
};

# ======================================================================
# Section 13: _get_columns DU chain
#
# $cols D (from source->columns) -> U (if-guard) -> U (return @$cols)
#   fallback branch:
#     %all D (from records[0] keys) -> U+D (delete id, U (sort remaining))
#     $c D (id_column) -> U ($c && $all{$c} check)
#     $id D (conditional) -> U (delete) -> U (return as first element)
# ======================================================================

subtest '_get_columns -- ordered source: columns() takes priority (D->U on first path)' => sub {
	# When source->columns returns an arrayref, the fallback is bypassed entirely.
	my $source = bless {
		_columns => [qw(z a m)],   # non-alphabetical: verifies no sorting applied
		_id_col  => 'z',
	}, 'Database::BI::Model::DataSource';
	my @records = ({ z => '1', a => '2', m => '3' });
	my @cols = $GET_COLS->($source, \@records);
	is_deeply \@cols, [qw(z a m)], 'ordered columns() result returned as-is (no sort)';
};

subtest '_get_columns -- fallback: id_column placed first, rest sorted alphabetically' => sub {
	# When source->columns returns undef, derive from first record.
	# id_column is 'entry' (exists in record) -> first; others sorted.
	my $source = bless {
		_columns => undef,
		_id_col  => 'entry',
	}, 'Database::BI::Model::DataSource';
	my @records = ({ entry => '1', zebra => 'z', alpha => 'a' });
	my @cols = $GET_COLS->($source, \@records);
	is $cols[0], 'entry', 'id_column placed first in fallback path';
	is $cols[1], 'alpha', 'remaining columns sorted alphabetically (alpha before zebra)';
	is $cols[2], 'zebra', 'zebra last';
};

subtest '_get_columns -- fallback: id_column absent from record yields any first sorted col' => sub {
	# When id_column is not in the records, fallback uses (sort keys)[0] as first.
	my $source = bless {
		_columns => undef,
		_id_col  => 'entry',       # 'entry' not in the record
	}, 'Database::BI::Model::DataSource';
	my @records = ({ name => 'Alice', score => '90' });
	my @cols = $GET_COLS->($source, \@records);
	is $cols[0], 'name',  'alphabetical first key used when id_column absent from record';
	is $cols[1], 'score', 'score second';
};

subtest '_get_columns -- empty records: returns empty list (guard on records->[0])' => sub {
	my $source = bless { _columns => undef, _id_col => 'entry' },
		'Database::BI::Model::DataSource';
	my @cols = $GET_COLS->($source, []);
	is scalar(@cols), 0, 'empty records with undef columns returns empty list';
};

# ======================================================================
# Section 14: _build_export_url DU chain
#
# $u D ('/export?l=' . url_escape($left_spec))
# $u U+D (appended for each j= spec in @$join_specs)
# $u U+D (appended for each c= spec in @$combine_specs)
# $u U+D (appended for each f= spec in @$filter_specs)
# $u U+D ('&d=1' appended when $dedup truthy)
# $u U (return)
# All appended values are url_escaped, so special characters in specs become %XX.
# ======================================================================

subtest '_build_export_url -- basic URL without join/filter/combine/dedup' => sub {
	my $url = $BUILD_URL->(undef, 'table:sales', [], []);
	is $url, '/export?l=table%3Asales', 'colon in table spec is url-escaped';
};

subtest '_build_export_url -- join specs appended as &j= params' => sub {
	my $url = $BUILD_URL->(undef, 'table:sales',
		['table:products|id|prod_id'],
		[],
	);
	like $url, qr/&j=/, '&j= param present for join spec';
	like $url, qr/table%3Aproducts/, 'table:products is url-escaped in j param';
};

subtest '_build_export_url -- filter specs appended as &f= params' => sub {
	my $url = $BUILD_URL->(undef, 'table:sales', [], ['region:eq:North']);
	like $url, qr/&f=region%3Aeq%3ANorth/, 'colons in filter spec url-escaped';
};

subtest '_build_export_url -- combine specs appended as &c= params' => sub {
	my $url = $BUILD_URL->(undef, 'table:sales', [], [], ['table:dogs']);
	like $url, qr/&c=table%3Adogs/, 'combine spec present and url-escaped';
};

subtest '_build_export_url -- dedup flag appends &d=1' => sub {
	my $with    = $BUILD_URL->(undef, 'table:sales', [], [], undef, 1);
	my $without = $BUILD_URL->(undef, 'table:sales', [], [], undef, 0);
	like    $with,    qr/&d=1/, '&d=1 present when dedup truthy';
	unlike  $without, qr/&d=/,  '&d= absent when dedup false';
};

subtest '_build_export_url -- multiple filter specs produce multiple &f= params' => sub {
	my $url = $BUILD_URL->(undef, 'table:sales', [],
		['region:eq:North', 'amount:gt:100'],
	);
	my @f_params = ($url =~ /(&f=[^&]*)/g);
	is scalar(@f_params), 2, 'two &f= params for two filter specs';
};

# ======================================================================
# Section 15: _is_safe_url DU chain
#
# $url U (regex to extract $host) -> $host D -> multiple U (guard checks)
# $packed D (inet_aton result) -> U (unpack) -> $n D -> U (range checks)
# The D~ anomaly from CLAUDE.md: non-standard IPv4 encodings (octal, hex,
# decimal integer) pass through because $host doesn't match the dotted-quad
# regex; the authoritative block is at the network-egress firewall layer.
# ======================================================================

subtest '_is_safe_url -- localhost variants are blocked' => sub {
	ok !$IS_SAFE->('http://localhost/'),          'localhost blocked';
	ok !$IS_SAFE->('https://localhost:8080/api'), 'localhost with port blocked';
	ok !$IS_SAFE->('http://127.0.0.1/'),          '127.0.0.1 (loopback) blocked';
	ok !$IS_SAFE->('http://127.255.255.255/'),    '127.x/8 range blocked';
	ok !$IS_SAFE->('http://0.0.0.0/'),            '0.0.0.0 blocked';
	ok !$IS_SAFE->('http://[::1]/'),              'IPv6 ::1 blocked (bracket parse fail)';
};

subtest '_is_safe_url -- RFC 1918 private addresses are blocked (all three ranges)' => sub {
	# 10.0.0.0/8
	ok !$IS_SAFE->('http://10.0.0.1/'),     '10.0.0.1 (RFC 1918 /8) blocked';
	ok !$IS_SAFE->('http://10.255.255.255/'), '10.255.255.255 blocked';
	# 172.16.0.0/12
	ok !$IS_SAFE->('http://172.16.0.1/'),   '172.16.0.1 (RFC 1918 /12) blocked';
	ok !$IS_SAFE->('http://172.31.255.255/'), '172.31.255.255 blocked';
	ok  $IS_SAFE->('http://172.32.0.1/'),    '172.32.0.1 outside /12 is allowed';
	# 192.168.0.0/16
	ok !$IS_SAFE->('http://192.168.1.100/'), '192.168.1.100 (RFC 1918 /16) blocked';
};

subtest '_is_safe_url -- link-local and CGNAT ranges blocked' => sub {
	ok !$IS_SAFE->('http://169.254.169.254/'), '169.254.169.254 (AWS metadata) blocked';
	ok !$IS_SAFE->('http://100.64.0.1/'),      '100.64.0.1 (CGNAT) blocked';
	ok !$IS_SAFE->('http://100.127.255.255/'), '100.127.255.255 (CGNAT edge) blocked';
	ok  $IS_SAFE->('http://100.128.0.1/'),     '100.128.0.1 outside CGNAT is allowed';
};

subtest '_is_safe_url -- public IP addresses are allowed' => sub {
	ok $IS_SAFE->('https://93.184.216.34/'),    '93.184.216.34 (example.com) allowed';
	ok $IS_SAFE->('https://8.8.8.8/'),          '8.8.8.8 (Google DNS) allowed';
	ok $IS_SAFE->('https://www.example.com/'),  'hostname allowed (firewall guards)';
};

subtest '_is_safe_url -- non-HTTP schemes fail host-extraction and return 0' => sub {
	ok !$IS_SAFE->('ftp://example.com/'),    'ftp scheme not http: blocked';
	ok !$IS_SAFE->('file:///etc/passwd'),    'file: scheme blocked';
};

subtest '_is_safe_url -- non-standard IPv4 encodings pass through (documented)' => sub {
	# Octal/hex/decimal-int IPv4 forms do NOT match the dotted-quad regex
	# (/\A\d{1,3}(?:\.\d{1,3}){3}\z/) so they skip the range checks and return 1.
	# This is documented behaviour in CLAUDE.md: the authoritative block is the
	# egress firewall.  These tests document the current behaviour, not a bug.
	ok $IS_SAFE->('http://0177.0.0.1/'),     'octal 127.0.0.1 passes (documented gap)';
	ok $IS_SAFE->('http://2130706433/'),     'decimal-int 127.0.0.1 passes (documented)';
};

# ======================================================================
# Section 16: _safe_back_url DU chain (XSS fix regression)
#
# $url D (param) -> U (defined/length guard) -> U (scheme regex) -> return
# D~ anomaly: when $url is '' or undef, all the scheme-check logic is
# short-circuited.  When $url is a non-empty non-matching string, the
# regex fires and returns undef.  No anomaly -- every branch has at most
# one D and one U for $url.
# ======================================================================

subtest '_safe_back_url -- javascript: scheme blocked (XSS regression)' => sub {
	is $SAFE_BACK->('javascript:alert(1)'), undef, 'javascript: URI scheme blocked';
	is $SAFE_BACK->('JAVASCRIPT:void(0)'),  undef, 'JAVASCRIPT: (caps) blocked';
	is $SAFE_BACK->('data:text/html,x'),    undef, 'data: scheme blocked';
	is $SAFE_BACK->('vbscript:MsgBox(1)'),  undef, 'vbscript: blocked';
	is $SAFE_BACK->('//evil.com'),          undef, 'protocol-relative // URL blocked';
};

subtest '_safe_back_url -- safe URLs pass through unchanged' => sub {
	is $SAFE_BACK->('/view/sales'),         '/view/sales',          'root-relative path allowed';
	is $SAFE_BACK->('https://example.com'), 'https://example.com',  'https: URL allowed';
	is $SAFE_BACK->('http://example.com'),  'http://example.com',   'http: URL allowed';
};

subtest '_safe_back_url -- undef and empty string return undef' => sub {
	is $SAFE_BACK->(undef), undef, 'undef input returns undef';
	is $SAFE_BACK->(''),    undef, 'empty string returns undef';
};

# ======================================================================
# Section 17: selectall_arrayref cache DU chain
#
# $cache D (from self->{_cache}) -> U (if guard)
# $key D (from _cache_key) -> U (cache->get)
# $hit D (cache->get result) -> U (return when defined)
# $data D (backend call) -> U (defined guard) -> U (cache->set) -> U (return)
#
# Key invariant: non-empty @args bypasses the cache entirely (narrowed queries
# must not pollute the full-table cache entry).
# ======================================================================

subtest 'selectall_arrayref -- cache hit returns stored data (backend not called)' => sub {
	require CHI;
	Mojo::File->new("$DIR/ctest.csv")->spew("id,name\n1,Alice\n2,Bob\n");
	my $cache = CHI->new(driver => 'Memory', global => 0);
	my $ds = Database::BI::Model::DataSource->new(
		directory => $DIR,
		table     => 'ctest',
		cache     => $cache,
	);

	my $call_count = 0;
	mock 'Database::Abstraction::selectall_hashref' => sub {
		$call_count++;
		return [{ id => '1', name => 'Alice' }];
	};
	# First call: cache miss -> backend called
	my $r1 = $ds->selectall_arrayref;
	my $first_count = $call_count;

	# Second call: cache hit -> backend NOT called
	my $r2 = $ds->selectall_arrayref;
	restore_all();

	is $call_count, $first_count, 'second selectall_arrayref uses cache (backend not called again)';
	is_deeply $r1, $r2, 'cache hit returns identical data';
};

subtest 'selectall_arrayref -- @args bypass cache (narrowed queries not cached)' => sub {
	require CHI;
	Mojo::File->new("$DIR/ctest2.csv")->spew("id,name\n1,Alice\n");
	my $cache = CHI->new(driver => 'Memory', global => 0);
	my $ds = Database::BI::Model::DataSource->new(
		directory => $DIR,
		table     => 'ctest2',
		cache     => $cache,
	);
	my $call_count = 0;
	mock 'Database::Abstraction::selectall_hashref' => sub { $call_count++ };
	mock 'Database::Abstraction::selectall_arrayref' => sub {
		$call_count++;
		return [{ id => '1', name => 'Alice' }];
	};
	$ds->selectall_arrayref('some filter');
	$ds->selectall_arrayref('some filter');
	restore_all();
	is $call_count, 2, 'narrowed queries (@args non-empty) bypass cache; backend called twice';
};

subtest 'selectall_arrayref -- _file_is_empty fast path returns [] without backend' => sub {
	Mojo::File->new("$DIR/emptysrc.csv")->spew('');
	my $ds = Database::BI::Model::DataSource->new(directory => $DIR, table => 'emptysrc');
	my $called = 0;
	mock 'Database::Abstraction::selectall_arrayref' => sub { $called++ };
	my $result = $ds->selectall_arrayref;
	restore_all();
	is $called,       0,       'backend not called for empty file';
	is ref($result),  'ARRAY', '_file_is_empty returns arrayref';
	is scalar(@$result), 0,    '_file_is_empty returns empty arrayref';
};

# ======================================================================
# Section 18: _cache_key DU chain
#
# URL path: $idx D (html_table_index // 0) -> U (concatenated into key string)
#           key D ('bi:url:' . $url . ':' . $idx) -> U (return)
# File path: $mtime D (stat()[9]) -> U (defined guard) -> U (concatenated into key)
#            key D ('bi:file:' . $path . ':' . $mtime) -> U (return)
# No-match path: returns undef (D~ avoided: no key variable declared)
# ======================================================================

subtest '_cache_key -- URL-backed: key includes URL and table index' => sub {
	my $fake = bless {
		_url              => 'http://example.com/data.html',
		_html_table_index => 2,
	}, 'Database::BI::Model::DataSource';
	my $key = $CACHE_KEY->($fake);
	like $key, qr{bi:url:http://example\.com/data\.html:2},
		'URL key includes full URL and table index';
};

subtest '_cache_key -- default table index 0 included in key' => sub {
	my $fake = bless {
		_url              => 'http://example.com/',
		_html_table_index => undef,    # undef -> // 0
	}, 'Database::BI::Model::DataSource';
	my $key = $CACHE_KEY->($fake);
	like $key, qr{:0\z}, 'default table index 0 appended when html_table_index is undef';
};

subtest '_cache_key -- file-backed: mtime embedded in key (natural invalidation)' => sub {
	Mojo::File->new("$DIR/mtime_test.csv")->spew("id,v\n1,x\n");
	my $path  = File::Spec->rel2abs("$DIR/mtime_test.csv");
	my $mtime = (stat($path))[9];
	my $fake  = bless { _file_path => $path }, 'Database::BI::Model::DataSource';
	my $key   = $CACHE_KEY->($fake);
	like $key, qr{bi:file:},    'file key starts with bi:file:';
	like $key, qr{\Q$path\E},   'full path embedded in key';
	like $key, qr{:$mtime\z},   'mtime appended at end of file key';
};

subtest '_cache_key -- non-existent file path returns undef (stat fails)' => sub {
	my $fake = bless {
		_file_path => '/nonexistent/path/to/file.csv',
	}, 'Database::BI::Model::DataSource';
	my $key = $CACHE_KEY->($fake);
	is $key, undef, 'returns undef when file does not exist on disk';
};

subtest '_cache_key -- no URL and no file path returns undef' => sub {
	my $fake = bless {}, 'Database::BI::Model::DataSource';
	my $key = $CACHE_KEY->($fake);
	is $key, undef, 'returns undef when neither _url nor _file_path are set';
};

# ======================================================================
# Section 19: _list_dir resource lifecycle (FD)
#
# O~ concern: opendir opens $dh; closedir $dh must be reached on every path.
# The function uses "if (opendir my $dh, ...)" so $dh is lexically scoped.
# Perl's lexical filehandles auto-close when they go out of scope, but
# closedir is called explicitly before the scope ends -- no O~ anomaly.
#
# DU chain:
# @dirs D (empty) -> U+D (push inside loop) -> U (sort for return)
# @files D (empty) -> U+D (push inside loop, only when $want_files) -> U (sort)
# $dh D (opendir) -> U (readdir loop) -> K (closedir)
# ======================================================================

subtest '_list_dir FD lifecycle -- no FD leak after listing a directory' => sub {
	SKIP: {
		skip '/proc/self/fd not available (non-Linux)', 1
			unless -d '/proc/self/fd';
		my $dir_path = tempdir(CLEANUP => 1);
		Mojo::File->new("$dir_path/alpha.csv")->spurt("id,v\n1,x\n");
		Mojo::File->new("$dir_path/beta.csv")->spurt("id,v\n2,y\n");

		# One request first, so the response held by the test client is the same
		# size as the ones measured: a page large enough for Mojolicious to
		# spool its body to a temp file costs one descriptor, and that
		# descriptor is released when the next response replaces it.  Measured
		# cold, that release lands inside the window and looks like a leak
		# going the other way.
		$t->get_ok('/browse?path=' . url_escape($dir_path));

		my @before = glob('/proc/self/fd/*');
		# Exercise the controller's /browse route which calls _list_dir.
		$t->get_ok('/browse?path=' . url_escape($dir_path)) for 1..10;
		my @after = glob('/proc/self/fd/*');
		cmp_ok scalar(@after), '<=', scalar(@before),
			'no FD accumulation after 10 /browse calls (_list_dir closedir called)';
	}
};

subtest '_list_dir -- hidden entries (dotfile) are excluded' => sub {
	my $dir_path = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir_path/visible.csv")->spurt("id,v\n1,x\n");
	Mojo::File->new("$dir_path/.hidden.csv")->spurt("id,v\n2,y\n");

	use Mojo::Util qw(url_escape);
	$t->get_ok('/browse?path=' . url_escape($dir_path))
	  ->status_is(200)
	  ->content_like(qr/visible/, 'visible.csv listed in browse')
	  ->content_unlike(qr/\.hidden/, '.hidden.csv excluded from listing');
};

subtest '_list_dir -- $want_files=false: /api/dirs returns no file entries' => sub {
	# /api/dirs passes want_files=false so _list_dir does not accumulate @files.
	# The JSON response has no "files" key and the CSV filename is absent.
	my $dir_path = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir_path/dataonly.csv")->spurt("id,v\n1,x\n");

	use Mojo::Util qw(url_escape);
	$t->get_ok('/api/dirs?path=' . url_escape($dir_path))
	  ->status_is(200)
	  ->json_hasnt('/files', '/api/dirs response has no "files" key (want_files=false)')
	  ->content_unlike(qr/dataonly/, 'CSV file absent from /api/dirs response');
};

subtest '_list_dir -- @dirs and @files sorted case-insensitively' => sub {
	my $dir_path = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir_path/Zebra.csv")->spurt("id,v\n1,x\n");
	Mojo::File->new("$dir_path/alpha.csv")->spurt("id,v\n2,y\n");
	Mojo::File->new("$dir_path/MANGO.csv")->spurt("id,v\n3,z\n");

	use Mojo::Util qw(url_escape);
	my $res = $t->get_ok('/browse?path=' . url_escape($dir_path))
	  ->status_is(200);

	# Files should appear in case-insensitive order: alpha, MANGO, Zebra
	my $content = $t->tx->res->body;
	my $alpha = index($content, 'alpha');
	my $mango = index($content, 'MANGO');
	my $zebra = index($content, 'Zebra');
	ok $alpha >= 0 && $mango >= 0 && $zebra >= 0, 'all files present in browse listing';
	ok $alpha < $mango && $mango < $zebra,
		'files sorted case-insensitively (alpha < MANGO < Zebra)';
};

# ======================================================================
# Section 20: _values_are_data_like and _synthesize_col_names DU chains
#
# _values_are_data_like: iterates @$vals, returns 1 on first data-like match,
#   0 if none match.  No intermediate variables -- $v is the loop var.
# _synthesize_col_names: %type_count D (empty) -> U+D in loop (counted per type)
#   @names D (empty) -> U+D (push per value) -> U (return)
#   $type D (in loop) -> U (type_count key) -> U (ternary suffix logic)
# ======================================================================

subtest '_values_are_data_like -- ISO date triggers true (short-circuit return)' => sub {
	ok $VALUES_LIKE->(['2026-09-16', 'some text']),
		'YYYY-MM-DD date recognised as data-like';
};

subtest '_values_are_data_like -- slash date triggers true' => sub {
	ok $VALUES_LIKE->(['9/16/2026', 'ACME CO']),
		'M/D/YYYY date recognised as data-like';
};

subtest '_values_are_data_like -- signed numeric triggers true' => sub {
	ok $VALUES_LIKE->(['-75.13', 'ACME CO']),
		'signed numeric recognised as data-like';
};

subtest '_values_are_data_like -- accounting negative triggers true' => sub {
	ok $VALUES_LIKE->(['(75.13)', 'ACME CO']),
		'accounting-notation negative recognised as data-like';
};

subtest '_values_are_data_like -- plain hyphenated identifiers return false' => sub {
	ok !$VALUES_LIKE->(['First-Name', 'Last-Name', 'Email-Address']),
		'hyphenated identifiers NOT data-like (CSV header, not data row)';
};

subtest '_values_are_data_like -- all plain text returns false' => sub {
	ok !$VALUES_LIKE->(['hello', 'world']), 'plain text not data-like';
};

subtest '_synthesize_col_names -- dates -> Date, amounts -> Amount, text -> Description' => sub {
	my @names = $SYNTH_COLS->(['2026-09-16', '-75.13', 'ACME CO']);
	is $names[0], 'Date',        'ISO date value -> Date';
	is $names[1], 'Amount',      'numeric value -> Amount';
	is $names[2], 'Description', 'text value -> Description';
};

subtest '_synthesize_col_names -- duplicate types get numeric suffix' => sub {
	my @names = $SYNTH_COLS->(['2026-01-01', '2026-02-01', '-10', '-20', 'foo', 'bar']);
	is $names[0], 'Date',         'first date -> Date';
	is $names[1], 'Date2',        'second date -> Date2';
	is $names[2], 'Amount',       'first amount -> Amount';
	is $names[3], 'Amount2',      'second amount -> Amount2';
	is $names[4], 'Description',  'first text -> Description';
	is $names[5], 'Description2', 'second text -> Description2';
};

subtest '_synthesize_col_names -- type_count per-type (DD check: no stale counts)' => sub {
	# %type_count starts fresh per call -- not persisted between calls.
	my @first  = $SYNTH_COLS->(['2026-01-01']);
	my @second = $SYNTH_COLS->(['2026-01-01']);
	is $first[0],  'Date', 'first call: Date (not Date2)';
	is $second[0], 'Date', 'second call: still Date (type_count starts fresh)';
};

# ======================================================================
# Section 21: XLSX all-unsafe-column-headers regression
#
# Bug (fixed): When an XLSX file has column headers that are all unsafe SQL
# identifiers (e.g. "First Name", "Account Number"), _detect_file_info returns
# { columns => [...], id => undef, _headerless_data => [...] }.
# The OLD _init_backend checked error_no_safe_id BEFORE _headerless_data and
# would croak even though the data was pre-loaded.
# The FIX: _headerless_data check now precedes error_no_safe_id.
# ======================================================================

subtest 'XLSX all-unsafe column headers -- opens without error_no_safe_id croak' => sub {
	SKIP: {
		eval { require Spreadsheet::ParseXLSX } or skip 'Spreadsheet::ParseXLSX not available', 2;
		eval { require Excel::Writer::XLSX }     or skip 'Excel::Writer::XLSX not available (needed to write test XLSX)', 2;

		my $path = "$DIR/unsafe_cols.xlsx";
		my $wb   = Excel::Writer::XLSX->new($path);
		my $ws   = $wb->add_worksheet;
		# Write all-unsafe column headers (spaces in names).
		$ws->write(0, 0, 'First Name');
		$ws->write(0, 1, 'Account Number');
		$ws->write(1, 0, 'Alice');
		$ws->write(1, 1, '12345');
		$wb->close;

		my $ds;
		lives_ok {
			$ds = Database::BI::Model::DataSource->new(
				directory => $DIR,
				table     => 'unsafe_cols',
			);
		} 'XLSX with all-unsafe headers opens without error_no_safe_id croak';

		my $records = eval { $ds->fetch_all };
		is scalar(@$records), 1, 'one data row read from XLSX with unsafe column names';
	}
};

# ======================================================================
# Section 22: Geocode _resolve -- cache copy-on-entry immutability
#
# DU chain:
#   $opts->{'cache'}  D:caller -> U:_resolve (copied to %cache on entry)
#   %cache            D:copy -> U:exists check -> D:new entries added
#   $result->{'cache'} D:\%cache -> returned to caller
#
# The caller's hashref must NEVER be modified.  A mid-flight exception
# must not leave a half-written cache in the caller's hashref.
# ======================================================================

subtest 'Geocode _resolve -- caller hashref unchanged after resolve_values' => sub {
	my ($geo, $gc) = _fresh_geo();
	my %caller_cache = (Ramsgate => [$RAM_LAT, $RAM_LON]);
	my $caller_ref   = \%caller_cache;

	$geo->resolve_values(['Ramsgate', 'Margate'], cache => $caller_ref);

	is_deeply $caller_ref, { Ramsgate => [$RAM_LAT, $RAM_LON] },
		'caller cache: Margate not added to caller hashref';
	ok !exists($caller_ref->{'Margate'}), 'Margate key absent from caller hashref';
};

subtest 'Geocode _resolve -- returned cache is a separate reference' => sub {
	my ($geo) = _fresh_geo();
	my %input_cache;
	my $result = $geo->resolve_values(['Ramsgate'], cache => \%input_cache);
	isnt $result->{'cache'}, \%input_cache,
		'returned cache hashref is not the same ref as caller cache';
};

subtest 'Geocode _resolve -- new resolved entries appear in returned cache' => sub {
	my ($geo) = _fresh_geo();
	my $result = $geo->resolve_values(['Ramsgate', 'Margate'], cache => {});
	is_deeply $result->{'cache'}{'Ramsgate'}, [$RAM_LAT, $RAM_LON],
		'Ramsgate in returned cache with correct coordinates';
	ok exists($result->{'cache'}{'Margate'}), 'Margate also in returned cache';
};

subtest 'Geocode _resolve -- pre-existing [lat,lon] entry survives in returned cache' => sub {
	my ($geo) = _fresh_geo();
	my $result = $geo->resolve_values(
		['Ramsgate'],
		cache => { Ramsgate => [$RAM_LAT, $RAM_LON] },
	);
	is_deeply $result->{'cache'}{'Ramsgate'}, [$RAM_LAT, $RAM_LON],
		'seeded [lat,lon] entry preserved in returned cache unchanged';
};

subtest 'Geocode _resolve -- 0 sentinel preserved and not re-attempted' => sub {
	my ($geo, $gc) = _fresh_geo();
	# Seed Ramsgate as a prior miss (0); it must not be sent to the geocoder.
	my $result = $geo->resolve_values(['Ramsgate'], cache => { Ramsgate => 0 });
	is $result->{'cache'}{'Ramsgate'}, 0, '0 sentinel not overwritten';
	is $gc->{calls}, 0,                   'geocoder not called (prior miss remembered)';
	is $result->{'counts'}{'unresolved'}, 1, 'prior miss counted as unresolved';
	is $result->{'counts'}{'attempted'},  0, 'nothing attempted (all were cached)';
};

# ======================================================================
# Section 23: Geocode _resolve -- %seen deduplication DU chain
#
# DU chain:
#   %seen      D:empty -> D+U:$seen{$key}++ (post-increment)
#   $distinct  D:0 -> U:++ on first occurrence only
#
# Post-increment semantics: $seen{$key}++ evaluates to 0 (falsy) for the
# FIRST occurrence of each key (the "next if" does not fire), then to >=1
# (truthy) for all subsequent occurrences (the "next if" fires).
# undef and '' map to the same key '': only the first of them is counted
# as distinct and pushed to @skipped; the rest are deduplicated silently.
# ======================================================================

subtest 'Geocode %seen -- duplicate values counted once in distinct' => sub {
	my ($geo) = _fresh_geo();
	my $result = $geo->resolve_values(['Ramsgate', 'Ramsgate', 'Ramsgate']);
	is $result->{'counts'}{'distinct'}, 1, 'three copies: distinct == 1';
	is $result->{'counts'}{'attempted'}, 1, 'only one lookup attempted';
};

subtest 'Geocode %seen -- undef and empty-string share the same seen key' => sub {
	my ($geo) = _fresh_geo();
	# undef, '', and a second undef all map to key ''.
	# First occurrence: distinct++, push @skipped.  Others: "next if" fires.
	my $result = $geo->resolve_values([undef, '', undef, '']);
	is $result->{'counts'}{'distinct'}, 1,
		'undef + empty-string: both map to key "", distinct == 1';
	is $result->{'counts'}{'skipped'}, 1,
		'only the first occurrence pushed to @skipped (not 4)';
	is scalar(@{ $result->{'skipped'} }), 1, 'skipped arrayref has exactly 1 entry';
};

subtest 'Geocode %seen -- count invariant holds after deduplication' => sub {
	my ($geo) = _fresh_geo();
	# Input: [Ramsgate, Margate, Ramsgate, undef, undef]
	# Distinct: Ramsgate=1, Margate=1, ''=1 -> distinct==3
	my $result = $geo->resolve_values(
		['Ramsgate', 'Margate', 'Ramsgate', undef, undef],
	);
	my $c = $result->{'counts'};
	my $sum = $c->{'skipped'} + $c->{'cached'} + $c->{'attempted'} + $c->{'not_attempted'};
	is $sum, $c->{'distinct'},
		'invariant: skipped+cached+attempted+not_attempted == distinct (post-dedup)';
};

# ======================================================================
# Section 24: Geocode _resolve -- $wanted vs $max cap DU chain
#
# DU chain:
#   @pending  D:push -> U:scalar @pending -> $wanted (before truncation)
#   $wanted   D:$wanted -> U:compare with $max, U:message arg
#   @attempt  D:copy of @pending -> D:truncated to $max elements
#   @not_attempted D:[] -> D:push overflow
#   $capped   D:0 -> D:1 (when $wanted > $max)
#
# $wanted captures the PRE-TRUNCATION count; the cap message reports
# "Geocoded M of the N places" where N==$wanted, M==scalar @attempt.
# Overflow values must NOT appear in the returned cache (they are held
# back so the next request can retry them).
# ======================================================================

subtest 'Geocode cap -- $wanted reflects total pending before truncation' => sub {
	my $gc  = DF::MissGeocoder->new;
	my $geo = Database::BI::Model::Geocode->new(geocoder => $gc, openaddr => 'test');
	# 5 new values, max=2: $wanted==5, @attempt has 2, @not_attempted has 3.
	my $result = $geo->resolve_values([qw(A B C D E)], max => 2, cache => {});
	my $c = $result->{'counts'};
	is $c->{'attempted'},     2, 'attempted == 2 (cap applied)';
	is $c->{'not_attempted'}, 3, 'not_attempted == 3 (overflow)';
	is $result->{'capped'},   1, 'capped flag set';
	my @cap = grep { $_->{'key'} eq 'warn_map_geocode_capped' } @{ $result->{'messages'} };
	is scalar(@cap), 1, 'exactly one cap message emitted';
	like $cap[0]{'text'}, qr/2 of the 5/, 'cap message says "2 of the 5"';
};

subtest 'Geocode cap -- overflow values absent from returned cache' => sub {
	my $gc  = DF::MissGeocoder->new;
	my $geo = Database::BI::Model::Geocode->new(geocoder => $gc, openaddr => 'test');
	my $result = $geo->resolve_values([qw(A B C D E)], max => 2, cache => {});
	# C, D, E were held back -- must NOT appear in the returned cache at all.
	ok !exists($result->{'cache'}{'C'}), 'C (overflow) not in returned cache';
	ok !exists($result->{'cache'}{'D'}), 'D (overflow) not in returned cache';
	ok !exists($result->{'cache'}{'E'}), 'E (overflow) not in returned cache';
};

subtest 'Geocode cap -- $capped is 0 when attempt count <= max' => sub {
	my ($geo) = _fresh_geo();
	my $result = $geo->resolve_values(['Ramsgate', 'Margate'], max => 500, cache => {});
	is $result->{'capped'}, 0, 'capped == 0 when attempt count <= max';
	my @cap = grep { $_->{'key'} eq 'warn_map_geocode_capped' } @{ $result->{'messages'} };
	is scalar(@cap), 0, 'no cap message when not capped';
};

# ======================================================================
# Section 25: Geocode _resolve -- count invariants
#
# DU chains for all count variables traced end-to-end.
#
# Invariant 1: skipped + cached + attempted + not_attempted  ==  distinct
# Invariant 2: resolved + unresolved  ==  cached + attempted
#
# These must hold for every input shape: empty, all-cached, all-miss, mixed.
# ======================================================================

subtest 'Geocode count invariants -- empty input' => sub {
	my ($geo) = _fresh_geo();
	my $result = $geo->resolve_values([]);
	my $c = $result->{'counts'};
	is $c->{'distinct'}, 0, 'distinct == 0 for empty input';
	my $sum = $c->{'skipped'} + $c->{'cached'} + $c->{'attempted'} + $c->{'not_attempted'};
	is $sum, 0, 'sum == 0 for empty input';
	is $c->{'resolved'} + $c->{'unresolved'}, $c->{'cached'} + $c->{'attempted'},
		'invariant 2 holds for empty input';
};

subtest 'Geocode count invariants -- mixed input (cached, skipped, new-miss)' => sub {
	my ($geo) = _fresh_geo();
	# Ramsgate: cached resolved.  London: cached miss (0).  Oxford: new miss.
	# undef: skipped.
	my $result = $geo->resolve_values(
		['Ramsgate', undef, 'London', 'Oxford'],
		cache => { Ramsgate => [$RAM_LAT, $RAM_LON], London => 0 },
	);
	my $c = $result->{'counts'};
	my $sum = $c->{'skipped'} + $c->{'cached'} + $c->{'attempted'} + $c->{'not_attempted'};
	is $sum, $c->{'distinct'},
		'invariant 1: skipped+cached+attempted+not_attempted == distinct';
	is $c->{'resolved'} + $c->{'unresolved'}, $c->{'cached'} + $c->{'attempted'},
		'invariant 2: resolved+unresolved == cached+attempted';
};

# ======================================================================
# Section 26: Geocode resolve_column -- $found guard DU chain
#
# DU chain:
#   $found  D:0 -> D:1 (when column key exists in any hashref row)
#   Guard   croak if @{$rows} && !$found
#
# Edge cases:
#   1. Empty @rows: guard body never reached (no croak for absent column).
#   2. Column present with undef value: exists returns true -> $found=1.
#   3. Column absent from ALL rows: $found stays 0 -> croak.
#   4. Column present in SOME rows: $found=1 at first occurrence -> no croak.
# ======================================================================

subtest 'Geocode resolve_column -- empty rows: no croak regardless of column' => sub {
	my ($geo) = _fresh_geo();
	my $result;
	lives_ok { $result = $geo->resolve_column([], 'nonexistent_col') }
		'empty @rows: no croak even for absent column';
	is $result->{'counts'}{'rows'}, 0, 'rows == 0';
};

subtest 'Geocode resolve_column -- column present with undef value: no croak' => sub {
	my ($geo) = _fresh_geo();
	lives_ok {
		$geo->resolve_column(
			[{ city => undef }, { city => 'Ramsgate' }], 'city',
		);
	} 'column present (even with undef value): $found==1, no croak';
};

subtest 'Geocode resolve_column -- column absent from all rows: croak' => sub {
	my ($geo) = _fresh_geo();
	throws_ok {
		$geo->resolve_column([{ name => 'Alice' }, { name => 'Bob' }], 'city');
	} qr/city.*is not in this dataset/i,
		'croak error_map_loc_column when column absent from all rows';
};

subtest 'Geocode resolve_column -- column in SOME rows: $found=1, no croak' => sub {
	my ($geo) = _fresh_geo();
	lives_ok {
		$geo->resolve_column(
			[{ city => 'Ramsgate' }, { name => 'no city key here' }], 'city',
		);
	} 'column present in at least one row: $found=1, no croak';
};

# ======================================================================
# Section 27: Geocode resolve_column -- $plotted counts rows, not values
#
# DU chain:
#   %row_count  D:{} -> D:++ per @cells index (counts ALL occurrences)
#   %first_row  D:{} -> D:set only on first occurrence
#   $plotted    D:0 -> D:+= $row_count{$key} per plotted key
#
# $plotted is the SUM of per-value row counts, not the number of distinct
# resolved values.  Three rows for "Ramsgate" contribute 3 to $plotted.
# markers[] are ordered by first_row (ascending), not alphabetically.
# ======================================================================

subtest 'Geocode resolve_column -- $plotted counts rows not distinct values' => sub {
	my ($geo) = _fresh_geo();
	my $rows = [
		{ city => 'Ramsgate' },
		{ city => 'Ramsgate' },
		{ city => 'Margate'  },
		{ city => 'Ramsgate' },
	];
	my $result = $geo->resolve_column($rows, 'city');
	# 2 distinct resolved cities, but 4 total rows -> plotted == 4.
	is $result->{'counts'}{'plotted'}, 4,
		'plotted == 4 (row count, not distinct resolved count)';
	is $result->{'counts'}{'rows'}, 4, 'rows == 4';
};

subtest 'Geocode resolve_column -- markers ordered by first_row not alphabetically' => sub {
	my ($geo) = _fresh_geo();
	# Margate appears first; Ramsgate second (alphabetically Ramsgate < Margate reversed).
	my $rows = [{ city => 'Margate' }, { city => 'Ramsgate' }];
	my $result = $geo->resolve_column($rows, 'city');
	my @m = @{ $result->{'markers'} };
	is $m[0]{'value'}, 'Margate',  'first marker is Margate (first_row==0)';
	is $m[1]{'value'}, 'Ramsgate', 'second marker is Ramsgate (first_row==1)';
};

subtest 'Geocode resolve_column -- marker rows field is per-value row count' => sub {
	my ($geo) = _fresh_geo();
	my $rows = [
		{ city => 'Ramsgate' },
		{ city => 'Ramsgate' },
		{ city => 'Margate'  },
	];
	my $result = $geo->resolve_column($rows, 'city');
	my %by_val = map { $_->{'value'} => $_ } @{ $result->{'markers'} };
	is $by_val{'Ramsgate'}{'rows'}, 2, 'Ramsgate marker rows == 2';
	is $by_val{'Margate'}{'rows'},  1, 'Margate marker rows == 1';
};

# ======================================================================
# Section 28: Geocode _resolve -- $lookups default-then-override DU chain
#
# DU chain:
#   $lookups  D:0 (outer scope) -> D:689 (batch->{'lookups'} OR scalar @attempt)
#
# The initializer D:677 ($lookups = 0 inside the if (@attempt) block) is
# reached only when @attempt is non-empty.  When @attempt is empty the
# outer D:0 stays.
#
# Two override paths:
#   Path A: batch is a hashref with a 'lookups' key -> use that value
#   Path B: batch has no 'lookups' key -> use scalar @attempt
# ======================================================================

subtest 'Geocode $lookups -- batch with lookups key: uses reported count' => sub {
	# DF::CountGeocoder returns { lookups => 7 } regardless of input size.
	my $gc  = DF::CountGeocoder->new(7);
	my $geo = Database::BI::Model::Geocode->new(geocoder => $gc, openaddr => 'test');
	my $result = $geo->resolve_values([qw(A B C)], cache => {});
	is $result->{'counts'}{'lookups'}, 7,
		'lookups == 7 (geocoder-reported, not scalar @attempt which is 3)';
};

subtest 'Geocode $lookups -- batch without lookups key: uses scalar @attempt' => sub {
	my $gc  = DF::MissGeocoder->new;
	my $geo = Database::BI::Model::Geocode->new(geocoder => $gc, openaddr => 'test');
	# DF::MissGeocoder returns {} (no 'lookups' key) -> lookups == scalar @attempt.
	my $result = $geo->resolve_values([qw(A B C)], cache => {});
	is $result->{'counts'}{'lookups'}, 3,
		'lookups == 3 (scalar @attempt; no geocoder-reported count)';
};

subtest 'Geocode $lookups -- empty @attempt: lookups stays at 0' => sub {
	my ($geo) = _fresh_geo();
	# Ramsgate already in cache -> nothing to attempt -> $lookups stays at 0.
	my $result = $geo->resolve_values(
		['Ramsgate'],
		cache => { Ramsgate => [$RAM_LAT, $RAM_LON] },
	);
	is $result->{'counts'}{'lookups'}, 0,
		'lookups == 0 when @attempt is empty (all cached)';
};

# ======================================================================
# Section 29: Geocode models_with_cache -- DU immutability
#
# DU chain:
#   \%models  D:caller -> U:1120 (read to copy $spec) -> never modified
#   \%cache   D:caller -> U:1122 (copied to $spec->{'places'}) -> never modified
#   $spec     D:shallow copy -> D:'places' set -> D:geo key inserted
#   \%updated D:shallow copy of \%models -> D:'geo' replaced
#
# The caller's \%models and \%cache are never modified.
# All other keys in \%models and all other geo specs are carried through.
# ======================================================================

subtest 'Geocode models_with_cache -- caller $models not modified' => sub {
	my $models = {
		calc => { foo => 1 },
		geo  => { 'table:x' => { places => { A => 0 } } },
	};
	Database::BI::Model::Geocode->models_with_cache(
		$models, 'table:x', { A => [$RAM_LAT, $RAM_LON] },
	);
	is_deeply $models->{'geo'}{'table:x'}{'places'}, { A => 0 },
		'original $models not modified: A still 0 in caller hashref';
};

subtest 'Geocode models_with_cache -- caller $cache not modified' => sub {
	my %orig_cache = (Ramsgate => [$RAM_LAT, $RAM_LON]);
	Database::BI::Model::Geocode->models_with_cache(
		{}, 'table:x', \%orig_cache, backend => 'test',
	);
	is_deeply \%orig_cache, { Ramsgate => [$RAM_LAT, $RAM_LON] },
		'caller cache hashref not modified by models_with_cache';
};

subtest 'Geocode models_with_cache -- other models keys preserved' => sub {
	my $models = { calc => { formula => 'x+y' }, groups => { col => {} } };
	my $updated = Database::BI::Model::Geocode->models_with_cache(
		$models, 'table:sales', { London => [$RAM_LAT, $RAM_LON] },
	);
	is_deeply $updated->{'calc'},   { formula => 'x+y' }, 'calc key preserved';
	is_deeply $updated->{'groups'}, { col => {} },        'groups key preserved';
};

subtest 'Geocode models_with_cache -- other geo specs preserved' => sub {
	my $models = {
		geo => {
			'table:sales' => { places => { A => [1.0, 2.0] } },
			'table:other' => { places => { B => 0 } },
		},
	};
	my $updated = Database::BI::Model::Geocode->models_with_cache(
		$models, 'table:sales', { A => [$RAM_LAT, $RAM_LON] },
	);
	is_deeply $updated->{'geo'}{'table:other'}, { places => { B => 0 } },
		'other geo spec (table:other) preserved';
};

subtest 'Geocode models_with_cache -- returned struct has correct places/backend/built' => sub {
	my $updated = Database::BI::Model::Geocode->models_with_cache(
		{}, 'table:x',
		{ Ramsgate => [$RAM_LAT, $RAM_LON], Paris => 0 },
		backend => 'MaxMind',
		built   => '2026-10-18T12:00:00',
	);
	is_deeply $updated->{'geo'}{'table:x'}{'places'},
		{ Ramsgate => [$RAM_LAT, $RAM_LON], Paris => 0 },
		'places set correctly in returned struct';
	is $updated->{'geo'}{'table:x'}{'backend'}, 'MaxMind',              'backend set';
	is $updated->{'geo'}{'table:x'}{'built'},   '2026-10-18T12:00:00', 'built set';
};

# ======================================================================
# Section 30: Geocode cache_from_models -- shallow copy DU chain
#
# DU chain:
#   $entry  D:1050 (models->geo->spec) -> U:1052 (ref check) -> U:1054 (copy)
#   return { %{ $entry->{'places'} } }  -- one level of copy only
#
# The returned hashref is a different reference from the original places.
# Adding top-level keys to it does not affect $models.
# But the inner [lat,lon] arrayrefs ARE shared (shallow copy of one level).
# ======================================================================

subtest 'Geocode cache_from_models -- returns a different hashref reference' => sub {
	my $models = { geo => { 'table:x' => { places => { A => [1.0, 2.0] } } } };
	my $cache  = Database::BI::Model::Geocode->cache_from_models($models, 'table:x');
	isnt $cache, $models->{'geo'}{'table:x'}{'places'},
		'returned hashref is a copy, not the original places hashref';
};

subtest 'Geocode cache_from_models -- adding key to returned cache does not modify models' => sub {
	my $models = { geo => { 'table:x' => { places => { A => 0 } } } };
	my $cache  = Database::BI::Model::Geocode->cache_from_models($models, 'table:x');
	$cache->{'B'} = [9.0, 9.0];
	ok !exists($models->{'geo'}{'table:x'}{'places'}{'B'}),
		'adding key to returned cache does not modify $models';
};

subtest 'Geocode cache_from_models -- inner arrayrefs are shared (shallow copy)' => sub {
	# DD anomaly note: modifying an inner [lat,lon] WOULD affect $models.
	# This is documented behaviour (one level of copy), not a bug.
	my $inner  = [51.3, 1.4];
	my $models = { geo => { 'table:x' => { places => { A => $inner } } } };
	my $cache  = Database::BI::Model::Geocode->cache_from_models($models, 'table:x');
	is $cache->{'A'}, $inner,
		'inner arrayref is the same reference (shallow copy -- one level only)';
};

subtest 'Geocode cache_from_models -- unknown spec returns {}' => sub {
	my $models = { geo => { 'table:x' => { places => { A => 0 } } } };
	my $cache  = Database::BI::Model::Geocode->cache_from_models($models, 'table:z');
	is_deeply $cache, {}, 'unknown spec returns empty hashref';
};

# ======================================================================
# Section 31: Global state integrity through Geocode operations
#
# DU anomaly targets:
#   $_ -- must not be clobbered by any Geocode operation
#   $@ -- must be clean after a successful call
#
# A function that uses $_ without localising it has a DU anomaly: it
# modifies the caller's $_, an implicit write to a global with no
# corresponding "kill" scoped to the function boundary.
# ======================================================================

subtest 'Geocode -- $_ not clobbered by resolve_values' => sub {
	my ($geo) = _fresh_geo();
	local $_ = 'sentinel';
	$geo->resolve_values(['Ramsgate', 'Margate']);
	is $_, 'sentinel', '$_ unchanged after resolve_values';
};

subtest 'Geocode -- $@ clean after a successful resolve_values' => sub {
	my ($geo) = _fresh_geo();
	$@ = '';  ## no critic
	$geo->resolve_values(['Ramsgate']);
	is $@, '', '$@ still empty after a successful call';
};

subtest 'Geocode -- $_ not clobbered by models_with_cache' => sub {
	local $_ = 'sentinel';
	Database::BI::Model::Geocode->models_with_cache(
		{}, 'table:x', { A => [1.0, 2.0] },
	);
	is $_, 'sentinel', '$_ unchanged after models_with_cache';
};

subtest 'Geocode -- $_ not clobbered by cache_from_models' => sub {
	local $_ = 'sentinel';
	Database::BI::Model::Geocode->cache_from_models(
		{ geo => { 'table:x' => { places => { A => 0 } } } }, 'table:x',
	);
	is $_, 'sentinel', '$_ unchanged after cache_from_models';
};

# ======================================================================
# Section 32: Concurrent Geocode object isolation
#
# DU chain:
#   $self->{'_geocoder'}  D:construction (injected geocoder pre-stored)
#                         D:_load_geocoder (lazy load, once per object)
#
# Two Geocode objects with different geocoder stubs must not share the
# _geocoder slot: each object's lazy-load cache is per-instance.
# ======================================================================

subtest 'Geocode concurrent objects -- different geocoders resolve independently' => sub {
	my $gc_a = DF::Geocoder->new(
		Ramsgate => DF::GeoPoint->new(lat => $RAM_LAT, lon => $RAM_LON, database => 'a'),
	);
	my $gc_b = DF::MissGeocoder->new;
	my $geo_a = Database::BI::Model::Geocode->new(geocoder => $gc_a, openaddr => 'a');
	my $geo_b = Database::BI::Model::Geocode->new(geocoder => $gc_b, openaddr => 'b');

	my $ra = $geo_a->resolve_values(['Ramsgate'], cache => {});
	my $rb = $geo_b->resolve_values(['Ramsgate'], cache => {});

	ok  $HAS_POSITION->($ra->{'cache'}{'Ramsgate'}),
		'geo_a resolved Ramsgate (known to its geocoder)';
	ok !$HAS_POSITION->($rb->{'cache'}{'Ramsgate'}),
		'geo_b did not resolve Ramsgate (miss geocoder)';
};

subtest 'Geocode concurrent objects -- _geocoder slot is per-instance' => sub {
	my $gc_a = DF::Geocoder->new();
	my $gc_b = DF::MissGeocoder->new;
	my $geo_a = Database::BI::Model::Geocode->new(geocoder => $gc_a, openaddr => 'a');
	my $geo_b = Database::BI::Model::Geocode->new(geocoder => $gc_b, openaddr => 'b');

	$geo_a->geocoder_available();
	$geo_b->geocoder_available();

	isnt $geo_a->{'_geocoder'}, $geo_b->{'_geocoder'},
		'_geocoder slot is a different reference between two objects';
};

# ======================================================================
# Section 33: Geocode _geocoder -- lazy-load loaded at most once per object
#
# DU chain:
#   $self->{'_geocoder'}  D:set on FIRST call to _geocoder()
#   exists check in _geocoder() gates re-entry: the second call returns
#   the cached value without calling _load_geocoder again.
#
# DD anomaly check: assigning to $self->{'_geocoder'} a second time
# without reading it in between would be a DD.  The exists guard prevents
# this: _load_geocoder is called once, and the result is stored once.
# ======================================================================

subtest 'Geocode _geocoder -- loaded at most once per object' => sub {
	my ($geo) = _fresh_geo();

	# First call: triggers the pre-set (injected geocoder path).
	$geo->geocoder_available();

	# Replace the stored geocoder with a sentinel to detect any re-assignment.
	my $sentinel = DF::MissGeocoder->new;
	$geo->{'_geocoder'} = $sentinel;

	# Second call: must return the sentinel (no re-load overwrites it).
	$geo->geocoder_available();
	is $geo->{'_geocoder'}, $sentinel,
		'_geocoder not reassigned on second call (loaded once, not again)';
};

subtest 'Geocode _geocoder -- injected geocoder is pre-set at construction' => sub {
	my $gc  = DF::MissGeocoder->new;
	my $geo = Database::BI::Model::Geocode->new(geocoder => $gc, openaddr => 'test');
	is $geo->{'_geocoder'}, $gc,
		'_geocoder slot pre-set to injected geocoder at construction (no lazy load needed)';
};

# ======================================================================
# Section 34: Geocode -- TOCTOU: cache state mutation between resolve calls
#
# TOCTOU scenario: _resolve copies the caller's cache hashref on entry.
# Even if the caller mutates that hashref after the call returns, the
# RETURNED cache from that call is a separate copy and is unaffected.
#
# The property tested: once the function returns a cache, that returned
# value is stable and does not change if the input hashref is later mutated.
# ======================================================================

subtest 'Geocode TOCTOU -- mutating caller cache after call does not corrupt returned cache' => sub {
	my ($geo) = _fresh_geo();
	my %shared;
	my $result = $geo->resolve_values(['Ramsgate'], cache => \%shared);

	# After the call: corrupt the caller's hashref.
	$shared{'Ramsgate'} = 'CORRUPTED';

	# The returned cache is a separate copy -- still holds the valid entry.
	ok $HAS_POSITION->($result->{'cache'}{'Ramsgate'}),
		'returned cache unaffected by post-call mutation of the input hashref';
};

subtest 'Geocode TOCTOU -- second call uses the cache state at its own call time' => sub {
	my ($geo) = _fresh_geo();
	my %shared;

	# First call: Ramsgate is new, gets resolved and added to returned cache.
	my $r1 = $geo->resolve_values(['Ramsgate'], cache => \%shared);
	is $r1->{'counts'}{'attempted'}, 1, 'first call: Ramsgate attempted';

	# Feed the first result back into the shared hashref.
	%shared = %{ $r1->{'cache'} };

	# Second call (fresh object to reset geocoder call count):
	# Ramsgate is now cached -- must not be attempted again.
	my ($geo2) = _fresh_geo();
	my $r2 = $geo2->resolve_values(['Ramsgate'], cache => \%shared);
	is $r2->{'counts'}{'attempted'}, 0, 'second call: Ramsgate not re-attempted (cached)';
	is $r2->{'counts'}{'cached'},    1, 'second call: Ramsgate counted as cached';
};

subtest 'Geocode TOCTOU -- two resolve calls with same input cache each get their own copy' => sub {
	# Simulates two parallel requests over the same shared cache hashref.
	# Each resolve_values() copies the cache on entry: the two operations do not
	# interfere even though they share the same input pointer.
	my $gc = DF::Geocoder->new(
		Ramsgate => DF::GeoPoint->new(lat => $RAM_LAT, lon => $RAM_LON, database => 'stub'),
		Margate  => DF::GeoPoint->new(lat => $MAR_LAT, lon => $MAR_LON, database => 'stub'),
	);
	my $geo1 = Database::BI::Model::Geocode->new(geocoder => $gc, openaddr => 'test');
	my $geo2 = Database::BI::Model::Geocode->new(geocoder => $gc, openaddr => 'test');
	my %shared;

	my $r1 = $geo1->resolve_values(['Ramsgate'], cache => \%shared);
	my $r2 = $geo2->resolve_values(['Margate'],  cache => \%shared);

	# The shared input hashref was never modified by either call.
	is_deeply \%shared, {}, 'shared input hashref unchanged by both calls';

	# Each returned cache contains only what THAT call resolved.
	ok  $HAS_POSITION->($r1->{'cache'}{'Ramsgate'}), 'r1 cache has Ramsgate';
	ok !exists($r1->{'cache'}{'Margate'}),            'r1 cache has no Margate';
	ok  $HAS_POSITION->($r2->{'cache'}{'Margate'}),   'r2 cache has Margate';
	ok !exists($r2->{'cache'}{'Ramsgate'}),            'r2 cache has no Ramsgate';
};

done_testing;
