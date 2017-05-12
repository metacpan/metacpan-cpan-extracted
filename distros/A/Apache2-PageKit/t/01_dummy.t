
# we require Apache2 silently, since maybe Apache2::PageKit is only
# installed under Apache2 and we try to load it later.

BEGIN { eval { require Apache2 }; $| = 1; $^W = 0; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use mod_perl2;
#use Apache2::PageKit;
$loaded = 1; 
print "ok 1\n";
