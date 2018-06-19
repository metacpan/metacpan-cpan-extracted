package Crypt::Perl::X509::Extension::ct_precert_scts;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::ct_precert_scts - X.509 ct_precert_scts extension

=head1 SYNOPSIS

    my $extn = Crypt::Perl::X509::Extension::ct_precert_scts->new(
        {
            log_id => ..,
            timestamp => ..,
            extensions => [ .. ],
            signature_algorithm => '..',
        },
        # ..
    );

=head1 DESCRIPTION

Instances of this class represent a C<ct_precert_scts> extension
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

use Crypt::Perl::X509::SCT ();

use constant OID => '1.3.6.1.4.1.11129.2.4.2';

use constant ASN1 => <<END;
    ct_precert_scts ::= SignedCertificateTimestampList

    SignedCertificateTimestampList ::= OCTET STRING
END

sub new {
    my ($class, @sct_hrs) = @_;

    return bless \@sct_hrs, $class;
}

sub _encode_params {
    my ($self) = @_;

    my @scts = map { Crypt::Perl::X509::SCT::encode(%$_) } @$self;

    # Prefix with length.
    _tls_length_encode($_) for @scts;

    my $list = join( q<>, @scts );

    _tls_length_encode($list);
}

sub _tls_length_encode {
    substr( $_[0], 0, 0, pack('n', length $_[0]) );

    return $_[0];
}

1;
