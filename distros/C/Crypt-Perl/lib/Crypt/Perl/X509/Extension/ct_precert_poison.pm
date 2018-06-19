package Crypt::Perl::X509::Extension::ct_precert_poison;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::ct_precert_poison

=head1 SYNOPSIS

    my $extn = Crypt::Perl::X509::Extension::ct_precert_poison->new();

=head1 DESCRIPTION

Instances of this class represent a C<ct_precert_poison> extension
of an X.509 (SSL) certificate.

You probably don’t need to
instantiate this class directly; see L<Crypt::Perl::PKCS10>
and L<Crypt::Perl::X509> for the way this module is meant to be used.

=head1 SEE ALSO

=over

=item * L<https://tools.ietf.org/html/rfc6962#section-3.3>

=item * L<https://letsencrypt.org/2018/04/04/sct-encoding.html>

=back

=cut

use parent qw(
    Crypt::Perl::X509::Extension
);

use constant OID => '1.3.6.1.4.1.11129.2.4.3';

use constant ASN1 => <<END;
    ct_precert_poison ::= NULL
END

sub new { bless [] }

use constant CRITICAL => 1;

use constant _encode_params => ();

1;
