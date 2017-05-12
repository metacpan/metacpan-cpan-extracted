
### This won't be testable for real until we have a good way of
### testing things inside modperl.

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use AxKit::Plugin::DisableXSLTParams;
$loaded = 1;
print "ok 1\n";
