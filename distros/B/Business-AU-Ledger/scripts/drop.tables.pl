#!/usr/bin/perl
#
# Name:
#	drop.tables.pl.

use strict;
use warnings;

use Business::AU::Ledger::Util::Create;

# ----------------------------

my($creator) = Business::AU::Ledger::Util::Create -> new(verbose => 1);

print "Dropping tables for database 'ledger'. \n";

$creator -> drop_all_tables;

print "Finished dropping tables. \n";
print "------------------------- \n";
