#!/usr/bin/perl -I./t
$| = 1;
print "1..$tests\n";

use DBI qw(:sql_types);
use tests;

print " Test 1: connecting to the database\n";
Check(my $dbh = MyConnect())
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

print " Test 4: insert test data\n";
my @data = 
    ( [ 1, 'foo', 'foo varchar' ],
      [ 2, 'bar', 'bar varchar' ],
      [ 3, 'bletch', 'bletch varchar' ],
    );
sub tab_insert {
  my $dref = shift;
  my @data = @{$dref};
  my $sth = $dbh->prepare("INSERT INTO $table VALUES (:1, :2, :3)");
  unless ($sth) {
    warn $DBI::errstr;
    return 0;
  }
  foreach (@data) {
#    $sth->execute($@_->[0], $_->[1], $_->[2]);
    $sth->bind_param(1, $_->[0]);
    $sth->bind_param(2, $_->[1]);
    $sth->bind_param(3, $_->[2]);
    unless ($sth->execute) {
      warn $DBI::errstr;
      return 0;
    }
  }
  $sth->finish();
  if (!$dbh->commit()) {
    warn $DBI::errstr;
    return 0;
  }
  1;
}
Check(tab_insert(\@data))
	or DbiError();

print " Test 5: select test data\n";
sub tab_select {
  my @row;

  my $sth = $dbh->prepare("SELECT * FROM $table WHERE a = :1")
	or return undef;
  $sth->execute(2);
  while (@row = $sth->fetchrow()) {
    print "$row[0]|$row[1]|$row[2]|\n";
  }
  $sth->finish();
  return 1;
}
Check(tab_select())
	or DbiError();

sub tab_delete {
  $dbh->do("DELETE FROM $table");
}
Check(tab_delete())
	or DbiError();

BEGIN {$tests = 5;}
