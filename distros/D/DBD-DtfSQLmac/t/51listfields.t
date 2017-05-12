#! perl -w
#
#
#   This is a test for statement attributes being present appropriately.
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

$verbose = 0; # set this to 1 if you like

@table_def = (
	      ["id",   SQL_INTEGER(),  0,  0, $COL_PRIMARY_KEY], # column name, DBI SQL code, size/precision, scale, flags
	      ["name", SQL_VARCHAR(),  64, 0, $COL_NULLABLE]
	     );

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
    #   Create a new table
    #
	#
	### Test 3
    Test($state or ($def = TableDefinition($table, @table_def),
		    $dbh->do($def)))
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 4
    Test($state or $cursor = $dbh->prepare("SELECT * FROM $table"))
	   or DbiError($dbh->err, $dbh->errstr);

	#
	### Test 5
    Test($state or $cursor->execute)
	   or DbiError($cursor->err, $cursor->errstr);

    my $res;
	#
	### Test 6
    Test($state or (($res = $cursor->{'NUM_OF_FIELDS'}) == @table_def))
	   or DbiError($cursor->err, $cursor->errstr);
    if (!$state && $verbose) {
	printf("# Number of fields: %s\n", defined($res) ? $res : "undef");
    }

	#
	### Test 7
    Test($state or ($ref = $cursor->{'NAME'})  &&  @$ref == @table_def
	            &&  (lc $$ref[0]) eq $table_def[0][0]
		    &&  (lc $$ref[1]) eq $table_def[1][0])
	   or DbiError($cursor->err, $cursor->errstr);
    if (!$state && $verbose) {
	print "# Names:\n";
	for ($i = 0;  $i < @$ref;  $i++) {
	    print "#     ", $$ref[$i], "\n";
	}
    }

	#
	### Test 8
    Test($state or ($ref = $cursor->{'NULLABLE'})  &&  @$ref == @table_def
		    &&  !($$ref[0] xor ($table_def[0][4] & $COL_NULLABLE))
		    &&  !($$ref[1] xor ($table_def[1][4] & $COL_NULLABLE)))
	   or DbiError($cursor->err, $cursor->errstr);
    if (!$state && $verbose) {
	print "# Nullable:\n";
	for ($i = 0;  $i < @$ref;  $i++) {
	    print "#     ", ($$ref[$i] & $COL_NULLABLE) ? "yes" : "no", "\n";
	}
    }

	#
	### Test 9
    Test($state or (($ref = $cursor->{TYPE})  &&  (@$ref == @table_def)
		    &&  ($ref->[0] eq DBI::SQL_INTEGER())
		    &&  ($ref->[1] eq DBI::SQL_VARCHAR()  ||
			 $ref->[1] eq DBI::SQL_CHAR())))
	or printf("# Expected types %d and %d, got %s and %s\n",
		  &DBI::SQL_INTEGER(), &DBI::SQL_VARCHAR(),
		  defined($ref->[0]) ? $ref->[0] : "undef",
		  defined($ref->[1]) ? $ref->[1] : "undef");

	#
	### Test 10
    Test($state or undef $cursor  ||  1);


    #
    #  Drop the test table
    #
	#
	### Test 11
    Test($state or ($cursor = $dbh->prepare("DROP TABLE $table")))
	or DbiError($dbh->err, $dbh->errstr);
	#
	### Test 12
    Test($state or $cursor->execute)
	or DbiError($cursor->err, $cursor->errstr);

    #  NUM_OF_FIELDS should be zero (Non-Select)
	#
	### Test 13
    Test($state or ($cursor->{'NUM_OF_FIELDS'} == 0))
	or !$verbose or printf("# NUM_OF_FIELDS is %s, not zero.\n",
			       $cursor->{'NUM_OF_FIELDS'});
	#
	### Test 14
    Test($state or (undef $cursor) or 1);

    #
    #  Test different flavours of quote. Need to work around a bug in
    #  DBI 1.02 ...
    #
    my $quoted;
    if (!$state) {
	$quoted = eval { $dbh->quote(0, DBI::SQL_INTEGER()) };
    }
	#
	### Test 15
    Test($state or $@  or  $quoted eq 0);
    if (!$state) {
	$quoted = eval { $dbh->quote('abc', DBI::SQL_VARCHAR()) };
    }
	#
	### Test 16
    Test($state or $@ or $quoted eq q{'abc'});
	
	#
    #   Finally disconnect.
    #
	#
	### Test 17
    Test($state or $dbh->disconnect())
	  or DbiError($dbh->err, $dbh->errstr);
}
