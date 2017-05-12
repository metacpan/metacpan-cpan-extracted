package Crypt::Perl::X509::Extension::subjectAltName;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::subjectAltName - X.509 subjectAltName extension

=head1 SYNOPSIS

    my $san = Crypt::Perl::X509::Extension::subjectAltName->new(
        dNSName => 'foo.com',
        dNSName => 'bar.com',
        rfc822Name => 'haha@tld.com',
    );

=head1 DESCRIPTION

Instances of this class represent a C<subjectAltName> extension
of an X.509 (SSL) certificate.

You probably don’t need to
instantiate this class directly; instead, you can instantiate it
implicitly by listing out arguments to
L<Crypt::Perl::PKCS10>’s constructor. See that module’s
L<SYNOPSIS|Crypt::Perl::PKCS10/SYNOPSIS> for an example.

You can also use instances of this class as arguments to
L<Crypt::Perl::PKCS10::Attribute::extensionRequest>’s constructor
to include a request for a C<subjectAltName> extension in a PKCS #10
Certificate Signing Request.

=cut

use parent qw( Crypt::Perl::X509::Extension );

use constant OID => '2.5.29.17';

use constant ASN1 => <<END;
    AnotherName ::= SEQUENCE {
         type           OBJECT IDENTIFIER,
         value      [0] EXPLICIT ANY
    }

    Name ::= SEQUENCE OF RelativeDistinguishedName
    RelativeDistinguishedName ::= SET OF AttributeTypeAndValue
    AttributeTypeAndValue ::= SEQUENCE {
      type  OBJECT IDENTIFIER,
      value DirectoryString}

    DirectoryString ::= CHOICE {
      teletexString   TeletexString,
      printableString PrintableString,
      bmpString       BMPString,
      universalString UniversalString,
      utf8String      UTF8String,
      ia5String       IA5String,
      integer         INTEGER}

    EDIPartyName ::= SEQUENCE {
         nameAssigner            [0]     DirectoryString OPTIONAL,
         partyName               [1]     DirectoryString }

    GeneralName ::= CHOICE {
         otherName                       [0]     AnotherName,
         rfc822Name                      [1]     IA5String,
         dNSName                         [2]     IA5String,
         x400Address                     [3]     ANY, --ORAddress,
         directoryName                   [4]     Name,
         ediPartyName                    [5]     EDIPartyName,
         uniformResourceIdentifier       [6]     IA5String,
         iPAddress                       [7]     OCTET STRING,
         registeredID                    [8]     OBJECT IDENTIFIER
    }

    subjectAltName ::= SEQUENCE OF GeneralName
END

use Crypt::Perl::ASN1 ();
use Crypt::Perl::PKCS10::ASN1 ();

sub new {
    my ($class, @type_vals) = @_;

    my @sequence;

    while ( my ($type, $val) = splice( @type_vals, 0, 2 ) ) {
        push @sequence, { $type => $val };
    }

    return bless \@sequence, $class;
}

sub _encode_params {
    return [ @{ $_[0] } ];  #“de-bless”
}

1;
