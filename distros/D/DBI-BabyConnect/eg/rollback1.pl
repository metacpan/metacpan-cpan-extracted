#!/usr/bin/perl

use strict;
use DBI::BabyConnect;

# For this example you should have set ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT=1
# so that the DBI::BabyConnect will do the rollback upon DBI failure

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log",2);

# save the attribute flags
$bbconn-> saveLags();
$bbconn->raiseerror(0);
$bbconn->printerror(1);
$bbconn->autocommit(0);
$bbconn->autorollback(1);


# Since ID is unique, and we already have ID=1 in TABLE1, the following insert should rollback
my $sql = "INSERT INTO TABLE1 (ID,DATASTRING,DATANUM,PCODE_SREF,BIN_SREF,RECORDDATE_T) VALUES 
        (1,'data string',1234,'bin code','bin data',SYSDATE())";


$bbconn-> do($sql);

print "You will never get to see this line\n";

# and none of this will be executed since the program already terminated
my $sql = qq{
		INSERT INTO TEST_TABLE 
		(DATASTRING,DATANUM,PCODE_SREF,BIN_SREF,RECORDDATE_T) 
		VALUES 
		('abc strinfg',1234,'bin code','bin data',SYSDATE())
	};
$bbconn-> do($sql);

# restore to attribute flags
$bbconn-> restoreLags();

