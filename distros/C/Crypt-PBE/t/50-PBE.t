#!perl

use strict;
use warnings;
use Test::More;

use MIME::Base64;

use_ok('Crypt::PBE');

my $md5_and_des     = Crypt::PBE::PBEWithMD5AndDES('mypassword');
my $sha1_aes_128    = Crypt::PBE::PBEWithHmacSHA1AndAES_128('mypassword');
my $sha1_aes_192    = Crypt::PBE::PBEWithHmacSHA1AndAES_192('mypassword');
my $sha1_aes_256    = Crypt::PBE::PBEWithHmacSHA1AndAES_256('mypassword');
my $sha224_aes_128  = Crypt::PBE::PBEWithHmacSHA224AndAES_128('mypassword');
my $sha224_aes_192  = Crypt::PBE::PBEWithHmacSHA224AndAES_192('mypassword');
my $sha224_aes_256  = Crypt::PBE::PBEWithHmacSHA224AndAES_256('mypassword');
my $sha256_aes_128  = Crypt::PBE::PBEWithHmacSHA256AndAES_128('mypassword');
my $sha256_aes_192  = Crypt::PBE::PBEWithHmacSHA256AndAES_192('mypassword');
my $sha256_aes_256  = Crypt::PBE::PBEWithHmacSHA256AndAES_256('mypassword');
my $sha_384_aes_128 = Crypt::PBE::PBEWithHmacSHA384AndAES_128('mypassword');
my $sha_384_aes_192 = Crypt::PBE::PBEWithHmacSHA384AndAES_192('mypassword');
my $sha_384_aes_256 = Crypt::PBE::PBEWithHmacSHA384AndAES_256('mypassword');
my $sha_512_aes_128 = Crypt::PBE::PBEWithHmacSHA512AndAES_128('mypassword');
my $sha_512_aes_192 = Crypt::PBE::PBEWithHmacSHA512AndAES_192('mypassword');
my $sha_512_aes_256 = Crypt::PBE::PBEWithHmacSHA512AndAES_256('mypassword');

cmp_ok( $md5_and_des->decrypt( $md5_and_des->encrypt('secret') ),         'eq', 'secret', 'MD5 And DES' );
cmp_ok( $sha1_aes_128->decrypt( $sha1_aes_128->encrypt('secret') ),       'eq', 'secret', 'HMAC-SHA1 AND AES 128' );
cmp_ok( $sha1_aes_192->decrypt( $sha1_aes_192->encrypt('secret') ),       'eq', 'secret', 'HMAC-SHA1 AND AES 192' );
cmp_ok( $sha1_aes_256->decrypt( $sha1_aes_256->encrypt('secret') ),       'eq', 'secret', 'HMAC-SHA1 AND AES 256' );
cmp_ok( $sha224_aes_128->decrypt( $sha224_aes_128->encrypt('secret') ),   'eq', 'secret', 'HMAC-SHA224 AND AES 128' );
cmp_ok( $sha224_aes_192->decrypt( $sha224_aes_192->encrypt('secret') ),   'eq', 'secret', 'HMAC-SHA224 AND AES 192' );
cmp_ok( $sha224_aes_256->decrypt( $sha224_aes_256->encrypt('secret') ),   'eq', 'secret', 'HMAC-SHA224 AND AES 256' );
cmp_ok( $sha256_aes_128->decrypt( $sha256_aes_128->encrypt('secret') ),   'eq', 'secret', 'HMAC-SHA256 AND AES 128' );
cmp_ok( $sha256_aes_192->decrypt( $sha256_aes_192->encrypt('secret') ),   'eq', 'secret', 'HMAC-SHA256 AND AES 192' );
cmp_ok( $sha256_aes_256->decrypt( $sha256_aes_256->encrypt('secret') ),   'eq', 'secret', 'HMAC-SHA256 AND AES 256' );
cmp_ok( $sha_384_aes_128->decrypt( $sha_384_aes_128->encrypt('secret') ), 'eq', 'secret', 'HMAC-SHA384 AND AES 128' );
cmp_ok( $sha_384_aes_192->decrypt( $sha_384_aes_192->encrypt('secret') ), 'eq', 'secret', 'HMAC-SHA384 AND AES 192' );
cmp_ok( $sha_384_aes_256->decrypt( $sha_384_aes_256->encrypt('secret') ), 'eq', 'secret', 'HMAC-SHA384 AND AES 256' );
cmp_ok( $sha_512_aes_128->decrypt( $sha_512_aes_128->encrypt('secret') ), 'eq', 'secret', 'HMAC-SHA512 AND AES 128' );
cmp_ok( $sha_512_aes_192->decrypt( $sha_512_aes_192->encrypt('secret') ), 'eq', 'secret', 'HMAC-SHA512 AND AES 192' );
cmp_ok( $sha_512_aes_256->decrypt( $sha_512_aes_256->encrypt('secret') ), 'eq', 'secret', 'HMAC-SHA512 AND AES 256' );

done_testing();
