# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 41;
BEGIN { 
	use_ok('Config::Frontend');
	use_ok('Config::Backend::File');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

### Regular tests

my $string="%test=HI=Yes\n%test1=NO!\n%test2=%joep%\n%test3=ok\n%%Hello";
open my $out,">conf.t.3.cfg";
print $out $string;
close $out;
my $conf=new Config::Frontend(new Config::Backend::File("conf.t.3.cfg"));

ok($conf->get("test") eq "HI=Yes", "initial conf in \$string -> test=HI=Yes");
ok($conf->get("test1") eq "NO!", "initial conf in \$string -> test1=NO!");
ok($conf->get("test2") eq "%joep%", "initial conf in \$string -> test2=%joep%");
ok($conf->get("test3") eq "ok\n%Hello", "initial conf in \$string -> test3=ok");

$conf->set("oesterhol","account");
ok($conf->get("oesterhol") eq "account","initial conf in \$string -> oesterhol=account");

### Empty configuration

my $econf=new Config::Frontend(new Config::Backend::File("conf.t.3a.cfg"));
$econf->set("oesterhol","%HI!\n%hallo%%hi%");

ok($econf->get("oesterhol","%hallo%%hi%"),"setting value in empty config -> oesterhol=%HI!\n%hallo%%hi%");

### Test reread conf

my $nconf=new Config::Frontend(new Config::Backend::File("conf.t.3.cfg"));

ok($nconf->get("test") eq "HI=Yes", "reread conf in \$string -> test=HI=Yes");
ok($nconf->get("test1") eq "NO!", "reread conf in \$string -> test1=NO!");
ok($nconf->get("test2") eq "%joep%", "reread conf in \$string -> test2=%joep%");
ok($nconf->get("test3") eq "ok\n%Hello", "reread conf in \$string -> test3=ok");
ok($nconf->get("oesterhol") eq "account","reread conf in \$string -> oesterhol=account");

### Test one item conf

my $oconf=new Config::Frontend(new Config::Backend::File("conf.t.3a.cfg"));
ok($oconf->get("oesterhol") eq "%HI!\n%hallo%%hi%","one item configuration -> oesterhol=%HI!\n%hallo%%hi%");

### Look up all variables

my %e;
$e{"test"}=0;
$e{"test1"}=0;
$e{"test2"}=0;
$e{"test3"}=0;
$e{"oesterhol"}=0;

my @vars=$conf->variables();
for my $var (@vars) {
	$e{$var}+=1;
}

my $all=1;
for my $k (keys %e) {
	if ($e{$k}==0) { $all=0; }
}

ok($all==1,"variables: --> all variables are there");

# With comments!

my $string="%# Comment 1 this is\n%test=HI=Yes\n%#OK, an other comment here!\n%test1=NO!\n%test2=%joep%\n%test3=ok\n%%Hello\n%# YES! Last comment!\n";
open my $out,">conf.t.3b.cfg";
print $out $string;
close $out;

undef $conf;
my $conf=new Config::Frontend(new Config::Backend::File("conf.t.3b.cfg"));

ok($conf->get("test") eq "HI=Yes", "initial comments conf in \$string -> test=HI=Yes");
ok($conf->get("test1") eq "NO!", "initial comments conf in \$string -> test1=NO!");
ok($conf->get("test2") eq "%joep%", "initial comments conf in \$string -> test2=%joep%");
ok($conf->get("test3") eq "ok\n%Hello", "initial comments conf in \$string -> test3=ok\n%Hello");

$conf->set("oesterhol","account");

ok($conf->get("oesterhol") eq "account", "initial comments conf in \$string -> account");

undef $conf;
# With comments reread

my $nconf=new Config::Frontend(new Config::Backend::File("conf.t.3b.cfg"));

ok($nconf->get("test") eq "HI=Yes", "reread comments conf in \$string -> test=HI=Yes");
ok($nconf->get("test1") eq "NO!", "reread comments conf in \$string -> test1=NO!");
ok($nconf->get("test2") eq "%joep%", "reread comments conf in \$string -> test2=%joep%");
ok($nconf->get("test3") eq "ok\n%Hello", "reread comments conf in \$string -> test3=ok");
ok($nconf->get("oesterhol") eq "account","reread comments conf in \$string -> oesterhol=account");

$nconf->set("oesterhol","nil");

# Reread again now

undef $nconf;
my $nconf=new Config::Frontend(new Config::Backend::File("conf.t.3b.cfg"));

ok($nconf->get("test") eq "HI=Yes", "reread comments conf in \$string -> test=HI=Yes");
ok($nconf->get("test1") eq "NO!", "reread comments conf in \$string -> test1=NO!");
ok($nconf->get("test2") eq "%joep%", "reread comments conf in \$string -> test2=%joep%");
ok($nconf->get("test3") eq "ok\n%Hello", "reread comments conf in \$string -> test3=ok");
ok($nconf->get("oesterhol") eq "nil","reread comments conf in \$string -> oesterhol=nil");

### Delete 2 variables

$nconf->del("test1");
$nconf->del("oesterhol");

### Look up all variables

undef %e;
my %e;
$e{"test"}=0;
$e{"test2"}=0;
$e{"test3"}=0;

undef @vars;
my @vars=$nconf->variables();
for my $var (@vars) {
	$e{$var}+=1;
}

undef $all;
my $all=1;
for my $k (keys %e) {
	if ($e{$k}==0) { $all=0; }
}

ok($all==1,"variables: --> all variables are there");
ok((not defined $nconf->get("test1")),"variables -> deleted not there");
ok((not defined $nconf->get("oesterhol")),"variables -> deleted not there");

# Reread again now

undef $nconf;
$nconf=new Config::Frontend(new Config::Backend::File("conf.t.3b.cfg"));

undef %e;
my %e;
$e{"test"}=0;
$e{"test2"}=0;
$e{"test3"}=0;

undef @vars;
my @vars=$nconf->variables();
for my $var (@vars) {
	$e{$var}+=1;
}

undef $all;
my $all=1;
for my $k (keys %e) {
	if ($e{$k}==0) { $all=0; }
}

ok($all==1,"variables: --> all variables are there");
ok((not defined $nconf->get("test1")),"variables -> deleted not there");
ok((not defined $nconf->get("oesterhol")),"variables -> deleted not there");

ok($nconf->get("test") eq "HI=Yes", "reread comments conf in \$string -> test=HI=Yes");
ok((not defined $nconf->get("test1")), "reread comments conf in \$string -> test1 deleted!");
ok($nconf->get("test2") eq "%joep%", "reread comments conf in \$string -> test2=%joep%");
ok($nconf->get("test3") eq "ok\n%Hello", "reread comments conf in \$string -> test3=ok");
ok((not defined $nconf->get("oesterhol")),"reread comments conf in \$string -> oesterhol deleted");

# Unlink conf files

END { 
	unlink("conf.t.3.cfg");
	unlink("conf.t.3a.cfg");
	unlink("conf.t.3b.cfg");
}

