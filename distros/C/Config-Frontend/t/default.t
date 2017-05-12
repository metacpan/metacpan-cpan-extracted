# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
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

ok($conf->get("UNKNOWN","DEFAULT") eq "DEFAULT", "default value for non existing var");


END { 
	unlink("conf.t.3.cfg");
}

