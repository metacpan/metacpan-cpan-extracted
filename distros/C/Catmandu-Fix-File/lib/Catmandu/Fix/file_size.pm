package Catmandu::Fix::file_size;
use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "${var} = is_string(${var}) && -f ${var} ? (-s ${var}) : 0;";
}
=head1 NAME

Catmandu::Fix::file_size - get file size

=head1 SYNOPSIS

add_field('path','/home/njfranck/test.txt')

#'path' is now the file size of file /home/njfranck/test.txt

file_size('path')

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
