#!perl

# ########################################################################## #
# Title:         Exception
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Abstract super class of DS generated exceptions
#                Data Stream class
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Exception.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# #TODO Importers should not by default be constructed with an explicit typespec, since this may be derived from the data source
# ########################################################################## #

package DS::Exception;

# Somewhat equivalent to use base qw{ Class::Exception }
use Exception::Class ( 'DS::Exception' );

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

1;
