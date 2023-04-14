package Catmandu::Fix::pica_tag;

use Catmandu::Sane;

our $VERSION = '1.13';

use Moo;
use Catmandu::Fix::Has;
use Scalar::Util 'reftype';

has tag => (
    fix_arg => 1,
    coerce  => sub {
        die "invalid tag: $_[0]\n" if $_[0] !~ qr/^[0-2]\d{2}[A-Z@]$/;
        $_[0];
    }
);

sub fix {
    my ( $self, $data ) = @_;

    if ( reftype $data->{record} eq 'ARRAY' ) {
        for ( @{ $data->{record} } ) {
            $_->[0] = $self->tag;
        }
    }

    return $data;
}

=head1 NAME

Catmandu::Fix::pica_tag - change tag of PICA+ field

=head1 SYNOPSIS

    # change every 012X field into 012Y
    do pica_each(012X)
      pica_tag(012Y)
    end

=head1 FUNCTIONS

=head2 pica_tag(TAG)

Set the PICA+ tag of every field.

=head2 SEE ALSO

L<Catmandu::Fix::pica_occurrence>

=cut

1;
