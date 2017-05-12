# Tests that it is possible to load the module
print "1..1\n";

use Data::Pivoter;

if ($Data::Pivoter::VERSION eq '0.08') {
    print "ok 1\n";
} else {
    print "not ok 1\n";
    print STDERR "Wrong version: $Data::Pivoter::VERSION\n";
}
