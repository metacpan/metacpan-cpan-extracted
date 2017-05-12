use Config;
use threads;
use DBI qw(:sql_types);
use DBIx::Threaded;

use strict;
use warnings;
use vars qw($testno $loaded $testtype);
BEGIN { 
	my $tests = 72;
	die "This Perl is not configured to support threads."
		unless $Config{useithreads};

#	print STDERR "Note: some tests have significant delays...\n";
	$^W= 1; 
	$| = 1; 
	print "1..$tests\n"; 
}

END {print "not ok $testno\n" unless $loaded;}

sub report_result {
	my ($result, $testmsg, $okmsg, $notokmsg) = @_;
	$okmsg = '' unless $okmsg;

	if ($result) {
	
		print STDOUT (($result eq 'skip') ?
			"ok $testno # skip $testmsg for $testtype\n" :
			"ok $testno $testmsg $okmsg for $testtype\n");
	}
	else {
		print STDOUT 
			"not ok $testno $testmsg $notokmsg for $testtype\n";
	}
	$testno++;
}

#######################################################################
#
#	DBMS specific test query map
#
#	The following queries are used:
#		ConnSetup: any query required to initialize a connection state
#		UserDateTime: returns the username, current date and time
#		CreateTable: create a (possibly temp/volatile) table with
#			3 columns: an integer, a varchar(100), and a decimal(10,3)
#		InsertRow: inserts a row into said table using placeholders
#			for all values
#		SelectRows: selects all columns from said table, ordered by
#			the integer column, ascending
#		Cleanup: any SQL statement required to cleanup the test (e.g.,
#			dropping the table created in CreateTable)
#
#######################################################################
my %query_sets = (
	Teradata => {
#
#	capabilities list
#
			CanPing => 1,
			CanGetInfo => 1,
			CanDataSources => undef,
			CanTableInfo => 1,
			CanColumnInfo => undef,
			CanPKInfo => undef,
			CanPK => undef,
			CanFKInfo => undef,
			CanCommit => 1,

			ConnSetup => 'set session dateform=integerdate',
			UserDateTime => 'select user, current_date, current_time',
			CreateTable => 
'create volatile table dbix_threaded_test (
	col1 int, 
	col2 varchar(100),
	col3 decimal(10,3)
) unique primary index(col1)
on commit preserve rows',
			InsertRow => 'insert into dbix_threaded_test values(?, ?, ?)',
			SelectRows => 'select * from dbix_threaded_test order by col1',
			HashCol => 'User'
		},
	ODBC => {
#
#	mininmal, in case we don't recognize the driver
#
#
#	capabilities list
#
			CanPing => 1,
			CanGetInfo => 1,
			CanDataSources => undef,
			CanTableInfo => 1,
			CanColumnInfo => 1,
			CanPKInfo => undef,
			CanPK => undef,
			CanFKInfo => undef,
			CanCommit => 1,

			ConnSetup => undef,
			UserDateTime => 'select current_timestamp, current_date, current_time',
			CreateTable => 
'create volatile table dbix_threaded_test (
	col1 int, 
	col2 varchar(100),
	col3 decimal(10,3)
) unique primary index(col1)
on commit preserve rows',
			InsertRow => 'insert into dbix_threaded_test values(?, ?, ?)',
			SelectRows => 'select * from dbix_threaded_test order by col1',
			HashCol => 'CURRENT_DATE'
	},
	ODBC_TERADATA => {
#
#	capabilities list
#
			CanPing => 1,
			CanGetInfo => 1,
			CanDataSources => undef,
			CanTableInfo => 1,
			CanColumnInfo => 1,
			CanPKInfo => undef,
			CanPK => undef,
			CanFKInfo => undef,
			CanCommit => 1,

			ConnSetup => 'set session dateform=integerdate',
			UserDateTime => 'select user, current_date, current_time',
			CreateTable => 
'create volatile table dbix_threaded_test (
	col1 int, 
	col2 varchar(100),
	col3 decimal(10,3)
) unique primary index(col1)
on commit preserve rows',
			InsertRow => 'insert into dbix_threaded_test values(?, ?, ?)',
			SelectRows => 'select * from dbix_threaded_test order by col1',
			HashCol => 'User'
		},
	CSV => {
#
#	capabilities list
#
			CanPing => undef,
			CanGetInfo => undef,
			CanDataSources => undef,
			CanTableInfo => undef,
			CanColumnInfo => undef,
			CanPKInfo => undef,
			CanPK => undef,
			CanFKInfo => undef,
			CanCommit => undef,

			ConnSetup => undef,
			UserDateTime => 'select current_timestamp, current_date, current_time',
			CreateTable => 
'create temp table dbix_threaded_test (
	col1 int, 
	col2 varchar(100),
	col3 int
)',			InsertRow => 'insert into dbix_threaded_test values(?, ?, ?)',
			SelectRows => 'select * from dbix_threaded_test order by col1',
			HashCol => 'CURRENT_DATE'
		},
