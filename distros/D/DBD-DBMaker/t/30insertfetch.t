#!/usr/local/bin/perl -I./t
#
#   $Id: 30insertfetch.t,v 1.1 1998/04/22 17:42:33 joe Exp $
#
#   This is a simple insert/fetch test.
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
#   Insert a row into the test table.......
#
Check($dbh->do("INSERT INTO $table VALUES(1, 'DBMaker')"))
	or DbiError();

#
#   ...and delete it........
#
Check($dbh->do("DELETE FROM $table WHERE id = 1"))
	or DbiError();

#
#   Now, try SELECT'ing the row out. This should be fail.
#
Check(my $cursor = $dbh->prepare("SELECT * FROM $table WHERE id = 1"))
	or DbiError();

Check($cursor->execute)
	or DbiError();

my ($row, $errstr);
Check(! defined($row = $cursor->fetchrow_arrayref) &&
      (defined($errstr = $cursor->errstr) && $cursor->errstr ne '')
     )	or DbiError();

Check( $cursor->finish, "\$sth->finish failed")
	or DbiError();

Check(undef $cursor || 1);

#
#   Finally drop the test table.
#
Check($dbh->do("DROP TABLE $table"))
	or DbiError();

#
#   Finally disconnect.
#
Check($dbh->disconnect())
        or DbiError();

BEGIN { $tests = 11 }
