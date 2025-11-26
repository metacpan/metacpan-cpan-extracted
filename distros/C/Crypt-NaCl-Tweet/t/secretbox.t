use strict;
use warnings;
use Test::More;
use Crypt::NaCl::Tweet ':secretbox';

# randomly generated. DO NOT USE
# for bad_* first or last nybble changed to 0
my $key = pack('H*', '590036d036f832397d9cd54b309bd24be449c2b3c54c9c08cb8b9e66305f4024');
my $bad_key = pack('H*', '090036d036f832397d9cd54b309bd24be449c2b3c54c9c08cb8b9e66305f4024');
my $nonce = pack('H*', '505008edf6eda898b7ad99935176cd004f3aa2eaf26ef5c2');
my $bad_nonce = pack('H*', '505008edf6eda898b7ad99935176cd004f3aa2eaf26ef5c0');

my $str = 'hey. yo. hullo.';

my $ct = secretbox($str, $nonce, $key);
ok($ct, "secretbox generated ciphertext");
is(length($ct), length($str) + secretbox_ZEROBYTES, "secretbox ciphertext correct length");

my $pt = secretbox_open($ct, $nonce, $key);
is($pt, $str, "secretbox_open decrypted correctly");
my $bad_pt = secretbox_open($ct, $nonce, $bad_key);
ok(!defined($bad_pt), "secretbox_open decrypt fail with bad key");
$bad_pt = secretbox_open($ct, $bad_nonce, $key);
ok(!defined($bad_pt), "secretbox_open decrypt fail with bad nonce");

my $bad_ct = secretbox($str, $nonce, $bad_key);
$bad_pt = secretbox_open($bad_ct, $nonce, $key);
ok(!defined($bad_pt), "secretbox_open decrypt fail with bad encryption key");
$bad_ct = secretbox($str, $bad_nonce, $key);
ok(!defined($bad_pt), "secretbox_open decrypt fail with bad encryption nonce");

done_testing();
