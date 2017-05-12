# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Crypt-OpenSSH-ChachaPoly.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Crypt::OpenSSH::ChachaPoly') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $key = 'abcdef0123456789abcdef0123456789';
my @plain = ( 'this is a test 123 test test test', 
              'yet another bunch of text to test' );
my @enc = ( '0798d93ac9fab398125f83319f3db0d3632e7c8bf07735e2e432c5e9215875a5b3',
            '00fbbc8cac15473c35ea6e10a60a6a163acb3a0830b993e2621a90914e77b8504e' );
my $one = chr(1) . "\0" x 7;

my $c = Crypt::OpenSSH::ChachaPoly->new($key);
$c->ivsetup($one,$one);

for (my $i=0; $i<=$#plain; $i++) {
	my $encrypted = unpack('H*',$c->encrypt($plain[$i]));
	ok($encrypted eq $enc[$i], "Encrypt $i");
}

$c->ivsetup($one,$one);

for (my $i=0; $i<=$#plain; $i++) {
	my $decrypted = $c->decrypt(pack('H*',$enc[$i]));
	ok($decrypted eq $plain[$i], "Decrypt $i");
}
