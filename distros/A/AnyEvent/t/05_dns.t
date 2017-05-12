# we avoid complicated tests here because some systems will
# not have working DNS

use AnyEvent;
BEGIN { require AnyEvent::Impl::Perl unless $ENV{PERL_ANYEVENT_MODEL} }
use AnyEvent::DNS;

$| = 1; print "1..5\n";

print "ok 1\n";

AnyEvent::DNS::resolver;

print "ok 2\n";

# make sure we timeout faster
AnyEvent::DNS::resolver->{timeout} = [0.5];
AnyEvent::DNS::resolver->_compile;

print "ok 3\n";

my $cv = AnyEvent->condvar;

AnyEvent::DNS::a "www.google.de", sub {
   print "ok 4 # www.google.de => @_\n";
   $cv->send;
};

$cv->recv;

print "ok 5\n";

