# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Business::Paybox;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

print "no further tests, install Java-LHL first and test it!\nThen see documentation how to make a test payment with this software...\n\n";


