package Catmandu::Fix::marc_append;

use Catmandu::Sane;
use Moo;
use Catmandu::MARC;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '1.171';

has marc_path      => (fix_arg => 1);
has value          => (fix_arg => 1);

sub fix {
    my ($self,$data) = @_;
    my $marc_path   = $self->marc_path;
    my $value       = $self->value;
    return Catmandu::MARC->instance->marc_append($data,$marc_path,$value);
}

=head1 NAME

Catmandu::Fix::marc_append - add a value at the end of a MARC field

=head1 SYNOPSIS

    # Append a period at the end of the 100 field
    marc_append(100,".")

=head1 DESCRIPTION

Append a value at the end of a MARC (sub)field

=head1 METHODS

=head2 marc_append(MARC_PATH ,  VALUE)

For each (sub)field matching the MARC_PATH append the VALUE to the last subfield.
This value can be a literal or reference an existing field in the record using the
dollar JSON_PATH syntax.

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_replace_all as => 'marc_replace_all';

    my $data = { record => [...] };

    $data = marc_replace_all($data, '245a', 'test' , 'rest');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
