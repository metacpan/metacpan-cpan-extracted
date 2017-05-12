#!perl

# ########################################################################## #
# Title:         Type pass through transformer
# Creation date: 2007-07-31
# Author:        Michael Zedeler
# Description:   Base class for transformers that does not change data type
#                Data Stream class
#                Data transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/TypePassthrough.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::TypePassthrough;

use base qw{ DS::Transformer };

use strict;
use Carp;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

use DS::TypeSpec;
use DS::TypeSpec::Any;

sub new {
    my( $class, $source, $target ) = @_;

    my $self = $class->SUPER::new( undef, undef, $source, $target );

    return $self;
}

sub out_type {
    my( $self, $out_type ) = @_;

    my $result;
    if( $out_type ) {    
        croak("The attribute out_type is read only");
    } else {
        if( $self->source ) {
            $result = $self->source->out_type;
        } else {
            $result = $DS::TypeSpec::Any;
        }
    }
    return $result;
}

sub in_type {
    my( $self, $in_type ) = @_;

    my $result;
    if( $in_type ) {    
        croak("The attribute in_type is read only");
    } else {
        if( $self->target ) {
            $result = $self->target->in_type;
        } else {
            $result = $DS::TypeSpec::Any;
        }
    }
    return $result;
}

sub validate_source_type {
    my( $self, $type ) = @_;

    my $result = 1;
    if( $self->target ) {
        $result &&= $self->target->validate_source_type( $type );
    }
    
    return $result;
}

1;
