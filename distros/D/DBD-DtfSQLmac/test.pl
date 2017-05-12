#! perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; $test = 1; print "\n1..4\n\n"; print "Loading required modules ...\n";  }
END {print "\nnot ok $test\n" unless $loaded;}

# test 1
undef $@;
eval 'use Mac::DtfSQL';
if ($@) { # Mac::DtfSQL could not be loaded
	
	print <<EOT_NOTOK;

The Mac::DtfSQL module could not be loaded.

Most likely reason:
The Mac::DtfSQL module needs the dtF/SQL 2.01 shared library for PPC in order to 
work. This lib has to be placed in the proper location on your harddisk.

Either put the dtF/SQL 2.01 shared library dtFPPCSV2.8K.shlb (or at least an alias 
to it) in the *same* folder as the shared library DtfSQL builded from this extension 
module (by default, the folder is :site_perl:MacPPC:auto:Mac:DtfSQL:) or put the 
dtF/SQL 2.01 shared library in the *system extensions* folder.

EOT_NOTOK

	exit(1);
}

print "ok $test \n";

print <<EOT_OK;

The Mac::DtfSQL module has been installed properly.

Look into the 'samples' folder. To play with this module, you first have
to create a sample database. Run

   createSampleDB.pl
   
to create one. Then run

   browser.pl

which lets you interactively query the database using SQL statements. Have fun.

EOT_OK


# try loading DBI
$test++; # 2
use DBI 1.08;
print "ok $test \n";

$test++; # 3
print "List of available DBI drivers ...\n";
my @dr_ary = DBI->available_drivers;
$found = 0;
foreach $driver (@dr_ary) {
	print "    $driver\n";
	if ($driver eq 'DtfSQLmac') {
		$found = 1;
	}
}
print "List ends.\n";
if (! $found) {
	print "\nThe DBD::DtfSQLmac driver is not installed.\n";
	exit 1;
}
print "ok $test \n";

$test++; # 4
print "\nCheck, if the DtfSQLmac driver gets loaded properly ...\n";
# DBI will print an error message, if it cannot load the DtfSQLmac driver 
# while excuting the data_sources method.
my @data_sources = DBI->data_sources('DtfSQLmac');
print "ok $test \n\n";
$loaded = 1;

print "The Mac::DtfSQLmac driver for DBI has been installed properly.\n\n";
print "    For a full driver test suite, look into the 't' folder and\n";
print "    run the scripts. Examples can be found in the 'samples' folder.\n\n";


######################### End of black magic. ^-^ huuhuuuuu
