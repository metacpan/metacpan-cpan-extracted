BEGIN { $| = 1; print "1..5\n"; }

END {print "not ok 1\n" unless $loaded;}

use Coro;
use Coro::Event;
$loaded = 1;

print "ok 1\n";

async {
   print "ok 3\n";
   $var = 7;
   print "ok 4\n";
};

print "ok 2\n";

do_var (var => \$var, poll => 'w');

print $var == 7 ? "ok 5\n" : "not ok 5\n";


