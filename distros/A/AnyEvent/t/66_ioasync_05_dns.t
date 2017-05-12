# we avoid complicated tests here because some systems will
# not have working DNS

use AnyEvent;

         BEGIN { $^W = 0 }
         BEGIN { $ENV{PERL_ANYEVENT_LOOP_TESTS} or ((print qq{1..0 # SKIP PERL_ANYEVENT_LOOP_TESTS not true\n}), exit 0) }
         BEGIN { eval q{use AnyEvent::Impl::IOAsync;1} or ((print qq{1..0 # SKIP AnyEvent::Impl::IOAsync not loadable\n}), exit 0) }
         
      
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

