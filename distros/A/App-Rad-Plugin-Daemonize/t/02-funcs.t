use Test::More tests => 12;
use File::Temp qw/:POSIX/;

use App::Rad qw/Daemonize/;
use App::Rad::Tester;

my $c = get_controller;

ok($c->write_pidfile);
ok($c->get_pidfile_name);
open my $FILE, "<", $c->get_pidfile_name
   || die "couldn't open file \"" . $c->get_pidfile_name . "\"";
my $pid_on_file = <$FILE>;
close $FILE;
if($pid_on_file =~ /^(\d+)$/) {
   is($1, $$);
}
chomp(my $ret = $c->read_pidfile);
is($c->read_pidfile, $$);

ok($c->write_pidfile(my $filename = tmpnam));
open $FILE, "<", $filename || die "couldn't open file $filename";
$pid_on_file = <$FILE>;
close $FILE;
if($pid_on_file =~ /^(\d+)$/){
   is($1, $$);
}
is($c->read_pidfile($filename), $$);

ok($c->is_running);

SKIP: {
   skip "Windows does no implement kill()", 1 if $^O eq "MSWin32";
   $SIG{ALRM} = sub{ok(1)};
   
   #$c->kill(10);
   alarm 1;
   sleep 2;
}

ok($< xor $c->check_root);

TODO: {
   local $TODO = "Make a better way to test change_user()";
   #skip "You are not root", 2 unless $c->check_root;
   my $file = tmpnam;
   my ($user, $new_uid);
   for my $uid(1 ... 9999){
      $user = getpwuid($uid);
      $new_uid = $uid;
      last if $user;
   }
   #skip "No user to test", 2 unless $user;
   my $pid = fork();
   if(not $pid){
      $c->change_user($user);
      open $TMP, "<", $file || die "Can't create \"$file\"";
      close $TMP;
      exit
   }
   sleep 3;
   ok(-f $file, "File \"$file\" wasn't created");
   is((stat $file)[4], $new_uid);
   unlink $file;
}
