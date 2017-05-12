#!perl

# ########################################################################## #
# Title:         Push data stream source
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Receives data from outside a processing chain and passes it
#                into the chain
#                Data Stream class
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Source/Push.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Source::Push;

use base qw{ DS::Source };

use strict;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

sub receive_row {
    my( $self, $row ) = @_;

    $self->pass_row( $row );

    return;
}

1;
