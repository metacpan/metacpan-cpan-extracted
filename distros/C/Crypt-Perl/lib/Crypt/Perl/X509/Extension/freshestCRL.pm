package Crypt::Perl::X509::Extension::freshestCRL;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::freshestCRL

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.1.15>

=cut

use parent qw( Crypt::Perl::X509::Extension::cRLDistributionPoints );

use constant {
    OID => '2.5.29.46',
    CRITICAL => 0,
};

use constant ASN1 => Crypt::Perl::X509::Extension::cRLDistributionPoints::ASN1() . <<END;
    freshestCRL ::= cRLDistributionPoints
END

1;
