#!/usr/bin/perl

#BEGIN { $ENV{BABYCONNECT} = '/opt/DBI-BabyConnect/configuration'; }

use strict;
use DBI::BabyConnect;


my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log",3);

print "Active descriptor for \$bbconn: ", $bbconn-> getActiveDescriptor, "\n\n";

# recreate the table with name TABLE1 and TABLE2 based on the
# skeleton TEST_TABLE.mysql saved in $ENV{BABYCONNECT}/SQL/TABLES
$bbconn-> recreateTable('TEST_TABLE.mysql','TABLE1');
$bbconn-> recreateTable('TEST_TABLE.mysql','TABLE2');
$bbconn-> recreateTable('TEST_CONCURRENT.mysql','CONCURRENT');

#$bbconn-> disconnect();

