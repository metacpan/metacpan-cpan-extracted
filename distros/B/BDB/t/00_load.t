BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use BDB;
$loaded = 1;
print "ok 1\n";
BDB::min_parallel(10);
print "ok 2\n";
BDB::max_parallel(0);
print "ok 3\n";

