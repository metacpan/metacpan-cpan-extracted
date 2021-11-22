package Crypt::Perl::ECDSA::Parse;

=encoding utf-8

=head1 NAME

Crypt::Perl::ECDSA::Parse - ECDSA key parsing

=head1 SYNOPSIS

    use Crypt::Perl::ECDSA::Parse ();

    #These accept either DER or PEM, native format or PKCS8.
    #
    my $prkey = Crypt::Perl::ECDSA::Parse::private($buffer);
    my $pbkey = Crypt::Perl::ECDSA::Parse::public($buffer);

=head1 DISCUSSION

See L<Crypt::Perl::ECDSA::PrivateKey> and L<Crypt::Perl::ECDSA::PublicKey>
for descriptions of the interfaces of these two classes.

=cut

use strict;
use warnings;

use Try::Tiny;

use Crypt::Perl::ASN1 ();
use Crypt::Perl::PKCS8 ();
use Crypt::Perl::ToDER ();
use Crypt::Perl::ECDSA::ECParameters ();
use Crypt::Perl::X ();

sub private {
    my ($pem_or_der) = @_;

    require Crypt::Perl::ECDSA::PrivateKey;

    Crypt::Perl::ToDER::ensure_der($pem_or_der);

    my $asn1 = _private_asn1();
    my $asn1_ec = $asn1->find('ECPrivateKey');

    my $struct;
    try {
        $struct = $asn1_ec->decode($pem_or_der);
    }
    catch {
        my $ec_err = $_;

        my $asn1_pkcs8 = $asn1->find('PrivateKeyInfo');

        try {
            my $pk8_struct = $asn1_pkcs8->decode($pem_or_der);

            #It still might succeed, even if this is wrong, so don’t die().
            if ( $pk8_struct->{'privateKeyAlgorithm'}{'algorithm'} ne Crypt::Perl::ECDSA::ECParameters::OID_ecPublicKey() ) {
                warn "Unknown private key algorithm OID: “$pk8_struct->{'privateKeyAlgorithm'}{'algorithm'}”";
            }

            my $asn1_params = $asn1->find('EcpkParameters');
            my $params = $asn1_params->decode($pk8_struct->{'privateKeyAlgorithm'}{'parameters'});

            $struct = $asn1_ec->decode($pk8_struct->{'privateKey'});
            $struct->{'parameters'} = $params;
        }
        catch {
            die Crypt::Perl::X::create('Generic', "Failed to decode private key as either ECDSA native ($ec_err) or PKCS8 ($_)");
        };
    };

    my $key_parts = {
        version => $struct->{'version'},
        private => Crypt::Perl::BigInt->from_bytes($struct->{'privateKey'}),
        public => Crypt::Perl::BigInt->from_bytes($struct->{'publicKey'}[0]),
    };

    return Crypt::Perl::ECDSA::PrivateKey->new($key_parts, $struct->{'parameters'});
}

sub public {
    my ($pem_or_der) = @_;

    require Crypt::Perl::ECDSA::PublicKey;

    Crypt::Perl::ToDER::ensure_der($pem_or_der);

    my $asn1 = _public_asn1();
    my $asn1_ec = $asn1->find('ECPublicKey');

    my $struct;
    try {
        $struct = $asn1_ec->decode($pem_or_der);
    }
    catch {
        die Crypt::Perl::X::create('Generic', "Failed to decode input as ECDSA public key ($_)");
    };

    return Crypt::Perl::ECDSA::PublicKey->new(
        $struct->{'publicKey'}[0],
        $struct->{'keydata'}{'parameters'},
    );
}

sub jwk {
    my ($hr) = @_;

    require Crypt::Perl::ECDSA::NIST;
    require Crypt::Perl::ECDSA::EC::DB;
    require Crypt::Perl::Math;
    require MIME::Base64;

    my $curve_name = Crypt::Perl::ECDSA::NIST::get_curve_name_for_nist($hr->{'crv'});
    my $curve_hr = Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_name($curve_name);

    my $keylen = $curve_hr->{'p'}->bit_length();
    my $pub_half_byte_length = Crypt::Perl::Math::ceil( $keylen / 8 );

    my $x = MIME::Base64::decode_base64url($hr->{'x'});
    my $y = MIME::Base64::decode_base64url($hr->{'y'});

    #Make sure both halves are the proper length.
    substr($_, 0, 0) = ("\0" x ($pub_half_byte_length - length)) for ($x, $y);

    my $public = Crypt::Perl::BigInt->from_bytes("\x{04}$x$y");

    if ($hr->{'d'}) {
        require Crypt::Perl::ECDSA::PrivateKey;
        require Crypt::Perl::JWK;

        my %args = (
            version => 1,
            public => $public,
            private => Crypt::Perl::JWK::jwk_num_to_bigint($hr->{'d'}),
        );

        return Crypt::Perl::ECDSA::PrivateKey->new_by_curve_name(\%args, $curve_name);
    }

    require Crypt::Perl::ECDSA::PublicKey;
    return Crypt::Perl::ECDSA::PublicKey->new_by_curve_name( $public, $curve_name);
}

#----------------------------------------------------------------------

sub _private_asn1 {
    my $template = join("\n", Crypt::Perl::ECDSA::PrivateKey->ASN1_PRIVATE(), Crypt::Perl::PKCS8::ASN1());

    return Crypt::Perl::ASN1->new()->prepare($template);
}

sub _public_asn1 {
    my $template = join("\n", Crypt::Perl::ECDSA::PublicKey->ASN1_PUBLIC(), Crypt::Perl::PKCS8::ASN1());

    return Crypt::Perl::ASN1->new()->prepare($template);
}

1;
