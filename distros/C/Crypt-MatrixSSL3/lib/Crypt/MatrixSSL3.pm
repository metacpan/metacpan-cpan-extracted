package Crypt::MatrixSSL3;
use 5.006;
use strict;
use warnings;
use Carp;

use Scalar::Util qw( dualvar );
use XSLoader;

BEGIN {
    use version 0.77 (); our $VERSION = 'v3.9.0';
    XSLoader::load(__PACKAGE__,$VERSION);
}

use File::ShareDir;
our $CA_CERTIFICATES = File::ShareDir::dist_file('Crypt-MatrixSSL3', 'ca-certificates.crt');

# WARNING The CONST_* constants automatically parsed from this file by
# Makefile.PL to generate const-*.inc, so if these constants will be
# reformatted there may be needs in updating regexp in Makefile.PL.
use constant CONST_VERSION_INT => qw(
    SSL2_MAJ_VER
    SSL3_MAJ_VER
    SSL3_MIN_VER
    TLS_1_1_MIN_VER
    TLS_1_2_MIN_VER
    TLS_MAJ_VER
    TLS_MIN_VER
    TLS_HIGHEST_MINOR
    MATRIXSSL_VERSION_MAJOR
    MATRIXSSL_VERSION_MINOR
    MATRIXSSL_VERSION_PATCH
);
use constant CONST_VERSION => (
    CONST_VERSION_INT,
    'MATRIXSSL_VERSION_CODE',
    'MATRIXSSL_VERSION',
);
use constant CONST_CIPHER => qw(
    SSL_NULL_WITH_NULL_NULL
    SSL_RSA_WITH_NULL_MD5
    SSL_RSA_WITH_NULL_SHA
    SSL_RSA_WITH_RC4_128_MD5
    SSL_RSA_WITH_RC4_128_SHA
    TLS_RSA_WITH_IDEA_CBC_SHA
    SSL_RSA_WITH_3DES_EDE_CBC_SHA
    SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA
    SSL_DH_anon_WITH_RC4_128_MD5
    SSL_DH_anon_WITH_3DES_EDE_CBC_SHA
    TLS_RSA_WITH_AES_128_CBC_SHA
    TLS_DHE_RSA_WITH_AES_128_CBC_SHA
    TLS_DH_anon_WITH_AES_128_CBC_SHA
    TLS_RSA_WITH_AES_256_CBC_SHA
    TLS_DHE_RSA_WITH_AES_256_CBC_SHA
    TLS_DH_anon_WITH_AES_256_CBC_SHA
    TLS_RSA_WITH_AES_128_CBC_SHA256
    TLS_RSA_WITH_AES_256_CBC_SHA256
    TLS_DHE_RSA_WITH_AES_128_CBC_SHA256
    TLS_DHE_RSA_WITH_AES_256_CBC_SHA256
    TLS_RSA_WITH_SEED_CBC_SHA
    TLS_PSK_WITH_AES_128_CBC_SHA
    TLS_PSK_WITH_AES_128_CBC_SHA256
    TLS_PSK_WITH_AES_256_CBC_SHA384
    TLS_PSK_WITH_AES_256_CBC_SHA
    TLS_DHE_PSK_WITH_AES_128_CBC_SHA
    TLS_DHE_PSK_WITH_AES_256_CBC_SHA
    TLS_RSA_WITH_AES_128_GCM_SHA256
    TLS_RSA_WITH_AES_256_GCM_SHA384
    TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA
    TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA
    TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA
    TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA
    TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
    TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
    TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
    TLS_ECDH_RSA_WITH_AES_128_CBC_SHA
    TLS_ECDH_RSA_WITH_AES_256_CBC_SHA
    TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256
    TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384
    TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256
    TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384
    TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256
    TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384
    TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256
    TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384
    TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
    TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
    TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256
    TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384
    TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
    TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
    TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256
    TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384
    TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
    TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
);

use constant CONST_SESSION_OPTION => qw(
    SSL_OPTION_FULL_HANDSHAKE
);

use constant CONST_ALERT_LEVEL => qw(
    SSL_ALERT_LEVEL_WARNING
    SSL_ALERT_LEVEL_FATAL
);

use constant CONST_ALERT_DESCR => qw(
    SSL_ALERT_NONE
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
    SSL_ALERT_INSUFFICIENT_SECURITY
    SSL_ALERT_INTERNAL_ERROR
    SSL_ALERT_INAPPROPRIATE_FALLBACK
    SSL_ALERT_NO_RENEGOTIATION
    SSL_ALERT_UNSUPPORTED_EXTENSION
    SSL_ALERT_UNRECOGNIZED_NAME
    SSL_ALERT_BAD_CERTIFICATE_STATUS_RESPONSE
    SSL_ALERT_UNKNOWN_PSK_IDENTITY
    SSL_ALERT_NO_APP_PROTOCOL
);

# Order is important in CONST_ERROR and CONST_RC! Some constants have same
# value, but their names ordered to get better output in %RETURN_CODE.
use constant CONST_ERROR => qw(
    PS_FAILURE
    MATRIXSSL_ERROR
    PS_ARG_FAIL
    PS_PLATFORM_FAIL
    PS_MEM_FAIL
    PS_LIMIT_FAIL
    PS_UNSUPPORTED_FAIL
    PS_DISABLED_FEATURE_FAIL
    PS_PROTOCOL_FAIL
    PS_TIMEOUT_FAIL
    PS_INTERRUPT_FAIL
    PS_PENDING
    PS_EAGAIN
    PS_PARSE_FAIL
    PS_CERT_AUTH_FAIL_BC
    PS_CERT_AUTH_FAIL_DN
    PS_CERT_AUTH_FAIL_SIG
    PS_CERT_AUTH_FAIL_REVOKED
    PS_CERT_AUTH_FAIL
    PS_CERT_AUTH_FAIL_EXTENSION
    PS_CERT_AUTH_FAIL_PATH_LEN
    PS_CERT_AUTH_FAIL_AUTHKEY
    PS_SIGNATURE_MISMATCH
    PS_AUTH_FAIL
);

