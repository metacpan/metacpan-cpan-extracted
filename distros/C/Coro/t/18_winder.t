$|=1;
print "1..17\n";

no warnings;
use Coro;

my @enter = (3, 8, 12, -1);
my @leave = (6, 10, 14, -1);

async {
   print "ok 2\n";
   {
      Coro::on_enter {
         print "ok ", shift @enter, "\n";
      };
      print "ok 4\n";
      Coro::on_leave {
         print "ok ", shift @leave, "\n";
      };
      print "ok 5\n";
      cede;
      print "ok 9\n";
      cede;
      print "ok 13\n";
   }
   print "ok 15\n";
   $cb = Coro::rouse_cb;
   print "ok 16\n";
};

print "ok 1\n";
cede;
print "ok 7\n";
cede;
print "ok 11\n";
cede;
print "ok 17\n";

