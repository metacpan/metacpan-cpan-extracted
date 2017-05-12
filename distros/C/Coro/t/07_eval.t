$|=1;
print "1..5\n";

use Coro;

async {
   my $t = eval "2";
   print "ok $t\n";
   cede;

   # a panic: restartop in this test can be caused by perl 5.8.8 not
   # properly handling constant folding (change 29976/28148)
   # (fixed in 5.10, 5.8.9)
   # we don't want to scare users, so disable it.
   delete $SIG{__DIE__} if $] < 5.008009;

   print defined eval "1/0" ? "not ok" : "ok", " 4\n";
};

async {
   my $t = eval "3";
   print "ok $t\n";
   cede;
   print defined eval "die" ? "not ok" : "ok", " 5\n";
};

print "ok 1\n";
cede;
cede;
cede;
cede;