use constant CONST_RC => qw(
    PS_SUCCESS
    MATRIXSSL_SUCCESS
    MATRIXSSL_REQUEST_SEND
    MATRIXSSL_REQUEST_RECV
    MATRIXSSL_REQUEST_CLOSE
    MATRIXSSL_APP_DATA
    MATRIXSSL_HANDSHAKE_COMPLETE
    MATRIXSSL_RECEIVED_ALERT
    MATRIXSSL_APP_DATA_COMPRESSED
);

use constant CONST_LIMIT => qw(
    SSL_MAX_DISABLED_CIPHERS
    SSL_MAX_PLAINTEXT_LEN
    SSL_MAX_RECORD_LEN
    SSL_MAX_BUF_SIZE
);

use constant CONST_VALIDATE => qw(
    SSL_ALLOW_ANON_CONNECTION
);

use constant CONST_BOOL => qw(
    PS_TRUE
    PS_FALSE
);

use constant CONST_CAPABILITIES => qw(
    SHARED_SESSION_CACHE_ENABLED
    STATELESS_TICKETS_ENABLED
    DH_PARAMS_ENABLED
    ALPN_ENABLED
    SNI_ENABLED
    OCSP_STAPLES_ENABLED
    CERTIFICATE_TRANSPARENCY_ENABLED
);

BEGIN {
    for (
        CONST_VERSION_INT,
        CONST_CIPHER,
        CONST_SESSION_OPTION,
        CONST_ALERT_LEVEL,
        CONST_ALERT_DESCR,
        CONST_ERROR,
        CONST_RC,
        CONST_LIMIT,
        CONST_VALIDATE,
        CONST_BOOL,
        CONST_CAPABILITIES,
        ) {
        ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
        eval 'use constant '.$_.' => '.(0+constant($_)).'; 1' or croak $@;
    }
}
# TODO  ExtUtils::Constant fail to generate correct const-*.inc when both
#       string and integer constants used. So, hardcode these constants
#       here until this issue will be fixed.
use constant MATRIXSSL_VERSION_CODE => 'OPEN';
use constant MATRIXSSL_VERSION      => sprintf '%d.%d.%d-%s',
    MATRIXSSL_VERSION_MAJOR,
    MATRIXSSL_VERSION_MINOR,
    MATRIXSSL_VERSION_PATCH,
    MATRIXSSL_VERSION_CODE;

my %ALERT_LEVEL = map { 0+constant($_) => $_ } CONST_ALERT_LEVEL;
my %ALERT_DESCR = map { 0+constant($_) => $_ } CONST_ALERT_DESCR;
my %RETURN_CODE = map { 0+constant($_) => $_ } CONST_ERROR, CONST_RC;


#
# Usage: use Crypt::MatrixSSL3 qw( :all :DEFAULT :RC :Cipher SSL_MAX_PLAINTEXT_LEN ... )
#
my %TAGS = (
    Version      => [ CONST_VERSION  ],
    Cipher       => [ CONST_CIPHER   ],
    SessOpts     => [ CONST_SESSION_OPTION ],
    Alert        => [ CONST_ALERT_LEVEL, CONST_ALERT_DESCR ],
    Error        => [ CONST_ERROR    ],
    RC           => [ CONST_RC       ],
    Limit        => [ CONST_LIMIT    ],
    Validate     => [ CONST_VALIDATE ],
    Bool         => [ CONST_BOOL     ],
    Capabilities => [ CONST_CAPABILITIES ],
    Func         => [qw(
        set_cipher_suite_enabled_status
        get_ssl_alert
        get_ssl_error
    )],
);
$TAGS{all}      = [ map { @{$_} } values %TAGS ];
$TAGS{DEFAULT}  = [ 'SSL_MAX_PLAINTEXT_LEN', @{$TAGS{RC}} ];
my %KNOWN = map { $_ => 1 } @{ $TAGS{all} };

sub import {
    my (undef, @p) = @_;
    if (!@p) {
        @p = (':DEFAULT');
    }
    @p = map { /\A:(\w+)\z/xms ? @{ $TAGS{$1} || [] } : $_ } @p;

    my $pkg = caller;
    no strict 'refs';

    for my $func (@p) {
        next if !$KNOWN{$func};
        *{"${pkg}::$func"} = \&{$func};
    }

    return;
}


sub get_ssl_alert {
    my ($pt_buf) = @_;
    my ($level_code, $descr_code) = map {ord} split //ms, $pt_buf;
    my $level = dualvar $level_code, $ALERT_LEVEL{$level_code};
    my $descr = dualvar $descr_code, $ALERT_DESCR{$descr_code};
    return wantarray ? ($level, $descr) : $descr;
}

sub get_ssl_error {
    my ($rc) = @_;
    my $error = dualvar $rc, $RETURN_CODE{$rc};
    return $error;
}


## no critic (ProhibitMultiplePackages)

# shift/goto trick used to force correct source line in XS's croak()
package Crypt::MatrixSSL3::Keys;
sub new { shift; goto &Crypt::MatrixSSL3::KeysPtr::new }

package Crypt::MatrixSSL3::SessID;
sub new { shift; goto &Crypt::MatrixSSL3::SessIDPtr::new }

package Crypt::MatrixSSL3::Client;
sub new { shift; goto &Crypt::MatrixSSL3::SessPtr::new_client }

package Crypt::MatrixSSL3::Server;
sub new { shift; goto &Crypt::MatrixSSL3::SessPtr::new_server }

package Crypt::MatrixSSL3::HelloExt;
sub new { shift; goto &Crypt::MatrixSSL3::HelloExtPtr::new }


1;
__END__

=encoding utf8

=for stopwords authStatus SessID HelloExt dualvar SCT ALPN SCTs certValidator extensionCback ALPNcb VHIndexCallback ALPNCallback

=head1 NAME

Crypt::MatrixSSL3 - Perl extension for SSL and TLS using MatrixSSL.org v3.7.2b


=head1 VERSION

This document describes Crypt::MatrixSSL3 version v3.9.0


