package Class::Property::RW::Lazy;
use strict; use warnings FATAL => 'all'; 
use parent 'Class::Property::RW';

sub TIESCALAR
{
    my( $class, $field, $init, $flag_ref ) = @_;
    return bless {
        'field' => $field
        , 'init' => $init
        , 'flag_ref' => $flag_ref
    }, $class;
}

sub STORE
{
    my( $self, $value ) = @_;
    $self->{'object'}->{$self->{'field'}} = $value;
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

eval{    
    if( not defined $self->{'flag_ref'}->{$self->{'object'}} )
    {
        $self->{'flag_ref'}->{$self->{'object'}} = $self->{'object'};
        Scalar::Util::weaken($self->{'flag_ref'}->{$self->{'object'}});
        $self->{'object'}->{$self->{'field'}} = $self->{'init'}->($self->{'object'});
    }
};
if( $@ )
{
    use Data::Dumper;
    use Carp qw(confess);
    print Dumper($self);
    confess $@ if $@;
}
    
    return $self->{'object'}->{$self->{'field'}};
}

1;