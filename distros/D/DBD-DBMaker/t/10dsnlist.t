#!/usr/local/bin/perl -I./t

use DBI;
use tests;

print "1..$tests\n";

Check((defined(@dsn = DBI->data_sources('DBMaker')))) or DbiError();
if (defined(@dsn)) {
  print "______________________________\n"; 
  print " DBMaker Available Databases:\n"; 
  print "______________________________\n"; 
  print "\t", join("\n\t", @dsn);
  print "\n\n";
}

BEGIN { $tests = 1 }
