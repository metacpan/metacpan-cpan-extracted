# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 1;
use App::Locker;

$SIG{ALRM}=sub{
  exit;
};
alarm(3);

my $locker=App::Locker->create;

my $pid=fork();

if (!$pid){
  # child
  sleep(1);
  my $p='test';
  $locker->unlock(\$p);
  sleep(1);
} else {
  # parent
  
  print "LOCK\n";
  my $p=$locker->lock();
  print ${$p};
  print "UNLOCK\n";
  
  ok(1, "fork_test");
}