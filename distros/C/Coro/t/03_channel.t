$|=1;
print "1..10\n";

# adapted testcase by Richard Hundt

use strict;

use Coro;
use Coro::Channel;

my $c1 = new Coro::Channel 1;
my $c2 = new Coro::Channel 1;

async {
   print "ok 2\n";
   print $c1->get eq "sig 1" ? "" : "not ", "ok 4\n";
   $c2->put ('OK 1');
   print "ok 7\n";
   $c1->put ('last');
};

async {
   print "ok 3\n";
   $c1->put('sig 1');
   print "ok 5\n";
   print $c2->get eq "OK 1" ? "" : "not ", "ok 6\n";
   $Coro::main->ready;
};

print "ok 1\n";
schedule;
print "ok 8\n";
print $c1->get eq "last" ? "" : "not ", "ok 9\n";
print "ok 10\n";

