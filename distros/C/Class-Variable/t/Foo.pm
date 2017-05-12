package Foo;
use strict;use warnings;
use Class::Variable;

sub new{return bless {}, shift;}

public 'public1';
protected 'protected1';
private 'private1';

sub get_protected_foo
{
    return shift->protected1;
}
sub set_protected_foo
{
    my( $self, $value) = @_;
    $self->protected1 = $value;
}

sub get_private_foo
{
    return my $var = shift->private1;
}
sub set_private_foo
{
    my( $self, $value) = @_;
    $self->private1 = $value;
}

sub benchmark
{
    my $self = shift;
    require Benchmark;
    Benchmark->import(':all');
    
    my $var = 100;
    timethese( 1000000, {
        '1. Direct write    ' => sub{ $self->{'var'} = $var; },
        '2. Direct read     ' => sub{ $var = $self->{'var'}; },
        '3. Public write    ' => sub{ $self->public1 = $var; },
        '4. Public read     ' => sub{ $var = $self->public1; },
        '5. Protected write ' => sub{ $self->protected1 = $var; },
        '6. Protected read  ' => sub{ $var = $self->protected1; },
        '7. Private write   ' => sub{ $self->private1 = $var; },
        '8. Private read    ' => sub{ $var = $self->private1; },
    });
}

1;
