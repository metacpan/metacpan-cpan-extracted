BEGIN { $| = 1; print "1..23\n" }

use AnyEvent::Impl::Perl;

require AnyEvent::HTTP;

print "ok 1\n";

my $t = 2;

for my $auth (qw(
   0.42.42.42
   [0.42.42.42]:81
   [::0.42.42.42]:81
   [::0:2]
   [0:0::2]:80
   [::0:2]:81
   [0:0::2]:81
)) {
   my $cv = AE::cv;

   AnyEvent::HTTP::http_get ("http://$auth/", timeout => 1/128, sub {
      print $_[1]{Status} == 599 ? "not ": "", "ok ", $t + 1, " # $_[1]{Status} $auth\n";
      $cv->send;
   });

   print "ok ", $t, "\n";
   $cv->recv;
   print "ok ", $t + 2, "\n";

   $t += 3;
}

print "ok 23\n";