=head1 SYNOPSIS

    use Crypt::MatrixSSL3;

    # 1. See the MatrixSSL documentation.
    # 2. See example scripts included in this package:
    #       ssl_client.pl
    #       ssl_server.pl
    #       functions.pl


=head1 DESCRIPTION

Crypt::MatrixSSL3 lets you use the MatrixSSL crypto library (see
http://matrixssl.org/) from Perl. With this module, you will be
able to easily write SSL and TLS client and server programs.

MatrixSSL includes everything you need, all in under 50KB.

You will need a "C" compiler to build this, unless you're getting
the ".ppm" prebuilt Win32 version. Crypt::MatrixSSL3 builds cleanly
on (at least) Windows, Linux, and Macintosh machines.

MatrixSSL is an Open Source (GNU General Public License) product, and is
also available commercially if you need freedom from GNU rules.

Everything you need is included here, but check the MatrixSSL.org
web site to make sure you've got the latest version of the
MatrixSSL "C" code if you like (it's in the directory "./inc"
of this package if you want to replace the included version from
the MatrixSSL.org download site).


=head1 API BACKWARD COMPATIBILITY AND STATUS

MatrixSSL tends to make incompatible API changes in minor releases, so
B<every next version of Crypt::MatrixSSL3 may have incompatible API changes>!

This version adds several new features which isn't well-tested yet and
thus considered unstable:

=over

=item Support for shared session cache using shared memory

=item Stateless ticket session resuming support

=item Loading the DH param for DH cipher suites

=item Application Layer Protocol Negotiation callback support

=item SNI (virtual hosts)

=item OCSP staple

=item Certificate Transparency

=item Support for TLS_FALLBACK_SCSV

=item Partial support for "status_request" TLS extension

=item Browser preferred ciphers

Selecting our strongest ciphers from the client supported list.

=back


=head1 TERMINOLOGY

When a client establishes an SSL connection without sending a SNI
extension in its CLIENT_HELLO message we say that the client connects to
the B<default server>.

If a SNI extension is present then the client connects to a B<virtual host>.


=head1 EXPORTS

Constants and functions can be exported using different tags.
Use tag ':all' to export everything.

By default (tag ':DEFAULT') only SSL_MAX_PLAINTEXT_LEN and return code
constants (tag ':RC') will be exported.

=over

=item :Version

    SSL2_MAJ_VER
    SSL3_MAJ_VER
    SSL3_MIN_VER
    TLS_1_1_MIN_VER
    TLS_1_2_MIN_VER
    TLS_MAJ_VER
    TLS_MIN_VER
    MATRIXSSL_VERSION
    MATRIXSSL_VERSION_MAJOR
    MATRIXSSL_VERSION_MINOR
    MATRIXSSL_VERSION_PATCH
    MATRIXSSL_VERSION_CODE

=item :Cipher

Used in matrixSslSetCipherSuiteEnabledStatus().

    #******************************************************************************
    #
    #   Recommended cipher suites:
    #
    #   Define the following to enable various cipher suites
    #   At least one of these must be defined.  If multiple are defined,
    #   the handshake will determine which is best for the connection.
    #

    TLS_RSA_WITH_AES_128_CBC_SHA
    TLS_RSA_WITH_AES_256_CBC_SHA
    TLS_RSA_WITH_AES_128_CBC_SHA256
    TLS_RSA_WITH_AES_256_CBC_SHA256
    TLS_RSA_WITH_AES_128_GCM_SHA256

    # Pre-Shared Key Ciphers
    TLS_RSA_WITH_AES_256_GCM_SHA384
    TLS_PSK_WITH_AES_256_CBC_SHA
    TLS_PSK_WITH_AES_128_CBC_SHA
    TLS_PSK_WITH_AES_256_CBC_SHA384
    TLS_PSK_WITH_AES_128_CBC_SHA256

    # Ephemeral ECC DH keys, ECC DSA certificates
    TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA
    TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA
    TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256
    TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384
    TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
    TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384

    # Ephemeral ECC DH keys, RSA certificates
    TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
    TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
    TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384
    TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256
    TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
    TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256

    # Non-Ephemeral ECC DH keys, ECC DSA certificates
    TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA
    TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA
    TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256
    TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384
    TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256
    TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384

    # Non-Ephemeral ECC DH keys, RSA certificates
    TLS_ECDH_RSA_WITH_AES_256_CBC_SHA
    TLS_ECDH_RSA_WITH_AES_128_CBC_SHA
    TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384
    TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256
    TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384
    TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256


    #******************************************************************************
    #
    #   These cipher suites are secure, but not in general use. Enable only if
    #   specifically required by application.
    #
    TLS_DHE_PSK_WITH_AES_256_CBC_SHA
    TLS_DHE_PSK_WITH_AES_128_CBC_SHA
    TLS_DHE_RSA_WITH_AES_256_CBC_SHA
    TLS_DHE_RSA_WITH_AES_128_CBC_SHA
    TLS_DHE_RSA_WITH_AES_128_CBC_SHA256
    TLS_DHE_RSA_WITH_AES_256_CBC_SHA256


    #******************************************************************************
    #
    #   These cipher suites are generally considered weak, not recommended for use.
    #
    TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
    SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA
    SSL_RSA_WITH_3DES_EDE_CBC_SHA
    TLS_RSA_WITH_SEED_CBC_SHA
    SSL_RSA_WITH_RC4_128_SHA
    SSL_RSA_WITH_RC4_128_MD5


    #******************************************************************************
    #
    #   These cipher suites do not combine authentication and encryption and
    #   are not recommended for use-cases that require strong security or
    #   Man-in-the-Middle protection.
    #
    TLS_DH_anon_WITH_AES_256_CBC_SHA
    TLS_DH_anon_WITH_AES_128_CBC_SHA
    SSL_DH_anon_WITH_3DES_EDE_CBC_SHA
    SSL_DH_anon_WITH_RC4_128_MD5
    SSL_RSA_WITH_NULL_SHA
    SSL_RSA_WITH_NULL_MD5


    # Other
    SSL_NULL_WITH_NULL_NULL
    TLS_RSA_WITH_IDEA_CBC_SHA

Flag for matrixSslEncodeRehandshake():

    SSL_OPTION_FULL_HANDSHAKE

=item :Alert

Alert level codes:

    SSL_ALERT_LEVEL_FATAL
    SSL_ALERT_LEVEL_WARNING

Alert description codes:

    SSL_ALERT_ACCESS_DENIED
    SSL_ALERT_BAD_CERTIFICATE
    SSL_ALERT_BAD_RECORD_MAC
    SSL_ALERT_CERTIFICATE_EXPIRED
    SSL_ALERT_CERTIFICATE_REVOKED
    SSL_ALERT_CERTIFICATE_UNKNOWN
    SSL_ALERT_CLOSE_NOTIFY
    SSL_ALERT_DECODE_ERROR
    SSL_ALERT_DECOMPRESSION_FAILURE
    SSL_ALERT_DECRYPTION_FAILED
    SSL_ALERT_DECRYPT_ERROR
    SSL_ALERT_HANDSHAKE_FAILURE
    SSL_ALERT_ILLEGAL_PARAMETER
    SSL_ALERT_INAPPROPRIATE_FALLBACK
    SSL_ALERT_INSUFFICIENT_SECURITY
    SSL_ALERT_INTERNAL_ERROR
    SSL_ALERT_NONE
    SSL_ALERT_NO_APP_PROTOCOL
    SSL_ALERT_NO_CERTIFICATE
    SSL_ALERT_NO_RENEGOTIATION
    SSL_ALERT_PROTOCOL_VERSION
    SSL_ALERT_RECORD_OVERFLOW
    SSL_ALERT_UNEXPECTED_MESSAGE
    SSL_ALERT_UNKNOWN_CA
    SSL_ALERT_UNRECOGNIZED_NAME
    SSL_ALERT_UNSUPPORTED_CERTIFICATE
    SSL_ALERT_UNSUPPORTED_EXTENSION

=item :Error

Error codes from different functions:

    PS_FAILURE
    MATRIXSSL_ERROR
    PS_ARG_FAIL
    PS_CERT_AUTH_FAIL
    PS_CERT_AUTH_FAIL_AUTHKEY
    PS_CERT_AUTH_FAIL_BC
    PS_CERT_AUTH_FAIL_DN
    PS_CERT_AUTH_FAIL_EXTENSION
    PS_CERT_AUTH_FAIL_PATH_LEN
    PS_CERT_AUTH_FAIL_REVOKED
    PS_CERT_AUTH_FAIL_SIG
    PS_DISABLED_FEATURE_FAIL
    PS_EAGAIN
    PS_INTERRUPT_FAIL
    PS_LIMIT_FAIL
    PS_MEM_FAIL
    PS_PARSE_FAIL
    PS_PENDING
    PS_PLATFORM_FAIL
    PS_PROTOCOL_FAIL
    PS_TIMEOUT_FAIL
    PS_UNSUPPORTED_FAIL

=item :RC

Return codes from different functions:

    PS_SUCCESS
    MATRIXSSL_SUCCESS
    MATRIXSSL_APP_DATA
    MATRIXSSL_APP_DATA_COMPRESSED
    MATRIXSSL_HANDSHAKE_COMPLETE
    MATRIXSSL_RECEIVED_ALERT
    MATRIXSSL_REQUEST_CLOSE
    MATRIXSSL_REQUEST_RECV
    MATRIXSSL_REQUEST_SEND

=item :Limit

Max amount of disabled ciphers in matrixSslSetCipherSuiteEnabledStatus():

    SSL_MAX_DISABLED_CIPHERS

Max size for message in matrixSslEncodeToOutdata():

    SSL_MAX_PLAINTEXT_LEN

=item :Validate

Return code in user validation callback:

    SSL_ALLOW_ANON_CONNECTION

=item :Bool

Boolean used in matrixSslSetCipherSuiteEnabledStatus() and {authStatus}:

    PS_TRUE
    PS_FALSE

=item :Func

    set_cipher_suite_enabled_status
    get_ssl_alert
    get_ssl_error

=back


=head1 VARIABLES

=head2 CA_CERTIFICATES

    $keys->load_rsa( undef, undef, undef, $Crypt::MatrixSSL3::CA_CERTIFICATES )

Scalar. Contains path to ca-certificates.crt file distributed with this module.
This file is generated by `mk-matrixssl-ca-certificates.pl` and contains
all certificates from current Firefox CA bundle supported by MatrixSSL.


=head1 FUNCTIONS

Some MatrixSSL functions are not accessible from Perl.

These functions implement optimization which is useless in Perl:

    matrixSslGetWritebuf
    matrixSslEncodeWritebuf

=head2 Open

=head2 Close

    Crypt::MatrixSSL3::Open();
    Crypt::MatrixSSL3::Close();

If you write server intensive applications it is still better to control
how often the MatrixSSL library gets initialized/deinitialized. For this
you can call Open() to initialize the library at the start of you
application and (optionally) Close() to deinitialize the library when your
application ends.

If you won't call Open() manually then these functions will be called
automatically before creating first object of any class (::Keys, ::SessID,
::Client, ::Server or ::HelloExt) and after last object will be destroyed:

    matrixSslOpen
    matrixSslClose

=head2 capabilities

    $caps = Crypt::MatrixSSL3::capabilities();

Returns a bitwise OR combination of the following constants:

    SHARED_SESSION_CACHE_ENABLED     - shared session cache between multiple processes is enabled
    STATELESS_TICKETS_ENABLED        - stateless ticket session resuming support is enabled
    DH_PARAMS_ENABLED                - loading the DH param for DH cipher suites is enabled
    ALPN_ENABLED                     - Application Layer Protocol Negotiation callback support is enabled
    SNI_ENABLED                      - Server Name Identification (virtual hosts) support is enabled
    OCSP_STAPLES_ENABLED             - handling of the "status_request" TLS extension by responding with an OCSP staple is enabled
    CERTIFICATE_TRANSPARENCY_ENABLED - handling of the "signed_certificate_timestamp" TLS extension is enabled

Before using any of these features it's a good idea to test if MatrixSSL is supporting them.

=head2 set_cipher_suite_enabled_status

    $rc = set_cipher_suite_enabled_status( $cipherId, $status );

    matrixSslSetCipherSuiteEnabledStatus( NULL, $cipherId, $status )

If this function will be used, matrixSslClose() will be never called.

=head2 get_ssl_alert

    ($level, $descr) = get_ssl_alert( $ptBuf );
    $descr           = get_ssl_alert( $ptBuf );

Unpack alert level and description from $ptBuf returned by
$ssl->received_data() or $ssl->processed_data().

Return ($level, $descr) in list context, and $descr in scalar context.
Both $level and $descr are dualvars (code in numeric context and text
in string context).

=head2 get_ssl_error

    $rc = get_ssl_error( $rc );

Return dualvar for this error code (same as $rc in numeric context and
text error name in string context).

=head2 refresh_OCSP_staple

    $rc = refresh_OCSP_staple( $server_index, $index, $DERfile );

Used to refresh an already loaded OCSP staple for a virtual host.

Parameters:

=over

=item $server_index

If you want to update the OCSP staple for a virtual host this parameter
must have the returned value of the first $sll->init_SNI(...) call.

=item $index

This value specifies the 0-based index of the virtual host for which
the OCSP staple should be refreshed.

When updating a default server this value must be -1 or undef

=item $DERfile

File containing the new OCSP staple in DER format as it was received from
the CA's OCSP responder.

=back

Returns PS_SUCCESS if the update was successful.

=head2 refresh_SCT_buffer

    $sct_array_size = refresh_SCT_buffer( $server_index, $index, $SCT_params );

Used to refresh an already loaded CT extension data buffer for a virtual host.

Parameters:

=over

=item $server_index and $index

Are the same as refresh_OCSP_staple above.

=item $SCT_params

=over

=item *

Perl scalar contains a file name with prepared extension data.

=item *

Perl array reference with file names of SCT binary structures that the
function will use to create the extension data.

=back

=back

Returns the number of files loaded (if this is 0 there was an error loading one of the files).

=head2 refresh_ALPN_data

    $num_protocols = refresh_ALPN_data( $server_index, $index, $protocols );

Used to refresh the application protocols for a default server or for a virtual host.

Parameters:

=over

=item $server_index and $index

Are the same as refresh_OCSP_staple above.

=item $protocols

=over

=item *

Perl array reference containing the new protocols.

=back

Returns the number of protocols you supplied (if this is 0 there was an error loading one of the files).

=back

Returns the number of files loaded in order to build extension data.

=head2 set_VHIndex_callback

    set_VHIndex_callback( \&VHIndexCallback );

More information about L</VHIndexCallback> in the L</CALLBACKS> section.

=head2 set_ALPN_callback

    set_ALPN_callback( \&ALPNCallback );

More information about L</ALPNCallback> in the L</CALLBACKS> section.

=head2 create_SSL_server

    $server_index = create_SSL_server();

Tells the XS module to allocate a new server structure. The returned index
must be saved and then used one time to initialize the server structure and then
each time a new client connection is accepted in order to set SNI/ALPN callbacks.

=head1 CLASSES

Constructors for all classes will throw exception on error instead of
returning error as matrixSslNew*() functions do. Exception will be
thrown using C< croak($return_code) >, so to get $return_code from $@
you should convert it back to number:

    eval { $client = Crypt::MatrixSSL3::Client->new(...) };
    $rc = 0+$@ if $@;


=head2 Crypt::MatrixSSL3::Keys

=head3 new

    $keys = Crypt::MatrixSSL3::Keys->new();

    matrixSslNewKeys( $keys )

Return new object $keys.
Throw exception if matrixSslNewKeys() doesn't return PS_SUCCESS.
When this object will be destroyed will call:

    matrixSslDeleteKeys( $keys )

=head3 load_rsa

    $rc = $keys->load_rsa( $certFile,
        $privFile, $privPass, $trustedCAcertFiles );

    matrixSslLoadRsaKeys( $keys, $certFile,
        $privFile, $privPass, $trustedCAcertFiles )

=head3 load_rsa_mem

    $rc = $keys->load_rsa_mem( $cert, $priv, $trustedCA );

    matrixSslLoadRsaKeysMem( $keys, $cert, length $cert,
        $priv, length $priv, $trustedCA, length $trustedCA )

=head3 load_ecc

    $rc = $keys->load_ecc( $certFile,
        $privFile, $privPass, $trustedCAcertFiles );

    matrixSslLoadEcKeys( $keys, $certFile,
        $privFile, $privPass, $trustedCAcertFiles )

=head3 load_rsa_mem

    $rc = $keys->load_ecc_mem( $cert, $priv, $trustedCA );

    matrixSslLoadEcKeysMem( $keys, $cert, length $cert,
        $priv, length $priv, $trustedCA, length $trustedCA )

=head3 load_pkcs12

    $rc = $keys->load_pkcs12( $p12File, $importPass, $macPass, $flags );

    matrixSslLoadPkcs12( $keys, $p12File, $importPass, length $importPass,
        $macPass, length $macPass, $flags )

=head3 load_DH_params

    $rc = $keys->load_DH_params( $DH_params_file );

    matrixSslLoadDhParams ( $keys, $DH_params_file )

=head3 load_session_ticket_keys

    $rc = $keys->load_session_ticket_keys( $name, $symkey, $hashkey );

    matrixSslLoadSessionTicketKeys ( $keys, $name, $symkey, length $symkey,
        $haskkey, length $hashkey )

=head3 load_OCSP_response

    $rc = $keys->load_OCSP_response( $OCSP_file );

    matrixSslLoadOCSPResponse ( $keys, $OCSPResponse, $OCSPResponseLen )

=head3 load_SCT_response

    $rc = $keys->load_SCT_response( $SCT_params );

    matrixSslLoadSCTResponse ( $keys, $SCTResponse, $SCTResponseLen )


B<Server side.>


=head2 Crypt::MatrixSSL3::SessID

=head3 new

    $sessID = Crypt::MatrixSSL3::SessID->new();

Return new object $sessID representing (sslSessionId_t*) type.
Throw exception if failed to allocate memory.
When this object will be destroyed will free memory, so you should
keep this object while there are still Client/Server session
which use this $sessID.

=head3 clear

    $sessID->clear();

    matrixSslClearSessionId($sessID)


=head2 Crypt::MatrixSSL3::Client

=head3 new

    $ssl = Crypt::MatrixSSL3::Client->new(
        $keys, $sessID, \@cipherSuites,
        \&certValidator, $expectedName,
        $extensions, \&extensionCback,
    );

    matrixSslNewClientSession( $ssl,
        $keys, $sessID, \@cipherSuites,
        \&certValidator, $expectedName,
        $extensions, \&extensionCback,
    )

Return new object $ssl.
Throw exception if matrixSslNewClientSession() doesn't return
MATRIXSSL_REQUEST_SEND.
When this object will be destroyed will call:

    matrixSslDeleteSession( $ssl )

More information about callbacks L</certValidator> and L</extensionCback>
in the L</CALLBACKS> section.


=head2 Crypt::MatrixSSL3::Server

=head3 new

    $ssl = Crypt::MatrixSSL3::Server->new( $keys, \&certValidator );

    matrixSslNewServerSession( $ssl, $keys, \&certValidator )

Return new object $ssl.
Throw exception if matrixSslNewServerSession() doesn't return PS_SUCCESS.
When this object will be destroyed will call:

    matrixSslDeleteSession( $ssl )

More information about callback L</certValidator> in the L</CALLBACKS> section.

=head3 init_SNI

    $ssl->init_SNI( $sserver_index, $sni_params );

This function should be called only once when the server is initialized.

Parameters:

=over

=item $server_index

Server structure index returned by C<create_SSL_server()>

=item $sni_params [{...},...] or undef

This is a reference to an array that contains one or more array references:

    $sni_params = [                                                     # virtual hosts support - when a client sends a TLS SNI extension, the settings below will apply
                                                                        #                         based on the requested hostname
        # virtual host 0 (also referred in the code as SNI entry 0)
        {
            'hostname' => 'hostname',                                   # regular expression for matching the hostname
            'cert' => '/path/to/certificate;/path/to/CA-chain',         # KEY - certificate (the CA-chain is optional)
            'key' => '/path/to/private_key',                            # KEY - private key
            'DH_param' => /path/to/DH_params',                          # KEY - file containing the DH parameter used with DH ciphers
            'session_ticket_keys' => {                                  # session tickets setup
                'id' => '1234567890123456',                             # KEY - TLS session tickets - 16 bytes unique identifier
                'encrypt_key' => '12345678901234567890123456789012',    # KEY - TLS session tickets - 128/256 bit encryption key
                'hash_key' => '12345678901234567890123456789012',       # KEY - TLS session tickets - 256 bit hash key
            },
            'OCSP_staple' => '/path/to/OCSP_staple.der',                # SESSION - file containing a OCSP staple that gets sent when a client
                                                                        #           send a TLS status request extension
            'SCT_params' => [                                           # SESSION - Certificate Transparency SCT files used to build the
                                                                        #           'signed_certificate_timestamp' TLS extension data buffer
                '/path/to/SCT1.sct',
                '/path/to/SCT2.sct',
                ...
            ],
            # instead of the Certificate Transparency SCT files you can specify a scalar with a single file that contains multiple SCT files
            # note that this file is not just a concatenation of the SCT files, but a ready-to-use 'signed_certificate_timestamp' TLS extension data buffer
            # see ct-submit.pl for more info
            #'SCT_params' => '/path/to/CT_extension_data_buffer',
            'ALPN' => ['protocol1', 'protocol2']                        # SESSION - server supported protocols
        },
        # virtual host 1
        ...
    ]

=back

=head3 set_server_params

    $ssl->set_server_params( $server_index, $sv_params );

Used to set the server supported protocols used when a client send a TLS
ALPN extension.

Note that this function call only affects the B<default server>. Virtual
hosts are managed by using the $ssl->init_SNI(...).

See $ssl->init_SNI(...) for usage.

Parameters:

=over

=item $server_index

Server structure index returned by C<create_SSL_server()>

=item $sv_params {...} or undef

This is a reference to a hash with the following structure (all keys are optional):

    $sv_params = {
        'ALPN' => ['protocol1', 'protocol2']
    }

If you specify the 'ALPN' parameter, you should also provide
an ALPN callback. More information about callback L</ALPNCallback>
in the L</CALLBACKS> section.

=back

=head3 set_callbacks

    $ssl->set_callbacks( $server_index, $ssl_id );

Parameters:

=over

=item $server_index

Server structure index returned by C<create_SSL_server()>

=item $ssl_id

A 32 bit integer that uniquely identifies this session. This parameter
will be sent back when MatrixSSL calls the SNI callback defined in the XS
module when a client sends a SNI extension.
If the XS module is able to match the requested client hostname it will
call the Perl callback set with set_VHIndex_callback.

=back

=head2 Crypt::MatrixSSL3::Client and Crypt::MatrixSSL3::Server

=head3 get_outdata

    $rc = $ssl->get_outdata( $outBuf );

Unlike C API, it doesn't set $outBuf to memory location inside MatrixSSL,
but instead it append buffer returned by C API to the end of $outBuf.

    matrixSslGetOutdata( $ssl, $tmpBuf )
    $outBuf .= $tmpBuf

Throw exception if matrixSslGetOutdata() returns < 0.

=head3 sent_data

    $rc = $ssl->sent_data( $bytes );

    matrixSslSentData( $ssl, $bytes )

=head3 received_data

    $rc = $ssl->received_data( $inBuf, $ptBuf );

    $n = matrixSslGetReadbuf( $ssl, $buf )
    $n = min($n, length $inBuf)
    $buf = substr($inBuf, 0, $n, q{})
    matrixSslReceivedData( $ssl, $n, $ptBuf, $ptLen )

Combines two calls: matrixSslGetReadbuf() and matrixSslReceivedData().
It copy data from beginning of $inBuf into buffer returned by
matrixSslGetReadbuf() and cut copied data from beginning of $inBuf (it may
copy less bytes than $inBuf contain if size of buffer provided by
MatrixSSL will be smaller).
Then it calls matrixSslReceivedData() to get $rc and may fill $ptBuf with
received alert or application data.

It is safe to call it with empty $inBuf, but this isn't a good idea
performance-wise.

Throw exception if matrixSslGetReadbuf() returns <= 0.

=head3 processed_data

    $rc = $ssl->processed_data( $ptBuf );

    matrixSslProcessedData( $ssl, $ptBuf, $ptLen )

In case matrixSslReceivedData() or matrixSslProcessedData() will return
MATRIXSSL_RECEIVED_ALERT, you can get alert level and description from
$ptBuf:

    my ($level, $descr) = get_ssl_alert($ptBuf);

=head3 encode_to_outdata

    $rc = $ssl->encode_to_outdata( $outBuf );

    matrixSslEncodeToOutdata( $ssl, $outBuf, length $outBuf )

=head3 encode_closure_alert

    $rc = $ssl->encode_closure_alert();

    matrixSslEncodeClosureAlert( $ssl )

=head3 encode_rehandshake

    $rc = $ssl->encode_rehandshake(
        $keys, \&certValidator, $sessionOption, \@cipherSuites,
    );

    matrixSslEncodeRehandshake( $ssl, $keys, \&certValidator,
        $sessionOption, \@cipherSuites )

More information about callback L</certValidator> in the L</CALLBACKS> section.

=head3 set_cipher_suite_enabled_status

    $rc = $ssl->set_cipher_suite_enabled_status( $cipherId, $status );

    matrixSslSetCipherSuiteEnabledStatus( $ssl, $cipherId, $status )

=head3 get_anon_status

    $anon = $ssl->get_anon_status();

    matrixSslGetAnonStatus( $ssl, $anon )


=head2 Crypt::MatrixSSL3::HelloExt

=head3 new

    $extension = Crypt::MatrixSSL3::HelloExt->new();

    matrixSslNewHelloExtension>( $extension )

Return new object $extension.
Throw exception if matrixSslNewHelloExtension() doesn't return PS_SUCCESS.
When this object will be destroyed will call:

    matrixSslDeleteHelloExtension( $extension )

=head3 load

    $rc = $extension->load( $ext, $extType );

    matrixSslLoadHelloExtension( $extension, $ext, length $ext, $extType )


=head1 CALLBACKS

=head2 certValidator

Will be called with two scalar params: $certInfo and $alert
(unlike C callback which also have $ssl param).

Param $certInfo instead of (psX509Cert_t *) will contain reference to
array with certificates. Each certificate will be hash in this format:

    notBefore       => $notBefore,
    notAfter        => $notAfter,
    subjectAltName  => {
        dns             => $dns,
        uri             => $uri,
        email           => $email,
    },
    subject        => {
        country         => $country,
        state           => $state,
        locality        => $locality,
        organization    => $organization,
        orgUnit         => $orgUnit,
        commonName      => $commonName,
    },
    issuer         => {
        country         => $country,
        state           => $state,
        locality        => $locality,
        organization    => $organization,
        orgUnit         => $orgUnit,
        commonName      => $commonName,
    },
    authStatus     => $authStatus,

This callback must return single scalar with integer value (as described in
MatrixSSL documentation). If callback die(), then warning will be printed,
and execution will continue assuming callback returned -1.

=head2 extensionCback

Will be called with two scalar params: $type and $data
(unlike C callback which also have $ssl and length($data) params).

This callback must return single scalar with integer value (as described in
MatrixSSL documentation). If callback die(), then warning will be printed,
and execution will continue assuming callback returned -1.

=head2 ALPNCallback

Will be called when a client sends an ALPN extension and a successful
application protocol has been negotiated. If the server doesn't implement
any of the client's protocols the XS module will send an appropriate
response and the client will receive a SSL_ALERT_NO_APP_PROTOCOL alert.

Will be called with 2 parameters:

    $ssl_id - this is the $ssl_id used in the $ssl->set_callbacks(...) call
    $app_proto - scalar with the negociated protocol name

=head2 VHIndexCallback

Will be called whenever we have a successful match against the hostname
specified by the client in its SNI extension. This will inform the Perl
code which virtual host the current SSL session belongs to.

Will be called with 3 parameters:

    $ssl_id - this is the $ssl_id used in the $ssl->set_callbacks(...) call
    $index - a 0-based int specifying which virtual host matchd the client requested hostname
    $match - a scalar containing the hostname sent in the client's SNI TLS extension

Doesn't return anything.


=head1 HOWTO: Certificate Transparency

=head2 PREREQUISITES

For generating Certificate Transparency files you will need the following:

=head3 Certificates

=over

=item *

Server certificate (server.crt)

=item *

Issuer certificate (issuer.crt)

=item *

Certificate Authority chain (server-CA.crt) - this includes any number of
intermediate certificate and optionally ends with the root certificate.

=back

=head2 USING THE ct-submit.pl TOOL

=head3 Generate one file containing SCTs from all CT log servers

    ct-submit.pl --pem server.crt --pem issuer.crt --pem server-CA.pem \
        --extbuf /path/to/CT.sct

The resulted file can be used in your script like:

    # set or refresh CT response for a SSL session (default server)
    $sv_keys->load_SCT_response('/path/to/CT.sct');


=head3 Generate multiple SCT files containing binary representation of the responses received from the log servers

    ct-submit.pl --pem server.crt --pem issuer.crt --pem server-CA.pem \
        --individual /path/to/sct/

This will create in the /path/to/stc/ folder the following files
(considering that the requests to the log servers were successful):

    aviator.sct          # https://ct.googleapis.com/aviator
    certly.sct           # https://log.certly.io
    pilot.sct            # https://ct.googleapis.com/pilot
    rocketeer.sct        # https://ct.googleapis.com/rocketeer
    digicert.sct         # https://ct1.digicert-ct.com/log - disabled by default -
                         # accepts certificates only from select CAs
    izenpe.sct           # https://ct.izenpe.com - disabled by default -
                         # accepts certificates only from select CAs

One or more files can be used in your script like:

    # set or refresh CT response for a SSL session (default server)
    # note that even if you're using a single file (which will be wrong
    # according to the RFC because at least 2 SCTs from different server logs
    # must be sent), you still need to provide an array reference with one element
    $sv_keys->load_SCT_response([
            '/path/to/sct/aviator.sct',
            '/path/to/sct/certly.sct'
    ]);


=head1 HOWTO: OCSP staple

=head2 PREREQUISITES

For generating an OCSP staple you will need to following:

=head3 OpenSSL

OpenSSL with OCSP application installed.

=head3 Certificates

=over

=item *

Server certificate (server.crt)

=item *

Issuer certificate (issuer.crt)

=item *

Full Certificate Authority chain (full-CA.crt) - this includes the issuer
certificate, any number of intermediate certificate and ends with the root
certificate.

=back

=head2 GETTING AN OCSP STAPLE

=head3 Get the OCSP responder URI

    openssl x509 -noout -ocsp_uri -in server.crt

=head3 Query the OCSP responder

    openssl ocsp -no_nonce -issuer issuer.crt -cert server.crt \
        -CAfile full-CA.crt -url OCSP_responder_URI \
        -header "HOST" OCSP_response_host -respout /path/to/OCSP_staple.der

=head3 Inspecting an OCSP staple

    openssl ocsp -respin /path/to/OCSP_staple.der -text -CAfile full-CA.crt

=head2 USAGE

=head3 Set or refresh an OCSP staple to be used within a SSL session (default server)

    $sv_keys->load_OCSP_response('/path/to/OCSP_staple.der');

=head3 Refreshing an already allocated OCSP staple buffer for a virtual host

    Crypt::MatrixSSL3::refresh_OCSP_staple( $erver_index, $index, '/path/to/OCSP_staple.der' );


=head1 HOWTO: Virtual hosts

=head2 TERMINOLOGY

=head3 Default server

Describes a set of properties (certificate, private key, OCSP staple, etc.)
to be used when the client connects but doesn't send a SNI TLS extension
in its CLIENT_HELLO message.

=head3 Virtual host (SNI entry)

Describes also a set of properties (like above) but these will be used
when the client sends a SNI extension and we have a successful match on
the virtual host's hostname and the client specified hostname.

=head3 SNI server

All the virtual hosts (SNI entries) declared for one server.

=head2 IMPLEMENTATION

Here is some Perl pseudo code on how these are used:

    Crypt::MatrixSSL3::set_VHIndex_callback(sub {
        my ($id, $index) = @_;
        print("Virtual host $index was selected for SSL session $ssl_id");
    });

    Crypt::MatrixSSL3::set_ALPN_callback(sub {
        my ($id, $app_proto) = @_;
        print("Application protocol $app_proto was negociated for SSL session $ssl_id");
    });

    my $server_index = -1;

    # define a listening socket
    $server_sock = ...

    # initialize default server keys - these will be shared by all server sessions
    my $sv_keys = Crypt::MatrixSSL3::Keys->new();

    # load key material (certificate, private key, etc)
    $sv_keys->load_rsa(...);

    # load OCSP response
    $sv_keys->load_OCSP_response(...);

    # load SCT response
    $sv_keys->load_SCT_response(...);

    ...

    # we assume when a client connects an accept_client sub will be called
    sub accept_client {
        # accept client socket
        my $client_sock = accept($server_sock, ...);

        # create server session reusing the keys
        my $cssl =  Crypt::MatrixSSL3::Server->new($sv_keys, undef);

        # create a unique SSL session ID
        # for example this can be the fileno of the client socket
        my $ssl_id = fileno($client_sock);

        # check if the server parameters are initialized
        if ($server_index == -1) {
            # tell the XS module to allocate a new SSL server structure
            $server_index = Crypt::MatrixSSL3::create_SSL_server();

            # set supported protocols for the default server.
            $ssl->set_server_params($server_index, {
                'ALPN' => [...]
            });

            # initialize virtual hosts:
            #   - allocates a SNI_entry structure for each virtual host and:
            #     - creates new server keys
            #     - sets up OCSP staple buffer (server keys - if needed)
            #     - sets up SCT buffer (server keys - if needed)
            #     - stores server implemented protocols if provided
            $ssl->init_SNI($server_index, [
                # see MatrixSSL.pm - init_SNI function
            ]);
        }

        # setup SNI/ALPN callback

        # sets up the matrixSSL SNI callback that will get called if the client sends a SNI TLS extension
        # in its CLIENT_HELLO message. When the XS SNI callback is called if any of the hostnames defined
        # for each virtual host matches againt the client requested hostname, the &VHIndexCallback setup
        # above will be called with the $ssl_id of the session and the 0-based index of the virtual host
        # the client sent its request

        # sets up the matrixSSL ALPN callback that will get called when the client sends an ALPN extension
        # the &ALPNCallback is called with the provided $ssl_id and the selected protocol

        $cssl->set_callbacks($server_index, $sll_id);

        # further initialization stuff after accepting the client
        ...
    }

    # secure communication with the client
    ...


=head1 SEE ALSO

http://www.MatrixSSL.org - the download from this site includes
simple yet comprehensive documentation in PDF format.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-Crypt-MatrixSSL3/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-Crypt-MatrixSSL3>

    git clone https://github.com/powerman/perl-Crypt-MatrixSSL3.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Crypt-MatrixSSL3>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Crypt-MatrixSSL3>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-MatrixSSL3>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Crypt-MatrixSSL3>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Crypt-MatrixSSL3>

=back


=head1 AUTHORS

C. N. Drake E<lt>christopher@pobox.comE<gt>

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005- by C. N. Drake E<lt>christopher@pobox.comE<gt>.

This software is Copyright (c) 2012- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The GNU General Public License version 2

MatrixSSL is distributed under the GNU General Public License,
Crypt::MatrixSSL3 uses MatrixSSL, and so inherits the same license.


=cut
