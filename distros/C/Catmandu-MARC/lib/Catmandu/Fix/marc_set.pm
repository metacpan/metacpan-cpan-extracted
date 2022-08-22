package Catmandu::Fix::marc_set;

use Catmandu::Sane;
use Moo;
use Catmandu::MARC;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '1.281';

has marc_path      => (fix_arg => 1);
has value          => (fix_arg => 1);

sub fix {
    my ($self,$data) = @_;
    my $marc_path   = $self->marc_path;
    my $value       = $self->value;
    return Catmandu::MARC->instance->marc_set($data,$marc_path,$value);
}

=head1 NAME

Catmandu::Fix::marc_set - set a marc value of one (sub)field to a new value

=head1 SYNOPSIS

    # Set a field in the leader
    if marc_match('LDR/6','c')
        marc_set('LDR/6','p')
    end

    # Set a control field
    marc_set('001',1234)

    # Set all the 650-p fields to 'test'
    marc_set('650p','test')

    # Set the 100-a subfield where indicator-1 is 3
    marc_set('100[3]a','Farquhar family.')

    # Copy data from another field in a subfield
    marc_set('100a','$.my.deep.field')

=head1 DESCRIPTION

Set the value of a MARC subfield to a new value.

=head1 METHODS

=head2 marc_set(MARC_PATH , VALUE)

Set a MARC subfield to a particular new value. This value can be a literal or
reference an existing field in the record using the dollar JSON_PATH syntax.

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_set as => 'marc_set';

    my $data = { record => [...] };

    $data = marc_set($data, '245a', 'test');

=head1 SEE ALSO

L<Catmandu::Fix::marc_add>,
L<Catmandu::Fix::marc_copy>,
L<Catmandu::Fix::marc_cut>,
L<Catmandu::Fix::marc_paste>

=cut

1;
