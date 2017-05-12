# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Crypt-OpenBSD-Blowfish.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Crypt::OpenBSD::Blowfish') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $iterate_expected = '8562ba180a45dad2';
my $enc_expected = 'eed0b8126a95281e';
my $encrypted = 'c057d5555914011fc4ca351e004330ea';

my $bf = Crypt::OpenBSD::Blowfish->new();
$bf->expandstate('abc123','thisisatest');
my $enc = $bf->encrypt_iterate('bytetest',16);
ok(unpack('H*',$enc) eq $iterate_expected, 'encrypt_iterate');

$bf = Crypt::OpenBSD::Blowfish->new('blahblahblah');
$enc = $bf->encrypt('bytetest');
ok(unpack('H*',$enc) eq $enc_expected, 'encrypt_iterate');

$bf = Crypt::OpenBSD::Blowfish->new('yetanothertest');
my $data = pack('H*',$encrypted);
ok($bf->decrypt($data) eq '*This is a test*','decrypt');
