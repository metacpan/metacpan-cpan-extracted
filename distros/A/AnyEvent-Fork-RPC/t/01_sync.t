$| = 1;
print "1..13\n";

use AnyEvent;
# explicit version on next line, as some cpan-testers test with the 0.1 version,
# ignoring dependencies, and this line will at least give a clear indication of that.
use AnyEvent::Fork 0.6; # we don't actually depend on it, this is for convenience
use AnyEvent::Fork::RPC;

print "ok 1\n";

my $done = AE::cv;

my $rpc = AnyEvent::Fork
   ->new
   ->eval (do { local $/; <DATA> })
   ->AnyEvent::Fork::RPC::run ("run",
      on_error   => sub { print "Bail out! $_[0]\n"; exit 1 },
      on_event   => sub { print "$_[0]\n" },
      on_destroy => $done,
   );

print "ok 2\n";

for (3..6) {
   $rpc->($_ * 2 - 1, sub { print $_[0] });
}

print "ok 3\n";

undef $rpc;

print "ok 4\n";

$done->recv;

print "ok 13\n";

__DATA__

sub run {
   my ($count) = @_;

   AnyEvent::Fork::RPC::event ("ok $count");

   "ok " . ($count + 1) . "\n"
}

