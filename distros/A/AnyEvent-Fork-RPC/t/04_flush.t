$| = 1;
print "1..10\n";

use AnyEvent::Fork;
use AnyEvent::Fork::RPC;

sub ok($;$) {
   print $_[0] ? "" : "not ", "ok ", ++$::ok, " # $_[1]\n";
}

ok 1;

my $code = do { local $/; <DATA> };

for my $async (0, 1) {
   my ($cv, $ev);

   my $rpc = AnyEvent::Fork
      ->new
      ->eval ($code)
      ->AnyEvent::Fork::RPC::run ("run",
         async      => $async,
         on_error   => sub { ok $ev, "on_error"; $cv->send },
         on_event   => sub { ok $_[0], "event"; $ev = 1 },
         on_destroy => $done,
      );

   ok 1, "before";
   $rpc->(0, $cv = AE::cv);
   $cv->recv;
   ok 1, "after";
}

ok 1;

__DATA__

sub run {
   AnyEvent::Fork::RPC::event (1);
   AnyEvent::Fork::RPC::flush ();
   exit 2;
}
