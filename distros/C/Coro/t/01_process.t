$|=1;
print "1..13\n";

use Coro;

async {
   print "ok 2\n";
};

print "ok 1\n";
cede;
print "ok 3\n";

my $c1 = async {
   print "ok 5\n";
   cede;
   print "not ok 8\n";#d#
};

print $c1->ready ? "not " : "", "ok 4\n";

cede;

print "ok 6\n";

$c1->on_destroy (sub {
   print "ok 7\n";
});

$c1->cancel;

print "ok 8\n";

cede; cede;

print "ok 9\n";

{
   my $as1 = async {
      print "not ok 10\n";
   };

   my $as2 = async {
      print "ok 10\n";
      $as1->cancel;
   };

   $as2->cede_to;
}

{
   my $as1 = async {
      print "not ok 11\n";
   };

   my $as2 = async {
      print "ok 11\n";
      $as1->cancel;
      cede;
      print "ok 12\n";
      $Coro::main->ready;
      $Coro::main->throw ("exit");
   };

   local $SIG{__DIE__} = sub {
      print "ok 13\n";
      exit if $@ eq "exit";
   };

   $as2->schedule_to;
}

print "not ok 12\n";

