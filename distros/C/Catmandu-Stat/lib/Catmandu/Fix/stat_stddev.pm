package Catmandu::Fix::stat_stddev;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use Statistics::Basic;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "${var} = Statistics::Basic::stddev(${var}) if is_array_ref(${var});";
}

=head1 NAME

Catmandu::Fix::stat_mean - calculate the standard deviation of an array

=head1 SYNOPSIS

   # Calculate the standard deviation of foo. E.g. foo => [1,2,3,4]
   stat_stddev(foo)  # foo => '1.12'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;