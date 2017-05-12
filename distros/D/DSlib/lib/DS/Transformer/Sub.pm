#!perl

# ########################################################################## #
# Title:         Sub-plug transformer
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Call sub after fetch and return result from sub as fetch result
#                Data Stream class
#                Data transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Sub.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::Sub;

use base qw{ DS::Transformer };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub new {
    my( $class, $sub, $in_type, $out_type, $source, $target ) = @_;

    my $self = $class->SUPER::new( $in_type, $out_type, $source, $target );

    $self->{sub} = $sub;

    return $self;
}

sub process {
    my( $self, $row ) = @_;
    return &{$self->{sub}}($self, $row);
}

1;


