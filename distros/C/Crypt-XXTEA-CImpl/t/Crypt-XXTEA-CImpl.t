# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Crypt-XXTEA-CImpl.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Crypt::XXTEA::CImpl') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $str =  "abcdfghijklmn";
my $pass = "1234";
my $cro =   "\x{64}\x{1f}\x{80}\x{36}\x{81}\x{fe}\x{55}\x{7a}\x{84}\x{05}\x{84}\x{0f}\x{94}\x{ad}\x{97}\x{cd}\x{92}\x{8e}\x{ae}\x{78}";

my $cr = Crypt::XXTEA::CImpl::xxtea_encrypt($str,$pass);
is($cro,$cr);
my $ec = Crypt::XXTEA::CImpl::xxtea_decrypt($cr,$pass);
is($str,$ec);

