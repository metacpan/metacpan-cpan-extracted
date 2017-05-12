use AnyEvent;

         BEGIN { $^W = 0 }
         BEGIN { $ENV{PERL_ANYEVENT_LOOP_TESTS} or ((print qq{1..0 # SKIP PERL_ANYEVENT_LOOP_TESTS not true\n}), exit 0) }
         BEGIN { eval q{use AnyEvent::Impl::IOAsync;1} or ((print qq{1..0 # SKIP AnyEvent::Impl::IOAsync not loadable\n}), exit 0) }
         
      

$| = 1; print "1..6\n";

print "ok 1\n";

my $cv = AnyEvent->condvar;

print "ok 2\n";

my $timer1 = AnyEvent->timer (after => 0.1, cb => sub { print "ok 5\n"; $cv->broadcast });

print "ok 3\n";

AnyEvent->timer (after => 0.01, cb => sub { print "not ok 5\n" });

print "ok 4\n";

$cv->wait;

print "ok 6\n";

