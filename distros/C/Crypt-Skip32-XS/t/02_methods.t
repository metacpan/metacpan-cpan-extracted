use strict;
use warnings;
use Test::More tests => 46;
use Crypt::Skip32::XS;

# Most of this is copied from Crypt::Skip32

# Create cipher
my $cipher1 = new Crypt::Skip32::XS pack("H20", "DE2624BD4FFC4BF09DAB");
isa_ok($cipher1, 'Crypt::Skip32::XS', 'new cipher1');

# Standard size methods
is(Crypt::Skip32::XS->blocksize, 4, 'blocksize is 4 - class method');
is(Crypt::Skip32::XS->keysize, 10, 'keysize is 10 - class method)');
is($cipher1->blocksize, 4, 'blocksize is 4 - object method');
is($cipher1->keysize, 10, 'keysize is 10 - object method)');

# Try out a few encrypt/decrypt
test($cipher1,          0,   78612854);
test($cipher1,          3, 3719912389);
test($cipher1,         21, 1463300585);
test($cipher1,        147, 1277082297);
test($cipher1,       1029, 2878029910);
test($cipher1,       7203, 4086218104);
test($cipher1,      50421, 2588160464);
test($cipher1,     352947, 2703568194);
test($cipher1,    2470629, 2600508864);
test($cipher1,   17294403, 4119915301);
test($cipher1,  121060821, 4266122367);
test($cipher1,  847425747, 2671425558);
test($cipher1, 4294967295,  949651845);

# Different cipher keys
my $cipher_text_1 = test($cipher1, 123456789, 2982653749);

my $cipher2 = new Crypt::Skip32::XS pack("H20", "EC1D4396C19C0E0A1CC8");
isa_ok($cipher2, 'Crypt::Skip32::XS', 'new cipher2');

my $cipher_text_2 = test($cipher2, 123456789, 2798020216);

isnt($cipher_text_1, $cipher_text_2,
    'different keys produce different encrypted text'
);

# Error conditions
eval { my $cipher3 = new Crypt::Skip32::XS 'shortkey'; };
ok($@, 'new() dies correctly on short key');

eval { my $cipher4 = new Crypt::Skip32::XS 'keythatistoolong'; };
ok($@, 'new() dies correctly on long key');

eval { $cipher1->encrypt('abc'); };
ok($@, 'encrypt() dies correctly on short plaintext');

eval { $cipher1->encrypt('abcde'); };
ok($@, 'encrypt() dies correctly on long plaintext');

eval { $cipher1->decrypt('abc'); };
ok($@, 'decrypt() dies correctly on short ciphertext');

eval { $cipher1->decrypt('abcde'); };
ok($@, 'decrypt() dies correctly on long ciphertext');

# Test based on the tests in the original C source.
my $cipher5 = new Crypt::Skip32::XS pack("H20", "00998877665544332211");
isa_ok($cipher5, 'Crypt::Skip32::XS', 'new cipher5');

test($cipher5, 0x33221100, 0x819D5F1F);

exit 0;


sub test {
    my ($cipher, $plain_number, $correct_cipher_number) = @_;

    my $plain_text_1  = pack('N', $plain_number);
    my $cipher_text   = $cipher->encrypt($plain_text_1);
    my $plain_text_2  = $cipher->decrypt($cipher_text);
    my $cipher_number = unpack('N', $cipher_text);

    is($cipher_number, $correct_cipher_number,
        "Skip32 encrypt $plain_number -> $cipher_number");

    is($plain_text_1, $plain_text_2,
        "Skip32 decrypt $cipher_number -> $plain_number");

    return $cipher_text;
}
