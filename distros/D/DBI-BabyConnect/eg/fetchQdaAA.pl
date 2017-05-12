#!/usr/bin/perl

use strict;
use DBI::BabyConnect;

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log",1);


my $qry = qq{SELECT * FROM TABLE2 WHERE ID < ? };

# $rows is an array reference to be filled by fetchQdaAA()
my $rows=[];

# fetch data from query, and put data into $rows. Do not exceed 2000 rows
# and include the header.
if ($bbconn-> fetchQdaAA($qry,$rows,{INCLUDE_HEADER=>1,MAX_ROWS=>2000},15) ) {
	# we will use the formatting method datalinesFormattedAA() to print the fetched data
	my $dataLines = $bbconn-> datalinesFormattedAA(
		$rows,
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

