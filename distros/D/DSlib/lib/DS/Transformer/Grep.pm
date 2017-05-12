#!perl

# ########################################################################## #
# Title:         grep transformer
# Creation date: 2007-04-09
# Author:        Michael Zedeler
# Description:   Greps in rows.
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Grep.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::Grep;

use base qw{ DS::Transformer::TypePassthrough };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub new {
    my( $class, $filter_sub ) = @_;

    my $self = $class->SUPER::new;
    $self->{filter_sub} = $filter_sub;
        
    return $self;
}

sub receive_row {
    my( $self, $row ) = @_;

    $self->pass_row( $row ) if !$row || &{$self->{filter_sub}}( $self, $row );

    return;
}

1;


