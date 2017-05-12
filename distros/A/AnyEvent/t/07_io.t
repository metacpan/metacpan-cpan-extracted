use AnyEvent;
use AnyEvent::Util;
BEGIN { require AnyEvent::Impl::Perl unless $ENV{PERL_ANYEVENT_MODEL} }

$| = 1; print "1..18\n";

print "ok 1\n";

my ($a, $b) = AnyEvent::Util::portable_socketpair;

print $a && $b ? "" : "not ", "ok 2 # $a,$b\n";

my ($cv, $t, $ra, $wa, $rb, $wb);

$rb = AnyEvent->io (fh => $b, poll => "r", cb => sub {
   print "ok 6\n";
   sysread $b, my $buf, 1;
   print "ok 7\n";
   $wb = AnyEvent->io (fh => $b, poll => "w", cb => sub {
      print "ok 8\n";
      undef $wb;
      syswrite $b, "1";
   });
});

print "ok 3\n";

{ my $cv = AnyEvent->condvar; $t = AnyEvent->timer (after => 0.05, cb => sub { $cv->send }); $cv->recv }

print "ok 4\n";

$wa = AnyEvent->io (fh => $a, poll => "w", cb => sub {
   syswrite $a, "0";
   undef $wa;
   print "ok 5\n";
});

$ra = AnyEvent->io (fh => $a, poll => "r", cb => sub {
   sysread $a, my $buf, 1;
   print "ok 9\n";
   $cv->send;
});

$cv = AnyEvent->condvar; $cv->recv;

print "ok 10\n";

$rb = AnyEvent->io (fh => fileno $b, poll => "r", cb => sub {
   print "ok 14\n";
   sysread $b, my $buf, 1;
   print "ok 15\n";
   $wb = AnyEvent->io (fh => fileno $b, poll => "w", cb => sub {
      print "ok 16\n";
      undef $wb;
      syswrite $b, "1";
   });
});

print "ok 11\n";

{ my $cv = AnyEvent->condvar; $t = AnyEvent->timer (after => 0.05, cb => sub { $cv->send }); $cv->recv }

print "ok 12\n";

$wa = AnyEvent->io (fh => fileno $a, poll => "w", cb => sub {
   syswrite $a, "0";
   undef $wa;
   print "ok 13\n";
});

$ra = AnyEvent->io (fh => $a, poll => "r", cb => sub {
   sysread $a, my $buf, 1;
   print "ok 17\n";
   $cv->send;
});

$cv = AnyEvent->condvar; $cv->recv;

print "ok 18\n";

