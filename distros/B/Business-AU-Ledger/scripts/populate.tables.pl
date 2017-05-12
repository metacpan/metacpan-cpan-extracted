#!/usr/bin/perl
#
# Name:
#	populate.tables.pl.

use strict;
use warnings;

use Business::AU::Ledger::Util::Create;

# ----------------------------

my($creator) = Business::AU::Ledger::Util::Create -> new(verbose => 1);

print "Populating tables for database 'ledger'. \n";

$creator -> populate_all_tables;

print "Finished populating tables \n";
print "-------------------------- \n";