#
#	can't do amazon til it can handle create tables and insert
#
#	Amazon => {
#
#	capabilities list
#
#			CanPing => undef,
#			CanGetInfo => undef,
#			CanDataSources => undef,
#			CanTableInfo => undef,
#			CanColumnInfo => undef,
#			CanPKInfo => undef,
#			CanPK => undef,
#			CanFKInfo => undef,
#			CanCommit => undef,

#			ConnSetup => undef,
#			UserDateTime => 'select current_timestamp, current_date, current_time',
#			CreateTable => undef,
#'create temp table dbix_threaded_test (
#	col1 int, 
#	col2 varchar(100),
#	col3 int
#)',
#			InsertRow => 'insert into dbix_threaded_test values(?, ?, ?)',
#			SelectRows => 'select * from dbix_threaded_test order by col1',
#			HashCol => 'CURRENT_DATE'
#		},
	SQLite => {
#
#	capabilities list
#
			CanPing => 1,
			CanGetInfo => 1,
			CanDataSources => undef,
			CanTableInfo => 1,
			CanColumnInfo => undef,
			CanPKInfo => undef,
			CanPK => undef,
			CanFKInfo => undef,
			CanCommit => 1,

			ConnSetup => undef,
			UserDateTime => 'select current_timestamp, current_date, current_time',
			CreateTable => 
'create temp table dbix_threaded_test (
	col1 int, 
	col2 varchar(100),
	col3 decimal(10,3)
)',
			InsertRow => 'insert into dbix_threaded_test values(?, ?, ?)',
			SelectRows => 'select * from dbix_threaded_test order by col1',
			HashCol => 'current_date'
		},
);

$testno = 1;
$testtype = 'main thread';
#
#	create some threads to pass the stmt handle to
#	*before* we connect, so the thread doesn't
#	have a ref to any of this stuff
#

my $q1 = Thread::Queue::Duplex->new(ListenerRequired => 1);
my $thrd1 = threads->create(\&sel_thread, $q1);
$q1->wait_for_listener();

my $q2 = Thread::Queue::Duplex->new(ListenerRequired => 1);
my $thrd2 = threads->create(\&sel_thread, $q2);
$q2->wait_for_listener();
#
#	create a DBIx::Threaded pool
#
report_result(DBIx::Threaded->dbix_threaded_create_pool(3), 
	'dbix_threaded_create_pool', '', '' );
#
#	now we can connect
#
my $dsn = $ENV{DBIX_THRD_DSN};
die "No DSN defined (you need to set DBIX_THRD_DSN)\n"
	unless $dsn;

my $subclass = $ENV{DBIX_THRD_SUBCLASS};
my $user = $ENV{DBIX_THRD_USER};
my $pass = $ENV{DBIX_THRD_PASS};

my ($driver) = ($dsn=~/^dbi:([^:]+):/);
die "No driver defined in DSN (check your DBIX_THRD_DSN)\n"
	unless $driver;

my $qrymap = $query_sets{$driver};

die "No query map for $driver\n"
	unless $qrymap;
#
#	first, run locally
#	test driver level APIs
#
my ($rc, $row, $sth);
my @row;

