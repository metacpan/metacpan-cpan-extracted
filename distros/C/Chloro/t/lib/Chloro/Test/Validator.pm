package Chloro::Test::Validator;

use Moose;
use Chloro;

use Chloro::Types qw( Int );

field min => (
    isa      => Int,
    required => 1,
);

field max => (
    isa       => Int,
    required  => 1,
    validator => '_max_greater_than_min',
);

sub _max_greater_than_min {
    my $self   = shift;
    my $value  = shift;
    my $params = shift;
    my $field  = shift;

    return if $value > $params->{min};

    return 'The max value must be greater than the min value.';
}

__PACKAGE__->meta()->make_immutable;

1;
