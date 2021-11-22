package Crypt::Perl::PK;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::PK - Public-key cryptography logic

=head1 SYNOPSIS

    #Will be an instance of the appropriate Crypt::Perl key class,
    #i.e., one of:
    #
    #   Crypt::Perl::RSA::PrivateKey
    #   Crypt::Perl::RSA::PublicKey
    #   Crypt::Perl::ECDSA::PrivateKey
    #   Crypt::Perl::ECDSA::PublicKey
    #   Crypt::Perl::Ed25519::PrivateKey
    #   Crypt::Perl::Ed25519::PublicKey
    #
    my $key_obj = Crypt::Perl::PK::parse_jwk( { .. } );

    #Likewise. Feed it public or private, DER or PEM format,
    #RSA or ECDSA.
    my $key_obj = Crypt::Perl::PK::parse_key( $octet_string );

=head1 DISCUSSION

As of now there’s not much of interest to find here except
parsing of L<JWK|https://tools.ietf.org/html/rfc7517>s.

=cut

use Try::Tiny;

use Module::Load ();

use Crypt::Perl::X ();

sub parse_key {
    my ($der_or_pem) = @_;

    if (ref $der_or_pem) {
        die Crypt::Perl::X::create('Generic', "Need unblessed octet string, not “$der_or_pem”!");
    }

    my $obj;

    for my $alg ( qw( RSA Ed25519 ECDSA ) ) {
        my $module = "Crypt::Perl::$alg\::Parse";
        Module::Load::load($module);

        try {
            $obj = $module->can('private')->($der_or_pem);
        }
        catch {
            try {
                $obj = $module->can('public')->($der_or_pem);
            }
        };

        return $obj if $obj;
    }

    die Crypt::Perl::X::create('Generic', "Unrecognized key: “$der_or_pem”");
}

sub parse_jwk {
    my ($hr) = @_;

    if ('HASH' ne ref $hr) {
        die( (caller 0)[3] . " needs a HASH reference, not $hr" );
    }

    my $kty = $hr->{'kty'};

    if ($kty) {
        my $module;

        if ($kty eq 'RSA') {
            $module = 'Crypt::Perl::RSA::Parse';

        }
        elsif ($kty eq 'OKP') {
            if ($hr->{'crv'} ne 'Ed25519') {
                die Crypt::Perl::X::create('Generic', "Unrecognized “crv” ($hr->{'crv'}) for key type “$kty”!");
            }

            $module = 'Crypt::Perl::Ed25519::Parse';
        }
        elsif ($kty eq 'EC') {
            $module = 'Crypt::Perl::ECDSA::Parse';
        }
        else {
            die Crypt::Perl::X::create('UnknownJWKkty', $kty);
        }

        Module::Load::load($module);

        return $module->can('jwk')->($hr);
    }

    die Crypt::Perl::X::create('InvalidJWK', %$hr);
}

1;
