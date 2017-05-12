#!/usr/local/bin/perl -I./t
#
#   $Id: 40blobs.t,v 1.1 1998/04/22 17:42:33 joe Exp $
#
#   This is a test for correct handling of BLOBS; namely $dbh->quote
#   is expected to work correctly.
#


use DBI;
use tests;

print "1..$tests\n";

sub ShowBlob($) {
    my ($blob) = @_;
    for($i = 0;  $i < 8;  $i++) {
	if (defined($blob)  &&  length($blob) > $i) {
	    $b = substr($blob, $i*32);
	} else {
	    $b = "";
	}
	printf("%08lx %s\n", $i*32, unpack("H64", $b));
    }
}

#
#   Connect to the database
Check($dbh = MyConnect())
	or DbiError();

foreach $size (128) {
#
#   Create a new table
#
  $table = "perl_blob";
  $def = "id int not null, name long varbinary";
  Check($dbh->do("create table $table ($def)"))
	or DbiError();

#
#  Create a blob
#
  my ($blob) = "";
  my $b = "";
  for ($j = 0;  $j < 256;  $j++) {
    $b .= chr($j);
  }
  for ($i = 0;  $i < $size;  $i++) {
    $blob .= $b;
  }
  printf ("Create a Blob length = %d\n", length($blob));

#
#   Insert a row into the test table.......
#
  my($sth);
  Check($sth = $dbh->prepare("INSERT INTO $table VALUES(1, ?)"))
	or DbiError();


  Check($sth->bind_param(1, $blob, { TYPE => DBI::SQL_LONGVARBINARY}))
	or DbiError();

  Check($sth->execute)
	or DbiError();

  Check($sth->finish)
	or DbiError();

#
#   Now, try SELECT'ing the row out.
#
  $dbh->{LongReadLen} = 40000;
  Check($cursor = $dbh->prepare("SELECT id, name FROM $table WHERE id = 1"))
	or DbiError();

  Check($cursor->execute)
	or DbiError();

  Check((defined($row = $cursor->fetchrow_arrayref)))
	or DbiError();

  Check((@$row == 2  &&  $$row[0] == 1  &&  $$row[1] eq $blob))
	or (ShowBlob($blob), ShowBlob(defined($$row[1]) ? $$row[1] : ""));

  Check($cursor->finish)
	or DbiError();

  Check(undef $cursor || 1)
	or DbiError();

#
#   Finally drop the test table.
#
  Check($dbh->do("DROP TABLE $table"))
	or DbiError();
}

Check($dbh->disconnect())
        or DbiError();

BEGIN { $tests = 14 }
