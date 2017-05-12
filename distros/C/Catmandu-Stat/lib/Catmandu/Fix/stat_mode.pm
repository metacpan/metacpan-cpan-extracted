package Catmandu::Fix::stat_mode;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use Statistics::Basic;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "${var} = '' . (Statistics::Basic::mode(${var})) if is_array_ref(${var});";
}

=head1 NAME

Catmandu::Fix::stat_mode - calculate the mode of an array

=head1 SYNOPSIS

   # Calculate the mode of foo. E.g. foo => [1,2,3,3,3,4]
   stat_mode(foo)  # foo => '3'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;