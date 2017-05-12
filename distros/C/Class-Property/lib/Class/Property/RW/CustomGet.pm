package Class::Property::RW::CustomGet;
use strict; use warnings FATAL => 'all'; 
use parent 'Class::Property::RW';

sub TIESCALAR
{
    my( $class, $field, $getter ) = @_;
    return bless {
        'field' => $field
        , 'getter' => $getter
    }, $class;
}

sub FETCH
{
    my( $self ) = @_;
    return $self->{'getter'}->($self->{'object'});
}

1;