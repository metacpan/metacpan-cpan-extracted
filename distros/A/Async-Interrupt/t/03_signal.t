unless (exists $SIG{USR1}) {
   print "1..0 # SKIP no SIGUSR1 - broken platform, skipping tests\n";
   exit;
}

print "1..9\n"; $|=1;

use Async::Interrupt;

my $three = 3;

my $ai = new Async::Interrupt
   cb     => sub { print "ok ", $three++, "\n" },
   signal => "CHLD";

print "ok 1\n";

{
   $ai->scope_block;
   $ai->scope_block;
   kill CHLD => $$;
   print "ok 2\n";
}

kill CHLD, $$;

$ai->signal_hysteresis (1);

kill CHLD, $$;
kill CHLD, $$;
kill CHLD, $$;
kill CHLD, $$;

print "ok 9\n";


