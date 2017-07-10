package Catmandu::Fix::marc_replace_all;

use Catmandu::Sane;
use Moo;
use Catmandu::MARC;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '1.161';

has marc_path      => (fix_arg => 1);
has regex          => (fix_arg => 1);
has value          => (fix_arg => 1);

sub fix {
    my ($self,$data) = @_;
    my $marc_path   = $self->marc_path;
    my $regex       = $self->regex;
    my $value       = $self->value;
    return Catmandu::MARC->instance->marc_replace_all($data,$marc_path,$regex,$value);
}

=head1 NAME

Catmandu::Fix::marc_replace_all - regex replace (sub)field values in a MARC file

=head1 SYNOPSIS

    # Append to all the 650-p values the string "xyz"
    marc_replace_all('650p','$','xyz')

    # Replace all 'Joe'-s in 100a to 'Joey'
    marc_replace_all('100a','\bJoe\b','Joey')

    # Replace all 'Joe'-s in 100a to the value in field x.y.z
    marc_replace_all('100a','\bJoe\b',$.x.y.z)

    # Replace all the content of 100a with everything in curly brackets
    marc_replace_all('100a','^(.*)$','{$1}')

=head1 DESCRIPTION

Use regex search and replace on MARC field values.

=head1 METHODS

=head2 marc_replace_all(MARC_PATH , REGEX, VALUE)

For each (sub)field matching the MARC_PATH replace the pattern found by REGEX to
a new VALUE. This value can be a literal or
reference an existing field in the record using the dollar JSON_PATH syntax.

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_replace_all as => 'marc_replace_all';

    my $data = { record => [...] };

    $data = marc_replace_all($data, '245a', 'test' , 'rest');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
