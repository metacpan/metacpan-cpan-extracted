#!/usr/bin/perl -I./t
$| = 1;

print "1..$tests\n";

use DBI;
use tests;
print "ok 1\n";
++$t;

#
# Connect to Database
#
print " Test 2: connecting to the database\n";
Check($dbh = MyConnect())
	or DbiError();

#
# Create a test table
#
print " Test 3: create test table\n";
my $table = "perl_test";
sub tab_create {
  my $fields = "a INTEGER, b CHAR(20), c VARCHAR(100)";
  $dbh->do("DROP TABLE $table");
  $dbh->do("CREATE TABLE $table ($fields)")
}
Check(tab_create())
	or DbiError();

#
# Check existance of last create table
#
print " Test 4: check existance of test table\n";
sub tab_exist {
  $rc = 0;
  return $rc unless ($sth = $dbh->table_info());  #NEW
  while ($row = $sth->fetchrow_hashref()) {
    if ($table eq $row->{TABLE_NAME}) {
       my $owner = $row->{TABLE_OWNER} || '(unknown owner)';
       print "  ==> $owner.$row->{TABLE_NAME}\n";
       $rc = 1;
       last;
    }
  }
  $sth->finish();
  $rc;
};
Check(tab_exist())
	or DbiError();

#
# Insert some tuple into test table
#
print " Test 5: insert test data\n";
sub tab_insert {
  $sth = $dbh->prepare("INSERT INTO $table values (3, 'bletch',"
                       ."'bletch varchar')") || die "Prepare $DBI::errstr";
  $sth->execute;
  $sth->finish;
  $dbh->do(qq{INSERT INTO $table (a, b, c) VALUES (1, 'foo', 'foo varchar')});
  $dbh->do(qq{INSERT INTO $table VALUES (2, 'bar', 'bar varchar')});
}
Check(tab_insert())
	or DbiError();

#
# Select tuple from test table
#
print " Test 6: select test data\n";
sub tab_select {
  $sth = $dbh->prepare("SELECT * FROM $table") or return undef;
  $sth->execute();
  while (@row = $sth->fetchrow()) {
    print((defined($row[0]) ? $row[0] : "NULL"), "|",
          (defined($row[1]) ? $row[1] : "NULL"), "|",
          (defined($row[2]) ? $row[2] : "NULL"), "\n");
  }
  $sth->finish();
  1;
}
Check(tab_select())
	or DbiError();

#
# Drop the test table
#
sub tab_delete {
    $dbh->do("DELETE FROM $table");
}
Check(tab_delete())
	or DbiError();

BEGIN {$tests = 7;}
