package Crypt::MatrixSSL;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.86';

require XSLoader;
XSLoader::load('Crypt::MatrixSSL', $VERSION);

sub import {
    my $pkg = caller(0);
    no strict 'refs';
    *{$pkg.'::'.$_} = \&$_ for qw(
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
    );
    # export read-only scalar constants
    eval "*{${pkg}::$_} = \\".(0+constant($_)) for qw(
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
    );
    # export hashes
    *{$pkg.'::'.$_} = \%{$_} for qw(
        SSL_alertLevel
        SSL_alertDescription
    );
}

# SSL Alert levels and descriptions. This implementation treats all alerts as fatal.
our %SSL_alertLevel         = map { 0+constant($_) => $_ } qw(
    SSL_ALERT_LEVEL_WARNING
    SSL_ALERT_LEVEL_FATAL
);
our %SSL_alertDescription   = map { 0+constant($_) => $_ } qw(
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
);

# for debug
our %mxSSL_RETURN_CODES = (
    0+constant('SSL_SUCCESS')       => 'SSL_SUCCESS	Generic success',
    0+constant('SSL_ERROR')         => 'SSL_ERROR	generic ssl error, see error code',
    0+constant('SSL_FULL')          => 'SSL_FULL	must call sslRead before decoding',
    0+constant('SSL_PARTIAL')       => 'SSL_PARTIAL	more data reqired to parse full msg',
    0+constant('SSL_SEND_RESPONSE') => 'SSL_SEND_RESPONSE	decode produced output data',
    0+constant('SSL_PROCESS_DATA')  => 'SSL_PROCESS_DATA	succesfully decoded application data',
    0+constant('SSL_ALERT')         => 'SSL_ALERT	weve decoded an alert',
    0+constant('SSL_FILE_NOT_FOUND')=> 'SSL_FILE_NOT_FOUND	File not found',
    0+constant('SSL_MEM_ERROR')     => 'SSL_MEM_ERROR	Memory allocation failure',
);


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Crypt::MatrixSSL - Perl extension for SSL and TLS using MatrixSSL.org 


=head1 SYNOPSIS

  use Crypt::MatrixSSL;

  # 1. See the MatrixSSL documentation.
  # 2. See scripts included in this package:
  #     sample_ssl_client.pl
  #     sample_ssl_server.pl
  #     sample_functions.pl


=head1 DESCRIPTION

