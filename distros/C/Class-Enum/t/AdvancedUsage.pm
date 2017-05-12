package t::AdvancedUsage;
use strict;
use warnings;

use Class::Enum (
    Left  => { delta => -1 },
    Right => { delta =>  1 },
);

sub move {
    my ($self, $pos) = @_;
    return $pos + $self->delta;
}

1;
