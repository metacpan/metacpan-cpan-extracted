#!perl

# ########################################################################## #
# Title:         Any type - wildcard typespec
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Class implementing a wildcard type spec that matches 
#                anything.
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/TypeSpec/Any.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::TypeSpec::Any;

use base qw{ DS::TypeSpec };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

sub contains {
    assert( $_[1]->isa('DS::TypeSpec') );
    return 1;
}

$DS::TypeSpec::Any = new DS::TypeSpec::Any;

1;
