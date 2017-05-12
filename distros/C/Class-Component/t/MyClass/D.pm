package MyClass::D;

use strict;
use warnings;
use base qw/ MyClass::Component /;

sub test {
    my $self = shift;
    ' -> D ' . $self->NEXT('test');
}

1;
