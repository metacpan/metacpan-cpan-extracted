package MyClass::Component::E;

use strict;
use warnings;
use base qw/ MyClass::F MyClass::Component /;

sub test {
    my $self = shift;
    ' -> E ' . $self->NEXT('test');
}

1;
