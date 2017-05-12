#!perl

# ########################################################################## #
# Title:         Trim trailing spaces transformer
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Removes trailing spaces from all values
#                Data Stream class
#                Data transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Rtrim.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::Rtrim;

use base qw{ DS::Transformer };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub process {
    my( $self, $row ) = @_;

    foreach my $field (keys %$row) {
        $row->{$field} =~ s/^(.*\S+)?\s*$/$1/o;
        $row->{$field} = '' unless defined $row->{$field};
    }

    return $row;
}

1;


