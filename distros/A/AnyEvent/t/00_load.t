$|=1;
BEGIN { print "1..13\n" }

require AnyEvent; print "ok 1\n";
require AnyEvent::Impl::Perl; print "ok 2\n";
require AnyEvent::Util; print "ok 3\n";
require AnyEvent::Handle; print "ok 4\n";
require AnyEvent::DNS; print "ok 5\n";

0 && require AnyEvent::Impl::EV; print "ok 6\n";
0 && require AnyEvent::Impl::Event; print "ok 7\n";
0 && require AnyEvent::Impl::EventLib; print "ok 8\n";
0 && require AnyEvent::Impl::Glib; print "ok 9\n";
0 && require AnyEvent::Impl::Tk; print "ok 10\n";
1 && require AnyEvent::Impl::Perl; print "ok 11\n";
0 && require AnyEvent::Impl::POE; print "ok 12\n";
0 && require AnyEvent::Impl::Qt; print "ok 13\n";


