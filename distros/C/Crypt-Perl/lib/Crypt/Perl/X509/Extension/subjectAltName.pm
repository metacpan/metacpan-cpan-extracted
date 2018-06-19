package Crypt::Perl::X509::Extension::subjectAltName;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::subjectAltName - X.509 subjectAltName extension

=head1 SYNOPSIS

    my $san = Crypt::Perl::X509::Extension::subjectAltName->new(
        [ dNSName => 'foo.com' ],
        [ dNSName => 'bar.com' ],
        [ rfc822Name => 'haha@tld.com' ],
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

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.1.6>

=cut

use parent qw(
    Crypt::Perl::X509::Extension
    Crypt::Perl::X509::GeneralNames
);

use Crypt::Perl::X509::GeneralNames ();

use constant OID => '2.5.29.17';

use constant ASN1 => Crypt::Perl::X509::GeneralNames::ASN1() . <<END;
    subjectAltName ::= GeneralNames
END

1;
