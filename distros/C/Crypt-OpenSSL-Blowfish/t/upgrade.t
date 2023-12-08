use strict;
use warnings;
use Test2::V0;
use Crypt::OpenSSL::Blowfish;

my $key = pack("C*", 0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33);
my $plaintext = pack("C*",0x41,0x42,0x43,0x44,0x41,0x42,0x43,0x44);
my $expected_enc = pack("C*", 0x87, 0x9b, 0x38, 0x92, 0x5e, 0x82, 0x19, 0x0b);
my $openssl_enc = pack("C*", 0x95, 0xd4, 0x6b, 0x2f, 0x14, 0xe6, 0xe1, 0x6f);

#echo -n "ABCDABCD"| openssl enc -nopad -e -bf-ecb -K '30313233303132333031323330313233' -provider legacy -provider default | xxd -i
# 0x95, 0xd4, 0x6b, 0x2f, 0x14, 0xe6, 0xe1, 0x6f

#==================================
# Upgrade the old encryption
# Using old method then new method
#==================================
my $cipher = Crypt::OpenSSL::Blowfish->new($key);
isa_ok($cipher, 'Crypt::OpenSSL::Blowfish');

ok($cipher->get_big_endian('ABCDABCD') eq 'DCBADCBA', "Successful big endian conversion",
    $cipher->get_big_endian('ABCDABCD'));
ok($cipher->get_little_endian('DCBADCBA') eq 'ABCDABCD', "Successful little endian conversion",
    $cipher->get_little_endian('DCBADCBA'));

# Just simple encryption test
my $encrypted = $cipher->encrypt($plaintext);
ok($encrypted eq $expected_enc, "Successfully encrypted plain text with old method",
    uc(unpack("H16", $encrypted)));

# Decrypt with the old method
my $decrypted = $cipher->decrypt($expected_enc);
ok($decrypted eq $plaintext, "Successfully decrypted data encrypted with old method",
    uc(unpack("H16", $decrypted)));

# Encrypt with the new method
$cipher = Crypt::OpenSSL::Blowfish->new($key, {});
isa_ok($cipher, 'Crypt::OpenSSL::Blowfish');

# Ensure that the encrypted value is compatible with openssl
$encrypted = $cipher->encrypt($plaintext);
ok($encrypted eq $openssl_enc, "Successfully encrypted plain text compatible with openssl using new method",
    uc(unpack("H16", $encrypted)));

#=============================================
# Upgrade the old encryption using old nethod
# Handle the endian conversion manually
#=============================================
$cipher = Crypt::OpenSSL::Blowfish->new($key);

# Convert the plaintext to big_endian
my $be = $cipher->get_big_endian($plaintext);

# Encrypt old method (only key was passed to new)
$encrypted = $cipher->encrypt($be);

# Convert the encrypted value to little_endian
my $le = $cipher->get_little_endian($encrypted);

# Ensure that the encrypted value is compatible with openssl
ok($le eq $openssl_enc, "Successfully encrypted plain text compatible with openssl - manual endian handling", uc(unpack("H16", $le)));

#=============================================
# Decrypt the old encryption using new nethod
# Handle the endian conversion manually
#=============================================
$cipher = Crypt::OpenSSL::Blowfish->new($key, {});

# Convert the encrypted value to big_endian
$be = $cipher->get_big_endian($expected_enc);

# Decrypt using the new method (two values passed to new)
my $new_data = $cipher->decrypt($be);

# Convert the decrypted value to little_endian
$le = $cipher->get_little_endian($new_data);

# Ensure that the decrypted value is the original plain text
ok($le eq $plaintext, "Successfully decrypted old encryption with new method - manual endian handling",
    uc(unpack("H16", $encrypted)));
done_testing;

