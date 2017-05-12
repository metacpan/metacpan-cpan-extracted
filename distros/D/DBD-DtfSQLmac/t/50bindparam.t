#! perl
#
#
#   This is a test for parameter binding.
#

$^W = 1;


use DBI qw(:sql_types);
use vars qw($NO_FLAG $COL_NULLABLE $COL_PRIMARY_KEY);

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
    ### Test 2
	
    Test($state or $table = FindNewTable($dbh))
	   or DbiError($dbh->err, $dbh->errstr);


    #
    #   Create a new table; note that the name column is fixed width
    #
    ### Test 3
	
    Test($state or ($def = TableDefinition($table,
					   ["id",   SQL_INTEGER(), 0,  0, $COL_PRIMARY_KEY], # column name, DBI SQL code, size/precision, scale, flags
					   ["name", SQL_VARCHAR(), 64, 0, $COL_NULLABLE]),  
		    $dbh->do($def)))
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 4	
    
    Test($state or $cursor = $dbh->prepare("INSERT INTO $table"
	                                   . " VALUES (?, ?)"))
	   or DbiError($dbh->err, $dbh->errstr);

    #
    #   Insert some rows
    #

	#
	### Test 5	   
	Test($state or $cursor->bind_param(1, 1, SQL_INTEGER()))
		or DbiError($dbh->err, $dbh->errstr);
	#
	### Test 6
    Test($state or $cursor->bind_param(2, "Fred Feuerstein", SQL_VARCHAR()))
		or DbiError($dbh->err, $dbh->errstr);
	#
	### Test 7
    Test($state or $cursor->execute)
	   or DbiError($dbh->err, $dbh->errstr);

    # Does the driver remember the type?
	#
	### Test 8
    Test($state or $cursor->execute("3", "Ally McBeal"))
	   or DbiError($dbh->err, $dbh->errstr);
	#
	### Test 9
	$numericVal = 2;
    $charVal = "Bart Simpson";
    Test($state or $cursor->execute($numericVal, $charVal))
	   or DbiError($dbh->err, $dbh->errstr);

    # Now try the explicit type settings
	#
	### Test 10
    Test($state or $cursor->bind_param(1, " 4", SQL_INTEGER()))
		or DbiError($dbh->err, $dbh->errstr);
	#
	### Test 11
    Test($state or $cursor->bind_param(2, "Thomas Wegner"))
		or DbiError($dbh->err, $dbh->errstr);
	#
	### Test 12
    Test($state or $cursor->execute)
	   or DbiError($dbh->err, $dbh->errstr);

    # Works undef -> NULL?
	#
	### Test 13
    Test($state or $cursor->bind_param(1, 5, SQL_INTEGER()))
	or DbiError($dbh->err, $dbh->errstr);
	#
	### Test 14
    Test($state or $cursor->bind_param(2, undef))
	or DbiError($dbh->err, $dbh->errstr);
	#
	### Test 15
    Test($state or $cursor->execute)
 	or DbiError($dbh->err, $dbh->errstr);

    #
    #   Try inserting a question mark
    #
	#
	### Test 16
    Test($state or $dbh->do("INSERT INTO $table VALUES (6, '?')"))
	   or DbiError($dbh->err, $dbh->errstr);

    #
    #   Test quote function
    #
	#
	### Test 17
    Test($state or ($string = $dbh->quote("don't")) );
	
	#
	### Test 18
    Test($state or $dbh->do("INSERT INTO $table VALUES (7, $string)"))
	   or DbiError($dbh->err, $dbh->errstr);
	
	#
	### Test 19
    Test($state or undef $cursor  ||  1);

    #
    #   And now retrieve the rows using bind_columns
    #

	#
	### Test 20    
	Test($state or $cursor = $dbh->prepare("SELECT * FROM $table"
					   . " ORDER BY id"))
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 21
    Test($state or $cursor->execute)
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 22
	Test($state or $cursor->bind_columns(\$id, \$name))
	   or DbiError($dbh->err, $dbh->errstr);


	#
	### Test 23   
    Test($state or ( $ref = $cursor->fetch && $id == 1))
	or printf("# Query returned id = %s, name = %20.20s, ref = %s, %d\n",
		  $id, $name, $ref, scalar(@$ref));


	#
	### Test 24
    Test($state or (($ref = $cursor->fetch)  &&  $id == 2  &&
		    $name eq 'Bart Simpson'))
	or printf("# Query returned id = %s, name = -%s-, ref = %s, %d\n",
		  $id, $name, $ref, scalar(@$ref));

	#
	### Test 25
    Test($state or (($ref = $cursor->fetch)  &&  $id == 3  &&
		    $name eq 'Ally McBeal'))
	or printf("# Query returned id = %s, name = %s, ref = %s, %d\n",
		  $id, $name, $ref, scalar(@$ref));

	#
	### Test 26
    Test($state or (($ref = $cursor->fetch)  &&  $id == 4  &&
		    $name eq 'Thomas Wegner'))
	or printf("# Query returned id = %s, name = %s, ref = %s, %d\n",
		  $id, $name, $ref, scalar(@$ref));

	#
	### Test 27
    Test($state or (($ref = $cursor->fetch)  &&  $id == 5  &&
		    !defined($name)))
	or printf("# Query returned id = %s, name = %s, ref = %s, %d\n",
		  $id, $name, $ref, scalar(@$ref));

	#
	### Test 28
    Test($state or (($ref = $cursor->fetch)  &&  $id == 6  &&
		   $name eq '?'))
	or print("# Query returned id = $id, name = $name, expected 6, ?\n");
	
	#
	### Test 29
    Test($state or (($ref = $cursor->fetch)  &&  $id == 7  &&
		   $name eq "don't"))
	or print("# Query returned id = $id, name = $name, expected 7, don't\n");

	#
	### Test 30
    Test($state or undef $cursor  or  1);


    #
    #   Drop the test table.
    #

	#
	### Test 31
	Test($state or $dbh->do("DROP TABLE $table"))
	   or DbiError($dbh->err, $dbh->errstr);
	   
	#
    #   Finally disconnect.
    #
	#
	### Test 32
    Test($state or $dbh->disconnect())
	  or DbiError($dbh->err, $dbh->errstr);
}
