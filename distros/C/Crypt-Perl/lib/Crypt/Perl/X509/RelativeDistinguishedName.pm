package Crypt::Perl::X509::RelativeDistinguishedName;

use strict;
use warnings;

use parent qw( Crypt::Perl::ASN1::Encodee );

use constant ASN1 => <<END;
    RelativeDistinguishedName ::= SET OF AttributeTypeAndValue

    AttributeTypeAndValue ::= SEQUENCE {
      type  OBJECT IDENTIFIER,
      value DirectoryString
    }

    DirectoryString ::= CHOICE {
      -- teletexString   TeletexString,
      printableString PrintableString,
      -- bmpString       BMPString,
      -- universalString UniversalString,
      utf8String      UTF8String,
      ia5String       IA5String,
      integer         INTEGER   -- probably unused??
    }
END

#Accessed from tests.
#Anything missing? Please let me know.
use constant {
    Name_OID_emailAddress               => '1.2.840.113549.1.9.1',
    Name_OID_commonName                 => '2.5.4.3',
    Name_OID_surname                    => '2.5.4.4',
    Name_OID_serialNumber               => '2.5.4.5',
    Name_OID_countryName                => '2.5.4.6',
    Name_OID_localityName               => '2.5.4.7',
    Name_OID_stateOrProvinceName        => '2.5.4.8',
    Name_OID_streetAddress              => '2.5.4.9',
    Name_OID_organizationName           => '2.5.4.10',
    Name_OID_organizationalUnitName     => '2.5.4.11',
    Name_OID_title                      => '2.5.4.12',
    Name_OID_description                => '2.5.4.13',
    Name_OID_searchGuide                => '2.5.4.14',
    Name_OID_businessCategory           => '2.5.4.15',
    Name_OID_postalAddress              => '2.5.4.16',
    Name_OID_postalCode                 => '2.5.4.17',
    Name_OID_postOfficeBox              => '2.5.4.18',
    Name_OID_physicalDeliveryOfficeName => '2.5.4.19',
    Name_OID_telephoneNumber            => '2.5.4.20',
    Name_OID_facsimileTelephoneNumber   => '2.5.4.23',
    Name_OID_name                       => '2.5.4.41',
    Name_OID_givenName                  => '2.5.4.42',
    Name_OID_initials                   => '2.5.4.43',
    Name_OID_generationQualifier        => '2.5.4.44',
    Name_OID_dnQualifier                => '2.5.4.46',
    Name_OID_pseudonym                  => '2.5.4.65',
};

#cf. RFC 5280, around p. 114
my %_type = (
    dnQualifier => 'printableString',
    countryName =>  'printableString',
    serialNumber => 'printableString',
    emailAddress => 'ia5String',
);

sub get_OID {
    my ($type) = @_;
    my $oid = __PACKAGE__->can("Name_OID_$type") || do {
        die "Unknown OID: “$type”";
    };

    return $oid->();
}

#static function
sub encode_string {
    my ($type, $value) = @_;

    $type = _string_type($type);

    return Crypt::Perl::ASN1->new()->prepare( ASN1() )->find('DirectoryString')->encode( { $type => $value } );
}

sub _string_type {
    my ($attr_type) = @_;

    return $_type{$attr_type} || 'utf8String'
}

sub new {
    my ($class, @key_values) = @_;

    my @set;

    while ( my ($type, $val) = splice( @key_values, 0, 2 ) ) {
        my $oid = get_OID($type);

        my $type = _string_type($type);

        push @set, { type => $oid, value => { $type => $val } };
    }

    return bless \@set, $class;
}

sub _encode_params {
    return [ @{ $_[0] } ];  #“de-bless”
}

1;
