#! perl -w
#
#
#   This is a simple insert/fetch test.
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


#
#   Main loop; leave this untouched, put tests after creating
#   the new table.
#
while (Testing()) {
    #
    #   Connect to the database
	#
	### Test 1
    Test($state or $dbh = DBI->connect($test_dsn, $test_user, $test_password))
	or die "Sorry, cannot connect: ", $DBI::errstr, "\n";

    #
    #   Find a possible new table name
    #
	#
	### Test 2
    Test($state or $table = FindNewTable($dbh))
	   or DbiError($dbh->err, $dbh->errstr);

    #
    #   Create a new table; EDIT THIS!
    #
	#
	### Test 3
    Test($state or ($def = TableDefinition($table,
					  ["id",   SQL_INTEGER(), 0,  0, $NO_FLAG], # col_name, DBI SQL code, size/precision, scale, flags
					  ["name", SQL_VARCHAR(), 64, 0, $NO_FLAG]),
		    $dbh->do($def)))
	   or DbiError($dbh->err, $dbh->errstr);


    #
    #   Insert a row into the test table.......
    #
	#
	### Test 4
    Test($state or $dbh->do("INSERT INTO $table"
			    . " VALUES(1, 'Alligator Descartes')"))
	   or DbiError($dbh->err, $dbh->errstr);

    #
    #   ...and delete it........
    #
	#
	### Test 5
    Test($state or $dbh->do("DELETE FROM $table WHERE id = 1"))
	   or DbiError($dbh->err, $dbh->errstr);

    #
    #   Now, try SELECT'ing the row out. This should fail.
    #
	#
	### Test 6
    Test($state or $cursor = $dbh->prepare("SELECT * FROM $table"
					   . " WHERE id = 1"))
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 7
    Test($state or $cursor->execute)
	   or DbiError($cursor->err, $cursor->errstr);

    my ($row, $errstr);
	#
	### Test 8
    Test($state or (!defined($row = $cursor->fetchrow_arrayref)  &&
		    (!defined($errstr = $cursor->errstr) ||
		     $cursor->errstr eq '')))
	or DbiError($cursor->err, $cursor->errstr);

	#
	### Test 9
    Test($state or $cursor->finish, "\$sth->finish failed")
	   or DbiError($cursor->err, $cursor->errstr);

	#
	### Test 10
    Test($state or undef $cursor || 1);


    #
    #   Drop the test table.
    #
	#
	### Test 11
    Test($state or $dbh->do("DROP TABLE $table"))
	   or DbiError($dbh->err, $dbh->errstr);


    #
    #   Finally disconnect.
    #
	#
	### Test 12
		
   Test($state or $dbh->disconnect());
	#   or DbiError($dbh->err, $dbh->errstr);
}

