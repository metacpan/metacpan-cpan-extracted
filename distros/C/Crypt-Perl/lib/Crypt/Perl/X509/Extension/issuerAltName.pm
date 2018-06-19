package Crypt::Perl::X509::Extension::issuerAltName;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::issuerAltName - X.509 issuerAltName extension

=head1 SYNOPSIS

    my $san = Crypt::Perl::X509::Extension::issuerAltName->new(
        [ dNSName => 'foo.com' ],
        [ dNSName => 'bar.com' ],
        [ rfc822Name => 'haha@tld.com' ],
    );

=head1 SEE ALSO

=cut

use parent qw(
    Crypt::Perl::X509::Extension
    Crypt::Perl::X509::GeneralNames
);

use Crypt::Perl::X509::GeneralNames ();

use constant OID => '2.5.29.18';

use constant ASN1 => Crypt::Perl::X509::GeneralNames::ASN1() . <<END;
    issuerAltName ::= GeneralNames
END

1;
