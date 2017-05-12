use warnings;
use strict;
use Test::More tests => 16;
use Test::Exception;

use Crypt::MatrixSSL3 qw( :DEFAULT :Error :Cipher :Bool );

Crypt::MatrixSSL3::Open();

my ($ssl, $keys);

is MATRIXSSL_SUCCESS, Crypt::MatrixSSL3::set_cipher_suite_enabled_status(TLS_RSA_WITH_AES_128_CBC_SHA, PS_FALSE),
    'disable TLS_RSA_WITH_AES_128_CBC_SHA';
is MATRIXSSL_SUCCESS, Crypt::MatrixSSL3::set_cipher_suite_enabled_status(TLS_RSA_WITH_AES_128_CBC_SHA, PS_FALSE),
    'disable TLS_RSA_WITH_AES_128_CBC_SHA again';
is MATRIXSSL_SUCCESS, Crypt::MatrixSSL3::set_cipher_suite_enabled_status(TLS_RSA_WITH_AES_128_CBC_SHA, PS_TRUE),
    'enable TLS_RSA_WITH_AES_128_CBC_SHA';
is MATRIXSSL_SUCCESS, Crypt::MatrixSSL3::set_cipher_suite_enabled_status(TLS_RSA_WITH_AES_128_CBC_SHA, PS_TRUE),
    'enable TLS_RSA_WITH_AES_128_CBC_SHA again';
is PS_FAILURE, Crypt::MatrixSSL3::set_cipher_suite_enabled_status(SSL_RSA_WITH_RC4_128_SHA, PS_FALSE),
    'disable not supported SSL_RSA_WITH_RC4_128_SHA';

lives_ok { $keys = Crypt::MatrixSSL3::Keys->new() }
    'Keys->new';
is PS_SUCCESS, $keys->load_rsa(undef, undef, undef, $Crypt::MatrixSSL3::CA_CERTIFICATES),
    '$keys->load_rsa';

lives_ok { $ssl = Crypt::MatrixSSL3::Server->new($keys, undef) }
    'Server->new';
is MATRIXSSL_SUCCESS, $ssl->set_cipher_suite_enabled_status(TLS_RSA_WITH_AES_128_CBC_SHA, PS_FALSE),
    'server: disable TLS_RSA_WITH_AES_128_CBC_SHA';
is MATRIXSSL_SUCCESS, $ssl->set_cipher_suite_enabled_status(TLS_RSA_WITH_AES_128_CBC_SHA, PS_FALSE),
    'server: disable TLS_RSA_WITH_AES_128_CBC_SHA again';
is MATRIXSSL_SUCCESS, $ssl->set_cipher_suite_enabled_status(TLS_RSA_WITH_AES_128_CBC_SHA, PS_TRUE),
    'server: enable TLS_RSA_WITH_AES_128_CBC_SHA';
is MATRIXSSL_SUCCESS, $ssl->set_cipher_suite_enabled_status(TLS_RSA_WITH_AES_128_CBC_SHA, PS_TRUE),
    'server: enable TLS_RSA_WITH_AES_128_CBC_SHA again';
is PS_FAILURE, $ssl->set_cipher_suite_enabled_status(SSL_RSA_WITH_RC4_128_SHA, PS_FALSE),
    'server: disable not supported SSL_RSA_WITH_RC4_128_SHA';
undef $ssl;

lives_ok { $ssl = Crypt::MatrixSSL3::Client->new($keys, undef, undef, undef, undef, undef, undef) }
    'Client->new';
is PS_UNSUPPORTED_FAIL, $ssl->set_cipher_suite_enabled_status(TLS_RSA_WITH_AES_128_CBC_SHA, PS_FALSE),
    'client: disable TLS_RSA_WITH_AES_128_CBC_SHA';
undef $ssl;

undef $keys;
ok(1, 'matrixSslClose');

Crypt::MatrixSSL3::Close();
