package Data::LUID::Generator::TUID;

use strict;
use warnings;

use Moose;
use Data::LUID::Carp;

use Data::TUID;

has length => qw/is ro isa Int required 1/, default => 6;

sub next {
    my $self = shift;
    return tuid length => $self->length;
}

1;
