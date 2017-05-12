print "1..12\n"; $|=1;

use Async::Interrupt;

my $ai = new Async::Interrupt
   cb => sub { print "ok $_[0]\n" };

my $ai2 = new Async::Interrupt;

print $$ai ? "" : "not ", "ok 1 # $$ai\n";

my ($a, $b) = $ai->signal_func;

print $a ? "" : "not ", "ok 2 # $a\n";
print $b ? "" : "not ", "ok 3 # $b\n";

$ai->signal (4);

my $ai3 = new Async::Interrupt;

print "ok 5\n";

$ai->block;
$ai->signal (7);
print "ok 6\n";
$ai->unblock;
print "ok 8\n";

undef $ai2;

print "ok 9\n";

{
   $ai->scope_block;
   $ai->signal (11);
   print "ok 10\n";
}
print "ok 12\n";

