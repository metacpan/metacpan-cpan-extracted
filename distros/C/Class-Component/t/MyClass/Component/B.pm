package MyClass::Component::B;

use strict;
use warnings;
use base qw/ MyClass::D MyClass::Component /;

sub test {
    my $self = shift;
    ' -> B ' . $self->NEXT('test');
}

1;
