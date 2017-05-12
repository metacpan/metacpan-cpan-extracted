#!/usr/bin/perl -w

use strict;

use DBI::BabyConnect;

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log",1);

my %rec;

$bbconn-> fetchQdaO( 
	"SELECT a.LOOKUP,b.DATASTRING, b.DATANUM,b.BIN_SREF,a.RECORDDATE_T FROM TABLE1 a, TABLE2 b WHERE a.DATASTRING=? ",
	 \%rec,
	['LOOKUP','DATASTRING','DATANUM','BIN_SREF','RECORDDATE_T'],
	'This is a flower ...',	
 );

print "${$rec{DATASTRING}}\n";
print "${$rec{RECORDDATE_T}}\n";
#print "${$rec{BIN_SREF}}\n";



