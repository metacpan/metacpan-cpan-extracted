package Class::Property::WO::CustomSet;
use strict; use warnings FATAL => 'all'; 
use parent 'Class::Property::WO';

sub TIESCALAR
{
    my( $class, $field, $setter ) = @_;
    return bless {
        'field' => $field
        , 'setter' => $setter
    }, $class;
}

sub STORE
{
    my( $self, $value ) = @_;
    $self->{'setter'}->($self->{'object'}, $value);
    return;
}

1;