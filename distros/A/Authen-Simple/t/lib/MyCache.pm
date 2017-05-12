package MyCache;

use strict;
use warnings;

sub new {
    my $class = shift;
    return bless( {}, $class );
}

sub get {
    my ( $self, $key ) = @_;
    return $self->{$key};
}

sub set {
    my ( $self, $key, $value ) = @_;
    return $self->{$key} = $value;
}

sub clear {
    my $self = shift;
    %{$self} = ();
}

sub hash {
    my $self = shift;
    return ( wantarray ) ? %{$self} : $self;
}

1;
