BEGIN {
   unless (exists $SIG{USR1}) {
      print <<EOF;
1..0 # SKIP Broken perl detected, skipping tests.
EOF
      exit 0;
   }
}

$|=1;
print "1..4\n";

# note: the fourth test falls into an infinite loop in older versions of Coro

use AnyEvent::Util; ();

use Coro;
use Coro::Handle;

my @sep = ("\n", "e", undef, "");
my @ex = (
   "one\n:two\n:\n:three\n:\n:\n:four\n:\n:\n:five\n:six\n:seven:",
   "one:\ntwo\n\nthre:e:\n\n\nfour\n\n\nfive:\nsix\nse:ve:n:",
   "one\ntwo\n\nthree\n\n\nfour\n\n\nfive\nsix\nseven:",
   "one\ntwo\n\n:three\n\n:four\n\n:five\nsix\nseven:",
);

for my $c (0..3) {
   my ($R, $W) = AnyEvent::Util::portable_pipe
      or die "error creating pipe pair: $!";

   $R = unblock $R;
   $W = unblock $W;

   $W->autoflush(1);
   async {
   	$W->print("one\ntwo\n\nthree\n\n\nfour\n\n\nfive\nsix\nseven");
   	$W->close;
   }

   my $p;
   while (defined(my $i = $R->readline($sep[$c]))) {
   	$p .= $i . ":";
   }

   $ex[$c] eq $p or
   	print "not ";
   print "ok " . (1 + $c) . "\n";
}
