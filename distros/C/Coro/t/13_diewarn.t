BEGIN { $| = 1; print "1..7\n"; }

use Coro;
use Coro::State;

print "ok 1\n";

async {
   warn "-";
   cede;
   warn "-";

   local $SIG{__WARN__} = sub { print "ok 7\n" };
   {
      local $SIG{__WARN__} = sub { print "ok 5\n" };
      cede;
      warn "-";
   }
   cede;
   warn "-";
   cede;
};

async {
   $Coro::State::WARNHOOK = sub { print "ok 3\n" };

   local $SIG{__WARN__} = sub { print "ok 6\n" };
   {
      local $SIG{__WARN__} = sub { print "ok 4\n" };
      cede;
      warn "-";
   }
   cede;
   warn "-";
};

$Coro::State::WARNHOOK = sub { print "ok 2\n" };

cede;
cede;
cede;
cede;
