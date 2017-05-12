#!perl

# ########################################################################## #
# Title:         Stack transformer
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Represents a stack of transformers
#                Data Stream class
#                Data transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Stack.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #


# TODO Make pass_row work again.
# TODO Make process work again (call internal stack)

package DS::Transformer::Stack;

use base qw{ DS::Transformer::Opaque };

use strict;
use Carp qw{ croak cluck confess };
use Carp::Assert;
use DS::Target::Proxy;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

sub new {
    my( $class, $source, $stack ) = @_;

    my $self = $class->SUPER::new( undef, undef, $source );
    
    foreach my $transformer (@$stack) {
        $self->push_transformer( $transformer );
    }
    
    return $self;
}

sub push_transformer {
    my( $self, $transformer ) = @_;

    assert( $transformer->isa('DS::Transformer') );

    if( $self->target ) {
        confess("Invalid use of stack. It is not possible to modify stack after target has been set.");
    }

    if( defined( $self->top() ) ) {
        $transformer->attach_source( $self->top() );
    } else {
       $self->bottom( $transformer );
    }
    $self->top( $transformer );
}

# Set top transformer and check that no target has been set yet
# Do NOT try to maintain links with internal transformers in stack
sub top {
    my( $self, $top ) = @_;

    my $result;
    if( defined( $top ) ) {
        if( $self->target ) {
            confess("Invalid use of stack. It is not possible to modify stack after target has been set.");
        }
        $self->{top} = $top;
        $result = 1;
    } else {
        $result = $self->{top};
    }
    return $result;
}

# Set bottom transformer and maintain links with source transformer (outside stack)
# Do NOT try to maintain links with internal transformers in stack
sub bottom {
    my( $self, $bottom ) = @_;

    my $result;
    if( defined( $bottom ) ) {
        if( defined( $self->source ) ) {
            $bottom->attach_source( $self->source );
        }
        $self->{bottom} = $bottom;
    } else {
        $result = $self->{bottom};
    }
    return $result;
}

sub in_type {
    my( $self, $in_type ) = @_;
    return $self->bottom()->in_type( $in_type );
}

sub out_type {
    my( $self, $out_type ) = @_;
    return $self->top()->out_type( $out_type );
}

sub receive_row {
    my( $self, $row ) = @_;
    return $self->bottom()->receive_row( $row );
}

sub attach_source_internal {
    my( $self, $source ) = @_;
    return $self->bottom()->attach_source( $source );
}

sub attach_target_internal {
    my( $self, $target ) = @_;
    return $self->top()->attach_target( $target );
}

sub process {
    croak 'Process is not well defined on stacks, since the transformers on the stack may return more or less than one row.';
}

1;
