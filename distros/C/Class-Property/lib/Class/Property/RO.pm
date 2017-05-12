package Class::Property::RO;
use strict; use warnings FATAL => 'all'; 
use parent 'Class::Property::RW';
use Carp;

sub STORE
{
    my( $self, $value ) = @_;
    croak sprintf(
        'Unable to set read-only property %s'
        , $self->{'field'}
    );
}

1;