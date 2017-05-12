#!/usr/local/bin/perl
#
#	testutf8.pl - UTF8 based test suite for DBD::Teradata
#
BEGIN {
	push @INC, './t';
}

use DBI;
use DBI qw(:sql_types);
use FileHandle;
use DBD::Teradata;
use Encode;
use Time::HiRes qw(time);
use Config;
use TdTestDataGen qw(gen_test_data);
use TdTestBulkload qw(
	load_nb_raw
	load_nb_vartext
	load_thrd_raw
	load_thrd_vartext);
use TdTestBigInt qw(dectests);
use TdTestBigSQL qw(bigsqltest);
use TdTestCursors qw(
	init_for_cursors
	updatable_cursor
	persistent_cursor
	rewind_cursor);

*STDERR = *STDOUT;

my %typestr = (
	SQL_VARCHAR, 'VARCHAR',
	SQL_CHAR, 'CHAR',
	SQL_FLOAT, 'FLOAT',
	SQL_DECIMAL, 'DECIMAL',
	SQL_INTEGER, 'INTEGER',
	SQL_SMALLINT, 'SMALLINT',
	SQL_TINYINT, 'TINYINT',
	SQL_VARBINARY, 'VARBINARY',
	SQL_BINARY, 'BINARY',
	SQL_LONGVARBINARY, 'LONG VARBINARY',
	SQL_DATE, 'DATE',
	SQL_TIMESTAMP, 'TIMESTAMP',
	SQL_TIME, 'TIME'
	);

use strict;
use warnings;

my $dbh;
#
#	process cmdline options
#
my $label;
my %opts = ( '-s', 8, '-d', 9, '-t', 10, '-v', 12);
my $logfile = undef;
# do all of normal,
#	tests 2 session limit, no tracing, threads on, default Teradata version
my @specials = (undef, 1, undef, undef, undef, undef, undef, undef, 2, 0, 1, 1, undef);

#
#	for mp debug
#$DB::fork_TTY = '/dev/ttyp2';


my $doall = 1;
if ($ARGV[0]=~/^-/) {
	@specials = (0) x 12;
	$specials[8] = 2;	# deflt util sesscount
	$specials[10] = 1;	# deflt threads enabled
	$specials[11] = 1;	# deflt use cli enabled
	while (1) {
		last
			unless ($ARGV[0]=~/^-/);

		$label = shift @ARGV;

		usage() and exit
			if ($label eq '-h');

		die "Unknown option $label; valid options are -[hsdv]\n"
			unless $opts{$label};

		$specials[$opts{$label}] = 1;

		$specials[$opts{$label}] = shift @ARGV
			if (($label eq '-t') && ($ARGV[0]=~/^[012]$/));

		$logfile = shift @ARGV
			if ($label eq '-d');

		$specials[8] = shift @ARGV
			if (($label eq '-s') && ($ARGV[0]=~/^\d+$/));

		$specials[12] = shift @ARGV
			if ($label eq '-v');
	}
}
#
#	R6.2 CLI manual says this is needed on UNIX to do threads
#
$ENV{THREADONOFF} = 1 if $specials[10];

my ($dsn, $userid, $passwd) = @ARGV;

$dsn = $ENV{'TDAT_DBD_DSN'},
$userid = $ENV{'TDAT_DBD_USER'},
$passwd = $ENV{'TDAT_DBD_PASSWORD'},
	unless defined($dsn) && defined($userid) && defined($passwd);

die "No host defined...check TDAT_DBD_DSN environment variable\n"
	unless defined($dsn);

die "No userid defined...check TDAT_DBD_USER environment variable\n"
	unless defined($userid);

die "No password defined...check TDAT_DBD_PASSWORD environment variable\n"
	unless defined($passwd);

unlink($logfile),
DBI->trace(2, $logfile),
$ENV{TDAT_DBD_DEBUG} = 1
	if $specials[9];

$ENV{TDAT_DBD_NO_CLI} = 1
	unless $specials[11];

my $versnum = $specials[12];

print STDERR "Logging onto $dsn as $userid...\n";
########################
#$DBD::Teradata::Cli::debug = 1;
##########################

