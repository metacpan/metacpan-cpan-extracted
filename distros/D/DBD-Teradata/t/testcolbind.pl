BEGIN {
	push @INC, './t';
}

use DBI;
use DBD::Teradata;
use TdTestBulkload qw(load_nb_raw);
use TdTestDataGen qw(gen_test_data);
use Time::HiRes qw(time);

use strict;
use warnings;

$| = 1;

my $load;
while (substr($ARGV[0], 0, 1) eq '-') {
	my $opt = shift @ARGV;

	$ENV{TDAT_DBD_NO_CLI} = 1,
	next
		if ($opt eq '-c');

	DBI->trace(2, shift @ARGV),
	$ENV{TDAT_DBD_DEBUG} = 1
		if ($opt eq '-d');

	$load = 1, next
		if ($opt eq '-l');
}
my $dbh;
my ($dsn, $userid, $passwd) = @ARGV;

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

die "Did not connect with CLI adapter, check your configuration."
	unless $dbh->{tdat_uses_cli} || $ENV{TDAT_DBD_NO_CLI};

print STDERR "Connected via ", ($dbh->{tdat_uses_cli} ? 'CLI' : 'pure Perl'), "\n";
#
#	force dateform to integer
#
$dbh->do('set session dateform=integerdate');

if ($load) {
#
#	pre-gen some data
#
gen_test_data()
	unless (-e 'rawdata.dat');
#
#	clear out the table
#
print STDERR "Reloading table...\n";
$dbh->do( 'DROP TABLE alltypetst');
die $dbh->errstr
	if $dbh->err && ($dbh->err != 3807);

my $ctsth = $dbh->do( 'CREATE TABLE alltypetst, NO FALLBACK (
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

load_nb_raw($dbh, $dsn, $userid, $passwd, 4, 4000);

my @row = $dbh->selectrow_array('select count(*) from alltypetst');
die $dbh->errstr unless scalar @row;
print "Table has $row[0] rows\n";
}
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
my $sth = $dbh->prepare('SELECT * from alltypetst') or die $dbh->errstr;
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

my $bcstarted = time;
$sth->execute or die $sth->errstr;
my $rowcnt = 0;
my $threshold = 1000;
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
my $rbcstarted = time;
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

sub trim_time {
	return int((time - $_[0]) * 1000)/1000;
}
