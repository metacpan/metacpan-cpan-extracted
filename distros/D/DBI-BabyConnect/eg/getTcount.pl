#!/usr/bin/perl -w

use strict;
use DBI::BabyConnect;

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log" , 2);

my $count = $bbconn-> getTcount('TABLE1', 'DATANUM', ' DATANUM > 1002 AND DATANUM < 1005');
print $count, "\n";

