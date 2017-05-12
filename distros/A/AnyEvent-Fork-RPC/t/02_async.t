$| = 1;
print "1..10\n";

use AnyEvent;
# explicit version on next line, as some cpan-testers test with the 0.1 version,
# ignoring dependencies, and this line will at least give a clear indication of that.
use AnyEvent::Fork 0.6; # we don't actually depend on it, this is for convenience
use AnyEvent::Fork::RPC;

print "ok 1\n";

my $done = AE::cv;

my $rpc = AnyEvent::Fork
   ->new
   ->require ("AnyEvent::Fork::RPC::Async")
   ->eval (do { local $/; <DATA> })
   ->AnyEvent::Fork::RPC::run ("run",
      async      => 1,
      on_error   => sub { print "Bail out! $_[0]\n"; exit 1 },
      on_event   => sub { print "$_[0]\n" },
      on_destroy => $done,
   );

print "ok 2\n";

$rpc->(3, sub { print $_[0] });

print "ok 3\n";

undef $rpc;

print "ok 4\n";

$done->recv;

print "ok 10\n";

__DATA__

use AnyEvent;

sub run {
   my ($done, $count) = @_;

   my $n;

   AnyEvent::Fork::RPC::event "ok 5";

   my $w; $w = AE::timer 0.1, 0.1, sub {
      ++$n;

      AnyEvent::Fork::RPC::event "ok " . ($n + 5);

      if ($n == $count) {
         undef $w;
         $done->("ok " . ($n + 6) . "\n");
      }
   };
}
