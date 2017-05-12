package Catmandu::Fix::basename;
use Catmandu::Sane;
use Moo;
use File::Basename qw();
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;

    "${var} = File::Basename::basename(${var}) if is_string( ${var} );";
}

=head1 NAME

Catmandu::Fix::basename - get file basename

=head1 SYNOPSIS

add_field('path','/home/njfranck')

#'path' is now 'njfranck'

basename('path')

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
