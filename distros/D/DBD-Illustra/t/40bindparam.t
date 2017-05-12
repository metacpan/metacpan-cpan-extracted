#!/usr/local/bin/perl
#
#   $Id: 40bindparam.t,v 1.1812 1997/09/27 14:34:44 joe Exp $
#
#   This is a skeleton test. For writing new tests, take this file
#   and modify/extend it.
#


#
#   Make -w happy
#
$test_dsn = '';
$test_user = '';
$test_password = '';


#
#   Include lib.pl
#
require DBI;
$mdriver = "";
foreach $file ("lib.pl", "t/lib.pl") {
    do $file; if ($@) { print STDERR "Error while executing lib.pl: $@\n";
			   exit 10;
		      }
    if ($mdriver ne '') {
	last;
    }
}

sub ServerError() {
    my $err = $DBI::errstr;  # Hate -w ...
    print STDERR ("Cannot connect: ", $DBI::errstr, "\n",
	"\tEither your server is not up and running or you have no\n",
	"\tpermissions for acessing the DSN $test_dsn.\n",
	"\tThis test requires a running server and write permissions.\n",
	"\tPlease make sure your server is running and you have\n",
	"\tpermissions, then retry.\n");
    exit 10;
}

#
#   Main loop; leave this untouched, put tests after creating
#   the new table.
#
while (Testing()) {
    #
    #   Connect to the database
    Test($state or $dbh = DBI->connect($test_dsn, $test_user, $test_password))
	or ServerError();

    #
    #   Find a possible new table name
    #
    Test($state or $table = FindNewTable($dbh))
	   or DbiError($dbh->err, $dbh->errstr);

    #
    #   Create a new table; EDIT THIS!
    #
    Test($state or ($def = TableDefinition($table,
					   ["id",   "INTEGER",  4, 0],
					   ["name", "VARCHAR",    64, 0]),
		    $dbh->do($def)))
	   or DbiError($dbh->err, $dbh->errstr);


    Test($state or $cursor = $dbh->prepare("INSERT INTO $table"
	                                   . " VALUES (?, ?)"))
	   or DbiError($dbh->err, $dbh->errstr);

    #
    #   Insert some values using bind_param
    #
    Test($state or $cursor->execute(1, "Alligator Descartes"))
	   or DbiError($dbh->err, $dbh->errstr);

    Test($state or $cursor->execute(2, "Tim Bunce"))
	   or DbiError($dbh->err, $dbh->errstr);

    Test($state or $cursor->execute(3, "Jochen Wiedmann"))
	   or DbiError($dbh->err, $dbh->errstr);

    Test($state or undef $cursor  ||  1);

    #
    #   And now retreive them using bind_columns
    #
    Test($state or $cursor = $dbh->prepare("SELECT * FROM $table"
					   . " ORDER BY id"))
	   or DbiError($dbh->err, $dbh->errstr);

    Test($state or $cursor->execute)
	   or DbiError($dbh->err, $dbh->errstr);

    Test($state or $cursor->bind_columns(undef, \$id, \$name))
	   or DbiError($dbh->err, $dbh->errstr);

    Test($state or ($ref = $cursor->fetch)  &&  $id == 1  &&
		   $name eq 'Alligator Descartes')
	   or DbiError($dbh->err, $dbh->errstr);
    if (!$state && $verbose) {
	print "Query returned id = $id, name = $name, ref = $ref, @$ref\n";
    }

    Test($state or (($ref = $cursor->fetch)  &&  $id == 2  &&
		    $name eq 'Tim Bunce'))
	   or DbiError($dbh->err, $dbh->errstr);
    if (!$state && $verbose) {
	print "Query returned id = $id, name = $name, ref = $ref, @$ref\n";
    }

    Test($state or (($ref = $cursor->fetch)  &&  $id == 3  &&
		    $name eq 'Jochen Wiedmann'))
	   or DbiError($dbh->err, $dbh->errstr);
    if (!$state && $verbose) {
	print "Query returned id = $id, name = $name, ref = $ref, @$ref\n";
    }

    Test($state or undef $cursor  or  1);

    #
    #   Finally drop the test table.
    #
    Test($state or $dbh->do("DROP TABLE $table"))
	   or DbiError($dbh->err, $dbh->errstr);

}
