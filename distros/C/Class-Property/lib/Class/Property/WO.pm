package Class::Property::WO;
use strict; use warnings FATAL => 'all'; 
use parent 'Class::Property::RW';
use Carp;

sub FETCH
{
    my( $self ) = @_;
    croak sprintf(
        'Unable to read write-only property %s'
        , $self->{'field'}
    );
}

1;