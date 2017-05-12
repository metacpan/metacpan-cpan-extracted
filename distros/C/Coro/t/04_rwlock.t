$|=1;
print "1..15\n";

use Coro;
use Coro::RWLock;

my $l = new Coro::RWLock;

print "ok 1\n";
$l->rdlock;
print (($l->tryrdlock ? "" : "not "), "ok 2\n");
print (($l->trywrlock ? "not " : ""), "ok 3\n");
$l->unlock;
$l->unlock;
print (($l->trywrlock ? "" : "not "), "ok 4\n");
print (($l->trywrlock ? "not " : ""), "ok 5\n");
print (($l->tryrdlock ? "not " : ""), "ok 6\n");

async {
   print "ok 8\n";
   $l->wrlock;
   print "ok 10\n";
   $l->unlock;
   $l->rdlock;
   print "ok 11\n";
   cede;
   print "ok 14\n";
};

print "ok 7\n";
cede;
cede;
cede;
cede;
print "ok 9\n";
$l->unlock;
cede;

print "ok 12\n";
$l->rdlock;
print "ok 13\n";
cede;
cede;
print "ok 15\n";






