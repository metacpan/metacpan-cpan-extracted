#!perl -w
#
#
#   This test should check whether 'ChopBlanks' works.
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
    my ($dbh, $sth, $query);

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
    my $table = '';
	#
	### Test 2
    Test($state or $table = FindNewTable($dbh))
	   or ErrMsgF("Cannot determine a legal table name: Error %s.\n",
		      $dbh->errstr);

    #
    #   Create a new table; EDIT THIS!
    #
	#
	### Test 3
    Test($state or ($query = TableDefinition($table,
				      ["id",   SQL_INTEGER(),  0, 0, $COL_NULLABLE], # column name, DBI SQL code, size/precision, scale, flags
				      ["name", SQL_CHAR(),     10, 0, $COL_NULLABLE]),
		    $dbh->do($query)))
	or ErrMsgF("Cannot create table: Error %s.\n",
		      $dbh->errstr);


    #
    #   and here's the right place for inserting new tests:
    #
    my @rows = (
	
		[1, '          '], # if retrieved: 10 blanks with ChopBlanks = 0, or empty string with ChopBlanks = 1 
		[2, '          '], # same as above, due to the fixed size column data type [CHAR(10)]
		[3, ' a b c    ']);
    my $ref;
    foreach $ref (@rows) {
	my ($id, $name) = @$ref;
	if (!$state) {
	    $query = sprintf("INSERT INTO $table (id, name) VALUES ($id, %s)",
			     $dbh->quote($name));
	}

	#
	### Test 4 / 14 / 24
	Test($state or $dbh->do($query))
	    or ErrMsgF("INSERT failed: query $query, error %s.\n",
		       $dbh->errstr);
        $query = "SELECT id, name FROM $table WHERE id = $id\n";

	#
	### Test 5 / 15 / 25
	Test($state or ($sth = $dbh->prepare($query)))
	    or ErrMsgF("prepare failed: query $query, error %s.\n",
		       $dbh->errstr);

	# First try to retreive without chopping blanks.
	$sth->{'ChopBlanks'} = 0;

	#
	### Test 6 / 16 / 26
	Test($state or $sth->execute)
	    or ErrMsgF("execute failed: query %s, error %s.\n", $query,
		       $sth->errstr);

	#
	### Test 7 / 17 / 27
	Test($state or defined($ref = $sth->fetchrow_arrayref))
	    or ErrMsgF("fetch failed: query $query, error %s.\n",
		       $sth->errstr);

	#
	### Test 8 / 18 / 28
	Test($state or ($$ref[1] eq $name)
	            or ($name =~ /^$$ref[1]\s+$/) )
	    or ErrMsgF("problems with ChopBlanks = 0:"
		       . " expected '%s', got '%s'.\n", $name, $$ref[1]);

	#
	### Test 9 / 19 / 29
	Test($state or $sth->finish());

	# Now try to retrieve with chopping blanks.
	
	$sth->{'ChopBlanks'} = 1;

	#
	### Test 10 / 20 / 30
	Test($state or $sth->execute)
	    or ErrMsg("execute failed: query $query, error %s.\n",
		      $sth->errstr);
	my $n = $name;
	$n =~ s/\s+$//;

	#
	### Test 11 / 21 / 31
	Test($state or ($ref = $sth->fetchrow_arrayref))
	    or ErrMsgF("fetch failed: query $query, error %s.\n",
		       $sth->errstr);
	#
	### Test 12 / 22 / 32
	Test($state or ($$ref[1] eq $n))
	    or ErrMsgF("problems with ChopBlanks = 1:"
		       . " expected '%s', got '%s'.\n",
		       $n, $$ref[1]);

	#
	### Test 13 / 23 / 33
	Test($state or $sth->finish)
	    or ErrMsgF("Cannot finish: %s.\n", $sth->errstr);
    
	} #foreach

    #
    #   Finally drop the test table.
    #
	#
	### Test 34
    Test($state or $dbh->do("DROP TABLE $table"))
	   or ErrMsgF("Cannot DROP test table $table: %s.\n",
		      $dbh->errstr);

    #   ... and disconnect
	#
	### Test 35
    Test($state or $dbh->disconnect)
	or ErrMsgF("Cannot disconnect: %s.\n", $dbh->errmsg);
}
