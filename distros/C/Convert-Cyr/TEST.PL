# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use Convert::Cyr qw(chcp);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$test="Text from DOS866 to WIN1251: �������������������������������";
	print chcp($test, length($test),'A', 'W')."\n";
ok(2);                                                 
$test="transliteration: ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	print chcp($test, length($test),'Z', 'W')."\n";
ok(3);
	print $test."\n";
ok(4);
	print "If you see converted text, then all tests are passed\n";

# I don't know how to make tests appear standard way :(
