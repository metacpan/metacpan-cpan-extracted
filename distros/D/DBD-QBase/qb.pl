#!/usr/bin/perl
#
# Assume Table1 has the following:
#	age (int)
#	name (varchar)
#
use DBI;

printf "Loading DBD driver...";
$drh = DBI->install_driver( 'QBase' );
die unless $drh;
print "Ok\n";

printf "Connecting to database...";
$dbh = $drh->connect( 'testdb','test','testdb' );
die unless $dbh;
print "Ok!\n";

printf "Insert Test..";
$cursor = $dbh->prepare( "INSERT Table1 (name,age) values (\"Mouring\",16)" );
$cursor->execute;
$cursor->finish;
printf "Ok\n";

printf "Update test..";
$cursor = $dbh->prepare( "UPDATE Table1 SET age=20 where name=\"Mouring\"" );
$cursor->execute;
$cursor->finish;
printf "Ok\n";

printf "Fetch test...\n";
$cursor = $dbh->prepare( "SELECT * from Table1" );
$cursor->execute;
 
while (@field = $cursor->fetchrow) {
   print "User: @field\n";
  }
$cursor->finish;

printf "Rollback test...Currently Broken\n";
#$cursor = $dbh->prepare( "INSERT Table1 SET age=23 where name=\"New User\"" );
#$cursor->execute;
#$cursor->finish;
#
#$cursor = $dbh->prepare( "SELECT * from Table1" );
#$cursor->execute;
#
#printf "** Changed State **\n"; 
#while (@field = $cursor->fetchrow) {
#   print "User: @field\n";
#  }
#$cursor->finish;
#
#$cursor->rollback;
#printf "** Original State **\n";
#$cursor = $dbh->prepare( "SELECT * from Table1" );
#$cursor->execute;
# 
#while (@field = $cursor->fetchrow) {
#   print "User: @field\n";
#  }
#$cursor->finish;

$dbh->disconnect;

exit;
