package Crypt::Perl::PKCS10;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::PKCS10 - Certificate Signing Request (CSR) creation

=head1 SYNOPSIS

    my $pkcs10 = Crypt::Perl::PKCS10->new(

        key => $private_key_obj,

        subject => [
            commonName => 'foo.com',
            localityName => 'somewhere',
            #...
        ],
        attributes => [
            [ 'extensionRequest',
                [ 'subjectAltName',
                    [ dNSName => 'foo.com' ],
                    [ dNSName => 'bar.com' ],
                ],
            ],
        ],
    );

    my $der = $pkcs10->to_der();
    my $pem = $pkcs10->to_pem();

=head1 DESCRIPTION

This module is for creation of (PKCS #10) certificate signing requests (CSRs).
Right now it supports only a
subset of what L<OpenSSL|http://openssl.org> can create; however, it’s
useful enough for use with many certificate authorities, including
L<ACME|https://ietf-wg-acme.github.io/acme/> services like
L<Let’s Encrypt|http://letsencrypt.org>.

It’s also a good deal easier to use!

I believe this is the only L<CPAN|http://search.cpan.org> module that
can create CSRs for RSA, ECDSA, and Ed25519 keys. Other encryption schemes
would not be difficult to integrate—but do any CAs accept them?

=head1 ECDSA KEY FORMAT

After a brief flirtation (cf. v0.13) with producing ECDSA-signed CSRs using
explicit curve parameters, this module produces CSRs using B<named> curves.
Certificate authorities seem to prefer this format—which makes sense since
they only allow certain curves in the first place.

=head1 SIGNATURE DIGEST ALGORITHMS

The signature digest algorithm is
determined based on the passed-in key: for RSA it’s always SHA-512, and for
ECDSA it’s the strongest SHA digest algorithm that the key allows
(e.g., SHA-224 for a 239-bit key, etc.)

If you need additional flexibility, let me know.

(Note that Ed25519 signs an entire document rather than a digest.)

=head1 CLASS METHODS

=head2 new( NAME => VALUE, ... );

Create an instance of this class. Parameters are:

=over 4

=item * C<key> - An instance of C<Crypt::Perl::RSA::PrivateKey>,
C<Crypt::Perl::ECDSA::PrivateKey>, or C<Crypt::Perl::Ed25519::PrivateKey>.
If you’ve got a DER- or PEM-encoded key string, use L<Crypt::Perl::PK>
(included in this distribution) to create an appropriate object.

=item * C<subject> - An array reference of arguments into
L<Crypt::Perl::X509::Name>’s constructor.

=item * C<attributes> - An array reference of arguments into
L<Crypt::Perl::PKCS10::Attributes>’s constructor.

=back

=head1 TODO

Let me know what features you would find useful, ideally with
a representative sample CSR that demonstrates the requested feature.
(Or, better yet, send me a pull request!)

=head1 SEE ALSO

=over 4

=item * L<Crypt::PKCS10> - Parse CSRs, in pure Perl.

=item * L<Crypt::OpenSSL::PKCS10> - Create CSRs using OpenSSL via XS.
Currently this only seems to support RSA.

=back

=cut

use Crypt::Perl::ASN1 ();
use Crypt::Perl::ASN1::Signatures ();
use Crypt::Perl::PKCS10::Attributes ();
use Crypt::Perl::PKCS10::Attributes ();
use Crypt::Perl::X509::Name ();
use Crypt::Perl::X ();

use parent qw( Crypt::Perl::ASN1::Encodee );

*to_der = __PACKAGE__->can('encode');

sub to_pem {
    my ($self) = @_;

    require Crypt::Format;
    return Crypt::Format::der2pem( $self->to_der(), 'CERTIFICATE REQUEST' );
}

use constant ASN1 => <<END;
    AlgorithmIdentifier ::= SEQUENCE {
      algorithm  OBJECT IDENTIFIER,
      parameters ANY
    }

    CertificationRequestInfo ::= SEQUENCE {
      version       INTEGER,
      subject       ANY,
      subjectPKInfo ANY,
      attributes    ANY OPTIONAL
    }

    CertificationRequest ::= SEQUENCE {
      certificationRequestInfo  CertificationRequestInfo,
      signatureAlgorithm        AlgorithmIdentifier,
      signature                 BIT STRING
    }
END

use constant asn1_macro => 'CertificationRequest';

sub new {
    my ($class, %opts) = @_;

    my ($key, $attrs, $subject) = @opts{'key', 'attributes', 'subject'};

    $subject = Crypt::Perl::X509::Name->new( @$subject );
    $attrs = Crypt::Perl::PKCS10::Attributes->new( @$attrs );

    my $self = {
        _key => $key,
        _subject => $subject,
        _attributes => $attrs,
    };

    return bless $self, $class;
}

sub _encode_params {
    my ($self) = @_;

    my $key = $self->{'_key'};

    my ($pk_der);
    my ($sig_alg, $sig_param, $sig_func);

    if ($key->isa('Crypt::Perl::ECDSA::PrivateKey')) {
        require Digest::SHA;

        my $bits = $key->max_sign_bits();

        if ($bits < 224) {
            die Crypt::Perl::X::create('Generic', "This key is too weak ($bits bits) to make a secure PKCS #10 CSR.");
        }
        elsif ($bits < 256) {
            $bits = 224;
        }
        elsif ($bits < 384) {
            $bits = 256;
        }
        elsif ($bits < 512) {
            $bits = 384;
        }
        else {
            $bits = 512;
        }

        $sig_alg = "ecdsa-with-SHA$bits";

        my $fn = "sign_sha$bits";

        $sig_func = sub {
            my ($key, $msg) = @_;

            return $key->$fn($msg);
        };

        $pk_der = $key->get_public_key()->to_der_with_curve_name();
    }
    elsif ($key->isa('Crypt::Perl::RSA::PrivateKey')) {
        require Digest::SHA;

        $sig_alg = 'sha512WithRSAEncryption';
        $sig_param = q<>;
        $sig_func = $key->can('sign_RS512');

        $pk_der = $key->to_subject_public_der();
    }
    elsif ($key->isa('Crypt::Perl::Ed25519::PrivateKey')) {
        $sig_alg = 'ed25519';
        $sig_func = $key->can('sign');
        $pk_der = $key->get_public_key()->to_der();
    }
    else {
        die Crypt::Perl::X::create('Generic', "Key ($key) is not a recognized private key class instance!");
    }

    $sig_alg = $Crypt::Perl::ASN1::Signatures::OID{$sig_alg} || do {
        die Crypt::Perl::X::create('Generic', "Unrecognized signature algorithm OID: “$sig_alg”");
    };

    my $asn1_reqinfo = Crypt::Perl::ASN1->new()->prepare( $self->ASN1() );
    $asn1_reqinfo = $asn1_reqinfo->find('CertificationRequestInfo');

    my $subj_enc = $self->{'_subject'}->encode();

    my $attr_enc = $self->{'_attributes'}->encode();

    #We need the attributes not to be a SET, but CONTEXT [0].
    #That means the first byte needs to be 0xa0, not 0x31.
    #This is a detail germane to the PKCS10 structure, not to the
    #Attributes itself (right??), so it makes sense to do the change here
    #rather than to put “[0] SET” into the ASN1 template for Attributes.
    #
    #“use bytes” is not necessary because we know the first character is
    #0x31, which came from Convert::ASN1.
    substr($attr_enc, 0, 1) = chr 0xa0;

    my %reqinfo = (
        version => 0,
        subject => $subj_enc,
        subjectPKInfo => $pk_der,
        attributes => $attr_enc,
    );

    my $reqinfo_enc = $asn1_reqinfo->encode(\%reqinfo);

    my $signature = $sig_func->( $key, $reqinfo_enc );

    return {
        certificationRequestInfo => \%reqinfo,
        signatureAlgorithm => {
            algorithm => $sig_alg,
            parameters => $sig_param || Crypt::Perl::ASN1::NULL(),
        },
        signature => $signature,
    };
}

1;