$dbh = DBI->connect("dbi:Teradata:$dsn", $userid, $passwd,
	{
		PrintError => 0,
		RaiseError => 0,
		tdat_charset => 'UTF8',
		tdat_mode => 'TERADATA',
	}
) || die "Can't connect to $dsn: $DBI::errstr. Exiting...\n";
print STDERR "Logon to $dsn ver. " . $dbh->{tdat_version} . '(' . $dbh->{tdat_mode} . " mode) ok.\n";
my $drh = $dbh->{Driver};
print STDERR "DBD::Teradata v. $drh->{Version}\n";

#$specials[10] = 0,
#print STDERR "Using CLI; thread tests disabled.\n"
#	if $dbh->{tdat_uses_cli};

die "Did not connect with CLI adapter, check your configuration."
	if $specials[11] && (! $dbh->{tdat_uses_cli});

$dbh->{tdat_versnum} = $versnum,
print STDERR "*** Emulating Teradata Version $versnum\n"
	if $versnum && (int($versnum/100) != int($dbh->{tdat_versnum}/100));

print STDERR "The following tests will be performed:\n";
print STDERR "Normal SQL with raw and vartext extensions\n" if $specials[1];
print STDERR "Fastload with raw and vartext extensions\n" if $specials[2];
print STDERR "Multiload with raw and vartext extensions\n" if $specials[3];
print STDERR "Fastexport\n" if $specials[4];
print STDERR "PM/API\n" if $specials[5];
print STDERR "Remote Console\n" if $specials[6];
print STDERR "Utility Loopback\n" if $specials[7];
print STDERR "Thread tests " . ($specials[10] ? ($specials[10] == 1) ? 'enabled' : 'only' : 'disabled') . "\n";
print STDERR "CLI adapter " . ($specials[11] ? 'enabled.' : 'disabled.') . "\n";
print STDERR "\n";

my ($i, $j, $rc, $rowcnt, $row);
my $sescnt = 7;

my ($sth, $ssth, $stmtnum, $stmtinfo,, $stmthash);
my ($updsth, $delsth, $reccnt, $ostarted, $fmostarted);
my ($bcstarted, $threshold);
my ($rows, $ristarted, $tristarted, $rbcstarted, $len);
my ($rvstarted, $trvstarted, $mprfestarted, $tmprfestarted, $rostarted, $vostarted);
my ($austarted, $apstarted, $aunstarted, $ausstarted, $apsstarted,
	$aitstarted, $avtstarted, $aifstarted, $avfstarted);
#
#	force dateform to integer
#
$dbh->do('set session dateform=integerdate');
#
#	pre-gen some data
#
gen_test_data()
	unless (-e 'rawdata.dat');

