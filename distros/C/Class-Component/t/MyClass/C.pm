package MyClass::C;

use strict;
use warnings;
use base qw/ MyClass::Component /;

sub test {
    my $self = shift;
    ' -> C ' . $self->NEXT('test');
}

1;
