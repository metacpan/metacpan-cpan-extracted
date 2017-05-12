#!perl

# ########################################################################## #
# Title:         Multiplex stream to multiple targets
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Sends stream to a series of transformers
#                Data Stream class
#                Data transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Multiplexer.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::Multiplexer;

use base qw{ DS::Transformer };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

require DS::TypeSpec;

sub new {
    my( $class, $transformers, $in_type, $out_type, $source, $target ) = @_;

    my $self = $class->SUPER::new( $in_type, $out_type, $source, $target );

    return $self;
}

sub process {
    my( $self, $row ) = @_;

    foreach my $field (keys %{$self->{rewrite_rules}}) {
        my( $from, $to) = @{${$self->{rewrite_rules}}{$field}};
        $row->{$field} =~ /$from/;
        $row->{$field} = eval("\"$to\""); ## no critic
    }
    
    return $row;
}

sub source {
    my( $self, $source ) = @_;
    if( defined( $source ) ) {
        if( defined( $source->out_type ) ) {
            $self->out_type( $source->out_type );
        } else {
            cluck("Can't determine what type to use as out_type, since sink $source has no out_type");
        }
    }
    return $self->SUPER::source( @_ );
}

1;


