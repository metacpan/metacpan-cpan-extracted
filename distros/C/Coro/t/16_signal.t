$|=1;
print "1..18\n";

no warnings;
use Coro;
use Coro::Signal;

{
   my $sig = new Coro::Signal;

   $as1 = async {
      my $g = $sig->wait;
      print "ok 3\n";
   };    

   $as2 = async {
      my $g = $sig->wait;
      print "ok 4\n";
   };    

   cede; # put 1, 2 in wait q

   $as3 = async {
      my $g = $sig->wait;
      print "ok 2\n";
   };    

   $as4 = async {
      my $g = $sig->wait;
      print "ok 6\n";
   };    

   $as5 = async {
      my $g = $sig->wait;
      print "ok 9\n";
   };    

   $sig->send; # ready 1
   $sig->send; # ready 2
   $sig->send; # remember

   print +(Coro::Semaphore::count $sig) == 1 ? "" : "not ", "ok 1\n";

   cede; # execute 3 (already ready, no contention), 1, 2

   print +(Coro::Semaphore::count $sig) == 0 ? "" : "not ", "ok 5\n";

   $sig->send;
   cede;

   print +(Coro::Semaphore::count $sig) == 0 ? "" : "not ", "ok 7\n";

   $sig->broadcast;
   print +(Coro::Semaphore::count $sig) == 0 ? "" : "not ", "ok 8\n";
   cede;

   $sig->wait (sub { print "ok 12\n" });
   print "ok 10\n";

   print "ok 11\n";

   $sig->send;
   print "ok 13\n";
   cede;

   print "ok 14\n";
   $sig->send;
   print "ok 15\n";

   $sig->wait (sub { print "ok 16\n" });
   print "ok 17\n";

   print +(Coro::Semaphore::count $sig) == 0 ? "" : "not ", "ok 18\n";
}

