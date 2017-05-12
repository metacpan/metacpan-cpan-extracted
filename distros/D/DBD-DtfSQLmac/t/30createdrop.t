#! perl -w
#
#
#   This test creates and drops a table. Very basic.
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
#   Main loop; leave this untouched, put tests into the loop
#
use vars qw($state);
while (Testing()) {
    #
    #   Connect to the database
	#
	### Test 1
    my $dbh;
    Test($state or $dbh = DBI->connect($test_dsn, $test_user, $test_password))
	or die "Sorry, cannot connect: ", $DBI::errstr, "\n";


    #
    #   Find a possible new table name
    #
    my $table;
	
	#
	### Test 2
    Test($state or $table = FindNewTable($dbh))
	   or DbiError($dbh->err, $dbh->errstr);

    #
    #   Create a new table
    #
    my $def;
    if (!$state) {
	($def = TableDefinition($table,
				["id",   SQL_INTEGER(),  0,  0, $NO_FLAG], # col_name, DBI SQL type, size/precision, scale, flags
				["name", SQL_VARCHAR(),  64, 0, $NO_FLAG]));
	print "# Creating table:\n# $def\n";
    }

	#
	### Test 3
    Test($state or $dbh->do($def))
	or DbiError($dbh->err, $dbh->errstr);


    #
    #   ... and drop it.
    #
	#
	### Test 4
    Test($state or $dbh->do("DROP TABLE $table"))
	   or DbiError($dbh->err, $dbh->errstr);

    #
    #   Finally disconnect.
    #
	#
	### Test 5
    Test($state or $dbh->disconnect())
	  or DbiError($dbh->err, $dbh->errstr);
}
