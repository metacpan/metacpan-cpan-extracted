package Catmandu::Fix::pica_occurrence;

use Catmandu::Sane;

our $VERSION = '1.14';

use Moo;
use Catmandu::Fix::Has;
use Scalar::Util 'reftype';

has occurrence => (
    fix_arg => 1,
    coerce  => sub {
        die "invalid occurrence: $_[0]\n" if $_[0] !~ qr/^[0-9]*$/;
        return $_[0] > 0 ? sprintf( "%02d", $_[0] ) : "";
    }
);

sub fix {
    my ( $self, $data ) = @_;

    if ( reftype( $data->{record} ) eq 'ARRAY' ) {
        for ( @{ $data->{record} } ) {
            $_->[1] = $self->occurrence;
        }
    }

    return $data;
}

=head1 NAME

Catmandu::Fix::pica_occurrence - change occurrence of PICA+ field

=head1 SYNOPSIS

    # remove occurrence of 012X fields
    do pica_each(012X/*)
      pica_occurrence(0)
    end

=head1 FUNCTIONS

=head2 pica_occurrence(OCCURRENCE)

Set the PICA+ occurrence of every field. Only occurrences C<00> (no occurrence) to C<99> are supported.

=head2 SEE ALSO

L<Catmandu::Fix::pica_tag>

=cut

1;
