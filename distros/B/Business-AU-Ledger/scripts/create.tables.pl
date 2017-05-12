#!/usr/bin/perl
#
# Name:
#	create.tables.pl.

use strict;
use warnings;

use Business::AU::Ledger::Util::Create;

# --------------------------------

my($creator) = Business::AU::Ledger::Util::Create -> new(verbose => 1);

print "Creating tables for database 'ledger'. \n";

$creator -> drop_all_tables;
$creator -> create_all_tables;

print "Finished creating tables. \n";
print "------------------------- \n";