@row = DBIx::Threaded->available_drivers(1);
report_result(scalar @row, 'available_drivers', '', $DBIx::Threaded::errstr);

if ($qrymap->{CanDataSources}) {
	@row = DBIx::Threaded->data_sources($driver);
	report_result(scalar @row, 'driver->data_sources()', '', $DBIx::Threaded::errstr);
}
else {
	report_result('skip', 'driver->data_sources()');
}

@row = DBIx::Threaded->installed_versions();
report_result(scalar @row, 'installed_versions()', '', $DBIx::Threaded::errstr);
#
#	need to test the RootClass connection method...
#
my $dbh = DBIx::Threaded->connect($dsn, $user, $pass,
	{ 
		RaiseError => 0,
		PrintError => 0,
		PrintWarn => 0,
		RootClass => $subclass
	});

report_result($dbh, 'connect()', '', $DBIx::Threaded::errstr);
die "Cannot proceed: $DBIx::Threaded::errstr"
	unless $dbh;
#
#	now filter ODBC drivers to their true query map
#
if ($driver eq 'ODBC') {
	my $dbms = $dbh->get_info(17);
	$driver .= '_' . uc $dbms,
	$qrymap = $query_sets{$driver}
		if $dbms;
}
#
#	do any needed setup SQL
#
if ($qrymap->{ConnSetup}) {
	$rc = $dbh->do($qrymap->{ConnSetup});
	report_result($rc, 'do(setup)', '', $dbh->errstr);
}
else {
	report_result('skip', 'do(setup)');
}
#
#	try setting an error with no print or raise
#
$rc = $dbh->do("gooble gobble gooble gobble one of us!");
report_result(!$rc, 'bad do()', $dbh->errstr, 'no error???');

#
#	first run connection level methods, using SQL
#
$qrymap->{CanPing} ?
report_result($dbh->ping, 'ping()', '', $dbh->errstr) :
report_result('skip', 'ping()', '', '');

if ($qrymap->{CanGetInfo}) {
	my $ver = $dbh->get_info(18);
	report_result($ver, 'get_info()', '', $dbh->errstr);
}
else {
	report_result('skip', 'get_info()');
}

if ($qrymap->{CanDataSources}) {
	@row = $dbh->data_sources();
	report_result(@row && scalar @row, 'data_sources()', '', $dbh->errstr);
}
else {
	report_result('skip', 'data_sources()');
}

@row = $dbh->selectrow_array($qrymap->{UserDateTime});
report_result(@row && (scalar @row == 3), 'selectrow_array(SQL)', '', $dbh->errstr);

$row = $dbh->selectrow_arrayref($qrymap->{UserDateTime});
report_result(defined($row) && (scalar @$row == 3), 
	'selectrow_arrayref(SQL)', '', $dbh->errstr);

$row = $dbh->selectrow_hashref($qrymap->{UserDateTime});
report_result(defined($row) && (scalar keys %$row == 3), 
	'selectrow_hashref(SQL)', '', $dbh->errstr);

$row = $dbh->selectall_arrayref($qrymap->{UserDateTime});
report_result(defined($row) && (scalar @$row == 1) && (scalar @{$row->[0]} == 3),
	'selectall_arrayref(SQL)', '', $dbh->errstr);

$row = $dbh->selectall_hashref($qrymap->{UserDateTime}, $qrymap->{HashCol});
report_result(defined($row) && (scalar keys %$row == 1), 
	'selectall_hashref(SQL)', '', $dbh->errstr);

$row = $dbh->selectcol_arrayref($qrymap->{UserDateTime});
report_result(defined($row) && (scalar @$row == 1), 
	'selectcol_arrayref(SQL)', '', $dbh->errstr);

#
#	...then using a prep'd statement
#
$sth = $dbh->prepare($qrymap->{UserDateTime});
report_result($sth, 'prepare()', '', $dbh->errstr);

@row = $dbh->selectrow_array($sth);
report_result(@row && (scalar @row == 3), 'selectrow_array(sth)', '', $dbh->errstr);

