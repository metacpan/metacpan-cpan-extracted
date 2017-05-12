#!/usr/bin/perl -w

use strict;

use DBI::BabyConnect;

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log",1);

my $rec= $bbconn-> fetchQdaO( 
	#"SELECT * FROM TABLE1 WHERE DATASTRING='This is a flower ...' ",
	"SELECT DATASTRING, DATANUM,BIN_SREF,RECORDDATE_T FROM TABLE1 WHERE DATASTRING='This is a flower ...' ",
 );

#foreach my $k (keys %$rec) {
#	print "$k -- ${$$rec{$k}}\n";
#}
print "${$$rec{DATASTRING}}\n";
print "${$$rec{RECORDDATE_T}}\n";



