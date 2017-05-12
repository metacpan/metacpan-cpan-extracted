BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Date::Day;
$loaded = 1;
print "ok 1\n";
print "April 8, 1980 was on ",&day(4,8,1980),"\n\n";