unless ($driver eq 'SQLite') {
$row = $dbh->selectrow_arrayref($sth);
report_result(defined($row) && (scalar @$row == 3), 
	'selectrow_arrayref(sth)', '', $dbh->errstr);
}
else {
	report_result('skip', 'selectrow_arrayref(sth)');
}

$row = $dbh->selectrow_hashref($sth);
report_result(defined($row) && (scalar keys %$row == 3), 
	'selectrow_hashref(sth)', '', $dbh->errstr);

unless ($driver eq 'SQLite') {
$row = $dbh->selectall_arrayref($sth);
report_result(defined($row) && (scalar @$row == 1) && (scalar @{$row->[0]} == 3),
	'selectall_arrayref(sth)', '', $dbh->errstr);
}
else {
	report_result('skip', 'selectall_arrayref(sth)');
}

$row = $dbh->selectall_hashref($sth, $qrymap->{HashCol});
report_result(defined($row) && (scalar keys %$row == 1), 
	'selectall_hashref(sth)', '', $dbh->errstr);

$row = $dbh->selectcol_arrayref($sth);
report_result(defined($row) && (scalar @$row == 1), 
	'selectcol_arrayref(sth)', '', $dbh->errstr);

#
#	then run statement objects
#
$rc = $sth->execute;
report_result($rc, 'execute() for fetch()', '', $sth->errstr);

$row = $sth->fetch;
report_result(scalar @$row, 'fetch()', join(', ', @$row), $sth->errstr);

$rc = $sth->execute;
report_result($rc, 'execute() for fetchrow()', '', $sth->errstr);

@row = $sth->fetchrow;
report_result(scalar @row, 'fetchrow()', join(', ', @row), $sth->errstr);

$rc = $sth->execute;
report_result($rc, 'execute() for fetchrow_array()', '', $sth->errstr);

@row = $sth->fetchrow_array;
report_result(scalar @row, 'fetchrow_array()', join(', ', @row), $sth->errstr);

$rc = $sth->execute;
report_result($rc, 'execute() for fetchrow_arrayref', '', $sth->errstr);

$row = $sth->fetchrow_arrayref;
report_result(scalar @$row, 'fetchrow_arrayref()', join(', ', @$row), $sth->errstr);

$rc = $sth->execute;
report_result($rc, 'execute() for fetchall_arrayref', '', $sth->errstr);

$row = $sth->fetchall_arrayref;
report_result(scalar @$row, 'fetchall_arrayref()', join(', ', @$row), $sth->errstr);

$rc = $sth->execute;
report_result($rc, 'execute() for fetchrow_hashref', '', $sth->errstr);

$row = $sth->fetchrow_hashref;
report_result(scalar keys %$row, 'fetchrow_hashref()', 
	join(', ', values %$row), $sth->errstr);

$rc = $sth->execute;
report_result($rc, 'execute() for fetchall_hashref', '', $sth->errstr);

my $name = $sth->{NAME};
$row = $sth->fetchall_hashref($name->[0]);
report_result(scalar keys %$row, 'fetchall_hashref()', 
	join(', ', values %$row), $sth->errstr);
#
#	now try some binding
#
my ($date, $time);

$rc = $sth->execute;
report_result($rc, 'execute() for bind_col', '', $sth->errstr);

$sth->bind_col(1, \$user);
$sth->bind_col(2, \$date);
$sth->bind_col(3, \$time);

@row = $sth->fetch;
report_result(scalar @row, 'fetch() for bind_col', '', $sth->errstr);

$rc = defined($user) && defined($date) && defined($time);
report_result($rc, 'bind_col()', join(', ', $user, $date, $time), $sth->errstr);

$rc = $sth->execute;
report_result($rc, 'execute() for bind_columns', '', $sth->errstr);

my ($user2, $date2, $time2);
$sth->bind_columns(\$user2, \$date2, \$time2);

@row = $sth->fetch;
report_result(scalar @row, 'fetch() for bind_columns', '', $sth->errstr);

$rc = defined($user) && defined($date) && defined($time);
report_result($rc, 'bind_columns()', 
	join(', ', $user2, $date2, $time2), $sth->errstr);
