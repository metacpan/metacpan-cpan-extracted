$| = 1;
print "1..63\n";

use AnyEvent;
# explicit version on next line, as some cpan-testers test with the 0.1 version,
# ignoring dependencies, and this line will at least give a clear indication of that.
use AnyEvent::Fork 0.6; # we don't actually depend on it, this is for convenience
use AnyEvent::Fork::Pool;

print "ok 1\n";

# all parameters with default values
my $pool = AnyEvent::Fork
   ->new
   ->eval (do { local $/; <DATA> })
   ->AnyEvent::Fork::Pool::run (
        "run", # the worker function

        on_destroy => (my $finish = AE::cv), # called when object is destroyed
     );

print "ok 2\n";

for (1..30) {
   $pool->(doit => $_, sub {
      print "ok # return\n";
   });
}

undef $pool;

$finish->recv;

print "ok 63\n";

__DATA__

sub run {
   print "ok # run\n";
   select undef, undef, undef, rand 0.2;
   AnyEvent::Fork::Pool::retire() if rand > 0.5;
   1
}

