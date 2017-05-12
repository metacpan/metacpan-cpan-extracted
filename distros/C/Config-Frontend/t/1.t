# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 19;
BEGIN { 
	use_ok('Config::Frontend');
	use_ok('Config::Backend::String');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

### Regular tests

my $string="test=HI=Yes\n%test1=NO!\n%test2=%joep%\n%test3=ok\n%%Hello";
my $conf=new Config::Frontend(new Config::Backend::String(\$string));

ok($conf->get("test") eq "HI=Yes", "initial conf in \$string -> test=HI=Yes");
ok($conf->get("test1") eq "NO!", "initial conf in \$string -> test1=NO!");
ok($conf->get("test2") eq "%joep%", "initial conf in \$string -> test2=%joep%");
ok($conf->get("test3") eq "ok\n%Hello", "initial conf in \$string -> test3=ok");

$conf->set("oesterhol","account");
ok($conf->get("oesterhol") eq "account","initial conf in \$string -> oesterhol=account");

### reuse

my $nstring=$string;
my $nconf=new Config::Frontend(new Config::Backend::String(\$nstring));

ok($conf->get("test") eq "HI=Yes", "reuse commited Config::Backend::String from \$string -> test=HI=Yes");
ok($conf->get("test1") eq "NO!", "reuse commited Config::Backend::String from \$string -> test1=NO!");
ok($conf->get("test2") eq "%joep%", "reuse commited Config::Backend::String from \$string -> test2=%joep%");
ok($conf->get("test3") eq "ok\n%Hello", "reuse commited Config::Backend::String from \$string -> test3=ok");
ok($conf->get("oesterhol") eq "account","reuse commited Config::Backend::String from \$string -> oesterhol=account");

### Test empty conf

my $estring="";
my $econf=new Config::Frontend(new Config::Backend::String(\$estring));
$econf->set("oesterhol","%HI!\n%hallo%%hi%");

ok($estring eq "oesterhol=%HI!\n%%hallo%%hi%","setting value in empty config -> \$estring eq \"%HI!\n%%hallo%%hi%\"");
ok($econf->get("oesterhol","%hallo%%hi%"),"setting value in empty config -> oesterhol=%HI!\n%hallo%%hi%");

### Test one item conf

my $ostring=$estring;
my $oconf=new Config::Frontend(new Config::Backend::String(\$ostring));
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

### Delete 2 variables

$conf->del("test1");
$conf->del("oesterhol");

### Look up all variables

undef %e;
my %e;
$e{"test"}=0;
$e{"test2"}=0;
$e{"test3"}=0;

undef @vars;
my @vars=$conf->variables();
for my $var (@vars) {
	$e{$var}+=1;
}

undef $all;
my $all=1;
for my $k (keys %e) {
	if ($e{$k}==0) { $all=0; }
}

ok($all==1,"variables: --> all variables are there");
ok((not defined $conf->get("test1")),"deleted var not there");
ok((not defined $conf->get("oesterhol")),"deleted var not there");