#
#	setup for multi thread inserts
#
if ($qrymap->{CreateTable}) {
report_result($dbh->do($qrymap->{CreateTable}), 
	'create table', '', $dbh->errstr);
}
else {
	report_result('skip', 'create table');
}
#
#	inject a few extra tests; we need to skip some of these
#	depending on the DBD
#
if ($qrymap->{CanTableInfo}) {
	$sth = $dbh->table_info('', '', 'dbix_threaded_test', 'TABLE');
	report_result($sth, 'table_info()', '', $dbh->errstr);
}
else {
	report_result('skip', 'table_info()');
}

if ($qrymap->{CanColumnInfo}) {
$sth = $dbh->column_info('', '', 'dbix_threaded_test', 'col1');
report_result($sth, 'column_info()', '', $dbh->errstr);
}
else {
	report_result('skip', 'column_info()');
}

if ($qrymap->{CanPKInfo}) {
$sth = $dbh->primary_key_info('', '', 'dbix_threaded_test');
report_result($sth, 'primary_key_info()', '', $dbh->errstr);
}
else {
	report_result('skip', 'primary_key_info()');
}

if ($qrymap->{CanPK}) {
@row = $dbh->primary_key('', '', 'dbix_threaded_test');
report_result(scalar @row, 'primary_key()', '', $dbh->errstr);
}
else {
	report_result('skip', 'primary_key()');
}

if ($qrymap->{CanFKInfo}) {
$sth = $dbh->foreign_key_info('', '', 'dbix_threaded_test');
report_result($sth, 'foreign_key_info()', '', $dbh->errstr);
}
else {
	report_result('skip', 'foreign_key_info()');
}

if ($qrymap->{CreateTable}) {
@row = $dbh->tables('', '', 'dbix_threaded_test');
report_result(scalar @row, 'tables()', '', $dbh->errstr);
}
else {
	report_result('skip', 'tables()');
}

@row = $dbh->type_info_all();
report_result(scalar @row, 'type_info_all()', '', $dbh->errstr);

@row = $dbh->type_info(SQL_VARCHAR);
report_result(scalar @row, 'type_info()', '', $dbh->errstr);

$rc = $dbh->quote("Quote'd");
report_result($rc, 'quote()', '', $dbh->errstr);

$rc = $dbh->quote_identifier('A fine day');
report_result($rc && ($rc eq '"A fine day"'), 
	'quote_identifier()', '', $dbh->errstr);

#
#	try various combos to validate
#	pass connection; let thread prepare
#
$testtype = 'distr. execution';
my $id = $q1->enqueue('prep_exec_fetch', $dbh, $qrymap->{UserDateTime});

my $resp = $q1->wait($id);

