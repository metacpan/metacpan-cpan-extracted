#!perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use AIX::ODM;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.


print ("\nTesting module AIX::ODM version $AIX::ODM::VERSION with Perl version $] running on $^O.\n\n");

my %odm = AIX::ODM::odm_dump('C');

while ( my ($ndx1, $lev2) = each %odm ) {
  while ( my ($ndx2, $val) = each %$lev2 ) {
    if (${odm{${ndx1}}{${ndx2}}}) {
      print "odm{${ndx1}}{${ndx2}} = ${odm{${ndx1}}{${ndx2}}}\n";
    }
  }
}

print("\nok 2\n");

