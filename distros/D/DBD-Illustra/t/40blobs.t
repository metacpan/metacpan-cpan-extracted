#!/usr/local/bin/perl
#
#   $Id: 40blobs.t,v 1.1812 1997/09/27 14:34:45 joe Exp $
#
#   This is a test for correct handling of BLOBS; namely $dbh->quote
#   is expected to work correctly.
#


#
#   Make -w happy
#
$::verbose = defined($::verbose) ? $::verbose : 0;
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
if ($dbdriver eq 'Illustra'){
    # XXX No direct blob support yet
    print "1..0\n";
    exit 0;
}

sub ServerError() {
    my $err = $DBI::errstr; # Hate -w ...
    print STDERR ("Cannot connect: ", $DBI::errstr, "\n",
	"\tEither your server is not up and running or you have no\n",
	"\tpermissions for acessing the DSN $test_dsn.\n",
	"\tThis test requires a running server and write permissions.\n",
	"\tPlease make sure your server is running and you have\n",
	"\tpermissions, then retry.\n");
    exit 10;
}


sub ShowBlob($) {
    my ($blob) = @_;
    for($i = 0;  $i < 8;  $i++) {
	if (defined($blob)  &&  length($blob) > $i) {
	    $b = substr($blob, $i*32);
	} else {
	    $b = "";
	}
	printf("%08lx %s\n", $i*32, unpack("H64", $b));
    }
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
	   or DbiError($dbh->error, $dbh->errstr);

    foreach $size (128) {
	#
	#   Create a new table
	#
	Test($state or ($def = TableDefinition($table,
					  ["id",   "INTEGER",      4, 0],
					  ["name", "BLOB",  $size, 0]),
			$dbh->do($def)))
	       or DbiError($dbh->err, $dbh->errstr);


	#
	#  Create a blob
	#
	my ($blob, $qblob) = "";
	if (!$state) {
	    my $b = "";
	    for ($j = 0;  $j < 256;  $j++) {
		$b .= chr($j);
	    }
	    for ($i = 0;  $i < $size;  $i++) {
		$blob .= $b;
	    }
	    if ($mdriver eq 'pNET') {
		# Quote manually, no remote quote
		$qblob = eval "DBD::" . $dbdriver . "::db->quote(\$blob)";
	    } else {
		$qblob = $dbh->quote($blob);
	    }
	}

	#
	#   Insert a row into the test table.......
	#
        Test($state or $dbh->do("INSERT INTO $table VALUES(1, "
				. $qblob . ")"))
	       or DbiError($dbh->err, $dbh->errstr);

	#
	#   Now, try SELECT'ing the row out.
	#
	Test($state or $cursor = $dbh->prepare("SELECT * FROM $table"
					       . " WHERE id = 1"))
	       or DbiError($dbh->err, $dbh->errstr);

	Test($state or $cursor->execute)
	       or DbiError($dbh->err, $dbh->errstr);

	Test($state or (defined($row = $cursor->fetchrow_arrayref)))
	    or DbiError($cursor->err, $cursor->errstr);

	Test($state or (@$row == 2  &&  $$row[0] == 1  &&  $$row[1] eq $blob))
	    or !$verbose or (ShowBlob($blob),
			     ShowBlob(defined($$row[1]) ? $$row[1] : ""));

	Test($state or $cursor->finish)
	       or DbiError($cursor->err, $cursor->errstr);

	Test($state or undef $cursor || 1)
	       or DbiError($cursor->err, $cursor->errstr);

	#
	#   Finally drop the test table.
	#
	Test($state or $dbh->do("DROP TABLE $table"))
	       or DbiError($dbh->err, $dbh->errstr);
    }
}