report_result(shift @$resp, 'threaded prep, exec, and fetch', @$resp);
#
#	prepare here; let thread exec/fetch
#
$sth = $dbh->prepare($qrymap->{UserDateTime});
if ($sth) {
	$id = $q1->enqueue('exec_fetch', $sth);

	$resp = $q1->wait($id);

	report_result(shift @$resp, 'threaded exec/fetch', @$resp);
}
else {
	report_result(undef, 'threaded exec/fetch', '', $dbh->errstr);
}
#
#	prepare/exec here; let thread fetch
#
if ($sth->execute) {
	$id = $q1->enqueue('fetch', $sth);

	$resp = $q1->wait($id);

	report_result(shift @$resp, 'threaded fetch', @$resp);
}
else {
	report_result(undef, 'threaded fetch', '', $sth->errstr);
}
#
#	multi thread inserts
#
$sth = $dbh->prepare($qrymap->{InsertRow});
my @ids = ();
my @resps = ();
if ($sth) {
	push @ids, $q1->enqueue('insert', $sth, 1, 'asdfsdf', 2345.67);
	push @ids, $q2->enqueue('insert', $sth, 2, 'fgsdfgsrthfthdftfh', 2345.67);

	push @ids, $q1->enqueue('insert', $sth, 3, 'xcvbxcvbxcb', 12345.67);
	push @ids, $q2->enqueue('insert', $sth, 4, '34r5retwete', 0.67);

	push @resps, $q1->wait($ids[0]);
	push @resps, $q2->wait($ids[1]);
	push @resps, $q1->wait($ids[2]);
	push @resps, $q2->wait($ids[3]);

	my $failed = 0;
	foreach (@resps) {
		$rc = shift @$_;
		$failed = 1,
		report_result($rc, 'threaded insert', @$_),
		last
			unless $rc;
	}
	report_result(1, 'threaded insert', '', '')
		unless $failed;
#
#	now try it with transactions (via
#		-setting AutoCommit, then commit or rollback
#		-calling begin_work, then commit
#
	if ($qrymap->{CanCommit}) {
	@ids = ();
	@resps = ();
	$dbh->{AutoCommit} = 0;
	push @ids, $q1->enqueue('insert', $sth, 101, 'asdfsdf', 2345.67);
	push @ids, $q2->enqueue('insert', $sth, 102, 'fgsdfgsrthfthdftfh', 2345.67);

	push @ids, $q1->enqueue('insert', $sth, 103, 'xcvbxcvbxcb', 12345.67);
	push @ids, $q2->enqueue('insert', $sth, 104, '34r5retwete', 0.67);

	push @resps, $q1->wait($ids[0]);
	push @resps, $q2->wait($ids[1]);
	push @resps, $q1->wait($ids[2]);
	push @resps, $q2->wait($ids[3]);

	$failed = 0;
	foreach (@resps) {
		$rc = shift @$_;
		$failed = 1,
		report_result($rc, 'threaded insert w/ commit', @$_),
		last
			unless $rc;
	}
	report_result($dbh->commit(), 'threaded insert w/ commit', '', '')
		unless $failed;
	}
	else {
		report_result('skip', 'threaded insert w/ commit');
	}

	if ($qrymap->{CanCommit}) {
	@ids = ();
	@resps = ();
	push @ids, $q1->enqueue('insert', $sth, 201, 'asdfsdf', 2345.67);
	push @ids, $q2->enqueue('insert', $sth, 202, 'fgsdfgsrthfthdftfh', 2345.67);

	push @ids, $q1->enqueue('insert', $sth, 203, 'xcvbxcvbxcb', 12345.67);
	push @ids, $q2->enqueue('insert', $sth, 204, '34r5retwete', 0.67);

	push @resps, $q1->wait($ids[0]);
	push @resps, $q2->wait($ids[1]);
	push @resps, $q1->wait($ids[2]);
	push @resps, $q2->wait($ids[3]);

	$failed = 0;
	foreach (@resps) {
		$rc = shift @$_;
		$failed = 1,
		report_result($rc, 'threaded insert w/ rollback', @$_),
		last
			unless $rc;
	}
	report_result($dbh->rollback(), 'threaded insert w/ rollback', '', '')
		unless $failed;
	}
	else {
		report_result('skip', 'threaded insert w/ rollback');
	}

	if ($qrymap->{CanCommit}) {
	$dbh->{AutoCommit} = 1;
	report_result($dbh->begin_work, 'begin_work()', '', $dbh->errstr);
	}
	else {
		report_result('skip', 'begin_work()');
	}

	if ($qrymap->{CanCommit}) {
	@ids = ();
	@resps = ();
	push @ids, $q1->enqueue('insert', $sth, 301, 'asdfsdf', 2345.67);
	push @ids, $q2->enqueue('insert', $sth, 302, 'fgsdfgsrthfthdftfh', 2345.67);

	push @ids, $q1->enqueue('insert', $sth, 303, 'xcvbxcvbxcb', 12345.67);
	push @ids, $q2->enqueue('insert', $sth, 304, '34r5retwete', 0.67);

	push @resps, $q1->wait($ids[0]);
	push @resps, $q2->wait($ids[1]);
	push @resps, $q1->wait($ids[2]);
	push @resps, $q2->wait($ids[3]);

	$failed = 0;
	foreach (@resps) {
		$rc = shift @$_;
		$failed = 1,
		report_result($rc, 'threaded insert w/ begin_work', @$_),
		last
			unless $rc;
	}
	report_result($dbh->commit(), 'threaded insert w/ begin_work', '', '')
		unless $failed;
	$dbh->{AutoCommit} = 1;
	}
	else {
		report_result('skip', 'threaded insert w/ begin_work');
	}
}
else {
	report_result($sth, 'prepare insert', '', $dbh->errstr);
}
#
#	2) multi thread select
#	NOTE: this requires that the DBD supports multiple
#	open cursors
#
$sth = $dbh->prepare($qrymap->{SelectRows});
@ids = ();
@resps = ();
if ($sth) {
	push @ids, $q1->enqueue('select', $sth);
	push @ids, $q2->enqueue('select', $sth);

	push @ids, $q1->enqueue('select', $sth);
	push @ids, $q2->enqueue('select', $sth);

	$resp = $q1->wait($ids[0]);
	push @resps, $resp;

	$resp = $q2->wait($ids[1]);
	push @resps, $resp;

	$resp = $q1->wait($ids[2]);
	push @resps, $resp;

	$resp = $q2->wait($ids[3]);
	push @resps, $resp;

	my $failed = 0;
	foreach (@resps) {
		$rc = shift @$_;
		$failed = 1,
		report_result($rc, 'threaded select', @$_),
		last
			unless $rc;
	}
	report_result(1, 'threaded select', '', '')
		unless $failed;
}
else {
	report_result($sth, 'prepare threaded select', '', $dbh->errstr);
}
#
#	3) async methods: connection level first
#
$testtype = 'async';
$dbh->do('delete from dbix_threaded_test');
$id = $dbh->dbix_threaded_start('insert into dbix_threaded_test values(10, \'asgertrergfdfv\', 2397.56)');

