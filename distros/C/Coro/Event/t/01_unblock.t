BEGIN {
   if ($^O =~ /mswin32/i) {
      print <<EOF;
1..0 # Perl binary broken, skipping test. Upgrading to a working perl is advised.
EOF
      exit 0;
   }
}

$| = 1;

print "1..12\n";

use Coro;
use Coro::Event;
use Coro::Handle;

print "ok 1\n";

use Socket;
socketpair my $r, my $w, AF_UNIX, SOCK_STREAM, PF_UNSPEC;

print "ok 2\n";

$r = unblock $r;
$w = unblock $w;

print "ok 3\n";

async {
   print "ok 5\n";

   do_timer (after => 0.001);

   print "ok 7\n";

   print $w "13\n";

   print "ok 8\n";

   Coro::Event::do_timer (after => 0.1); # see EV/t/01*

   $w->print ("x" x (1024*1024*8));
   print "ok 10\n";
   $w->print ("x" x (1024*1024*8));

   print $w "77\n";
   close $w;
};

print "ok 4\n";

cede;

print "ok 6\n";

print <$r> == 13 ? "" : "not ", "ok 9\n";

$r->read (my $buf, 1024*1024*16);

print "ok 11\n";

print <$r> == 77 ? "" : "not ", "ok 12\n";


