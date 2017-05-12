package Crypt::Perl::X509::Name;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Name - Representation of Distinguished Name

=head1 SYNOPSIS

    my $name = Crypt::Perl::X509::Name->new(

        #The keys are short OID names (e.g., C<postalCode>).
        streetAddress => '...',
        localityName => '...',

        #...
    );

    my $der = $name->encode();

=head1 DISCUSSION

This is useful to represent the Subject and Issuer parts of an
X.509 (i.e., SSL/TLS) certificate as well as the name portion of
a PCKS #10 Certificate Signing Request (CSR).

=head1 ABOUT C<commonName>

Note that C<commonName> is
deprecated (cf. L<RFC 6125 §2.3|https://tools.ietf.org/html/rfc6125#section-2.3>,
L<CA Browser Forum Baseline Requirements §7.1.4.2.2|https://cabforum.org/wp-content/uploads/CA-Browser-Forum-BR-1.4.1.pdf>) here, but many CAs still require it as of December 2016.

=cut

use parent qw( Crypt::Perl::ASN1::Encodee );

use constant ASN1 => <<END;
    Name ::= SEQUENCE OF RelativeDistinguishedName

    RelativeDistinguishedName ::= SET OF AttributeTypeAndValue

    AttributeTypeAndValue ::= SEQUENCE {
      type  OBJECT IDENTIFIER,
      value DirectoryString
    }

    DirectoryString ::= CHOICE {
      -- teletexString   TeletexString,
      -- printableString PrintableString,
      -- bmpString       BMPString,
      -- universalString UniversalString,
      utf8String      UTF8String,
      -- ia5String       IA5String,
      integer         INTEGER
    }
END

#Accessed from tests.
#Anything missing? Please let me know.
our %_OID = (
    emailAddress               => '1.2.840.113549.1.9.1',
    commonName                 => '2.5.4.3',
    surname                    => '2.5.4.4',
    countryName                => '2.5.4.6',
    localityName               => '2.5.4.7',
    stateOrProvinceName        => '2.5.4.8',
    streetAddress              => '2.5.4.9',
    organizationName           => '2.5.4.10',
    organizationalUnitName     => '2.5.4.11',
    title                      => '2.5.4.12',
    description                => '2.5.4.13',
    searchGuide                => '2.5.4.14',
    businessCategory           => '2.5.4.15',
    postalAddress              => '2.5.4.16',
    postalCode                 => '2.5.4.17',
    postOfficeBox              => '2.5.4.18',
    physicalDeliveryOfficeName => '2.5.4.19',
    telephoneNumber            => '2.5.4.20',
    facsimileTelephoneNumber   => '2.5.4.23',
    name                       => '2.5.4.41',
    givenName                  => '2.5.4.42',
    initials                   => '2.5.4.43',
    pseudonym                  => '2.5.4.65',
);

sub new {
    my ($class, @key_values) = @_;

    my @sequence;

    while ( my ($type, $val) = splice( @key_values, 0, 2 ) ) {
        my $oid = $_OID{$type} || do {
            die Crypt::Perl::X::create('Generic', "Unknown OID: “$type”");
        };

        push @sequence, [ { type => $oid, value => { utf8String => $val } } ];
    }

    return bless \@sequence, $class;
}

sub _encode_params {
    return [ @{ $_[0] } ];  #“de-bless”
}

1;
