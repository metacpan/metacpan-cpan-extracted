use warnings;
use strict;
use Test::More;

use Crypt::MatrixSSL;

my @exports
    = qw(
        matrixSslOpen
        matrixSslClose
        matrixSslReadKeys
        matrixSslReadKeysMem
        matrixSslFreeKeys
        matrixSslNewSession
        matrixSslDeleteSession
        matrixSslDecode
        matrixSslEncode
        matrixSslEncodeClosureAlert
        matrixSslEncodeClientHello
        matrixSslEncodeHelloRequest
        matrixSslSetSessionOption
        matrixSslHandshakeIsComplete
        matrixSslGetSessionId
        matrixSslFreeSessionId
        matrixSslSetCertValidator
        matrixSslGetAnonStatus
        matrixSslAssignNewKeys
        matrixSslSetResumptionFlag
        matrixSslGetResumptionFlag
    )
    ;
my @not_exports
    = qw( )
    ;
my @exports_scalar
    = qw(
        SSL_ALLOW_ANON_CONNECTION
        SSL_MAX_PLAINTEXT_LEN
        SSL_FLAGS_SERVER
        SSL_FLAGS_CLIENT_AUTH
        SSL_OPTION_DELETE_SESSION
        SSL_SUCCESS
        SSL_ERROR
        SSL_FULL
        SSL_PARTIAL
        SSL_SEND_RESPONSE
        SSL_PROCESS_DATA
        SSL_ALERT
        SSL_FILE_NOT_FOUND
        SSL_MEM_ERROR
        SSL_ALERT_LEVEL_WARNING
        SSL_ALERT_LEVEL_FATAL
        SSL_ALERT_CLOSE_NOTIFY
        SSL_ALERT_UNEXPECTED_MESSAGE
        SSL_ALERT_BAD_RECORD_MAC
        SSL_ALERT_DECOMPRESSION_FAILURE
        SSL_ALERT_HANDSHAKE_FAILURE
        SSL_ALERT_NO_CERTIFICATE
        SSL_ALERT_BAD_CERTIFICATE
        SSL_ALERT_UNSUPPORTED_CERTIFICATE
        SSL_ALERT_CERTIFICATE_REVOKED
        SSL_ALERT_CERTIFICATE_EXPIRED
        SSL_ALERT_CERTIFICATE_UNKNOWN
        SSL_ALERT_ILLEGAL_PARAMETER 
    )
    ;

my @exports_hash
    = qw(
        SSL_alertLevel
        SSL_alertDescription
    )
    ;

plan +(@exports + @not_exports + @exports_scalar + @exports_hash)
    ? ( tests       => @exports + @not_exports + @exports_scalar + @exports_hash )
    : ( skip_all    => q{This module doesn't export anything}       )
    ;

for my $export (@exports) {
    can_ok( __PACKAGE__, $export );
}

for my $not_export (@not_exports) {
    ok( ! __PACKAGE__->can($not_export) );
}

no strict 'refs';
for my $export (@exports_scalar) {
    ok( defined(${$export}), "\$$export" );
}

for my $export (@exports_hash) {
    ok( scalar(keys %{$export}), "\%$export" );
}

