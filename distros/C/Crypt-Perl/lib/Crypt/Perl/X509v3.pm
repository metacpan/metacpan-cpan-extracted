package Crypt::Perl::X509v3;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509v3 - TLS/SSL Certificates

=head1 SYNOPSIS

    my $cert = Crypt::Perl::X509v3->new(
        key => $crypt_perl_public_key_obj,
        issuer => [
            [ commonName => 'Foo', surname => 'theIssuer' ],
            [ givenName => 'separate RDNs' ],
        ],
        subject => \@subject,   #same format as issuer

        not_before => $unixtime,
        not_after => $unixtime,

        # The same structure as in Crypt::Perl::PKCS10 …
        extensions => [
            [ keyUsage => 'keyCertSign', 'keyEncipherment' ],
            [ $extn_name => @extn_args ],
            # ..
        ],

        serial_number => 12345,

        issuer_unique_id => '..',
        subject_unique_id => '..',
    );

    # The signature algorithm (2nd argument) is not needed
    # when the signing key is Ed25519.
    $cert->sign( $crypt_perl_private_key_obj, 'sha256' );

    my $pem = $cert->to_pem();

=head1 STATUS

This module is B<experimental>! The API may change between versions.
If you’re going to build something off of it, ensure that you check
Crypt::Perl’s changelog before updating this module.

=head1 DESCRIPTION

This module can create TLS/SSL certificates. The caller has full control
over all certificate components, and anything not specified is not assumed.

There currently is not a parsing interface. Hopefully that can be remedied.

=cut

use parent qw( Crypt::Perl::ASN1::Encodee );

use Crypt::Perl::ASN1::Signatures ();
use Crypt::Perl::X509::Extensions ();
use Crypt::Perl::X509::Name ();

use Crypt::Perl::X ();

#TODO: refactor
*to_der = __PACKAGE__->can('encode');

sub to_pem {
    my ($self) = @_;

    require Crypt::Format;
    return Crypt::Format::der2pem( $self->to_der(), 'CERTIFICATE' );
}

use constant ASN1 => <<END;
    X509v3  ::=  SEQUENCE  {
        tbsCertificate       ANY,
        signatureAlgorithm   SigIdentifier,
        signature            BIT STRING
    }

    SigIdentifier ::= SEQUENCE {
        algorithm   OBJECT IDENTIFIER,
        parameters  ANY OPTIONAL
    }

    TBSCertificate  ::=  SEQUENCE  {
        version         [0]  Version,
        serialNumber         INTEGER,
        signature            SigIdentifier,
        issuer               ANY,   -- Name
        validity             Validity,
        subject              ANY,   -- Name
        subjectPublicKeyInfo ANY,
        issuerUniqueID  [1]  IMPLICIT BIT STRING OPTIONAL,
                            -- If present, version MUST be v2 or v3
        subjectUniqueID [2]  IMPLICIT BIT STRING OPTIONAL,
                            -- If present, version MUST be v2 or v3
        extensions      [3]  Extensions OPTIONAL
                            -- If present, version MUST be v3 --
    }

    Version  ::=  SEQUENCE {
        version INTEGER
    }

    Validity ::= SEQUENCE {
        notBefore      Time,
        notAfter       Time
    }

    Time ::= CHOICE {
        -- utcTime        UTCTime,  -- Y2K problem … wtf?!?
        generalTime    GeneralizedTime
    }

    Extensions  ::=  SEQUENCE {
        extensions  ANY
    }
END

sub new {
    my ($class, %opts) = @_;

    my @missing = grep { !$opts{$_} } qw( subject key not_after );

    if (@missing) {
        die Crypt::Perl::X::create('Generic', "Missing: @missing");
    }

    $opts{'extensions'} &&= Crypt::Perl::X509::Extensions->new(@{ $opts{'extensions'} });

    my $subj = Crypt::Perl::X509::Name->new( @{ $opts{'subject'} } );

    my $issuer;
    if ($opts{'issuer'}) {
        $issuer = Crypt::Perl::X509::Name->new( @{ $opts{'issuer'} } );
    }
    else {
        $issuer = $subj;    #self-signed
    }

    $opts{'serial_number'} ||= 0;

    my %self = (
        _subject => $subj,
        _issuer => $issuer,
        _not_before => $opts{'not_before'} || time,

        ( map { ( "_$_" => $opts{$_} ) } qw(
            key
            not_after
            extensions
            serial_number
            subject_unique_id
            issuer_unique_id
        ) ),
    );

    return bless \%self, $class;
}

