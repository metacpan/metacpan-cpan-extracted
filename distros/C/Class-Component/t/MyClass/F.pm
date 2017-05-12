package MyClass::F;

use strict;
use warnings;
use base qw/ MyClass::C MyClass::Component /;

sub test {
    my $self = shift;
    ' -> F ' . $self->NEXT('test');
}

1;
