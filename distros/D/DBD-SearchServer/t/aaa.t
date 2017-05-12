#!/usr/local/bin/perl -w
# This tests the existence of the test table.


my $tests;

BEGIN {

   $tests = 1;

   if (length($ENV{'FULCRUM_HOME'}) <= 0) {
      $ENV{'FULCRUM_HOME'} = "/home/fulcrum";
      warn "FULCRUM_HOME set to /home/fulcrum!";
   }
   $ENV{'FULSEARCH'} = "./fultest";
   $ENV{'FULTEMP'} = "./fultest";
}


print "1..$tests\n";

if (! -r "$ENV{FULSEARCH}/test.cat") {
   print STDERR "\n\tIt seems you have not prepared the test table in $ENV{FULSEARCH}\n";
   print STDERR "\tRead the docs and come back later!\n";
   print STDERR "\tALL TESTS WILL FAIL.\n";
}
else {
  print "ok 1\n"; 
}
