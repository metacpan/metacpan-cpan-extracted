package Class::Property::RW::Lazy::CustomSet;
use strict; use warnings FATAL => 'all'; 
use parent 'Class::Property::RW';

sub TIESCALAR
{
    my( $class, $field, $init, $setter, $flag_ref ) = @_;
    return bless {
        'field' => $field
        , 'init' => $init
        , 'setter' => $setter
        , 'flag_ref' => $flag_ref
    }, $class;
}

sub STORE
{
    my( $self, $value ) = @_;
    $self->{'setter'}->($self->{'object'}, $value );
    if( not defined $self->{'flag_ref'}->{$self->{'object'}} )
    {
        $self->{'flag_ref'}->{$self->{'object'}} = $self->{'object'};
        Scalar::Util::weaken($self->{'flag_ref'}->{$self->{'object'}});
    }
    return;
}

sub FETCH
{
    my( $self ) = @_;
    
    if( not defined $self->{'flag_ref'}->{$self->{'object'}} )
    {
        $self->{'flag_ref'}->{$self->{'object'}} = $self->{'object'};
        Scalar::Util::weaken($self->{'flag_ref'}->{$self->{'object'}});
        $self->{'setter'}->($self->{'object'}, $self->{'init'}->($self->{'object'}));
    }
    
    return $self->{'object'}->{$self->{'field'}};
}

1;