if ($specials[1]) {
###################################################
#
#	buffer size adjustment test
#
###################################################
print STDERR "Testing Buffer adjustment and large responses...\n";
#
#	first, big buffers
#
$dbh->{tdat_reqsize} = (2**17) - 1;
$dbh->{tdat_respsize} = (2**19) - 1;

my $respchk = $dbh->selectall_arrayref('select user, date, time')
	or die "Can't adjust buffers: " . $dbh->errstr . "\n";

die "Unexpected results\n"
	unless (scalar @$respchk == 1) &&
		(scalar @{$respchk->[0]} == 3);

$respchk = $dbh->selectall_arrayref('SELECT user(char(30000))', {tdat_formatted => 1})
	or die "Can't adjust buffers: " . $dbh->errstr . "\n";

die "Unexpected results\n"
	unless (scalar @$respchk == 1) &&
		(scalar @{$respchk->[0]} == 1) &&
		(length($respchk->[0]->[0]) >= 24000);	# not 30000, due to UTF encoding weirdness

#
#	then, small buffers
#
$dbh->{tdat_reqsize} = (2**8) - 1;
$dbh->{tdat_respsize} = (2**10) - 1;

$sth = $dbh->prepare( 'SELECT user(char(30000))', {tdat_formatted => 1}) || die ($dbh->errstr . "\n");
$rc = $sth->execute;
die ($sth->errstr . "\n") unless defined($rc);

die "Unexpected results\n"
	unless (scalar @$respchk == 1) &&
		(scalar @{$respchk->[0]} == 1) &&
		(length($respchk->[0]->[0]) >= 24000); 	# not 30000, due to UTF encoding weirdness

print STDERR "Buffer adjustment w/ large response ok.\n";

###################################################
#
#	test metadata
#
###################################################
print STDERR "Test metadata...\n";
my @tbls = $dbh->tables;
my $tblcnt = ($#tbls > 10) ? 10 : $#tbls;
print "Partial table listing:\n" if ($tblcnt < $#tbls);
print join("\n", @tbls[0..$tblcnt]), "\n";

$sth = $dbh->table_info;
my $names = $sth->{NAME};
$tblcnt = 0;
while ($row = $sth->fetchrow_arrayref) {
	$tblcnt++;
	last if ($tblcnt > 10);
	print $$names[$_], ': ', (defined($$row[$_]) ? $$row[$_] : 'NULL'), "\n"
		foreach (0..$#$row);
}

my $typeinfo = $dbh->type_info_all() || die "Can't get type info: " . $dbh->errstr . "\n";

my $srvname = $dbh->get_info(13) || die "Can't get_info(SQL_SERVER_NAME): " . $dbh->errstr . "\n";
$srvname = $dbh->get_info(17) || die "Can't get_info(SQL_DBMS_NAME): " . $dbh->errstr . "\n";
die "Invalid DBMS name $srvname\n" unless ($srvname eq 'Teradata');

print STDERR (($tblcnt > 0) ? "Metadata OK.\n" : "Metadata failed.\n");
###################################################
#
#	test large response
#
###################################################
if ($dbh->{tdat_versnum} < 6000000) {
	print STDERR "Large response not supported, skipping...\n";
}
else {
	print STDERR "Test large response...\n";
	my $lsth = $dbh->prepare('select * from dbc.columnsx order by databasename, tablename, columnname')
		or die "Can't prepare large response request: " . $dbh->errstr . "\n";
	$lsth->execute
		or die "Can't execute large response request: " . $lsth->errstr . "\n";
	my $rowcnt = 0;
	my $row;
	while ($row = $lsth->fetchrow_arrayref) {
		print "\r Recv'd $rowcnt rows..."
			unless ++$rowcnt % 100;
	}
	print STDERR "\n$rowcnt rows returned.\n";
	print STDERR "Large response OK.\n";
}
###################################################
#
#	test DDL
#
###################################################
print STDERR "Testing DDL...\n";
$dbh->do( 'DROP TABLE alltypetst');
($dbh->err != 3807) ? die $dbh->errstr : print STDERR $dbh->errstr . "\n"
	if $dbh->err;

my $ctsth = $dbh->prepare( 'CREATE TABLE alltypetst, NO FALLBACK (
col1 integer,
col2 smallint,
col3 byteint,
col4 char(20) character set unicode,
col5 varchar(100) character set unicode,
col6 float,
col7 decimal(2,1),
col8 decimal(4,2),
col9 decimal(8,4),
col10 decimal(14,5),
col11 date,
col12 time,
col13 timestamp(0))
unique primary index(col1);'
) || die ($dbh->errstr . "\n");

$rc = $ctsth->execute;
die ($ctsth->errstr . "\n") unless defined($rc);
###################################################
#
#	test result when update to empty table
#
###################################################
print STDERR "Update empty table...\n";
$rc = $dbh->do('UPDATE alltypetst SET col2 = 23 WHERE col1 = 10');
die ($ctsth->errstr . "\n") unless defined($rc);
print STDERR "Update empty table OK\n";

print STDERR "SHOW TABLE...\n";
$sth = $dbh->prepare('SHOW TABLE alltypetst') || die ($dbh->errstr . "\n");
$rc = $sth->execute;
die ($sth->errstr . "\n") unless defined($rc);
$names = $sth->{NAME};

while ($row = $sth->fetchrow_arrayref() ) {
	foreach (0..$#$row) {
		if (defined($$row[$_])) {
			$$row[$_]=~s/\r/\n/g;
			print "$$names[$_]:\n$$row[$_]\n";
		}
		else {
			print "$$names[$_]: NULL\n";
		}
	}
	print "\n";
}
print STDERR "SHOW TABLE OK\n";

print STDERR "HELP TABLE...\n";
$sth = $dbh->prepare('HELP TABLE alltypetst') || die ($dbh->errstr . "\n");
$rc = $sth->execute;
die ($sth->errstr . "\n") unless defined($rc);
$names = $sth->{NAME};

while ($row = $sth->fetchrow_arrayref() ) {
	print $$names[$_], ': ', (defined($$row[$_]) ? $$row[$_] : 'NULL'), "\n"
		foreach (0..$#$row);
	print "\n";
}
print STDERR "HELP TABLE OK\n";

print STDERR "EXPLAIN...\n";
$sth = $dbh->prepare('EXPLAIN select * from alltypetst') || die ($dbh->errstr . "\n");
$sth->execute or die ($sth->errstr . "\n");

while ($row = $sth->fetchrow_arrayref() ) {
	foreach (@$row) {
		print "NULL\n" and next
			unless defined($_);

		$_=~s/\r/\n/g;
		print $_;
	}
	print "\n";
}
print STDERR "EXPLAIN OK\n";
###################################################
#
#	test MACRO execution
#
###################################################
print STDERR "Testing Macro creation...\n";

$rc = $dbh->do( 'DROP MACRO dbitest');
die $dbh->errstr unless
	(defined($rc) || ($dbh->err == 3824));
#print STDERR $dbh->errstr . "\n" if $dbh->err;

my $cmsth = $dbh->prepare(
'CREATE MACRO dbitest(col1 integer,
col2 smallint,
col3 byteint,
col4 char(20) character set unicode,
col5 varchar(100) character set unicode,
col6 float,
col7 decimal(2,1),
col8 decimal(4,2),
col9 decimal(8,4),
col10 decimal(14,5),
col11 DATE,
col12 TIME,
col13 TIMESTAMP(0)) AS (
INSERT INTO alltypetst VALUES(:col1, :col2, :col3, :col4, :col5, :col6,
:col7, :col8, :col9, :col10, :col11, :col12, :col13);
 /* now read it back */
SELECT * FROM alltypetst; );' ) || die ($dbh->errstr . "\n");
$cmsth->execute or die ($cmsth->errstr . "\n");

print STDERR "DROP/CREATE MACRO ok.\n";
#
#	now test all datatypes as bound params
#	and placeholders
#
print STDERR "Testing multiple prepared statements, placeholders, and explicit commit...\n";
$dbh->{AutoCommit} =  0;

my $isth = $dbh->prepare(
'INSERT INTO alltypetst VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?(time(6)), ?(timestamp(0)))')
	|| die ($dbh->errstr . "\n");
my $dsth = $dbh->prepare( 'DELETE FROM alltypetst') || die ($dbh->errstr . "\n");
$ssth = $dbh->prepare('SELECT * FROM alltypetst ORDER BY col1',
	{ChopBlanks => 1}) || die ($dbh->errstr . "\n");
#
#	insert a row
#
print STDERR "Test explicit param binding...\n";
my @invals = (123456, 1234, 12, 'perl is great', 'okey dokey',
12.34567, 1.2, 12.34, 1234.5678, 123456789.01234,
1021121, '11:21:02.034500', '2002-11-21 11:21:02');

$isth->bind_param(1, 123456) || die ($isth->errstr . "\n");
$isth->bind_param(2, 1234) || die ($isth->errstr . "\n");
$isth->bind_param(3, 12) || die ($isth->errstr . "\n");
$isth->bind_param(4, 'perl is great') || die ($isth->errstr . "\n");
$isth->bind_param(5, 'okey dokey') || die ($isth->errstr . "\n");
$isth->bind_param(6, 12.34567) || die ($isth->errstr . "\n");
$isth->bind_param(7, 1.2) || die ($isth->errstr . "\n");
$isth->bind_param(8, 12.34) || die ($isth->errstr . "\n");
$isth->bind_param(9, 1234.5678) || die ($isth->errstr . "\n");
$isth->bind_param(10, 123456789.01234) || die ($isth->errstr . "\n");
$isth->bind_param(11, '2002-11-21') || die ($isth->errstr . "\n");
$isth->bind_param(12, '11:21:02.0345') || die ($isth->errstr . "\n");
$isth->bind_param(13, '2002-11-21 11:21:02') || die ($isth->errstr . "\n");

$isth->execute or die ($isth->errstr . "\n");
#
#	make sure the returned values are the same
#	as we inserted
#
$names = $ssth->{NAME};
$ssth->execute or die ($ssth->errstr . "\n");
while ($row = $ssth->fetchrow_arrayref() ) {
	foreach (0..$#$row) {
		print $$names[$_], ': ', (defined($$row[$_]) ? $$row[$_] : 'NULL'), "\n";
		print "WARNING: field $$names[$_] does not match: src len ", length($invals[$_]), " recv len ", length($$row[$_]), "\n"
			if ($$row[$_] ne $invals[$_]);
	}
	print "\n";
}
print STDERR "Explicit param binding OK\n";
###################################################
#
#	now try passing wo/ bind
#
###################################################
print STDERR "Test default param binding...\n";
$isth->execute(234567, 2345, 23, 'perl is great',
	'a really long string to test that default bindings get adjusted',
	12.3456, 1.2, 12.34, 1234.5678, -12345679.01234,
	'2002-12-20', '23:43:56.098', undef) or die ($isth->errstr . "\n");

$names = $ssth->{NAME};
$ssth->execute || die ($ssth->errstr . "\n");
while ($row = $ssth->fetchrow_arrayref() ) {
	print $$names[$_], ': ', (defined($$row[$_]) ? $$row[$_] : 'NULL'), "\n"
		foreach (0..$#$row);
	print "\n";
}
print STDERR "Default param binding OK\n";
###################################################
#
#	test explicit column binding
#
###################################################
print STDERR "Testing explicit column binding...\n";
my ($bcol1, $bcol2, $bcol3, $bcol4, $bcol5, $bcol6, $bcol7, $bcol8, $bcol9, $bcol10, $bcol11, $bcol12, $bcol13);
$ssth->bind_col(1, \$bcol1);
$ssth->bind_col(2, \$bcol2);
$ssth->bind_col(3, \$bcol3);
$ssth->bind_col(4, \$bcol4);
$ssth->bind_col(5, \$bcol5);
$ssth->bind_col(6, \$bcol6);
$ssth->bind_col(7, \$bcol7);
$ssth->bind_col(8, \$bcol8);
$ssth->bind_col(9, \$bcol9);
$ssth->bind_col(10, \$bcol10);
$ssth->bind_col(11, \$bcol11);
$ssth->bind_col(12, \$bcol12);
$ssth->bind_col(13, \$bcol13);
$ssth->execute or die $ssth->errstr;

$bcol13 ||= 'NULL',
print join(', ', $bcol1, $bcol2, $bcol3, $bcol4, $bcol5, $bcol6, $bcol7, $bcol8, $bcol9, $bcol10, $bcol11, $bcol12, $bcol13), "\n"
	while $ssth->fetch;

print STDERR "Explicit column binding OK\n";
#
#	clean up
#
$dbh->commit || die ($dbh->errstr . "\n");

$dbh->{AutoCommit} = 1;

$dsth->execute or die ($dsth->errstr . "\n");

print STDERR "DELETE/Parameterized INSERT/SELECT, and commit() ok.\n";
###################################################
#
#	test the MACRO execution
#
###################################################
print STDERR "Testing MACRO execution w/ USING...\n";
$isth = $dbh->prepare(
'USING (col1 INTEGER,
col2 SMALLINT,
col3 BYTEINT,
col4 char(40),
col5 varchar(200),
col6 float,
col7 decimal(2,1),
col8 decimal(4,2),
col9 decimal(8,4),
col10 decimal(14,5),
col11 date,
col12 time,
col13 timestamp(0))
EXEC dbitest(:col1, :col2, :col3, :col4, :col5, :col6, :col7, :col8, :col9, :col10,
:col11, :col12, :col13)') || die ($dbh->errstr . "\n");
$isth->bind_param(1, 123456) || die ($isth->errstr . "\n");
$isth->bind_param(2, 1234) || die ($isth->errstr . "\n");
$isth->bind_param(3, 12) || die ($isth->errstr . "\n");
$isth->bind_param(4, 'rough and ready') || die ($isth->errstr . "\n");
$isth->bind_param(5, 'okey dokey') || die ($isth->errstr . "\n");
$isth->bind_param(6, 12.34567) || die ($isth->errstr . "\n");
$isth->bind_param(7, 1.2) || die ($isth->errstr . "\n");
$isth->bind_param(8, 12.34) || die ($isth->errstr . "\n");
$isth->bind_param(9, 1234.5678) || die ($isth->errstr . "\n");
$isth->bind_param(10, 123456789.01234) || die ($isth->errstr . "\n");
$isth->bind_param(11, 1021231) || die ($isth->errstr . "\n");
$isth->bind_param(12, '20:32:45.567') || die ($isth->errstr . "\n");
$isth->bind_param(13, '2002-12-20 11:22:33') || die ($isth->errstr . "\n");
$rc = $isth->execute;
die ($isth->errstr . "\n") unless defined($rc);

$names = $isth->{NAME};
my $typestr = $isth->{tdat_TYPESTR};
while ($isth->{tdat_more_results}) {
	$stmthash = $isth->{tdat_stmt_info}->[$isth->{tdat_stmt_num}];
	print 'For statement ', $isth->{tdat_stmt_num}, ":\n";
	print "$_ is ", (defined($$stmthash{$_}) ? $$stmthash{$_} : 'undefined'), "\n"
		foreach (keys(%$stmthash));

	while ($row = $isth->fetchrow_arrayref) {
		print $$names[$_], '(', $$typestr[$_], '): ',
			(defined($$row[$_]) ? $$row[$_] : 'NULL'), "\n"
			foreach ($$stmthash{StartsAt}..$$stmthash{EndsAt});
		print "\n";
	}
}

print STDERR "MACRO execution w/ USING ok.\n";
###################################################
#
#	test summary support
#
###################################################
print STDERR "Testing summarized SELECT...\n";
my $sumsth = $dbh->prepare(
'select col1, col2, col9 from alltypetst with avg(col2), avg(col9) by col1
with sum(col2)') || die ($dbh->errstr . "\n");
$names = $sumsth->{NAME};
$sumsth->execute or die ($ssth->errstr . "\n");
$stmtnum = $sumsth->{'tdat_stmt_num'};
$stmtinfo = $sumsth->{'tdat_stmt_info'};
$stmthash = $$stmtinfo[1];
print "$_ is ", (defined($$stmthash{$_}) ? $$stmthash{$_} : 'undefined'), "\n"
	foreach (keys(%$stmthash));
my $sumstarts = $$stmthash{'SummaryStarts'};
my $sumends = $$stmthash{'SummaryEnds'};
my $colstart = $$stmthash{'StartsAt'};
my $colend = $$stmthash{'EndsAt'};

while ($row = $sumsth->fetchrow_arrayref() ) {
	if (defined($$stmthash{'IsSummary'})) {
		my $issum = $$stmthash{'IsSummary'};
		print "\n-------------------------------------\n";
		my $sumpos = $$stmthash{'SummaryPosition'};
		my $sumposst = $$stmthash{'SummaryPosStart'};
		for ($i = $$sumstarts[$issum], $j = $$sumposst[$issum];
			$i <= $$sumends[$issum]; $i++, $j++) {
			print "\t" x $$sumpos[$j], "$$names[$i] = $$row[$i],\n";
		}
	}
	else {
		print "$$names[$_] = $$row[$_], "
			foreach ($colstart..$colend);
	}
	print "\n";
}

print STDERR "Summarized SELECT ok.\n";

###################################################
#
#	test BigInt vs. float decimals
#
###################################################

dectests($dbh);

###################################################
#
#	test Big SQL
#
###################################################

bigsqltest($dbh)
	if ($dbh->{tdat_versnum} >= 5000000);

###################################################
#
#	test stored procedures
#
###################################################
if ($dbh->{tdat_versnum} >= 4000000) {
	eval {
		require TdTestProcs;
		import TdTestProcs qw(sptests);
	};
	die "Unable to load TdTestProcs: $@"
		if $@;
	sptests($dbh);
}
else {
	print STDERR "Unable to test stored procedures: not supported by DBMS.\n";
}

###################################################
#
#	test bulkloads
#
###################################################

$| = 1;

$ristarted  = load_nb_raw($dbh, $dsn, $userid, $passwd, $sescnt, 1000);

$rvstarted  = load_nb_vartext($dbh, $dsn, $userid, $passwd, $sescnt, 1000);
###################################################
#
#	test threaded implementation of above,
#	but only with no-cli
#
###################################################
#if ($Config{useithreads} && $specials[10] && (! $dbh->{tdat_uses_cli})) {
if ($Config{useithreads} &&
	($Config{useithreads} eq 'define') &&
	$specials[10]) {
	$tristarted  = load_thrd_raw($dsn, $userid, $passwd, $sescnt, 1000);

	$trvstarted  = load_thrd_vartext($dsn, $userid, $passwd, $sescnt, 1000);
}
else {
	print STDERR "Perl built without thread support, skipping thread tests\n"
		if $specials[10];
}
###################################################
#
#	test updatable cursors
#
###################################################
if ($dbh->{tdat_uses_cli}) {
	print STDERR "Using CLI, skipping persistent/rewindable cursors.\n";
}
else {
	init_for_cursors($dbh, 1000);
	updatable_cursor($dbh, $dsn, $userid, $passwd);

	persistent_cursor($dbh);
	rewind_cursor($dbh);
}

###################################################
#
#	test output mode
#
###################################################
print STDERR "Testing standard output mode...\n";

init_for_cursors($dbh, 10000);

$ostarted = time;
$ssth = $dbh->prepare('SELECT * FROM alltypetst') or die ($dbh->errstr . "\n");
$names = $ssth->{NAME};
print join(' ', @$names), "\n";

$ssth->execute or die ($ssth->errstr . "\n");
$reccnt = 0;
while ($row = $ssth->fetchrow_arrayref() ) {
	$reccnt++;
	print STDERR "Got $reccnt rows\n"
		unless $reccnt%1000;
}
$ostarted = trim_time($ostarted);
print STDERR "$reccnt rows retrieved in $ostarted secs.\n";

print STDERR "Std output ok.\n";
###################################################
#
#	test formatted output mode
#
###################################################
print STDERR "Testing formatted output mode...\n";
$fmostarted = time;
$ssth = $dbh->prepare('SELECT * FROM alltypetst', {tdat_formatted => 1}) ||
	die ($dbh->errstr . "\n");
$names = $ssth->{NAME};
print join(' ', @$names), "\n";

$ssth->execute or die ($ssth->errstr . "\n");
$reccnt = 0;
while ($row = $ssth->fetchrow_arrayref() ) {
	$reccnt++;
	print STDERR "Got $reccnt rows\n"
		unless $reccnt%1000;
}
$fmostarted = trim_time($fmostarted);
print STDERR "$reccnt rows retrieved in $fmostarted secs.\n";

print STDERR "Formatted output ok.\n";
###################################################
#
#	test raw output mode
#
###################################################
print STDERR "Testing raw output mode...\n";
$rostarted = time;
$ssth = $dbh->prepare('SELECT * FROM alltypetst', {
	tdat_raw_out => 'IndicatorMode'
	}) || die ($dbh->errstr . "\n");
$names = $ssth->{NAME};
#print join(' ', @$names), "\n";

$ssth->execute or die ($ssth->errstr . "\n");
$reccnt = 0;
while ($row = $ssth->fetchrow_arrayref() ) {
	$reccnt++;
	print STDERR "Got $reccnt rows\n" unless $reccnt%1000;
}
$rostarted = trim_time($rostarted);
print STDERR "$reccnt rows retrieved in $rostarted secs.\n";

print STDERR "Raw output ok.\n";
###################################################
#
#	test vartext output mode
#
###################################################
print STDERR "Testing vartext output mode...\n";
$vostarted = time;
$ssth = $dbh->prepare('SELECT * FROM alltypetst', {
	tdat_vartext_out => '|'
	}) || die ($dbh->errstr . "\n");
$names = $ssth->{NAME};
#print join(' ', @$names), "\n";

$ssth->execute or die ($ssth->errstr . "\n");
$reccnt = 0;
while ($row = $ssth->fetchrow_arrayref() ) {
	$reccnt++;
	print "Got $reccnt rows\n" and
	print $$row[0], "\n"
		unless $reccnt%1000;
}
$vostarted = trim_time($vostarted);
print STDERR "$reccnt rows retrieved in $vostarted secs.\n";

print STDERR "Vartext output ok.\n";
###################################################
#
#	test tdat_BindColArray()
#
###################################################
print STDERR "Testing tdat_BindColArray()...\n";
my @col1 = ();
my @col2 = ();
my @col3 = ();
my @col4 = ();
my @col5 = ();
my @col6 = ();
my @col7 = ();
my @col8 = ();
my @col9 = ();
my @col10 = ();
my @col11 = ();
my @col12 = ();
my @col13 = ();
$sth = $dbh->prepare('SELECT * from alltypetst') or die $dbh->errstr;
$sth->tdat_BindColArray(1, \@col1, 300);
$sth->tdat_BindColArray(2, \@col2, 300);
$sth->tdat_BindColArray(3, \@col3, 300);
$sth->tdat_BindColArray(4, \@col4, 300);
$sth->tdat_BindColArray(5, \@col5, 300);
$sth->tdat_BindColArray(6, \@col6, 300);
$sth->tdat_BindColArray(7, \@col7, 300);
$sth->tdat_BindColArray(8, \@col8, 300);
$sth->tdat_BindColArray(9, \@col9, 300);
$sth->tdat_BindColArray(10, \@col10, 300);
$sth->tdat_BindColArray(11, \@col11, 300);
$sth->tdat_BindColArray(12, \@col12, 300);
$sth->tdat_BindColArray(13, \@col13, 300);

$bcstarted = time;
$sth->execute or die $sth->errstr;
$rowcnt = 0;
$threshold = 1000;
while ($sth->fetch) {
	$rowcnt += scalar(@col1);
	print STDERR "Got $rowcnt rows...\n" and
	$threshold += 1000
		if ($rowcnt >= $threshold);
	$#col1 = -1;
}

$bcstarted = trim_time($bcstarted);
print STDERR "Recvd $rowcnt rows in $bcstarted secs.\n";
print STDERR "tdat_BindColArray OK.\n";
###################################################
#
#	test rawmode tdat_BindColArray()
#
###################################################
print STDERR "Testing rawmode tdat_BindColArray()...\n";
my @cols = ();
$sth = $dbh->prepare('SELECT * from alltypetst',
	{ tdat_raw_out => 'IndicatorMode' });
$sth->tdat_BindColArray(1, \@cols, 300);
$rbcstarted = time;
$sth->execute or die "Can't execute:" . $sth->errstr . "\n";
$rowcnt = 0;
$threshold = 1000;
while ($sth->fetch) {
	$rowcnt += scalar(@cols);
	print STDERR "Got $rowcnt rows...\n" and
	$threshold += 1000
		if ($rowcnt >= $threshold);
	@cols = ();
}

$rbcstarted = trim_time($rbcstarted);
print STDERR "Recvd $rowcnt rows in $rbcstarted secs.\n";
print STDERR "Rawmode tdat_BindColArray OK.\n";

}
##################################
#
#	All done, clean up and report results
#
##################################
print STDERR "Cleaning up...\n";
#$dbh->do('DROP TABLE alltypetst');
$rc = $dbh->do('DROP MACRO dbitest');

my $out =
"Raw input:                 $ristarted secs
Vartext input:             $rvstarted secs
"
	if $specials[1];

$out .=
"Threaded Raw input:        $tristarted secs
Threaded Vartext input:    $trvstarted secs
"
	if $specials[1] && $specials[10];

print
"$out
Std output:                $ostarted secs
Formatted output:          $fmostarted secs
Raw output:                $rostarted secs
Vartext output:            $vostarted secs
tdat_BindColArry:          $bcstarted secs
Rawmode tdat_BindColArray: $rbcstarted secs
\n"
	if $specials[1];

print STDERR "Logging off...\n";
$dbh->disconnect();
print STDERR "Tests completed ok, exitting...\n";

sub usage {
	print
"test.pl [options] [ hostname userid password[,account] ]
where [options] are any number of instances of
	-h : print this message
	-s count : set max sessions for utilities (default 2)
	-d logfile : turn on diagnostic tracing and log to logfile
	-t [2|1|0] : only/enable/disable thread testing (default enabled)
	-v <version> : force behavior for specified integer Teradata version
		(e.g., 6000127 eq 'V2R6.0.1.27')

Default is all tests, no trace, 2 sessions, enable thread testing.

If no host/user/password are given, then the environment variables
TDAT_DBD_DSN, TDAT_DBD_USER, and TDAT_DBD_PASSWORD are used.

Example:

perl test.pl -d bugtest.txt DBC dbitst dbitst

will use the DBC server, user dbitst password dbitst and will log
traces to bugtest.txt.
";

}

sub trim_time {
	return int((time - $_[0]) * 1000)/1000;
}
