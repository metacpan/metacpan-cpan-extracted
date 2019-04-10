package Catmandu::Fix::marc_remove;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '1.251';

has marc_path => (fix_arg => 1);

sub fix {
    my ($self,$data) = @_;
    my $marc_path  = $self->marc_path;
    return Catmandu::MARC->instance->marc_remove($data, $marc_path);
}

=head1 NAME

Catmandu::Fix::marc_remove - remove marc (sub)fields

=head1 SYNOPSIS

    # remove all marc 600 fields
    marc_remove('600')

    # remove the 245-a subfield
    marc_remove('245a')

=head1 DESCRIPTION

Remove (sub)fields in a MARC record

=head1 METHODS

=head2 marc_remove(MARC_PATH)

Delete the (sub)fields from the MARC record as indicated by the MARC_PATH.

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_remove as => 'marc_remove';

    my $data = { record => [...] };

    $data = marc_remove($data,'600');

=head1 SEE ALSO

L<Catmandu::Fix::marc_add>,
L<Catmandu::Fix::marc_copy>,
L<Catmandu::Fix::marc_cut>,
L<Catmandu::Fix::marc_paste>,
L<Catmandu::Fix::marc_set>

=cut

1;
