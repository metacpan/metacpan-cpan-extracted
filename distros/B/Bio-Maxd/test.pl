# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Bio::Maxd;
$loaded = 1;
print "ok 1\tloaded\n";

######################### End of black magic.

use DBI;
use DBD::mysql;

# Test 2:
my $maxd_db = new Bio::Maxd(); # Gets defaults from MAXD_USERID and MAXD_HOSTDB
my $dbh = $maxd_db->{'dbh'};
print (ref($dbh) eq "DBI::db" ? "ok 2\tconnected\n" : "not ok 2\n");

