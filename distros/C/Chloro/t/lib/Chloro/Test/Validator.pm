package Chloro::Test::Validator;

use Moose;
use namespace::autoclean;

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

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _max_greater_than_min {
    my $self   = shift;
    my $value  = shift;
    my $params = shift;

    return if $value > $params->{min};

    return 'The max value must be greater than the min value.';
}
## use critic

__PACKAGE__->meta()->make_immutable;

1;