$id ?
	report_result($dbh->dbix_threaded_wait($id), 'dbh start()', '', $dbh->errstr) :
	report_result(undef, 'dbh start()', '', $dbh->errstr);

$id = $dbh->dbix_threaded_start_selectrow_array('select * from dbix_threaded_test');
if ($id) {
	my @row = $dbh->dbix_threaded_wait($id);
	report_result(scalar @row, 'start_selectrow_array()', '', $dbh->errstr);
}
else {
	report_result(undef, 'start_selectrow_array()', '', $dbh->errstr);
}

$id = $dbh->dbix_threaded_start_selectrow_arrayref('select * from dbix_threaded_test');
if ($id) {
	report_result($dbh->dbix_threaded_wait($id), 'start_selectrow_arrayref()', '', $dbh->errstr);
}
else {
	report_result(undef, 'start_selectrow_arrayref()', '', $dbh->errstr);
}

$id = $dbh->dbix_threaded_start_selectrow_hashref('select * from dbix_threaded_test');
if ($id) {
	report_result($dbh->dbix_threaded_wait($id), 'start_selectrow_hashref()', '', $dbh->errstr);
}
else {
	report_result(undef, 'start_selectrow_hashref()', '', $dbh->errstr);
}

$id = $dbh->dbix_threaded_start_selectall_arrayref('select * from dbix_threaded_test');
if ($id) {
	report_result($dbh->dbix_threaded_wait($id), 'start_selectall_arrayref()', '', $dbh->errstr);
}
else {
	report_result(undef, 'start_selectall_arrayref()', '', $dbh->errstr);
}

$id = $dbh->dbix_threaded_start_selectall_hashref('select * from dbix_threaded_test', 'col1');
if ($id) {
	report_result($dbh->dbix_threaded_wait($id), 'start_selectall_hashref()', '', $dbh->errstr);
}
else {
	report_result(undef, 'start_selectall_hashref()', '', $dbh->errstr);
}

$id = $dbh->dbix_threaded_start_selectcol_arrayref('select * from dbix_threaded_test');
if ($id) {
	report_result($dbh->dbix_threaded_wait($id), 'start_selectcol_arrayref()', '', $dbh->errstr);
}
else {
	report_result(undef, 'start_selectcol_arrayref()', '', $dbh->errstr);
}

