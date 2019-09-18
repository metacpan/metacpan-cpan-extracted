use Scalar::Util qw(weaken);
use AnyEvent;
BEGIN { require AnyEvent::Impl::Perl unless $ENV{PERL_ANYEVENT_MODEL} }

$| = 1; print "1..7\n";

print "ok 1\n";

my $c1 = AnyEvent->condvar;
my $c2 = AE::cv;

my $t1 = AnyEvent->timer (after => 0.1, cb => sub { print "ok 3\n"; $c1->() });
my $t2 = AnyEvent->timer (after => 0.5, cb => sub { print "not ok 6\n" });
my $t3 = AnyEvent->timer (after => 0.9, cb => sub { print "ok 6\n"; $c2->send });

print "ok 2\n";

$c1->wait;

print "ok 4\n";

Scalar::Util::weaken $t2;

print $t2 ? "not " : "", "ok 5\n";

$c2->wait;

print "ok 7\n";
