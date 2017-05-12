package Class::Property::RO::CustomGet;
use strict; use warnings FATAL => 'all'; 
use parent 'Class::Property::RO';

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
    my $self = shift;
    return $self->{'getter'}->($self->{'object'});
}

1;