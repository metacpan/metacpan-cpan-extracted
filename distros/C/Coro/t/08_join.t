$|=1;
print "1..10\n";

use Coro;

print "ok 1\n";

$p1 = async {
   print "ok 3\n";
   terminate 5;
};

$p2 = async {
   print "ok 4\n";
   ()
};

$p3 = async {
   print "ok 5\n";
   (0,1,2)
};

print "ok 2\n";
print 0 == @{[$p2->join]} ? "ok " : "not ok ", "6\n";
print 0 == ($p3->join)[0] ? "ok " : "not ok ", "7\n";
print 1 == ($p3->join)[1] ? "ok " : "not ok ", "8\n";
print 2 == ($p3->join)[2] ? "ok " : "not ok ", "9\n";
print 5 == $p1->join      ? "ok " : "not ok ", "10\n";

