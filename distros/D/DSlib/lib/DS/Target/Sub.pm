#!perl

# ########################################################################## #
# Title:         Data stream sink
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Receives data and does nothing.
#                Data Stream class
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Target/Sub.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Target::Sub;

use base qw{ DS::Target };

use strict;

use DS::TypeSpec::Any;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;
our ($STATE) = '$State: Exp $' =~ /:\s+(.+\S)\s+\$$/;

sub new {
    my( $class, $sub, $in_type, $source ) = @_;
    my $self = $class->SUPER::new( $in_type, $source );
    $self->{sub} = $sub;
    return $self;
}

# Don't do anything when getting a row
sub receive_row {
    my( $self, $row ) = @_;
    &{$self->{sub}}( $self, $row );
    return;
}

1;
