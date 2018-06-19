package Crypt::Perl::X509::Name;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Name - Representation of Distinguished Name

=head1 SYNOPSIS

    #This encodes each key/value into separate
    #RelativeDistinguishedName structures, as OpenSSL does by default.
    #Unless you know otherwise, this is probably what you want.
    #(See ENCODING below for more details.)
    my $name = Crypt::Perl::X509::Name->new(
        streetAddress => '...',     #keys are short OID names
        localityName => '...',
        #...
    );

    my $der = $name->encode();

=head1 DISCUSSION

This is useful to represent the Subject and Issuer parts of an
X.509 (i.e., SSL/TLS) certificate as well as the name portion of
a PCKS #10 Certificate Signing Request (CSR).

=head1 ENCODING

L<RFC 5280 §4.1.2.4|https://tools.ietf.org/html/rfc5280#section-4.1.2.4>
defines the C<Name> type as an ordered C<SEQUENCE> of unordered C<SET>s
—C<RelativeDistinguishedName> objects, or “RDN”s—of key/value pairs.
OpenSSL defaults to having each RDN contain only one key/value
pair. (L<You can also have it create “multi-value RDNs”.|http://openssl.6102.n7.nabble.com/Multi-value-RDNs-and-openssl-cnf-format-td7925.html>) I’m unclear as to why this is,
but I suspect it has to do with ease of matching up C<Name> values; since
the RDNs are unordered, to compare one multi-value RDN against another takes
more work than to compare two ordered lists of single-value RDNs, which can be
done with a simple text equality check.
(cf. L<RFC 5280 §7.1|http://tools.ietf.org/html/rfc5280#section-7.1>)

If you need a multi-value RDN, it can be gotten by grouping key/value pairs
in an array reference, thus:

    my $name = Crypt::Perl::X509::Name->new(

        #a multi-value RDN
        [ streetAddress => '...', localityName => '...' ],

        #regular key/value pair becomes its own single-value RDN
        stateOrProvinceName => '...',
    );

=head1 ABOUT C<commonName>

Note that C<commonName> is
deprecated (cf. L<RFC 6125 §2.3|https://tools.ietf.org/html/rfc6125#section-2.3>,
L<CA Browser Forum Baseline Requirements §7.1.4.2.2|https://cabforum.org/wp-content/uploads/CA-Browser-Forum-BR-1.4.1.pdf>)
for use in X.509 certificates, but many CAs still require it as of
December 2016.

=cut

use parent qw( Crypt::Perl::ASN1::Encodee );

use Crypt::Perl::ASN1 ();
use Crypt::Perl::X509::RelativeDistinguishedName ();

use constant ASN1 => Crypt::Perl::X509::RelativeDistinguishedName::ASN1() . <<END;
    RDNSequence ::= SEQUENCE OF ANY -- RelativeDistinguishedName

    Name ::= CHOICE {
        rdnSequence RDNSequence
    }
END

#XXX TODO de-duplicate
*get_OID = \&Crypt::Perl::X509::RelativeDistinguishedName::get_OID;
*encode_string = \&Crypt::Perl::X509::RelativeDistinguishedName::encode_string;

sub new {
    my ($class, @inputs) = @_;

    my @seq;

    while (@inputs) {
        if (my $ref = ref $inputs[0]) {
            my $input = shift @inputs;
            die "Invalid RDN ref: $ref" if $ref ne 'ARRAY';
            push @seq, Crypt::Perl::X509::RelativeDistinguishedName->new( @$input )->encode();
        }

        #Legacy-ish …
        else {
            my ($k, $v) = splice( @inputs, 0, 2 );
            my $rdn = Crypt::Perl::X509::RelativeDistinguishedName->new( $k, $v )->encode();
            push @seq, $rdn;
        }
    }

    return bless \@seq, $class;
}

sub _encode_params {
    return { rdnSequence => [ @{ $_[0] } ] };
}

1;
