package Data::ObjectStore::Cache;

use strict;
use warnings;

sub new {
    my( $cls, $size ) = @_;
    return bless [ $size, {}, {} ], $cls;
}

sub empty {
    my $self = shift;
    $self->[1] = {};
    $self->[2] = {};
}

sub fetch {
    my( $self, $key ) = @_;
    my( $size, $c1, $c2 ) = @$self;
    my $v = $c1->{$key};
    unless( $v ) {
        $v = $c2->{$key};
        if( $v ) {
            $self->stow( $key, $v );
        }
    }
    return $v;
}

sub stow {
    my( $self, $key, $val ) = @_;
    my( $size, $c1, $c2 ) = @$self;
    $c1->{$key} = $val;
    if( scalar( keys( %$c1 ) ) > $size ) {
        $self->[1] = {};
        $self->[2] = $c1;
    }
}

sub entries {
    my $self = shift;
    my( $size, $c1, $c2 ) = @$self;
    my( %e ) = ( %$c1, %$c2 );
    return keys %e;
}


1;
