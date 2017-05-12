BEGIN { $| = 1; $^W = 0; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Apache::PageKit;
$loaded = 1; 
print "ok 1\n";
