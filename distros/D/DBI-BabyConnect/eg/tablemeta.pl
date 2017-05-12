#!/usr/bin/perl

use strict;
use DBI::BabyConnect;

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log" , 2);

print "Active descriptor for \$bbconn: ", $bbconn-> getActiveDescriptor, "\n\n";

print $bbconn-> snapTableMetadata('TABLE2');

#use Data::Dumper;
#print Dumper($bbconn-> strucTableMetadata('TABLE2'));

