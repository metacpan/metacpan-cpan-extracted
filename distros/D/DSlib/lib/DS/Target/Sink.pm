#!perl

# ########################################################################## #
# Title:         Data stream sink
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Receives data and does nothing.
#                Data Stream class
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Target/Sink.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Target::Sink;

use base qw{ DS::Target };

use strict;

use DS::TypeSpec::Any;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;
our ($STATE) = '$State: Exp $' =~ /:\s+(.+\S)\s+\$$/;

sub new {
    my( $class, $source ) = @_;
    return $class->SUPER::new( $DS::TypeSpec::Any, $source );
}

# Don't do anything when getting a row
sub receive_row {}

# All types are okay
sub validate_source_type {
    return 1;
}

1;
