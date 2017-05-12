# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Business::BancaSella::Ris::File;
my $file = 't/bsRis.txt';
$ric = new Business::BancaSella::Ris::File(file => $file);
# open file to extract first password for checking
open(F,$file) or die "Unable to open $file";
my $password = <F>;chomp($password);
close(F);
print $ric->check($password) . "\n";
die if (!$ric->check($password));
$ric->remove($password);
die if ($ric->check($password));


$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

