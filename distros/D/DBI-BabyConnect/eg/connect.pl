#!/usr/bin/perl

use strict;
use DBI::BabyConnect;

my $bbconn1 = DBI::BabyConnect->new('BABYDB_001');
$bbconn1-> HookError(">>/tmp/error1.log");
$bbconn1-> HookTracing(">>/tmp/db1.log" , 2);

my $bbconn2 = DBI::BabyConnect->new('BABYDB_002');
$bbconn1-> HookError(">>/tmp/error2.log");
$bbconn1-> HookTracing(">>/tmp/db2.log" , 2);

print "Active descriptor for \$bbconn1: ", $bbconn1-> getActiveDescriptor, "\n\n";
print "\$bbconn1 handler is set to database '", $bbconn1-> dbname, "' with driver '", $bbconn1-> dbdriver, "'\n";

print "Active descriptor for \$bbconn2: ", $bbconn2-> getActiveDescriptor, "\n\n";
print "\$bbconn2 handler is set to database '", $bbconn2-> dbname, "' with driver '", $bbconn2-> dbdriver, "'\n";

