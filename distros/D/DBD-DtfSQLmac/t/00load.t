#! perl -w
#
# Tests loading of required modules and driver.
#

BEGIN { $| = 1; $test = 1; print "# Test loading of required modules and driver.\n\n1..2\n"; }
END {print "\nnot ok $test\n" unless $loaded;}

# the following two modules are required
use Mac::DtfSQL;
use DBI 1.08;
print "ok $test\n";

$test++;
# DBI will print an error message, if it cannot load the DtfSQLmac driver 
# while excuting the data_sources method.
my @data_sources = DBI->data_sources('DtfSQLmac');
print "ok $test\n";
$loaded = 1;

exit 0;



