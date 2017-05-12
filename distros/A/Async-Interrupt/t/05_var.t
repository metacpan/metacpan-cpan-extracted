print "1..7\n"; $|=1;

use Async::Interrupt;

my $var;

my $ai = new Async::Interrupt
   var => \$var,
   cb => sub { print $var ? "not " : "", "ok $_[0]\n" };

print $$ai ? "" : "not ", "ok 1 # $$ai\n";

print $ai->c_var ? "" : "not ", "ok 2\n";

$ai->signal (3);

print $var == 0 ? "" : "not ", "ok 4\n";

$ai->block;
$ai->signal (7);

print "ok 5\n";

print $var == 7 ? "" : "not ", "ok 6\n";

$ai->unblock;

