# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Crypt-AON.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
BEGIN { 
	use lib "./";
	use_ok('Crypt::AllOrNothing::Util', ":all") 
};


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(length randomValue(), 16, "Length of new key, no arguments");
is(length randomValue(size=>256, 'return'=>'ascii'), 32, "Length of new key-32 bytes-ascii");
is(length randomValue(size=>512, 'return'=>'ascii'), 64, "Length of new key-64 bytes-ascii");
is(length randomValue(size=>256, 'return'=>'hex'), 64, "Length of new key-32 bytes-hex");
is(length randomValue(size=>512, 'return'=>'hex'), 128, "Length of new key-64 bytes-hex");
is(length randomValue(size=>512, 'return'=>'wrong'), 64, "Length of new key-64 bytes-incorrect return type, should give error and go ascii");
is(length randomValue(size=>128, 'return'=>'base64'), 24, "Length of new key-16 bytes- encoded as base64 length 24");
my @foo = breakString(string=>"abcdefghijklmnopqrstuvwxyz", size=>7);
is_deeply( \@foo, ["abcdefg","hijklmn","opqrstu","vwxyz"], "breaks alphabet correctly");

addLength_andPad(array=>\@foo, size=>7, padding=>"A");
is_deeply( \@foo, ["abcdefg","hijklmn","opqrstu","vwxyzAA","AAA".pack("L",26)], "pads correctly");

remLength_andPad(array=>\@foo);
is_deeply(\@foo, ["abcdefg","hijklmn","opqrstu","vwxyz"], "unpads correctly");