Crypt::MatrixSSL lets you use the MatrixSSL crypto library (see
http://matrixssl.org/) from Perl.  With this module, you will be
able to easily write SSL and TLS client and server programs.

MatrixSSL includes everything you need, all in under 50KB.

You will need a "C" compiler to build this, unless you're getting
the ".ppm" prebuilt Win32 version.  Crypt::MatrixSSL builds cleanly
on (at least) Windows, Linux, and Macintosh machines.

MatrixSSL is an Open Source (GNU Public License) product, and is
also available commercially if you need freedom from GNU rules.

Everything you need is included here, but check the MatrixSSL.org
web site to make sure you've got the latest version of the 
MatrixSSL "C" code if you like (it's in the directory "./matrixssl"
of this package if you want to replace the included version from
the MatrixSSL.org download site.)


=head2 EXPORT

=head3 FUNCTIONS EXPORTED BY DEFAULT

See MatrixSSL documentations about these functions. This documentation will
describe only differences between original C interface provided by MatrixSSL
and Perl interface provided by this module (see below).

 matrixSslOpen()
 matrixSslClose()
 matrixSslReadKeys()
 matrixSslReadKeysMem()
 matrixSslFreeKeys()
 matrixSslNewSession()
 matrixSslDeleteSession()
 matrixSslDecode()
 matrixSslEncode()
 matrixSslEncodeClosureAlert()
 matrixSslEncodeClientHello()
 matrixSslEncodeHelloRequest()
 matrixSslSetSessionOption()
 matrixSslHandshakeIsComplete()
 matrixSslGetSessionId()
 matrixSslFreeSessionId()
 matrixSslSetCertValidator()
 matrixSslGetAnonStatus()
 matrixSslAssignNewKeys()
 matrixSslSetResumptionFlag()
 matrixSslGetResumptionFlag()

=head3 CONSTANTS EXPORTED BY DEFAULT

Return code in user validation callback:

 $SSL_ALLOW_ANON_CONNECTION

Max size for message in matrixSslEncode():

 $SSL_MAX_PLAINTEXT_LEN

Flags for matrixSslNewSession():

 $SSL_FLAGS_SERVER
 $SSL_FLAGS_CLIENT_AUTH

Options for matrixSslSetSessionOption():

 $SSL_OPTION_DELETE_SESSION

matrixSslDecode() return values:

 $SSL_SUCCESS
 $SSL_ERROR
 $SSL_FULL
 $SSL_PARTIAL
 $SSL_SEND_RESPONSE
 $SSL_PROCESS_DATA
 $SSL_ALERT
 $SSL_FILE_NOT_FOUND
 $SSL_MEM_ERROR

matrixSslDecode() alertLevel:

 $SSL_ALERT_LEVEL_WARNING
 $SSL_ALERT_LEVEL_FATAL

matrixSslDecode() alertDescription:

 $SSL_ALERT_CLOSE_NOTIFY
 $SSL_ALERT_UNEXPECTED_MESSAGE
 $SSL_ALERT_BAD_RECORD_MAC
 $SSL_ALERT_DECOMPRESSION_FAILURE
 $SSL_ALERT_HANDSHAKE_FAILURE
 $SSL_ALERT_NO_CERTIFICATE
 $SSL_ALERT_BAD_CERTIFICATE
 $SSL_ALERT_UNSUPPORTED_CERTIFICATE
 $SSL_ALERT_CERTIFICATE_REVOKED
 $SSL_ALERT_CERTIFICATE_EXPIRED
 $SSL_ALERT_CERTIFICATE_UNKNOWN
 $SSL_ALERT_ILLEGAL_PARAMETER

=head3 HASHES EXPORT BY DEFAULT

 %SSL_alertLevel
 %SSL_alertDescription


=head1 FUNCTIONS

=over

=item B<matrixSslDecode>( $ssl, $inBuf, $outBuf, $error, $alertLevel, $alertDescription )

$inBuf and $outBuf are usual string scalars, not (sslBuf_t *) as in C interface.

After succesfull decoding one packet, matrixSslDecode() will cut decoded
packet from $inBuf's beginning.

Reply SSL packets or application data will be appended to $outBuf, if any.

To convert error/alert codes into text use exported hashes:

 $SSL_alertDescription{ $error }
 $SSL_alertLevel{ $alertLevel }
 $SSL_alertDescription{ $alertDescription }


=item B<matrixSslEncode>( $ssl, $inBuf, $outBuf )

=item B<matrixSslEncodeClosureAlert>( $ssl, $outBuf )

=item B<matrixSslEncodeClientHello>( $ssl, $outBuf, $cipherSuite )

=item B<matrixSslEncodeHelloRequest>( $ssl, $outBuf )

$outBuf in all matrixSslEncode* functions is usual string scalar,
not (sslBuf_t *) as in C interface.

Encoded SSL packet will be appended to $outBuf.

If you need to matrixSslEncode() huge $inBuf, then you should split $inBuf
into strings with size <= $SSL_MAX_PLAINTEXT_LEN and call matrixSslEncode()
for each of these strings. If you don't do this matrixSslEncode() will return
one of these errors: $SSL_ERROR, $SSL_FULL or matrixSslDecode() on other side
will return $SSL_ERROR.


=item B<matrixSslSetCertValidator>( $ssl, \&cb, $cb_arg )

While interface of this function is same as in C, there some important notes
about perl callback \&cb. Perl callback will be called with two scalar params:
$certInfo and $cb_arg - just like in C.

But $certInfo instead of (sslCertInfo_t *) will contain reference to array
with certificates. Each certificate will be hash in this format:

 verified       => $verified,
 notBefore      => $notBefore,
 notAfter       => $notAfter,
 subjectAltName => {
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

This callback must return single scalar with integer value (as described in
MatrixSSL documentation). If callback die(), then warning will be printed,
and execution will continue assuming callback returned -1.


=back

=head1 SEE ALSO

http://www.MatrixSSL.org - the download from this site includes
simple yet comprehensive documentation in PDF format.

=head1 AUTHORS

C. N. Drake, E<lt>christopher@pobox.comE<gt>
Alex Efros

=head1 COPYRIGHT AND LICENSE

MatrixSSL is distrubed under the GNU Public License:-
http://www.gnu.org/copyleft/gpl.html

Crypt::MatrixSSL uses MatrixSSL, and so inherits the same License.

Copyright (C) 2005 by C. N. Drake.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
