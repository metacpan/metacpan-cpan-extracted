#!/usr/bin/perl -I./t

require DBI;
use tests;

print "1..$tests\n";

#
#   Connect to the database
my $dbh;
Check($dbh = DBI->connect())
        or DbiError();
$dbh->{PrintError}=0;
$dbh->{AutoCommit}=0;

foreach (qw(perl_test perl_blob perl_chartest testaa)) {
  Check(($dbh->do("DROP TABLE $_")) or ($dbh->state eq "S0002"))
	or DbiError();
}

Check($dbh->commit())
	or DbiError();

Check($dbh->disconnect())
	or DbiError();

BEGIN { $tests = 7; }
