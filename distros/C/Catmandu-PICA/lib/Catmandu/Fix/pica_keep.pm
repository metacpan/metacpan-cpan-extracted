package Catmandu::Fix::pica_keep;

use Catmandu::Sane;

our $VERSION = '1.18';

use Moo;
use Catmandu::Fix::Has;
use PICA::Data qw(pica_path pica_fields);
use Scalar::Util 'reftype';

has pathes => (
    fix_arg => 'collect',
    coerce  => sub {
        [ map { pica_path($_) } map { split /\s*,\s*/ } @{ $_[0] } ]
    }
);

sub fix {
    my ( $self, $data ) = @_;
    if ( reftype( $data->{record} ) eq 'ARRAY' ) {
        $data->{record} = pica_fields( $data, @{ $self->pathes } );
    }
    return $data;
}

=head1 NAME

Catmandu::Fix::pica_keep - reduce PICA record to selected fields

=head1 SYNOPSIS

    # keep level 0 fields
    pica_keep('0.../*')

    # keep two specific fields only
    pica_keep(003@,021A)    # pathes can passed as multiple arguments
    pica_keep("003@,021A")  # equivalent: one argument with multiple pathes

=head1 FUNCTIONS

=head2 pica_keep(PATH,PATH...)

Reduce PICA record to fields referenced by L<PICA Path expressions|https://format.gbv.de/query/picapath>.
Multiple expressions can be separated by C<,> and optional space or given as multiple arguments.
Path expressions should not contain subfields.

=head2 SEE ALSO

Function C<pica_fields> of L<PICA::Data>, L<PICA::Path>, L<Catmandu::Fix::pica_remove>.

=cut

1;
