#!perl

# ########################################################################## #
# Title:         Data stream source proxy
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Receives data and passes it to another, underlying source
#                Data Stream class
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Source/Proxy.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Source::Proxy;

use base qw{ DS::Source };

use strict;
use Carp qw{ croak cluck confess carp };
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

my @proxy_methods = qw{ pass_row target attach_target out_type };

sub new {
    my( $class, $inner_object, $delegate ) = @_;

    bless my $self = {}, $class;
    $self->inner_object( $inner_object ) if $inner_object;
    $self->delegate( $delegate ) if $delegate;

    return $self;
}

sub inner_object {
    my( $self, $object ) = @_;
    
    my $result = 1;
    if( $object ) {
        assert($object->isa( 'DS::Source' ) );
        $self->{inner_object} = $object;
    } else {
        $result = $self->{inner_object};
    }
    return $result;
}

sub delegate {
    my( $self, $delegate ) = @_;
    
    my $result = 1;
    if( $delegate ) {
        $self->{delegate} = $delegate;
    } else {
        $result = $self->{delegate};
    }
    return $result;
}

# Create all proxy methods using eval
# This is not very expensive, since it is only done once - at load time
foreach my $method ( @proxy_methods ) {
    eval <<"END_METHOD"; ## no critic
        sub $method {
            my( \$self, \@args ) = \@_;
            if( \$self->{delegate}->can( 'delegate_$method' ) ) {
                return \$self->{delegate}->delegate_invoke( '$method', \$self, \@args );
            } else {
                return \$self->{inner_object}->$method( \@args );
            }
        }
END_METHOD
}

1;
