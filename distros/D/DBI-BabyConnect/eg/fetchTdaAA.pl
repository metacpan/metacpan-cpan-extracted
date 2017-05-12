#!/usr/bin/perl

use strict;
use DBI::BabyConnect;

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log",1);


my $qry = qq{SELECT * FROM TABLE2 WHERE ID < ? };

# $rows is an array reference to be filled by fetchQdaAA()
my $AA=[];

if ($bbconn-> fetchTdaAA('TABLE2', ' ID,DATASTRING,FLAG,DATANUM,CHANGEDATE_T  '  ,  " ID < 15 ", $AA)) {
	# we will use the formatting method textFormattedAA() to print the datalines
	print "\n\nTEXT FORMATTED DATA:";
	print $bbconn-> textFormattedAA(
		$AA,
		['ID',6,'DATASTRING',22,'DATANUM',10],
		{ID=>'Id', DATASTRING=>'Data', DATANUM => 'Data Number'}
	);
	
	# we will use the formatting method datalinesFormattedAA() to print the datalines
	print "\n\nDATA FORMATTED AS DATALINES:";
	my $dataLines = $bbconn-> datalinesFormattedAA(
		$AA,
		['ID',6,'DATASTRING',22,'DATANUM',10],
		{ID=>'Id', DATASTRING=>'Data', DATANUM => 'Data Number'}
	);
	for (my $i=0; $i<@{ $$dataLines{DATA_LINES} }; $i++) {
		if ($i % 10 == 0) {
			print $$dataLines{TITLE_LINE};
			print $$dataLines{UNDERLINE};
		}	
		print ${$$dataLines{DATA_LINES}}[$i];
	}
}
else {
	print "NONE!!!!!!!!\n";
}

