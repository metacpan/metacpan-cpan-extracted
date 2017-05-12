use strict;
use warnings;

use Test::More;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::RSA;
BEGIN { use_ok('Crypt::Cryptoki::Raw', qw/:all/) };

=pod

  This test first generates a keypair on slot0 of the token. Then the public-key
  is extracted by reading the modulus and the exponent.
  
  Crypt::OpenSSL::RSA is used to encrypt a chunk of data with the public key.
  
  Finally decryption takes place in the token and the result is compared to the
  original chunk.

=cut

my $f = Crypt::Cryptoki::Raw::load('/usr/lib64/softhsm/libsofthsm.so');
ok $f, 'load';

is $f->C_Initialize, CKR_OK, 'C_Initialize';

my $session = -1;
is rv_to_str($f->C_OpenSession(0,CKF_SERIAL_SESSION|CKF_RW_SESSION,$session)), 'CKR_OK', 'C_OpenSession';

is rv_to_str($f->C_Login($session, CKU_USER, '1234')), 'CKR_OK', 'C_Login';

my $public_key_template = [
    [ CKA_CLASS ,          pack('Q',CKO_PUBLIC_KEY) ],
    [ CKA_KEY_TYPE,        pack('Q',CKK_RSA) ],
    [ CKA_TOKEN,           pack('C',TRUE) ],
    [ CKA_ENCRYPT,         pack('C',TRUE) ],
    [ CKA_VERIFY,          pack('C',TRUE) ],
    [ CKA_WRAP,            pack('C',TRUE) ],
    [ CKA_MODULUS_BITS,    pack('Q',4096) ],
    [ CKA_PUBLIC_EXPONENT, pack('C*', 0x01, 0x00, 0x01) ],
    [ CKA_LABEL,    	   'test_pub' ],
	[ CKA_ID, 			   pack('C*', 0x01, 0x02, 0x03) ],
];

my $private_key_template = [
    [ CKA_CLASS,      pack('Q',CKO_PRIVATE_KEY) ],
    [ CKA_KEY_TYPE,   pack('Q',CKK_RSA) ],
    [ CKA_TOKEN,      pack('C',TRUE) ],
    [ CKA_PRIVATE,    pack('C',TRUE) ],
    [ CKA_SENSITIVE,  pack('C',TRUE) ],
    [ CKA_DECRYPT,    pack('C',TRUE) ],
    [ CKA_SIGN,       pack('C',TRUE) ],
    [ CKA_UNWRAP,     pack('C',TRUE) ],
    [ CKA_LABEL,      'test' ],
	[ CKA_ID, 		  pack('C*', 0x04, 0x05, 0x06) ],
];

my $private_key = -1;
my $public_key = -1;

is rv_to_str($f->C_GenerateKeyPair(
	$session, 
	[ CKM_RSA_PKCS_KEY_PAIR_GEN, NULL_PTR, 0 ], 
	$public_key_template,
    $private_key_template,
	$public_key, 
	$private_key
)), 'CKR_OK', 'C_GenerateKeyPair';

my $get_attributes_template = [
    [ CKA_MODULUS, '' ],
    [ CKA_PUBLIC_EXPONENT, '' ],
];

is rv_to_str($f->C_GetAttributeValue(
	$session,
	$public_key,
	$get_attributes_template
)), 'CKR_OK', 'C_GetAttributeValue';
	
diag 'modulus: ', unpack('H*', $get_attributes_template->[0][1]);
diag 'exponent: ', unpack('H*', $get_attributes_template->[1][1]);

my $n = Crypt::OpenSSL::Bignum->new_from_bin($get_attributes_template->[0][1]);
my $e = Crypt::OpenSSL::Bignum->new_from_bin($get_attributes_template->[1][1]);

my $plain_text = <<EOT;
Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit 
EOT

my $rsa_pub = Crypt::OpenSSL::RSA->new_key_from_parameters($n,$e);
$rsa_pub->use_pkcs1_padding;
diag $rsa_pub->get_public_key_string;
my $encrypted_text = $rsa_pub->encrypt($plain_text);
my $encrypted_text_len = length($encrypted_text);

#diag 'enc: ', unpack('H*', $encrypted_text);
#diag 'len: ', $encrypted_text_len;

is rv_to_str($f->C_DecryptInit(
	$session, 
	[ CKM_RSA_PKCS, NULL_PTR, 0 ], 
	$private_key, 
)), 'CKR_OK', 'C_DecryptInit';

my $decrypted_text = '';
my $decrypted_text_len = 0;
is rv_to_str($f->C_Decrypt(
	$session, 
	$encrypted_text,
	$encrypted_text_len,
	$decrypted_text,
	$decrypted_text_len,
)), 'CKR_OK', 'C_Decrypt';

is $decrypted_text, $plain_text, 'decryption OK';

is $f->C_DestroyObject($session, $public_key), CKR_OK, 'destroy public key';
is $f->C_DestroyObject($session, $private_key), CKR_OK, 'destroy private key';

done_testing();













