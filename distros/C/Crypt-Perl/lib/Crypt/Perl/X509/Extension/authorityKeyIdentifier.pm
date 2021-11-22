package Crypt::Perl::X509::Extension::authorityKeyIdentifier;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::authorityKeyIdentifier

=head1 SYNOPSIS

    my $usage_obj = Crypt::Perl::X509::Extension::authorityKeyIdentifier->new(
        keyIdentifier       => $key_id_octet_string,  #optional
        authorityCertIssuer => [ [ dNSName => '..' ], .. ],
        authorityCertSerialNumber => $auth_cert_serial_num
    );

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.1.1>

=cut

use parent qw( Crypt::Perl::X509::Extension );

use Crypt::Perl::X ();
use Crypt::Perl::X509::GeneralNames ();

use constant {
    OID => '2.5.29.35',
    CRITICAL => 0,
};

use constant ASN1 => Crypt::Perl::X509::GeneralNames::ASN1() . <<END;
    authorityKeyIdentifier ::= SEQUENCE {
        keyIdentifier             [0] OCTET STRING  OPTIONAL,
        -- authorityCertIssuer       [1] GeneralNames  OPTIONAL,
        authorityCertIssuer       ANY OPTIONAL,
        authorityCertSerialNumber [2] INTEGER       OPTIONAL
    }
END

my @_attrs = qw(
    keyIdentifier
    authorityCertIssuer
    authorityCertSerialNumber
);

sub new {
    my ($class, %attrs) = @_;

    if (!grep { defined } @attrs{ @_attrs }) {
        die Crypt::Perl::X::create('Generic', "Need one of: [@_attrs]");
    }

    return bless \%attrs, $class;
}

sub _encode_params {
    my ($self) = @_;

    my %params;

    for my $a ( @_attrs ) {
        next if !defined $self->{$a};
        $params{$a} = $self->{$a};
    }

    if ( $params{'authorityCertIssuer'} ) {
        #$params{'authorityCertIssuer'} = Crypt::Perl::X509::GeneralNames->new( @{ $params{'authorityCertIssuer'} } )->_encode_params(); #XXX FIXME

        $params{'authorityCertIssuer'} = Crypt::Perl::X509::GeneralNames->new( @{ $params{'authorityCertIssuer'} } )->encode();
        substr( $params{'authorityCertIssuer'}, 0, 1 ) = "\xa1";
    }

    return \%params;
}

1;
