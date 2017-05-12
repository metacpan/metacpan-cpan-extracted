package t::Crypt::Perm::RSA::PublicKey;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use lib "$FindBin::Bin/lib";
use parent qw( TestClass );

use MIME::Base64 ();

use Crypt::Perl::BigInt ();
use Crypt::Perl::RSA::Parse ();
use Crypt::Perl::RSA::PublicKey ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_pem_der_export : Tests(2) {
    my ($self) = @_;

    my $pem = <<END;
-----BEGIN RSA PUBLIC KEY-----
MGYCYQCfMGcQpapQgxepWmP0idxLSysHZsF5iBIil5PX9k0YETbxMCBA3Y9mv2wK
8+aMsheOS/6PCSJNozFcD3ec6YPknqkuUMsNgzcqmZu5h2wiKM71W4ctLiL7xY/A
OCncb2kCAQM=
-----END RSA PUBLIC KEY-----
END
    my $der = Crypt::Format::pem2der($pem);

    my $pbkey = Crypt::Perl::RSA::Parse::public($pem);

    is(
        sprintf("%v.02x", $pbkey->to_der()),
        sprintf("%v.02x", $der),
        'to_der()',
    );

    is(
        sprintf("%v.02x", Crypt::Format::pem2der( $pbkey->to_pem() )),
        sprintf("%v.02x", $der),
        'to_pem()',
    );

    return;
}

sub test_get_jwk_thumbprint : Tests(1) {

    #cf. RFC 7638 pp3-4
    my %params = (
        modulus => '0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx4cbbfAAtVT86zwu1RK7aPFFxuhDR1L6tSoc_BJECPebWKRXjBZCiFV4n3oknjhMstn64tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6Cf0h4QyQ5v-65YGjQR0_FDW2QvzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qMQvRL5hajrn1n91CbOpbISD08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPksINHaQ-G_xBniIqbw0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw',
        publicExponent => 'AQAB',
    );

    $_ = MIME::Base64::decode_base64url($_) for values %params;
    $_ = Crypt::Perl::BigInt->from_bytes($_) for values %params;

    my $pbkey = Crypt::Perl::RSA::PublicKey->new(\%params);

    is(
        $pbkey->get_jwk_thumbprint('sha256'),
        'NzbLsXh8uDCcd-6MNwXF4W_7noWXFZAfHkxZsRGC9Xs',
        'expected JWK thumbprint',
    );

    return;
}
