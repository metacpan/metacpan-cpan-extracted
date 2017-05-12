#! perl

BEGIN { $| = 1; print "1..7\n"; }

use Coro;
use Coro::AnyEvent;
use Coro::Multicore;

print "ok 1\n";

my $a11 = async {
   print "ok 3\n";
   Coro::Multicore::sleep 1;
   print "ok 4\n";
};

my $a12 = async {
   Coro::Multicore::sleep 2;
   print "ok 6\n";
};

print "ok 2\n";

$a11->join;
print "ok 5\n";
$a12->join;

print "ok 7\n";

