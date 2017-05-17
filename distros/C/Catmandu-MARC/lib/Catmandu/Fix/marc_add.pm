package Catmandu::Fix::marc_add;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '1.11';

has marc_path   => (fix_arg => 1);
has subfields   => (fix_arg => 'collect');

sub fix {
    my ($self, $data) = @_;
    my $marc_path  = $self->marc_path;
    my @subfields  = @{$self->subfields};

    return Catmandu::MARC->instance->marc_add($data,$marc_path,@subfields);
}

=head1 NAME

Catmandu::Fix::marc_add - add new fields to marc

=head1 SYNOPSIS

    # Set literal values
    marc_add('900', a, 'test' , 'b', test)
    marc_add('900', ind1 , ' ' , a, 'test' , 'b', test)
    marc_add('900', ind1 , ' ' , a, 'test' , 'b', test , record:record2)

    # Copy data from an other field (when the field value is an array, the
    # subfield will be repeated)
    marc_add('900', a, '$.my.data.field')

=head1 DESCRIPTION

Add a new subfield to MARC record.

=head1 METHODS

=head2 marc_add(MARC_FIELD, SUBFIELD, VALUE, [ SUBFIELD, VALUE , ... ])

Add new subfields to a MARC record. The MARC_FIELD should contain a marc field
name, all other arguments contain the subfields to be added.

By default literal values will be added. To point to an existing value in
a record use the JSON_PATH syntax with a dollar '$.' added in front.

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_add as => 'marc_add';

    my $data = { record => [...] };

    $data = marc_add($data,'245','a','title');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
