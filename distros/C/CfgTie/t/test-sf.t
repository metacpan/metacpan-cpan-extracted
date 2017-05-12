# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Secure::File;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print STDERR "Plain test\n";
my $N=new Secure::File;
$N->open(">/tmp/$$",0666);
if (-f "/tmp/$$")
  {
     print "ok 2\n";
     unlink "/tmp/$$";
  }
else
  {print "not ok 2\n";}

#Open a new file, with the same name
print STDERR "New open test\n";
my $N2=new Secure::File ">/tmp/$$";
#Do a stat:: they shouldn't be the same
if (-f "/tmp/$$")
  {
     print "ok 3\n";
     unlink "/tmp/$$";
  }
else
  {print "not ok 3\n";}

#Now close the files
#And see of the files inodes are what we expect
