# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 38;
BEGIN { 
	use_ok('Config::Frontend');
	use_ok('Config::Backend::File');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

### Regular tests

my $string="%test=HI=Yes\n%test1=NO!\n%test2=%joep%\n%test3=ok\n%%Hello";
open my $out,">conf.t.move.cfg";
print $out $string;
close $out;
my $conf=new Config::Frontend(new Config::Backend::File("conf.t.move.cfg"));

ok($conf->get("test") eq "HI=Yes", "initial conf in \$string -> test=HI=Yes");
ok($conf->get("test1") eq "NO!", "initial conf in \$string -> test1=NO!");
ok($conf->get("test2") eq "%joep%", "initial conf in \$string -> test2=%joep%");
ok($conf->get("test3") eq "ok\n%Hello", "initial conf in \$string -> test3=ok");

$conf->set("oesterhol","account");
ok($conf->get("oesterhol") eq "account","initial conf in \$string -> oesterhol=account");

my @a=sort $conf->variables();
my $w;
for my $ww (@a) { $w.=$ww; }
ok($w eq "oesterholtesttest1test2test3","props");

$conf->set_prop("oesterhol","ishuman","no");
ok($conf->get_prop("oesterhol","ishuman","") eq "no","properties");

$conf->set_prop("nonexist","prop1",1);
ok($conf->get_prop("nonexist","prop1") eq 1,"properties");
ok($conf->get("nonexist","empty") eq "empty","properties");

$conf->set_prop("oesterhol","animal","dog");
$conf->del_prop("oesterhol","ishuman");
ok($conf->get_prop("oesterhol","ishuman","empty") eq "empty","properties");
ok($conf->get_prop("oesterhol","animal","") eq "dog","properties");

$conf->set_prop("oesterhol","human","woman");

my @aa=sort $conf->properties("oesterhol");
my $y;
for my $yy (@aa) { $y.=$yy; }
ok($y eq "animalhuman","properties");

$conf->move_prop("oesterhol","animal","amigo");
ok($conf->get_prop("oesterhol","animal","empty") eq "empty","move_prop");
ok($conf->get_prop("oesterhol","amigo","empty") eq "dog","move_prop");

$conf->move("oesterhol","joesterhol");
ok($conf->get("oesterhol","empty") eq "empty","move");
ok($conf->get_prop("oesterhol","amigo","empty") eq "empty","move");
ok($conf->get_prop("oesterhol","human","empty") eq "empty","move");
ok($conf->get("joesterhol") eq "account","move");
ok($conf->get_prop("joesterhol","amigo","empty") eq "dog","move");
ok($conf->get_prop("joesterhol","human","empty") eq "woman","move");

$conf->move("joesterhol","oesterhol");
$conf->del("oesterhol");
ok($conf->get_prop("oesterhol","human","empty") eq "empty","properties");
ok($conf->get_prop("oesterhol","amigo","empty") eq "empty","properties");
ok($conf->get("oesterhol","empty") eq "empty","properties");

$conf->del("nonexist");
ok($conf->get("nonexist","empty") eq "empty","properties");
ok($conf->get_prop("nonexist","prop1","empty") eq "empty","properties");

$conf->set("oesterhol","account");
$conf->set_prop("oesterhol","animal","dog");
$conf->del_prop("oesterhol","ishuman");
ok($conf->get_prop("oesterhol","ishuman","empty") eq "empty","properties");
ok($conf->get_prop("oesterhol","animal","") eq "dog","properties");

$conf->set_prop("oesterhol","human","woman");

{
  my @aa=sort $conf->properties("oesterhol");
  my $y;
  for my $yy (@aa) {
    $y.=$yy;
  }
  ok($y eq "animalhuman","properties");
}

$conf->move_prop("oesterhol","animal","amigo");
ok($conf->get_prop("oesterhol","animal","empty") eq "empty","move_prop");
ok($conf->get_prop("oesterhol","amigo","empty") eq "dog","move_prop");

$conf->move("oesterhol","joesterhol");
ok($conf->get("oesterhol","empty") eq "empty","move");
ok($conf->get_prop("oesterhol","amigo","empty") eq "empty","move");
ok($conf->get_prop("oesterhol","human","empty") eq "empty","move");
ok($conf->get("joesterhol") eq "account","move");
ok($conf->get_prop("joesterhol","amigo","empty") eq "dog","move");
ok($conf->get_prop("joesterhol","human","empty") eq "woman","move");

END { 
	unlink("conf.t.move.cfg");
}
