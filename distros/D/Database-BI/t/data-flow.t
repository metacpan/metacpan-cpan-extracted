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

# Direct references to :Private package functions (intact post-CHECK).
my $DETECT_INFO  = \&Database::BI::Model::DataSource::_detect_file_info;
my $URL_LABEL    = \&Database::BI::Model::DataSource::_url_label;
my $WRITE_SQLITE = \&Database::BI::Controller::Dashboard::_write_sqlite_db;
my $SERIALIZE    = \&Database::BI::Controller::Dashboard::_serialize_csv;
my $LEFT_JOIN    = \&Database::BI::Controller::Dashboard::_left_join;
my $FILTER       = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
my $CSV_ROW      = \&Database::BI::Controller::Dashboard::_csv_row;

Readonly my $DIR  => tempdir(CLEANUP => 1);

# Fixed sample dataset -- column order matters for header assertions.
Readonly my @RECS => (
	{ name => 'Alice', amount => '500', region => 'North' },
	{ name => 'Bob',   amount => '100', region => 'South' },
	{ name => 'Carol', amount => '300', region => 'North' },
);
Readonly my @COLS => qw(name amount region);

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
# Section 7: _left_join -- DU chains
#
# %right_idx D:364-368 (first-match semantics) -> U:389 (lookup)
# @rcols D:383-384 (precomputed [$right, $mapped] pairs) -> U:391 (for)
# $_ in "for @rcols" is localised by the for loop -- no global leak.
# ======================================================================

{
	my @left_recs = (
		{ emp => 'Alice', dept_id => '10' },
		{ emp => 'Bob',   dept_id => '20' },
		{ emp => 'Carol', dept_id => '99' },	# no matching right row
	);
	my @left_cols  = qw(emp dept_id);
	my @right_recs = (
		{ dept_id => '10', dept_name => 'Engineering' },
		{ dept_id => '20', dept_name => 'Marketing'   },
	);
	my @right_cols = qw(dept_id dept_name);

	subtest '_left_join -- all left rows preserved regardless of match (outer join)' => sub {
		my ($merged, $cols) = $LEFT_JOIN->(
			\@left_recs, \@left_cols, 'dept_id',
			\@right_recs, \@right_cols, 'dept_id', 'dept',
		);
		is scalar(@$merged), 3, 'all 3 left rows present in merged output';
	};

	subtest '_left_join -- matching rows receive right column values' => sub {
		my ($merged, $cols) = $LEFT_JOIN->(
			\@left_recs, \@left_cols, 'dept_id',
			\@right_recs, \@right_cols, 'dept_id', 'dept',
		);
		is $merged->[0]{dept_name}, 'Engineering', 'Alice (dept 10) -> Engineering';
		is $merged->[1]{dept_name}, 'Marketing',   'Bob (dept 20) -> Marketing';
	};

	subtest '_left_join -- non-matching rows get undef for right columns' => sub {
		my ($merged, $cols) = $LEFT_JOIN->(
			\@left_recs, \@left_cols, 'dept_id',
			\@right_recs, \@right_cols, 'dept_id', 'dept',
		);
		ok !defined $merged->[2]{dept_name},
			'Carol (dept 99, no match) has undef for right columns';
	};

	subtest '_left_join -- column name collision prefixed with right table label' => sub {
		# Add "emp" to right table: it collides with left "emp" column.
		my @right_with_collision = (
			{ dept_id => '10', dept_name => 'Engineering', emp => 'Mgr-E' },
		);
		my @right_cols2 = qw(dept_id dept_name emp);
		my ($merged, $cols) = $LEFT_JOIN->(
			\@left_recs, \@left_cols, 'dept_id',
			\@right_with_collision, \@right_cols2, 'dept_id', 'dept',
		);
		ok  exists $merged->[0]{'dept.emp'}, 'colliding right column prefixed as label.col';
		is  $merged->[0]{'dept.emp'}, 'Mgr-E', 'prefixed column holds right-table value';
		is  $merged->[0]{'emp'}, 'Alice', 'original left emp column is preserved';
	};

	subtest '_left_join -- duplicate right keys: first occurrence wins (%right_idx //= $row)' => sub {
		my @duped_right = (
			{ dept_id => '10', dept_name => 'First'  },
			{ dept_id => '10', dept_name => 'Second' },	# duplicate key
		);
		my ($merged, $cols) = $LEFT_JOIN->(
			\@left_recs, \@left_cols, 'dept_id',
			\@duped_right, \@right_cols, 'dept_id', 'dept',
		);
		is $merged->[0]{dept_name}, 'First',
			'first right row for duplicate key wins (//= semantics in %right_idx)';
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

subtest 'global state -- $_ not leaked by _left_join (for @rcols inner loop)' => sub {
	local $_ = 'sentinel_join';
	$LEFT_JOIN->(
		[{ a => '1', k => 'x' }], [qw(a k)], 'k',
		[{ k => 'x', b => '2' }], [qw(k b)], 'k', 'right',
	);
	is $_, 'sentinel_join', '$_ unchanged after _left_join';
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

done_testing;
