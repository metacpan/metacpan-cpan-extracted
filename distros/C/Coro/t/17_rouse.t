$|=1;
print "1..5\n";

no warnings;
use Coro;

my $cb;

async {
   $cb = Coro::rouse_cb;
   print "ok 2\n";
   print Coro::rouse_wait == 77 ? "" : "not", "ok 4\n";
};

print "ok 1\n";
cede;
print "ok 3\n";
$cb->(13, 77);
cede;
print "ok 5\n";

