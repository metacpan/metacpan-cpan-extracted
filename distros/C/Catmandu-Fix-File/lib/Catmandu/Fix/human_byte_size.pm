package Catmandu::Fix::human_byte_size;
use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use Catmandu::Util qw();

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;

    "${var} = Catmandu::Util::human_byte_size(${var}) if is_string( ${var} );";
}
=head1 NAME

Catmandu::Fix::human_byte_size - convert from size in bytes to human readable form

=head1 SYNOPSIS

#size in bytes

add_field('size',1024)

#size converted to '1KB'

human_byte_size('size')

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
