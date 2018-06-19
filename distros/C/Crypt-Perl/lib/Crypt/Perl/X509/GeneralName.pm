package Crypt::Perl::X509::GeneralName;

use strict;
use warnings;

use Crypt::Perl::X509::Name ();

use parent qw( Crypt::Perl::ASN1::Encodee );

use constant ASN1 => Crypt::Perl::X509::Name::ASN1() . <<END;
    AnotherName ::= SEQUENCE {
         type           OBJECT IDENTIFIER,
         value      [0] EXPLICIT ANY
    }

    EDIPartyName ::= SEQUENCE {
         nameAssigner            [0]     DirectoryString OPTIONAL,
         partyName               [1]     DirectoryString
    }

    -- No support for “compound” values until there’s a use case
    -- that can verify functionality. (OpenSSL’s parse doesn’t know
    -- what to do with the compound values as of 1.0.1j.)
    GeneralName ::= CHOICE {
         -- otherName                       [0]     AnotherName,
         rfc822Name                      [1]     IA5String,
         dNSName                         [2]     IA5String,
         -- x400Address                     [3]     ORAddress,
         directoryName                   [4] EXPLICIT ANY,

         -- I’ve not figured out how to get OpenSSL to create this,
         -- and OpenSSL 1.0.1j doesn’t parse output from the below correctly.
         -- ediPartyName                    [5] EDIPartyName,

         uniformResourceIdentifier       [6]     IA5String,
         iPAddress                       [7]     OCTET STRING,
         registeredID                    [8]     OBJECT IDENTIFIER
    }
END

sub new {
    my ($class, $type, $value) = @_;

    if ($type eq 'otherName') {
        $value = {
            type => $value->[0],
            value => $value->[1],
        };
    }
    elsif ($type eq 'directoryName') {
        $value = Crypt::Perl::X509::Name->new(@$value)->encode();
        #substr( $value, 0, 1 ) = "\xa4";
    }
    elsif ($type eq 'ediPartyName') {
        $value = { %$value };
        $_ = { utf8String => $_ } for values %$value;
    }

    return bless [ $type => $value ], $class;
}

sub _encode_params {
    my ($self) = @_;

    return { @$self };  #“de-bless”
}

1;
