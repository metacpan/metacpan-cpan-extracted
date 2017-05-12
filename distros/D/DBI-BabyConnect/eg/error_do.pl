#!/usr/bin/perl -w

use strict;
use DBI::BabyConnect;

# For this example, in configuration/dbconf/globalconf.pl, you should have set
# ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT=0
# so that the DBI::BabyConnect continue running (without exiting) whenever the
# error is encountered. The do() is called and checked for success. If the
# do() returns an undef, we will then call dbierror() to get the error.


# get an $bbconn object to access the BABYDB database
my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log",2);

# save the attribute flags, make sure that RaiseError=0
$bbconn-> saveLags();
$bbconn-> raiseerror(0);

# this SQL will fail because we do not have a table BABYDB.TABLEEEEEEE
my $sql = qq{
		INSERT INTO TABLEEEEEEE
		(DATASTRING,DATANUM,PCODE_SREF,BIN_SREF,RECORDDATE_T) 
		VALUES 
		('abc strinfg',1234,'bin code','bin data',SYSDATE())
	};

if ($bbconn-> do($sql)) {
	print "do() OK\n";
}
else {
	print "do() failed\n\t", $bbconn-> dbierror(), "\n";
}

# you can also consult the /tmp/error.log and /tmp/db.log for
# extended error output.

# restore to attribute flags
$bbconn-> restoreLags();

# continue doing stuff ...

