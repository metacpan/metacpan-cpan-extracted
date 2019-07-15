package Algorithm::CP::IZ::NoGoodElement;

use strict;
use warnings;

sub index {
    my $self = shift;
    return $self->[0];
}

sub method {
    my $self = shift;
    return $self->[1];
}

sub value {
    my $self = shift;
    return $self->[2];
}

1;
