package Crypt::Perl::X509::Extension::authorityInfoAccess;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::authorityInfoAccess

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.2.1>

=cut

use parent qw( Crypt::Perl::X509::InfoAccessBase );

use constant {
    OID => '1.3.6.1.5.5.7.1.1',
    OID_ocsp => '1.3.6.1.5.5.7.48.1',
    OID_caIssuers => '1.3.6.1.5.5.7.48.2',
};

1;
