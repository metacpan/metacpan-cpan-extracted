BEGIN {
   unless (exists $SIG{USR1}) {
      print <<EOF;
1..0 # SKIP Broken perl detected, skipping tests.
EOF
      exit 0;
   }
}

use AnyEvent;
BEGIN { require AnyEvent::Impl::Perl unless $ENV{PERL_ANYEVENT_MODEL} }

$| = 1; print "1..5\n";

print "ok 1\n";

my $cv = AnyEvent->condvar;

my $error = AnyEvent->timer (after => 5, cb => sub {
   print <<EOF;
Bail out! No signal caught.
EOF
   exit 0;
});

my $sw = AnyEvent->signal (signal => 'INT', cb => sub {
  print "ok 3\n";
  $cv->broadcast;
});

print "ok 2\n";
kill 'INT', $$;
$cv->recv;
undef $error;

print "ok 4\n";

undef $sw;

print "ok 5\n";

