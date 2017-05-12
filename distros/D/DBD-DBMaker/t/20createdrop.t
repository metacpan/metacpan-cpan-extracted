#!/usr/local/bin/perl -I./t
#
#   $Id: 20createdrop.t,v 1.1 1998/04/22 17:42:33 joe Exp $
#
#   This is a skeleton test. For writing new tests, take this file
#   and modify/extend it.
#

use DBI;
use tests;

print "1..$tests\n";

#
#   Connect to the database
my $dbh;
Check($dbh = MyConnect())
	or DbiError();

#
#   Create a new table
#
my $table='testaa';
my $def="id int not null, name char(64) not null";
Check($dbh->do("Create table $table ($def)"))
	or DbiError();

#
#   ... and drop it.
#
Check($dbh->do("DROP TABLE $table"))
	or DbiError();

#
#   Finally disconnect.
#
Check($dbh->disconnect())
	or DbiError();

BEGIN { $tests = 4 }
