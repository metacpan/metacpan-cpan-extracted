#
#	$Id: test.pl, Empress Software Inc., 0.52, Mon Jul 15 11:15:45 Canada/Eastern 1996
#

#BEGIN{unshift @INC, "../../lib", "./lib";}

use DBI "0.89";
use Sys::Hostname;
use Cwd;

my $test_dbname	= 'test_db';
my $conn_dbname	= 'test_db';
my $test_tabname = 'test_table';
my $nconnect	= 10;		# no of times to loop in testing connect
my $ncreate	= 10;		# no of times to loop in testing create/drop table
my ($iconnect, $icreate);

$mspath = $ENV{MSPATH};
if ($mspath)
{
	print "Using Empress Version located at $mspath\n";
}
else
{
	print "MSPATH not set\n";
	exit 1;
}

#----------------------------------------------------------------------
# Which version of DBD::Empress 
#----------------------------------------------------------------------
$dsql = TRUE;
print ("Running tests in local mode\n");

# Now redirect errors to file
$stderr_file = "test.stderr.$$";
open (STDERR, ">$stderr_file") || die ("open STDERR output file $stderr_file failed");


# --------------------------------------------------------------------------
# TODO: This section is not generic!!!
# --------------------------------------------------------------------------

my $mkdbcmd	= "$mspath/bin/empmkdb $test_dbname";
my $mktabcmd	= "$mspath/bin/empcmd $test_dbname \"run from \'$test_dbname.schema\'\"";
my $mkdatacmd	= "$mspath/bin/empcmd $test_dbname \"run from \'$test_dbname.data\'\"";
my $rmdbcmd	= "rm -rf $test_dbname";

# --------------------------------------------------------------------------
# install the Empress driver
# --------------------------------------------------------------------------

print "Testing: DBI->install_driver( 'Empress' ): ";
( $drh = DBI->install_driver( 'Empress' ) )
  and print( "ok\n" )
  or die "not ok: $DBI::errstr\n";

# -----------------------------------------------------------------------
# set Empress low-level debugging.  Set to 0 .. 4.
# -----------------------------------------------------------------------

DBI->internal->{DebugDispatch} = 0;

# --------------------------------------------------------------------------
# create the testing database 
# --------------------------------------------------------------------------

# TODO: This section is not generic!!!

# remove the db if it exists
if ( -d $test_dbname ) {
	print "Removing old database '$test_dbname'...";
	$st = system ($rmdbcmd);
	if ( -d $test_dbname ) {
		print "failed... exiting.\n";
		exit 1;
	}
	print "... ok\n";
}

# make db
print "Making database '$test_dbname'...";
$st = system ($mkdbcmd);
if ( $st & 256 ) {	# this checks the exit status of empmkdb...
	print "... command '$mkdbcmd' failed ($st)... exiting.\n";
	exit 1;
}
print "...ok\n";


# --------------------------------------------------------------------------
# connect/disconnect to the testing database, repeatedly
# --------------------------------------------------------------------------

print "Test repeated connect/disconnect: \$drh->connect( '$conn_dbname' ):\n";
for $iconnect (1 .. $nconnect) {

	( $dbh = DBI->connect( "DBI:Empress:$conn_dbname" ) )
	    and print(" c$iconnect\n") 
	    or die "not ok on connect $iconnect: $DBI::errstr\n";
	
	( $dbh->disconnect )
	    and print(" d$iconnect\n") 
	    or die "not ok on disconnect $iconnect: $DBI::errstr\n";

}

# --------------------------------------------------------------------------
# test the db handle functions.
# --------------------------------------------------------------------------

print "Test db handle functions\n";
( $dbh = $drh->connect( $conn_dbname ) )
    and print( "connect ok\n" )
    or die "connect not ok: $DBI::errstr\n";

# -----------------------------------------------------------------------
# test repeated table creation/table drop
# -----------------------------------------------------------------------

for $icreate (1 .. $ncreate) {

	# ------------ create

	print "Testing: \$dbh->prepare('create table $test_tabname')\n";
	( $sth = $dbh->prepare( "CREATE TABLE $test_tabname ( fname nlschar, lname nlschar, age integer, id longinteger )" ) )
	    and print( "ok ($icreate)\n" )
	    or die "not ok HERE($icreate): $DBI::errstr\n";

	print "Testing: \$sth->execute()\n";
	( $sth->execute )
	    and print( "ok ($icreate)\n" )
	    or die "not ok ($icreate): $DBI::errstr\n";
	
	# ------------ drop

	print "Testing: \$dbh->prepare('drop table $test_tabname')\n";
	( $sth = $dbh->prepare( "DROP TABLE $test_tabname" ) )
	    and print( "ok ($icreate)\n" )
	    or die "not ok ($icreate): $DBI::errstr\n";
	
	print "Testing: \$sth->execute()\n";
	( $sth->execute )
	    and print( "ok ($icreate)\n" )
	    or die "not ok ($icreate): $DBI::errstr\n";
}

# -----------------------------------------------------------------------
# create a table to do further tests with
# -----------------------------------------------------------------------

print "Testing: \$dbh->prepare('create table $test_tabname')\n";
( $sth = $dbh->prepare( "CREATE TABLE $test_tabname ( fname nlschar, lname nlschar, age integer, id longinteger )" ) )
    and print( "ok ($icreate)\n" )
    or die "not ok ($icreate): $DBI::errstr\n";

