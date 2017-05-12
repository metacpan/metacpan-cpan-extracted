#! perl -w
#
#
#   This test connects and disconnects to the test database, checks
#   if the connection is alive or not and checks if we can connect a 
#   second time and as an unknown user.
#

$^W = 1;

#
#   Make -w happy
#
$test_dsn = '';
$test_user = '';
$test_password = '';

use DBI qw(:sql_types);
use vars qw($NO_FLAG $COL_NULLABLE $COL_PRIMARY_KEY);

#
#   Include lib.pl
#

$file = "lib.pl"; 
do $file; 
if ($@) { 
	print "Error while executing lib.pl: $@\n";
	exit 10;
}

$verbose = 0; # set this to 1 if you like

#
#   Main loop; leave this untouched, put tests into the loop
#
use vars qw($state);
while (Testing()) {
    #
    #   Connect to the database (first connection)
	#
	### Test 1
    my $dbh;
    Test($state or $dbh = DBI->connect($test_dsn, $test_user, $test_password) )
	or die "Sorry, cannot connect: ", $DBI::errstr, "\n";


    #
    #   Try a second connection, this should fail
    #
	
	#
	### Test 2
    my $dbh2;
    Test($state or ( ! ($dbh2 = DBI->connect(	$test_dsn, 
												$test_user, 
												$test_password,
												{RaiseError => 0, 
												 PrintError => $verbose}
											)) ) )
		 or DbiError($dbh->err, $dbh->errstr);


    #
    #   Disconnect from first connection
    #

	#
	### Test 3
    Test($state or $dbh->disconnect())
	  or DbiError($dbh->err, $dbh->errstr);
	  
	#
    # Check if the first connection is alive (this should fail)  
    #

	#
	### Test 4
    Test($state or (! $dbh->ping() ) )
	  or DbiError($dbh->err, $dbh->errstr);


    #
    #   Try a second connection with an unknown user and password, this should fail
    #
		
	#
	### Test 5
    my $dbh3;
    Test($state or ( ! ($dbh3 = DBI->connect(	$test_dsn, 
												'unknown', 
												'unknown',
												{RaiseError => 0, 
												 PrintError => $verbose}
											)) ) )
		 or DbiError($dbh->err, $dbh->errstr);


    #
    #   Try a second connection after the first has been closed (this should work)
	#
	
	#
	### Test 6
    undef $dbh;
    Test($state or $dbh = DBI->connect($test_dsn, $test_user, $test_password) )
	or die "Sorry, cannot connect: ", $DBI::errstr, "\n";

   
   	#
    # Check if this connection is alive (this should work)  
    #

	#
	### Test 7
    Test($state or $dbh->ping() )
	  or DbiError($dbh->err, $dbh->errstr);
   
   
    #
    #   Finally disconnect.
    #
	
	#
	### Test 8
    Test($state or $dbh->disconnect())
	  or DbiError($dbh->err, $dbh->errstr);
}


