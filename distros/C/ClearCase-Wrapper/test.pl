# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use ClearCase::Wrapper;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

### This is a pretty trivial test but then the only valid requirement
### you can make of this module is that it act as a wrapper to cleartool;
### any specific functionality delivered after the __END__ token is provided
### as an example only and I specifically do not want to test it here.

if (`cleartool pwd -h`) {
    system $^X, qw(-w -Mblib ./cleartool.plx pwv);
    print $? ? "not ok 2\n" : "ok 2\n";
} else {
    print "Warning: no cleartool command found, test skipped\n";
    print "ok 2\n";
    exit 0;
}