print "Testing: \$sth->execute()\n";
( $sth->execute )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

# -----------------------------------------------------------------------
# bulk insert into the table (from a file)
# -----------------------------------------------------------------------
 
print "bulk insertion into table '$test_tabname'\n";
$st = system ($mkdatacmd);
if ( $st & 256 ) {      # this checks the exit status of empcmd...
	print "Insert data command '$mkdatacmd' failed ($st)... exiting.\n";
	exit 1;
}

# -----------------------------------------------------------------------
# insert into the table
# -----------------------------------------------------------------------

print "Testing: \$dbh->prepare( 'INSERT INTO $test_tabname VALUES ( \'Mr. Mike\', \'Magoo\', 73, 99)' ): ";
( $sth = $dbh->prepare ( "INSERT INTO $test_tabname VALUES( \'Mr. Mike\', \'Magoo\', 73, 99, \'Mr. Magilla\', \'Gorilla\', 13, 98, \'Mr. Barney\', \'Rubble\', 35, 97 )" ) )
    and print( "prepare insert ok\n" )
    or die "prepare insert not ok: $DBI::errstr\n";

( $sth->execute )
    and print( "execute insert ok\n" )
    or die "execute insert not ok: $DBI::errstr\n";

# -----------------------------------------------------------------------
# update the table using a WHERE clause
# -----------------------------------------------------------------------

print "Testing: \$dbh->prepare ( 'UPDATE $test_tabname SET id = 22 WHERE lname match \'M*\'' ): ";
( $sth = $dbh->prepare ( "UPDATE $test_tabname SET id = 22 WHERE lname match \'M*\'" ) )
    and print( "prepare update ok\n" )
    or die "prepare update not ok: $DBI::errstr\n";

( $sth->execute )
    and print( "execute update ok\n" )
    or die "execute update not ok: $DBI::errstr\n";

print "Testing: \$sth->rows(): ";
( $numrows = $sth->rows( ) )
    and print( "rows() ok\n" )
    or die "rows() not ok: $DBI::errstr\n";

print "Rows returned should be: 3\nActual rows returned: $numrows\n";

# -----------------------------------------------------------------------
# delete from the table using a WHERE clause
# -----------------------------------------------------------------------

print "Testing: \$dbh->prepare( 'DELETE FROM $test_tabname WHERE id < 5' ): ";
( $sth = $dbh->prepare( "DELETE FROM $test_tabname WHERE id < 5" ) )
    and print( "prepare delete ok\n" )
    or die "prepare delete not ok: $DBI::errstr\n";

( $sth->execute )
    and print( "execute delete ok\n" )
    or die "execute delete not ok: $DBI::errstr\n";

print "Testing: \$sth->rows():\n ";
( $numrows = $sth->rows( ) )
    and print( "rows() ok\n" )
    or die "rows() not ok: $DBI::errstr\n";

print "Rows returned should be: 3\nActual rows returned: $numrows\n";

# --------------------------------------------------------------------------
# Cursor functions: prepare/execute/fetch/nrows, etc.
# --------------------------------------------------------------------------

print "Testing: \$cursor = \$dbh->prepare( 'SELECT FROM $test_tabname WHERE id = 1' ): ";
( $cursor = $dbh->prepare( "SELECT * FROM $test_tabname WHERE id = 1" ) )
    and print( "prepare select ok\n" )
    or print( "prepare select not ok: $DBI::errstr\n" );

print "Testing: \$cursor->execute: ";
( $cursor->execute )
    and print( "execute select ok\n" )
    or die "execute select not ok: $DBI::errstr\n";

# expect the following select to fail, as id=1 has been deleted already

print "Testing: \$cursor->fetchrow: ";
if ( @row = $cursor->fetchrow ) 
{
	print( "not ok ($DBI::err): $DBI::errstr, record: @row\n" );
}
else
{
	print( "ok\n" );	# expect it to fail for id=1
}

print "Testing: \$cursor->finish: ";
( $cursor->finish )
    and print( "ok\n" )
    or print( "not ok: $DBI::errstr\n" );

# multiple record tests

print "Testing: \$cursor = \$dbh->prepare( 'SELECT FROM $test_tabname' ): ";
( $cursor = $dbh->prepare( "SELECT * FROM $test_tabname" ) )
    and print( "prepare select ok\n" )
    or die "prepare select not ok: $DBI::errstr\n";

print "Testing: \$cursor->execute: ";
( $cursor->execute )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Testing: multiple \$cursor->fetchrow's:\n";
while ( @row = $cursor->fetchrow ) 
{
    if ( $DBD::Empress::err != 0 )
    {
	print "Fetch Error ($DBD::Empress::err): $DBD::Empress::errstr\n";
    }
    print( "@row\n" )
}

print "Testing: \$cursor->finish: ";
( $cursor->finish )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

( $dbh->disconnect )
    and print(" d$iconnect\n") 
    or die "not ok on disconnect $iconnect: $DBI::errstr\n";

close (STDERR);

if ($dsql eq FALSE)
{
	print "Shutting down server\n";
	system ("$mspath/bin/empoadm", "svshut", "nowarn");
}

print "*** Testing of DBD::Empress complete! You appear to be normal! ***\n";

# remove the db 
print "Removing database '$test_dbname'...";
$st = system ($rmdbcmd);
if ( -d $test_dbname ) {
	print "failed... exiting.\n";
	exit 1;
}
print "... ok\n";

system ("rm $stderr_file");

