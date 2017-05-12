#! perl -w
#
#
#   This test lists all available DBI drivers, checks if the DtfSQLmac driver is found
#   and lists all available data sources for our driver. 
#

use DBI qw(:sql_types);
use vars qw($NO_FLAG $COL_NULLABLE $COL_PRIMARY_KEY);

#
#   Include lib.pl
#

$file = "lib.pl";  # as a site effect, lib.pl creates a test database, if it not already exists
do $file; 
if ($@) { 
	print "Error while executing lib.pl: $@\n";
	exit 10;
}

print "# Driver is $mdriver\n";


#
#   Main loop; leave this untouched, put tests into the loop
#
while (Testing()) {

	#
	### Test 1
    Test($state or (@dr_ary = DBI->available_drivers) >= 0);
    if (!$state) {
		my $d;
		print "# List of available DBI drivers:\n";
		$found = 0;
		foreach $driver (@dr_ary) {
			print "#     $driver\n";
			if ($driver eq "$mdriver") {
				$found = 1;
			}
		}
		print "# List ends.\n";
	}

	#
	### Test 2
	Test($state or $found);
	if (!$state) {
		if (! $found) {
			print "\n# The DBD::$mdriver driver is not installed.\n";
		}
    }
	
	#
	### Test 3
    Test($state or (@dsn = DBI->data_sources($mdriver)) >= 0);
    if (!$state) {
		my $d;
		print "# List of $mdriver data sources:\n";
		if (! @dsn) {
			print "#     No database found.\n";
		} else {
			foreach $d (@dsn) {
	    		print "#     dtF/SQL database found. DSN = $d\n";
			}#for
		}#if
		print "# List ends.\n";
    }

}

exit 0;


