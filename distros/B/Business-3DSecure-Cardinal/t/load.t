BEGIN { $| = 1; print "1..1\n"; }
END { print "not ok 1\n" unless $loaded; }
use Business::3DSecure::Cardinal;
$loaded = 1;
print "ok 1\n";

