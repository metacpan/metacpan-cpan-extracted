# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use DBIx::Dump;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

eval {require Spreadsheet::WriteExcel;};
if ($@)
{
	print "Skipping the Excel test, Spreadsheet::WriteExcel module not found...\n";
}
else
{
	## tests comming...
	ok(1);
}

eval {require Text::CSV_XS;};
if ($@)
{
	print "Skipping the CSV test, Text::CSV_XS module not found...\n";
}
else
{
	## tests comming...
	ok(1);
}


