package MyClass::Component::A;

use strict;
use warnings;
use base qw/ MyClass::C MyClass::Component /;

sub test {
    my $self = shift;
    ' -> A ' . $self->NEXT('test');
}

1;
