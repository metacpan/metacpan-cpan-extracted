package Class::Property::RO::Lazy;
use strict; use warnings FATAL => 'all'; 
use parent 'Class::Property::RO';

sub TIESCALAR
{
    my( $class, $field, $init, $flag_ref ) = @_;
    return bless {
        'field' => $field
        , 'init' => $init
        , 'flag_ref' => $flag_ref
    }, $class;
}

sub FETCH
{
    my( $self ) = @_;
    
    if( not defined $self->{'flag_ref'}->{$self->{'object'}} )
    {
        $self->{'flag_ref'}->{$self->{'object'}} = $self->{'object'};
        Scalar::Util::weaken($self->{'flag_ref'}->{$self->{'object'}});
        $self->{'object'}->{$self->{'field'}} = $self->{'init'}->($self->{'object'});
    }
    
    return $self->{'object'}->{$self->{'field'}};
}

1;