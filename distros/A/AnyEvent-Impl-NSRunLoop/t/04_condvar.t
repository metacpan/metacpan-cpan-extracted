use AnyEvent;
use AnyEvent::Impl::NSRunLoop;

$| = 1; print "1..21\n";

print "ok 1\n";

{
   my $cv = AnyEvent->condvar;

   $cv->cb (sub {
      print $_[0]->ready ? "" : "not ", "ok 4\n";

      my $x = $_[0]->recv;
      print $x == 7 ? "" : "not ", "ok 5 # $x == 7\n";

      my @x = $_[0]->recv;
      print $x[1] == 5 ? "" : "not ", "ok 6 # $x[1] == 5\n";

      my $y = $cv->recv;
      print $y == 7 ? "" : "not ", "ok 7 # $x == 7\n";
   });

   my $t = AnyEvent->timer (after => 0, cb => sub {
      print "ok 3\n";
      $cv->send (7, 5);
   });

   print "ok 2\n";
   $cv->wait;
   print "ok 8\n";

   my @x = $cv->recv;
   print $x[1] == 5 ? "" : "not ", "ok 9 # $x[1] == 5\n";
}

{
   my $cv = AnyEvent->condvar;

   $cv->cb (sub {
      print $_[0]->ready ? "" : "not ", "ok 12\n";

      my $x = eval { $_[0]->recv };
      print !defined $x ? "" : "not ", "ok 13\n";
      print $@ =~ /^kill/ ? "" : "not ", "ok 14 # $@\n";
   });

   my $t = AnyEvent->timer (after => 0, cb => sub {
      print "ok 11\n";
      $cv->croak ("kill");
      print "ok 15\n";
      $cv->send (8, 6, 4);
      print "ok 16\n";
   });

   print "ok 10\n";
   my @x = eval { $cv->recv };
   print !@x ? "" : "not ", "ok 17 # @x\n";
   print $@ =~ /^kill / ? "" : "not ", "ok 18 # $@\n";
}

{
   my $cv = AnyEvent->condvar;

   print "ok 19\n";
   my $t = AnyEvent->timer (after => 0, cb => $cv);

   print "ok 20\n";
   $cv->recv;
   print "ok 21\n";
}

