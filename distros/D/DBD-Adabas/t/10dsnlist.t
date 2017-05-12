#!/usr/local/bin/perl
#
#   $Id: 10dsnlist.t,v 1.1 1998/08/20 11:31:14 joe Exp $
#
#   This test creates a database and drops it. Should be executed
#   after listdsn.
#


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
if ($mdriver eq 'pNET') {
    print "1..0\n";
    exit 0;
}
if ($verbose) { print "Driver is $mdriver\n"; }

sub ServerError() {
    print STDERR ("Cannot connect: ", $DBI::errstr, "\n",
	"\tEither your server is not up and running or you have no\n",
	"\tpermissions for acessing the DSN $test_dsn.\n",
	"\tThis test requires a running server and write permissions.\n",
	"\tPlease make sure your server is running and you have\n",
	"\tpermissions, then retry.\n");
    exit 10;
}

#
#   Main loop; leave this untouched, put tests into the loop
#
while (Testing()) {
    # Check if the server is awake.
    $dbh = undef;
    Test($state or ($dbh = DBI->connect($test_dsn, $test_user,
					$test_password)))
	or ServerError();

    my @dsn;
    if (!$state) {
	@dsn = DBI->data_sources($mdriver);
    }

    Test($state or !$DBI::errstr)
	or print "Error in data_sources method: $DBI::errstr\n";
    if (!$state  &&  $verbose) {
	my $d;
	print "List of $mdriver data sources:\n";
	foreach $d (@dsn) {
	    print "    $d\n";
	}
	print "List ends.\n";
    }
}

exit 0;

# Hate -w :-)
$test_dsn = $test_user = $test_password = $DBI::errstr;
