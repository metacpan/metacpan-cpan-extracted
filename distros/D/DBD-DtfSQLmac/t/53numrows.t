#! perl -w
#
#
#   This tests, whether the number of rows can be retrieved.
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

sub TrueRows($) {
    my ($sth) = @_;
    my $count = 0;
    while ($sth->fetchrow_arrayref) {
	++$count;
    }
    $count;
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
    Test($state or ($dbh = DBI->connect($test_dsn, $test_user,
					$test_password)))
	or die "Sorry, cannot connect: ", $DBI::errstr, "\n";

    #
    #   Find a possible new table name
    #
	#
	### Test 2
    Test($state or ($table = FindNewTable($dbh)))
	   or DbiError($dbh->err, $dbh->errstr);

    #
    #   Create a new table; EDIT THIS!
    #
	#
	### Test 3
    Test($state or ($def = TableDefinition($table,
					   ["id",   SQL_INTEGER(),  0,  0, $NO_FLAG], # column name, DBI SQL code, size/precision, scale, flags
					   ["name", SQL_VARCHAR(),  64, 0, $NO_FLAG]),
		    $dbh->do($def)))
	   or DbiError($dbh->err, $dbh->errstr);


    #
    #   This section should exercise the sth->rows
    #   method by preparing a statement, then finding the
    #   number of rows within it.
    #   Prior to execution, this should fail. After execution, the
    #   number of rows affected by the statement will be returned.
    #
	#
	### Test 4
    Test($state or $dbh->do("INSERT INTO $table"
			    . " VALUES( 1, 'Thomas Wegner' )"))
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 5
    Test($state or ($cursor = $dbh->prepare("SELECT * FROM $table"
					   . " WHERE id = 1")))
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 6
    Test($state or $cursor->execute)
           or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 7
    Test($state or ($numrows = $cursor->rows) == 1  or  ($numrows == -1))
	or ErrMsgF("Expected 1 rows, got %s.\n", $numrows);

	#
	### Test 8
    Test($state or ($numrows = TrueRows($cursor)) == 1)
	or ErrMsgF("Expected to fetch 1 rows, got %s.\n", $numrows);

	#
	### Test 9
    Test($state or $cursor->finish)
           or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 10
    Test($state or undef $cursor or 1);

	#
	### Test 11
    Test($state or $dbh->do("INSERT INTO $table"
			    . " VALUES( 2, 'Ally McBeal' )"))
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 12
    Test($state or ($cursor = $dbh->prepare("SELECT * FROM $table"
					    . " WHERE id >= 1")))
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 13
    Test($state or $cursor->execute)
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 14
    Test($state or ($numrows = $cursor->rows) == 2  or  ($numrows == -1))
	or ErrMsgF("Expected 2 rows, got %s.\n", $numrows);

	#
	### Test 15
    Test($state or ($numrows = TrueRows($cursor)) == 2)
	or ErrMsgF("Expected to fetch 2 rows, got %s.\n", $numrows);


	#
	### Test 16
    Test($state or $cursor->finish)
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 17
    Test($state or undef $cursor or 1);

	#
	### Test 18
    Test($state or $dbh->do("INSERT INTO $table"
			    . " VALUES(3, 'Bart Simpson')"))
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 19
    Test($state or ($cursor = $dbh->prepare("SELECT * FROM $table"
					    . " WHERE id >= 2")))
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 20
    Test($state or $cursor->execute)
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 21
    Test($state or ($numrows = $cursor->rows) == 2  or  ($numrows == -1))
	or ErrMsgF("Expected 2 rows, got %s.\n", $numrows);

	#
	### Test 22
    Test($state or ($numrows = TrueRows($cursor)) == 2)
	or ErrMsgF("Expected to fetch 2 rows, got %s.\n", $numrows);

	#
	### Test 23
    Test($state or $cursor->finish)
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 24
    Test($state or undef $cursor or 1);

    #
    #   Drop the test table.
    #
	#
	### Test 25
    Test($state or $dbh->do("DROP TABLE $table"))
	   or DbiError($dbh->err, $dbh->errstr);
	   
	#
    #   Finally disconnect.
    #
	#
	### Test 26
    Test($state or $dbh->disconnect())
	  or DbiError($dbh->err, $dbh->errstr);

}
