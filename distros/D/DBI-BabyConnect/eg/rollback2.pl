#!/usr/bin/perl

use strict;
use DBI::BabyConnect;

# For this example, in globalconf.pl set ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT=0

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log",2);

# save the attribute flags before setting them with new values
$bbconn-> saveLags();
$bbconn->raiseerror(0);
$bbconn->printerror(1);
$bbconn->autocommit(0);
$bbconn->autorollback(1);


# Since ID is unique, and we already have ID=1 in TABLE1, the following insert should rollback
my $sql = "INSERT INTO TABLE1 (ID,DATASTRING,DATANUM,PCODE_SREF,BIN_SREF,RECORDDATE_T) VALUES 
        (1,'data string',1234,'bin code','bin data',SYSDATE())";

# do nothing although the folowing do() will fail, and the script will continue
$bbconn-> do($sql);

# check if do() failed, then exit(), this will call DBI::BabyConnect::DESTROY
# and it will rollback if possible to rollback, but we are exiting
# anyway and the script is terminated at this point.
#defined ($bbconn-> do($sql)) || (exit);

# the script is not terminated and the rollback is done explicitly, and
# the script will continue
#defined ($bbconn-> do($sql)) || ($bbconn-> rollback);

print "We are continuing with our program\n";

my $sql = qq{
		INSERT INTO TABLE1 
		(DATASTRING,DATANUM,PCODE_SREF,BIN_SREF,RECORDDATE_T) 
		VALUES 
        ('abc string',1234,'bin code','bin data',SYSDATE())
	};
$bbconn-> do($sql);

# restore to attribute flags
$bbconn-> restoreLags();

