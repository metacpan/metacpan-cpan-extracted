use strict;
use warnings;
use Test2::V0;
use MIME::Base64 qw/encode_base64/;
use Crypt::OpenSSL::Blowfish;

my $key = pack("C*", 0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33);
my $plaintext = pack("C*",0x41,0x42,0x43,0x44,0x41,0x42,0x43,0x44);
my $expected_enc = pack("C*", 0x95, 0xd4, 0x6b, 0x2f, 0x14, 0xe6, 0xe1, 0x6f);

#echo -n "ABCDABCD"| openssl enc -nopad -e -bf-ecb -K '30313233303132333031323330313233' -provider legacy -provider default | xxd -i
#  0x95, 0xd4, 0x6b, 0x2f, 0x14, 0xe6, 0xe1, 0x6f

my $cipher = Crypt::OpenSSL::Blowfish->new($key, {});
isa_ok($cipher, 'Crypt::OpenSSL::Blowfish');

my $encrypted = $cipher->encrypt($plaintext);
ok($encrypted eq $expected_enc, "encrypt with key length 32 (AES-128-ECB)");

ok($cipher->decrypt($expected_enc) eq $plaintext, "decrypt with key length 32 (AES-128-ECB)");

ok($cipher->decrypt($cipher->encrypt("Hello!!!")) eq "Hello!!!", "Simple String Encrypted/Decrypted Successfully with key length 32 AES-128-ECB");

$encrypted = $cipher->encrypt("Hello!!!");
#FIXME my $decrypted_openssl = `echo -n $encrypted | openssl enc -nopad -d -bf-ecb -K '30313233303132333031323330313233' -provider legacy -provider default`;
#FIXME ok ($decrypted_openssl eq "Hello!!!", "properly decrypted with openssl");

#use Crypt::Digest::SHA512_256 qw/sha512_256_hex/;
#print '$key = pack("H*", "', substr(sha512_256_hex(rand(1000)), 0, (128/4)), "\");\n";
$key = pack("H*", "3f6f39c26f148ba136e11f3fc00ae75f");

$plaintext = pack("C*",0x41,0x42,0x43,0x44,0x41,0x42,0x43,0x44);

#echo -n "ABCDABCD"| openssl enc -nopad -e -bf-ecb -K '3f6f39c26f148ba136e11f3fc00ae75f' -provider legacy -provider default | xxd -i
#  0xc3, 0x8a, 0x99, 0x56, 0x4a, 0xed, 0x8a, 0x84
$expected_enc = pack("C*", 0xc3, 0x8a, 0x99, 0x56, 0x4a, 0xed, 0x8a, 0x84);

$cipher = Crypt::OpenSSL::Blowfish->new($key, {});
isa_ok($cipher, 'Crypt::OpenSSL::Blowfish');

$encrypted = $cipher->encrypt($plaintext);
ok($encrypted eq $expected_enc, "encrypt with key length 24 (AES-128-ECB)");
ok($plaintext eq $cipher->decrypt($expected_enc), "decrypt with key length 24 (AES-128-ECB)");
done_testing;
