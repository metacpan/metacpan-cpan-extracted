#! perl -w
#
#
#   This is a test for correctly handling NULL values.
#

$^W = 1;


use DBI qw(:sql_types);
use vars qw($NO_FLAG $COL_NULLABLE $COL_PRIMARY_KEY $verbose);

#
#   Make -w happy
#
$test_dsn = '';
$test_user = '';
$test_password = '';


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
				   ["id",   SQL_INTEGER(),  4,  0, $COL_NULLABLE], # column name, DBI SQL code, size/precision, scale, flags
				   ["name", SQL_VARCHAR(),  64, 0, $NO_FLAG]),
		    $dbh->do($def)))
	   or DbiError($dbh->err, $dbh->errstr);

    #
    #   Test whether or not a field containing a NULL is returned correctly
    #   as undef, or something much more bizarre
    #
	#
	### Test 4
    Test($state or $dbh->do("INSERT INTO $table VALUES"
	                    . " ( NULL, 'NULL-valued id' )"))
           or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 5
    Test($state or $cursor = $dbh->prepare("SELECT * FROM $table"
	                                   . " WHERE " . IsNull("id")))
           or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 6
    Test($state or $cursor->execute)
           or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 7
    Test($state or ($rv = $cursor->fetchrow_arrayref) )
           or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 8
    Test($state or (!defined($$rv[0])  and  defined($$rv[1])) )
           or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 9
    Test($state or $cursor->finish)
           or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 10
    Test($state or undef $cursor  ||  1);


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
    Test($state or $dbh->disconnect())
	  or DbiError($dbh->err, $dbh->errstr);
}
