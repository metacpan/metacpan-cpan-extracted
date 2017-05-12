# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 14;
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

# Turn on caching.

$conf->cache(1);

# Get some values

ok($conf->get("test") eq "HI=Yes", "initial conf in \$string -> test=HI=Yes");
ok($conf->get("test1") eq "NO!", "initial conf in \$string -> test1=NO!");
ok($conf->get("test2") eq "%joep%", "initial conf in \$string -> test2=%joep%");
ok($conf->get("test3") eq "ok\n%Hello", "initial conf in \$string -> test3=ok");

$conf->set("oesterhol","account");
ok($conf->get("oesterhol") eq "account","initial conf in \$string -> oesterhol=account");


ok($conf->cached()==5,"cached items should be 5");

$conf->set("oesterhol","NOtcached");
ok($conf->cached()==4,"cached items should now be 4");

$conf->del("test1");
ok($conf->cached()==3,"cached items should now be 3");

$conf->get("oesterhol");
ok($conf->cached()==4,"cached items should now be 4");

ok((not defined $conf->get("unkown")),"unknown should be undef");
ok($conf->cached()==5,"cached items should now be 5");
ok((not defined $conf->get("unkown")),"unknown should be undef");

END { 
	unlink("conf.t.3.cfg");
}

