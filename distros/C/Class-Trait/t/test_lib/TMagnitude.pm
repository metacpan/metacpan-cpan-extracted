
use strict;
use warnings;

package TMagnitude;

use Class::Trait 'base';

use Class::Trait ("TEquality");

our %OVERLOADS = (
    '<'  => "lessThan",
    '<=' => "lessThanOrEqualTo",
    '>'  => "greaterThan",
    '>=' => "greaterThanOrEqualTo",
);

our @REQUIRES = qw(
    lessThan
    equalTo
);

sub lessThanOrEqualTo {
    my ( $left, $right ) = @_;
    return ( $left->lessThan($right) || $left->equalTo($right) );
}

sub greaterThan {
    my ( $left, $right ) = @_;
    return ( $right->isLessThan($left) );
}

sub greaterThanOrEqualTo {
    my ( $left, $right ) = @_;
    return ( $right->isLessThanOrEqualTo($left) );
}

sub isBetween {
    my ( $self, $left, $right ) = @_;
    return ( $self->greaterThanOrEqualTo($left)
          && $self->lessThanOrEqualTo($right) );
}

1;

__DATA__
