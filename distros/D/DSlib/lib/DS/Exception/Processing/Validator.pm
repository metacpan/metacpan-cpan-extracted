#!perl

# ########################################################################## #
# Title:         Exception thrown by row value validator
# Creation date: 2008-04-16
# Author:        Michael Zedeler
# Description:   Processing Exception.
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Exception/Processing/Validator.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Exception::Processing::Validator;

use DS::Exception::Processing;

use Exception::Class ( 
    'DS::Exception::Processing::Validator' => {
        isa => 'DS::Exception::Processing',
        fields => [ 'field', 'regex', 'validator' ] 
    }
);

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

1;
