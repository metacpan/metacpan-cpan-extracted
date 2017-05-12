package Catmandu::Fix::dirname;
use Catmandu::Sane;
use Moo;
use File::Basename qw();
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;

    "${var} = File::Basename::dirname(${var}) if is_string( ${var} );";
}

=head1 NAME

Catmandu::Fix::dirname - get file directory

=head1 SYNOPSIS

add_field('path','/home/njfranck')

#'path' is now '/home'

dirname('path')

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>


=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
