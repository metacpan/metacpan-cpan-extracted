#!/usr/bin/perl

use strict;
use DBI::BabyConnect;

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log" , 2);

print $bbconn-> snapTableDescription('TABLE2');

