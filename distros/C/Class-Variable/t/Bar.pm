package Bar;
use strict;use warnings;
use parent 'Foo';
use Class::Variable;

public 'public2';
protected 'protected2';
private 'private2';

sub get_protected_bar
{
    return shift->protected2;
}
sub set_protected_bar
{
    my( $self, $value) = @_;
    $self->protected2 = $value;
}

sub get_private_bar
{
    return shift->private2;
}
sub set_private_bar
{
    my( $self, $value) = @_;
    $self->private2 = $value;
}

sub get_protected_foo_bar
{
    return shift->protected1;
}
sub set_protected_foo_bar
{
    my( $self, $value) = @_;
    $self->protected1 = $value;
}

sub get_private_foo_bar
{
    return shift->private1;
}
sub set_private_foo_bar
{
    my( $self, $value) = @_;
    $self->private1 = $value;
}


1;