# $Id: test.pl,v 1.2 1998/09/15 17:40:00 don Exp $

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Apache::Throttle;
use Apache::Throttle::Log;
$loaded = 1;
print "ok 1\n";
