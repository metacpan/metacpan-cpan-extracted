package Catmandu::Fix::marc_sort;

use Catmandu::Sane;
use Moo;
use Catmandu::MARC;

our $VERSION = '1.254';

sub fix {
    my ( $self, $data ) = @_;
    return Catmandu::MARC->instance->marc_sort($data);
}

=head1 NAME

Catmandu::Fix::marc_sort - sort MARC record fields by tag

=head1 SYNOPSIS

    # Sort MARC record fields by tag
    marc_sort()

=head1 DESCRIPTION

Sort MARC record fields by tag.

=head1 METHODS

=head2 marc_sort()

If you added new fields to a MARC record with L<Catmandu::Fix::marc_add> or L<Catmandu::Fix::marc_paste>, use I<marc_sort> to sort them by tag.

=head1 SEE ALSO

L<Catmandu::Fix::marc_add>,
L<Catmandu::Fix::marc_copy>,
L<Catmandu::Fix::marc_cut>,
L<Catmandu::Fix::marc_paste>

=cut

1;
