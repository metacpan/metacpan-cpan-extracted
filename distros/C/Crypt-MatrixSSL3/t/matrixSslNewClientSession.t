use warnings;
use strict;
use Test::More tests => 7;
use Test::Exception;

use Crypt::MatrixSSL3 qw( :DEFAULT :Error :Cipher :Bool );

Crypt::MatrixSSL3::Open();

my ($ssl, $keys);

lives_ok { $keys = Crypt::MatrixSSL3::Keys->new() }
    'Keys->new';

is undef, $ssl,
    'ssl not defined';

#throws_ok { $ssl = Crypt::MatrixSSL3::Client->new($keys, undef, undef, undef, undef, undef, undef) }
#    qr/^${\PS_PROTOCOL_FAIL}\b/,
#    'empty keys';

is PS_SUCCESS, $keys->load_rsa(undef, undef, undef, $Crypt::MatrixSSL3::CA_CERTIFICATES),
    '$keys->load_rsa';
is MATRIXSSL_SUCCESS, Crypt::MatrixSSL3::set_cipher_suite_enabled_status(TLS_RSA_WITH_AES_128_CBC_SHA, PS_FALSE),
    'disable TLS_RSA_WITH_AES_128_CBC_SHA';
#throws_ok { $ssl = Crypt::MatrixSSL3::Client->new($keys, undef, [TLS_RSA_WITH_AES_128_CBC_SHA], undef, undef, undef, undef) }
#    qr/^${\PS_UNSUPPORTED_FAIL}\b/,
#    'unsupported cipher';
lives_ok { $ssl = Crypt::MatrixSSL3::Client->new($keys, undef, undef, undef, undef, undef, undef) }
    'Client->new';
ok ref $ssl && $$ssl > 0,
    'ssl is not NULL';
undef $ssl;

undef $keys;
ok(1, 'matrixSslClose');

Crypt::MatrixSSL3::Close();
