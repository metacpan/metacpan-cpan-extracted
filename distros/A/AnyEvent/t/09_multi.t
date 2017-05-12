BEGIN {
   # check for broken perls
   if ($^O =~ /mswin32/i) {
      my $ok;
      local $SIG{CHLD} = sub { $ok = 1 };
      kill 'CHLD', 0;

      unless ($ok) {
         print <<EOF;
1..0 # SKIP Your perl interpreter is badly BROKEN. Child watchers will not work, ever. Try upgrading to a newer perl or a working perl (cygwin's perl is known to work). If that is not an option, you should be able to use the remaining functionality of AnyEvent, but child watchers WILL NOT WORK.
EOF
         exit 0;
      }
   }
}

$^W = 0; # 5.8.6 bugs

use AnyEvent;
use AnyEvent::Util;
BEGIN { require AnyEvent::Impl::Perl unless $ENV{PERL_ANYEVENT_MODEL} }

$| = 1; print "1..15\n";

print "ok 1\n";

$AnyEvent::MAX_SIGNAL_LATENCY = 0.05;

my ($a, $b) = AnyEvent::Util::portable_socketpair;

# I/O write
{
   my $cv = AE::cv;
   my $wt = AE::timer 1, 0, $cv;
   my $s = 0;

   $cv->begin; my $wa = AE::io $a, 1, sub { $cv->end; $s |= 1 };
   $cv->begin; my $wb = AE::io $a, 1, sub { $cv->end; $s |= 2 };

   $cv->recv;

   print $s == 3 ? "" : "not ", "ok 2 # $s\n";
}

# I/O read
{
   my $cv = AE::cv;
   my $wt = AE::timer 0.01, 0, $cv;
   my $s = 0;

   my $wa = AE::io $a, 0, sub { $cv->end; $s |= 1 };
   my $wb = AE::io $a, 0, sub { $cv->end; $s |= 2 };

   $cv->recv;

   print $s == 0 ? "" : "not ", "ok 3 # $s\n";

   syswrite $b, "x";

   $cv = AE::cv;
   $wt = AE::timer 1, 0, $cv;

   $s = 0;
   $cv->begin;
   $cv->begin;
   $cv->recv;

   print $s == 3 ? "" : "not ", "ok 4 # $s\n";

   sysread $a, my $dummy, 1;

   $cv = AE::cv;
   $wt = AE::timer 0.01, 0, $cv;

   $s = 0;
   $cv->recv;

   print $s == 0 ? "" : "not ", "ok 5 # $s\n";
}

# signal
{
   my $cv = AE::cv;
   my $wt = AE::timer 0.01, 0, $cv;
   my $s = 0;

   $cv->begin; my $wa = AE::signal INT => sub { $cv->end; $s |= 1 };
   $cv->begin; my $wb = AE::signal INT => sub { $cv->end; $s |= 2 };

   $cv->recv;

   print $s == 0 ? "" : "not ", "ok 6 # $s\n";

   kill INT => $$;

   $cv = AE::cv;
   $wt = AE::timer 0.2, 0, $cv; # maybe OS X needs more time here? or maybe some buggy arm kernel?

   $s = 0;
   $cv->recv;

   print $s == 3 ? "" : "not ", "ok 7 # $s\n";

   $cv = AE::cv;
   $wt = AE::timer 0.01, 0, $cv;

   $s = 0;
   $cv->recv;

   print $s == 0 ? "" : "not ", "ok 8 # $s\n";
}

# child
{
   my $cv = AE::cv;
   my $wt = AE::timer 0.01, 0, $cv;
   my $s = 0;

   my $pid = fork;

   unless ($pid) {
      sleep 2;
      exit 1;
   }

   my ($apid, $bpid, $astatus, $bstatus);

   $cv->begin; my $wa = AE::child $pid, sub { ($apid, $astatus) = @_; $cv->end; $s |= 1 };
   $cv->begin; my $wb = AE::child $pid, sub { ($bpid, $bstatus) = @_; $cv->end; $s |= 2 };

   $cv->recv;

   print $s == 0 ? "" : "not ", "ok 9 # $s\n";

   kill 9, $pid;

   $cv = AE::cv;
   $wt = AE::timer 0.2, 0, $cv; # cygwin needs ages for this

   $s = 0;
   $cv->recv;

   print $s == 3 ? "" : "not ", "ok 10 # $s\n";
   print $apid == $pid && $bpid == $pid ? "" : "not ", "ok 11 # $apid == $bpid == $pid\n";
   print $astatus == 9 && $bstatus == 9 ? "" : "not ", "ok 12 # $astatus == $bstatus == 9\n";

   $cv = AE::cv;
   $wt = AE::timer 0.01, 0, $cv;

   $s = 0;
   $cv->recv;

   print $s == 0 ? "" : "not ", "ok 13 # $s\n";
}

# timers (don't laugh, some event loops are more broken...)
{
   my $cv = AE::cv;
   my $wt = AE::timer 1, 0, $cv;
   my $s = 0;

   $cv->begin; my $wa = AE::timer 0   , 0, sub { $cv->end; $s |= 1 };
   $cv->begin; my $wb = AE::timer 0   , 0, sub { $cv->end; $s |= 2 };
   $cv->begin; my $wc = AE::timer 0.01, 0, sub { $cv->end; $s |= 4 };

   $cv->recv;

   print $s == 7 ? "" : "not ", "ok 14 # $s\n";
}

print "ok 15\n";

exit 0;