sub sign {
    my ($self, $signer_key, $digest_algorithm) = @_;

    my ( $tbs, $digest_length ) = $self->_encode_tbs_certificate($signer_key, $digest_algorithm);

    my ($sig_alg, $sig_func, $signature);

    if ($signer_key->isa('Crypt::Perl::ECDSA::PrivateKey')) {
        require Digest::SHA;

        $sig_alg = "ecdsa-with-SHA$digest_length";

        my $fn = "sign_sha$digest_length";

        $signature = $signer_key->$fn($tbs);
    }
    elsif ($signer_key->isa('Crypt::Perl::RSA::PrivateKey')) {
        require Digest::SHA;

        $sig_alg = "sha${digest_length}WithRSAEncryption";

        my $sign_cr = $signer_key->can("sign_RS$digest_length") or do {
            die "Unsupported digest for RSA: $digest_algorithm";
        };

        $signature = $sign_cr->($signer_key, $tbs);
    }
    elsif ($signer_key->isa('Crypt::Perl::Ed25519::PrivateKey')) {
        $sig_alg = 'ed25519';
        $signature = $signer_key->sign($tbs);
    }
    else {
        die "Key ($signer_key) is not a recognized private key object!";
    }

    $sig_alg = {
        algorithm => $Crypt::Perl::ASN1::Signatures::OID{$sig_alg},
    };

    $self->{'_signed'} = {
        tbsCertificate => $tbs,
        signatureAlgorithm  => $sig_alg,
        signature        => $signature,
    };

    return $self;
}

sub _get_digest_length {
    $_[0] =~ m<\Asha(224|256|384|512)\z> or do {
        die Crypt::Perl::X::create('Generic', "Unknown digest algorithm: “$_[0]”");
    };

    return $1;
}

sub _encode_params {
    my ($self) = @_;

    if (!$self->{'_signed'}) {
        die Crypt::Perl::X::create('Generic', 'Call sign() first!');
    }

    return $self->{'_signed'};
}

sub _encode_tbs_certificate {
    my ($self, $signing_key, $digest_algorithm) = @_;

    my $digest_length = $digest_algorithm && _get_digest_length($digest_algorithm);

    my $sig_alg;

    my $pubkey_der;

    if ($self->{'_key'}->isa('Crypt::Perl::ECDSA::PublicKey')) {
        $pubkey_der = $self->{'_key'}->to_der_with_curve_name();
        $sig_alg = "ecdsa-with-SHA$digest_length";
    }
    elsif ($self->{'_key'}->isa('Crypt::Perl::RSA::PublicKey')) {
        $pubkey_der = $self->{'_key'}->to_subject_der();
        $sig_alg = "sha${digest_length}WithRSAEncryption";
    }
    elsif ($self->{'_key'}->isa('Crypt::Perl::Ed25519::PublicKey')) {
        $sig_alg = 'ed25519';
        $pubkey_der = $self->{'_key'}->to_der();
    }
    else {
        die "Key ($self->{'_key'}) is not a recognized public key object!";
    }

    my $extns_bin;
    if ($self->{'_extensions'}) {
        $extns_bin = $self->{'_extensions'}->encode();
    }

    my $params_hr = {
        version => { version => 2 },

        serialNumber => $self->{'_serial_number'},

        issuerUniqueID => $self->{'_issuer_unique_id'},

        subjectUniqueID => $self->{'_subject_unique_id'},

        subject => $self->{'_subject'}->encode(),
        issuer => $self->{'_issuer'}->encode(),

        validity => {
            notBefore => { generalTime => $self->{'_not_before'} },
            notAfter => { generalTime => $self->{'_not_after'} },
        },

        subjectPublicKeyInfo => $pubkey_der,

        signature => {
            algorithm => $Crypt::Perl::ASN1::Signatures::OID{$sig_alg},
        },

        ( $extns_bin ? ( extensions => { extensions => $extns_bin } ) : () ),
    };

    my $asn1 = Crypt::Perl::ASN1->new()->prepare($self->ASN1());
    $asn1 = $asn1->find('TBSCertificate');
    $asn1->configure( encode => { time => 'utctime' } );

    return ( $asn1->encode($params_hr), $digest_length );
}

#sub _get_GeneralizedTime {
#    my ($epoch) = @_;
#
#    my @smhdmy = (gmtime $epoch)[0 .. 5];
#    $smhdmy[4]++;       #month
#    $smhdmy[5] += 1900; #year
#
#    return sprintf '%04d%02d%02d%02d%02d%02dZ', reverse @smhdmy;
#}

1;
