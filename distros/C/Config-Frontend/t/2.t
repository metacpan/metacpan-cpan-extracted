# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { 
	use_ok('Config::Backend::String');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

### Regular tests

my $conf_str="HII!";
$conf_str=eval "use Config::Backend::String;my \$string=\"test=HI=Yes%test1=NO!%test2=%%joep%%%test3=ok\";return ref(new Config::Backend::String(\$string))";
ok($conf_str eq "","Died as expected");

