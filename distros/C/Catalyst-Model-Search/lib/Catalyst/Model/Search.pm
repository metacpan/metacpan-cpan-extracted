package Catalyst::Model::Search;

use strict;
use NEXT;
use base qw/Catalyst::Base/;

our $VERSION='0.03';

sub new { 
    my ( $self, $c ) = @_;

    return $self->NEXT::new( $c );
}

sub init {
    my $self = shift;
    
    Catalyst::Exception->throw(
        message => ( ref $self || $self ) . ' does not implement init()'
    );
}

sub add {
    my $self = shift;
    
    Catalyst::Exception->throw(
        message => ( ref $self || $self ) . ' does not implement add()'
    );
}

sub update {
    my $self = shift;
    
    Catalyst::Exception->throw(
        message => ( ref $self || $self ) . ' does not implement update()'
    );
}

sub remove {
    my $self = shift;
    
    Catalyst::Exception->throw(
        message => ( ref $self || $self ) . ' does not implement remove()'
    );
}

sub query {
    my $self = shift;
    
    Catalyst::Exception->throw(
        message => ( ref $self || $self ) . ' does not implement query()'
    );
}

sub is_indexed {
    my $self = shift;
    
    Catalyst::Exception->throw(
        message => ( ref $self || $self ) . ' does not implement is_indexed()'
    );
}

sub optimize {
    my $self = shift;
    
    Catalyst::Exception->throw(
        message => ( ref $self || $self ) . ' does not implement optimize()'
    );
}

1;
__END__
