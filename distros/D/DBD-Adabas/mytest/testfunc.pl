#!/usr/bin/perl -I./t

use DBI qw(:sql_types);
# use DBD::ODBC::Const qw(:sql_types);

my (@row);

my $dbh = DBI->connect()
    or exit(0);
# ------------------------------------------------------------

# dumb, for now...
# SQL_DRIVER_VER returns string
# SQL_CURSOR_COMMIT_BEHAVIOR returns 16 bit value
# SQL_ALTER_TABLE returns 32 bit value 
# SQL_ACCESSIBLE_PROCEDURES returns short string (Y or N)

my %InfoTests = (
	'SQL_DRIVER_NAME', 6,
	'SQL_DRIVER_VER', 7,
	'SQL_CURSOR_COMMIT_BEHAVIOR', 23,
	'SQL_ALTER_TABLE', 86,
	'SQL_ACCESSIBLE_PROCEDURES', 20,
);

my %TypeTests = (
	'SQL_ALL_TYPES' => 0,
	'SQL_VARCHAR' => SQL_VARCHAR,
	'SQL_INTEGER' => SQL_INTEGER,
	'SQL_SMALLINT' => SQL_SMALLINT,
	'SQL_NUMERIC' => SQL_NUMERIC,
	'SQL_LONGVARCHAR' => SQL_LONGVARCHAR,
);

my $ret; 
print "\nInformation for DBI_DSN=$ENV{'DBI_DSN'}\n\n";
foreach $SQLInfo (sort keys %InfoTests) {
	$ret = 0;
	$ret = $dbh->func($InfoTests{$SQLInfo}, GetInfo);
	print "$SQLInfo ($InfoTests{$SQLInfo}):\t$ret\n";
}

print "\nGetfunctions: ", join(",", $dbh->func(0, GetFunctions)), "\n\n";

foreach $SQLInfo (sort keys %TypeTests) {
	print "Listing all $SQLInfo types\n";
	$sth = $dbh->func($TypeTests{$SQLInfo}, GetTypeInfo);
	my $colcount = $sth->func(1, 0, ColAttributes); # 1 for col (unused) 0 for SQL_COLUMN_COUNT
	print "Column count is $colcount\n";
	my $i;
	# column 0 should be an error/blank
	for ($i = 0; $i <= $colcount; $i++) {
		# $i is colno (1 based) 2 is for SQL_COLUMN_TYPE
		# $i == 0 is intentional error...tests error handling.
		print "Col Attributes (TYPE): ", $sth->func($i, 2, ColAttributes), "\n";
		print "Col Attributes (NAME): ", $sth->func($i, 1, ColAttributes), "\n";
		print "Desc Col: ", join(', ', $sth->func($i, DescribeCol)), "\n";
	}

	while (@row = $sth->fetchrow()) {
		print "$row[0]\n\t$row[1] , $row[2] , $row[3] , $row[4] , $row[5]\n";
	}
	$sth->finish();
}

$dbh->disconnect();

