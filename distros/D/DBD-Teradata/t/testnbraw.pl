BEGIN {
	push @INC, './t';
}

use DBI;
use DBD::Teradata;
use TdTestBulkload qw(load_nb_raw load_thrd_raw load_nb_vartext load_thrd_vartext);
use TdTestDataGen qw(gen_test_data);


use strict;
use warnings;

$| = 1;
my $sessions = 7;
my $thrd = undef;
my $vt = undef;

while (substr($ARGV[0], 0, 1) eq '-') {
	my $opt = shift @ARGV;

	$ENV{TDAT_DBD_NO_CLI} = 1,
	next
		if ($opt eq '-c');

	DBI->trace(2, shift @ARGV),
	$ENV{TDAT_DBD_DEBUG} = 1
		if ($opt eq '-d');

	$sessions = shift @ARGV,
	next
		if ($opt eq '-s');

	$thrd =1, next
		if ($opt eq '-t');

	$vt = 1, next
		if ($opt eq '-v');
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
#
#	pre-gen some data
#
gen_test_data()
	unless (-e 'rawdata.dat');
#
#	clear out the table
#
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

my $elapsed = 0;
if ($thrd) {
	$elapsed = $vt ?
		load_thrd_vartext($dsn, $userid, $passwd, $sessions, 10000) :
		load_thrd_raw($dsn, $userid, $passwd, $sessions, 10000);
}
else {
	$elapsed = $vt ?
		load_nb_vartext($dbh, $dsn, $userid, $passwd, $sessions, 10000) :
		load_nb_raw($dbh, $dsn, $userid, $passwd, $sessions, 10000);
}

my @row = $dbh->selectrow_array('select count(*) from alltypetst');
die $dbh->errstr unless scalar @row;
print "Table has $row[0] rows\n";

$dbh->disconnect();
