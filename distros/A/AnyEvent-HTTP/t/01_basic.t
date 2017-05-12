BEGIN { $| = 1; print "1..4\n" }

use AnyEvent::Impl::Perl;

require AnyEvent::HTTP;

print "ok 1\n";

my $cv = AnyEvent->condvar;

AnyEvent::HTTP::http_get ("http://nonexistant.invalid/", timeout => 1, sub {
   print "ok 3\n";
   $cv->send;
});

print "ok 2\n";
$cv->recv;
print "ok 4\n";
