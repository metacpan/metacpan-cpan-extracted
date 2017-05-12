
use strict;
use warnings;

package TCircle;

use Class::Trait 'base';

use Class::Trait qw(TMagnitude TGeometry);

our %OVERLOADS = (
    '<'  => "lessThan",
    '==' => "equalTo"
);

sub lessThan {
    my ( $left, $right ) = @_;

    # ...
}

sub equalTo {
    my ( $left, $right ) = @_;

    # ...
}

1;

__DATA__
