# Connector::Wrapper
#
# Wrapper class to filter access to a connector by a prefix 
#
# Written by Oliver Welter for the OpenXPKI project 2012
#
# TODO: To make this really transparent it need to be inherited 
# from Connector and implement the prefix stuff 

package Connector::Wrapper;

use strict;
use warnings;
use English;
use Moose;
use Data::Dumper;

extends 'Connector';

has 'BASECONNECTOR' => ( 
    is => 'ro', 
    required => 1, 
);

has '+LOCATION' => ( required => 0 );

# Build arrayref from target the first time it is required
has _target => ( is => 'rw', isa => 'ArrayRef|Undef', writer => '__target' );

has TARGET => ( 
    is => 'ro', 
    isa => 'Connector::Types::Key|ArrayRef|Undef', 
    trigger => sub {
        my ($self, $target) = @_;    
        my @target = $self->_build_path( $target );
        $self->__target( \@target );
        # Force rebuild of prefix 
        $self->PREFIX( $self->PREFIX() );
    }
);

# override the prefix trigger to prepend the wrapper prefix
has '+PREFIX' => (
    trigger => sub {
        my ($self, $prefix, $old_prefix) = @_;
        
        if (not $self->TARGET) {
            $self->log()->debug( 'prefix before target - skipping!' ) ;
            return;
        }
        
        if (defined $prefix) {
            my @path = $self->_build_path($prefix);
            $self->__prefix_path( [ @{$self->_target()}, @path ]);
        } else {
            $self->__prefix_path( $self->_target() );
        }   
    }
);


sub _route_call {
    
    my $self = shift;
    my $call = shift;
    my $path = shift;
    my @args = @_;
              
    my @fullpath = $self->_build_path_with_prefix( $path );
    
    unshift @args, \@fullpath; 
    
    return $self->BASECONNECTOR()->$call( @args );       
}


# Proxy calls
sub get {    
    my $self = shift;        
    unshift @_, 'get'; 
    return $self->_route_call( @_ );     
}

sub get_list {    
    my $self = shift;        
    unshift @_, 'get_list';    
    return $self->_route_call( @_ );     
}

sub get_size {    
    my $self = shift;        
    unshift @_, 'get_size'; 
    return $self->_route_call( @_ );     
}

sub get_hash {    
    my $self = shift;        
    unshift @_, 'get_hash'; 
    return $self->_route_call( @_ );     
}

sub get_keys {    
    my $self = shift;        
    unshift @_, 'get_keys';     
    return $self->_route_call( @_ );     
}

sub set {    
    my $self = shift;        
    unshift @_, 'set'; 
    return $self->_route_call( @_ );     
}

sub get_meta {    
    my $self = shift;        
    unshift @_, 'get_meta'; 
    return $self->_route_call( @_ );     
}

sub exists {
    my $self = shift;
    unshift @_, 'exists';
    return $self->_route_call( @_ );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 Name

Connector

=head1 Description

This provides a wrapper to the connector with a fixed prefix.

=head2 Supported methods

get, get_list, get_size, get_hash, get_keys, set, meta
