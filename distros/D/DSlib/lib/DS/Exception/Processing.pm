#!perl

# ########################################################################## #
# Title:         Processing Exception
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Exception thrown when processing a row
#                Data Stream class
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Exception/Processing.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Exception::Processing;

use DS::Exception;

use Exception::Class ( 
    DS::Exception::Processing => {
        isa => 'DS::Exception',
        fields => [ 'row', 'message' ] 
    }
);

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

1;
