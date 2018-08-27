package Crypt::Perl::X509::Extension::acmeValidation_v1;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

=head1 SYNOPSIS

See L<Crypt::Perl::X509v3> for a more useful syntax for instantiating
this extension as part of certificate creation. The following is how
to instantiate it directly .. which isn’t very useful per se.

    my $extn = Crypt::Perl::X509::Extension::acmeValidation_v1->new(
        $string_of_32_octets,
    );

=head1 DESCRIPTION

This is the X.509 extension to use when creating validation certificates
for use with the experimental ACME TLS ALPN challenge, described at
L<https://datatracker.ietf.org/doc/draft-ietf-acme-tls-alpn/>.

=cut

use parent qw( Crypt::Perl::X509::Extension );

use constant {

    # https://www.ietf.org/rfc/rfc7299.txt
    # id-pkix = 1.3.6.1.5.5.7
    # id-pe = id-pkix 1
    # id-pe-acmeIdentifier = id-pe 31
    #
    OID => '1.3.6.1.5.5.7.1.31',

    CRITICAL => 1,

    # This results in an OCTET STRING that nests inside the extension’s
    # own OCTET STRING. That seems to be what ACME wants.
    ASN1 => 'acmeValidation_v1 ::= OCTET STRING',
};

my $str_len = 32;

sub new {
    my ($class, $octets) = @_;

    if ($str_len != length($octets)) {
        die sprintf( 'Must have %d bytes, not “%v.02x”!', $str_len, $octets );
    }

    return bless \$octets, $class
}

sub _encode_params {
    return ${ $_[0] };
}

1;
