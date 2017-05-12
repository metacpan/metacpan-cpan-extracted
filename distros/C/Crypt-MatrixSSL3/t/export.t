use warnings;
use strict;
use Test::More;

use Crypt::MatrixSSL3;

my @exports
    = qw(
        SSL_MAX_PLAINTEXT_LEN

        PS_SUCCESS
        MATRIXSSL_SUCCESS
        MATRIXSSL_REQUEST_SEND
        MATRIXSSL_REQUEST_RECV
        MATRIXSSL_REQUEST_CLOSE
        MATRIXSSL_APP_DATA
        MATRIXSSL_HANDSHAKE_COMPLETE
        MATRIXSSL_RECEIVED_ALERT
    )
    ;
my @not_exports
    = qw(
        SSL_MAX_DISABLED_CIPHERS

        SSL_ALERT_LEVEL_WARNING
        SSL_ALERT_LEVEL_FATAL
        SSL_ALERT_CLOSE_NOTIFY
        SSL_ALERT_UNEXPECTED_MESSAGE
        SSL_ALERT_BAD_RECORD_MAC
        SSL_ALERT_DECRYPTION_FAILED
        SSL_ALERT_RECORD_OVERFLOW
        SSL_ALERT_DECOMPRESSION_FAILURE
        SSL_ALERT_HANDSHAKE_FAILURE
        SSL_ALERT_NO_CERTIFICATE
        SSL_ALERT_BAD_CERTIFICATE
        SSL_ALERT_UNSUPPORTED_CERTIFICATE
        SSL_ALERT_CERTIFICATE_REVOKED
        SSL_ALERT_CERTIFICATE_EXPIRED
        SSL_ALERT_CERTIFICATE_UNKNOWN
        SSL_ALERT_ILLEGAL_PARAMETER
        SSL_ALERT_UNKNOWN_CA
        SSL_ALERT_ACCESS_DENIED
        SSL_ALERT_DECODE_ERROR
        SSL_ALERT_DECRYPT_ERROR
        SSL_ALERT_PROTOCOL_VERSION
        SSL_ALERT_INTERNAL_ERROR
        SSL_ALERT_NO_RENEGOTIATION
        SSL_ALERT_UNSUPPORTED_EXTENSION
        SSL_ALERT_NONE

        SSL_ALLOW_ANON_CONNECTION

        SSL_NULL_WITH_NULL_NULL
        SSL_RSA_WITH_NULL_MD5
        SSL_RSA_WITH_NULL_SHA
        SSL_RSA_WITH_RC4_128_MD5
        SSL_RSA_WITH_RC4_128_SHA
        SSL_RSA_WITH_3DES_EDE_CBC_SHA
        TLS_RSA_WITH_AES_128_CBC_SHA
        TLS_RSA_WITH_AES_256_CBC_SHA
        SSL_OPTION_FULL_HANDSHAKE

        PS_FAILURE
        MATRIXSSL_ERROR
        PS_ARG_FAIL
        PS_PLATFORM_FAIL
        PS_MEM_FAIL
        PS_LIMIT_FAIL
        PS_UNSUPPORTED_FAIL
        PS_PROTOCOL_FAIL
        PS_TRUE
        PS_FALSE

        SSL2_MAJ_VER
        SSL3_MAJ_VER
        SSL3_MIN_VER
        TLS_MIN_VER
        TLS_1_1_MIN_VER
        TLS_1_2_MIN_VER
        TLS_MAJ_VER
        MATRIXSSL_VERSION
        MATRIXSSL_VERSION_MAJOR
        MATRIXSSL_VERSION_MINOR
        MATRIXSSL_VERSION_PATCH
        MATRIXSSL_VERSION_CODE

        set_cipher_suite_enabled_status
        get_ssl_alert
        get_ssl_error
    )
    ;
my @exports_scalar
    = qw(
    )
    ;

my @exports_hash
    = qw(
    )
    ;

plan +(@exports + @not_exports + @exports_scalar + @exports_hash)
    ? ( tests       => @exports + 2*@not_exports + @exports_scalar + @exports_hash )
    : ( skip_all    => q{This module doesn't export anything}       )
    ;

for my $export (@exports) {
    can_ok( __PACKAGE__, $export );
}

for my $not_export (@not_exports) {
    ok( Crypt::MatrixSSL3->can($not_export) );
    ok( ! __PACKAGE__->can($not_export) );
}

no strict 'refs';
for my $export (@exports_scalar) {
    ok( defined(${$export}), "\$$export" );
}

for my $export (@exports_hash) {
    ok( scalar(keys %{$export}), "\%$export" );
}

