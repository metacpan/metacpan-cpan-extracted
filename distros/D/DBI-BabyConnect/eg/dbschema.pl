#!/usr/bin/perl

use strict;
use DBI::BabyConnect;

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log" , 2);

print "Active descriptor for \$bbconn: ", $bbconn-> getActiveDescriptor, "\n\n";

print $bbconn-> dbschema('BABYDB','TABL');

# insert a record in BABYDB.TABLE1
my $sql = qq{
		INSERT INTO TABLE1
		(DATASTRING,DATANUM,PCODE_SREF,BIN_SREF,RECORDDATE_T)
		VALUES
		(?,?,?,'bin data',SYSDATE())
	};
$bbconn-> sqlbnd($sql,'data string',7000,'binary code');

# now TABLE_ROWS for BABYDB.TABLE1 should be bumped by 1
print $bbconn-> dbschema('BABYDB','TABL');

