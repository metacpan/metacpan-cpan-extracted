use AnyEvent;
BEGIN { require AnyEvent::Impl::Perl unless $ENV{PERL_ANYEVENT_MODEL} }

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

