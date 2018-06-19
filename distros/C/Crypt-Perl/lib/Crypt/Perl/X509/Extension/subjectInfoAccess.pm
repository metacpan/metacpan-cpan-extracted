package Crypt::Perl::X509::Extension::subjectInfoAccess;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::subjectInfoAccess

=head1 SYNOPSIS

    my $usage_obj = Crypt::Perl::X509::Extension::subjectInfoAccess->new(
    );

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.2.2>

=cut

use parent qw( Crypt::Perl::X509::InfoAccessBase );

use constant {
    OID => '1.3.6.1.5.5.7.1.11',
    OID_caRepository => '1.3.6.1.5.5.7.48.5',
    OID_timeStamping => '1.3.6.1.5.5.7.48.3',
};

1;
