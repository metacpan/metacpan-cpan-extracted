BEGIN { $| = 1; print "1..5\n"; }

END {print "not ok 1\n" unless $loaded;}

use Coro;
use Coro::EV;
$loaded = 1;

print "ok 1\n";

async {
   print "ok 3\n";
   $var = 7;
   print "ok 4\n";
};

print "ok 2\n";

Coro::EV::timed_io_once \*STDOUT, EV::WRITE
   unless $^O =~ /mswin32/i; # *sigh*
cede;

print $var == 7 ? "ok 5\n" : "not ok 5\n";