$id = $dbh->dbix_threaded_start_prepare($qrymap->{UserDateTime});
if ($id) {
	$sth = $dbh->dbix_threaded_wait($id);
	report_result($sth, 'start_prepare()', '', $dbh->errstr);
}
else {
	report_result(undef, 'start_prepare()', '', $dbh->errstr);
}
#
#	now stmt level
#
$id = $sth->dbix_threaded_start();
if ($id) {
	my $rc = $sth->dbix_threaded_wait($id);
	report_result($rc, 'sth start()', '', $dbh->errstr);
}
else {
	report_result(undef, 'sth start()', '', $dbh->errstr);
}
#
#	cleanup
#

$dbh->do($qrymap->{Cleanup})
	if $qrymap->{Cleanup};

$q1->enqueue_simplex('stop');
$q2->enqueue_simplex('stop');
$thrd1->join;
$thrd2->join;

undef $sth;

$dbh->disconnect;

$loaded = 1;
#
#	a thread to pass a stmt handle to and 
#	let it dump the results
#
sub sel_thread {
	my $q = shift;

	$q->listen();

	my ($id, $cmd, $sth, $dbh, $sql);	
	while (1) {
		my $params = $q->dequeue();
		$id = shift @$params;
		$cmd = shift @$params;

		last if ($cmd eq 'stop');
	
		if ($cmd eq 'prep_exec_fetch') {
			$dbh = shift @$params;
			$sql = shift @$params;

			$q->respond($id, undef, '', "Didn't get my dbh!"),
			next
				unless $dbh && ref $dbh && 
					(ref $dbh eq 'DBIx::Threaded::db');

			$q->respond($id, undef, '', "Didn't get my SQL!"),
			next
				unless $sql;

			$sth = $dbh->prepare($sql);

			$q->respond($id, undef, '', $dbh->errstr),
			next
				unless $sth;

			my $rc = $sth->execute;
	
			$q->respond($id, undef, '', $sth->errstr),
			next
				unless $rc;

			my @row = $sth->fetchrow_array;

			$q->respond($id, 1, join(', ', @row), '');
		}
		elsif ($cmd eq 'exec_fetch') {
			$sth = shift @$params;

			$q->respond($id, undef, '', "Didn't get my sth!"),
			next
				unless $sth && ref $sth && 
					(ref $sth eq 'DBIx::Threaded::st');

			my $rc = $sth->execute;
	
			$q->respond($id, undef, '', $sth->errstr),
			next
				unless $rc;

			my @row = $sth->fetchrow_array;

			$q->respond($id, 1, join(', ', @row), '');

		}
		elsif ($cmd eq 'fetch') {

			$sth = shift @$params;

			$q->respond($id, undef, '', "Didn't get my sth!"),
			next
				unless $sth && ref $sth && 
					(ref $sth eq 'DBIx::Threaded::st');

			my @row = $sth->fetchrow_array;

			$q->respond($id, 1, join(', ', @row), '');
		}
		elsif ($cmd eq 'insert') {
			$sth = $params->[0];

#print "\n**** selthread: ID $id CMD $cmd ", join(', ', @$params), "\n";

			$q->respond($id, undef, '', "Didn't get my sth!"),
			next
				unless $sth && ref $sth && 
					(ref $sth eq 'DBIx::Threaded::st');

			shift @$params;
			my $rc = $sth->execute(@$params);
	
			$rc ? 
				$q->respond($id, $rc, '', '') :
				$q->respond($id, undef, '', $sth->errstr);
		}
		elsif ($cmd eq 'select') {
			$sth = shift @$params;

			$q->respond($id, undef, '', "Didn't get my sth!"),
			next
				unless $sth && ref $sth && 
					(ref $sth eq 'DBIx::Threaded::st');

			my $rc = $sth->execute;
	
			$q->respond($id, undef, '', $sth->errstr),
			next
				unless $rc;

			1 while $sth->fetchrow_arrayref;

			$q->respond($id, 1, $rc, '');
		}
		else {
			$q->respond($id, undef, '', "Unknown command $cmd");
		}
	}
	$q->ignore;
	undef $dbh;
	return 1;
}