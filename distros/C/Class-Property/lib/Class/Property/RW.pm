package Class::Property::RW;
use strict; use warnings FATAL => 'all'; 
use Scalar::Util 'weaken';

#
# This package is prototype. It has no use by itself
#
sub TIESCALAR
{
    my( $class, $field ) = @_;
    return bless {
        'field' => $field
    }, $class;
}

sub STORE
{
    my $self = shift;
    $self->{'object'}->{$self->{'field'}} = shift;
    return;
}

sub FETCH
{
    my( $self ) = @_;
    return $self->{'object'}->{$self->{'field'}};
}

sub DESTROY
{
    my $self = shift;
    $self = undef;
    return;
}

sub set_object
{
    my $self = shift;
    $self->{'object'} = shift;
    weaken($self->{'object'});
}

1;