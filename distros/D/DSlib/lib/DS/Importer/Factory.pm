#!perl

# ########################################################################## #
# Title:         Data stream importer factory
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Importer/Factory.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# #TODO Importers should not by default be constructed with an explicit typespec, since this may be derived from the data source
# ########################################################################## #

package DS::Importer::Factory;

use base qw{ DS };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

require DS::Transformer;
require DS::Importer::Hash;
require DS::Importer::Sub;
require DS::Importer::TabStream;
require DS::Importer::Sth;


sub factory {
    my($class, $data_source) = @_;

    if(ref($data_source) eq 'HASH') {
        return new DS::Importer::Hash(@_);
    } elsif(ref($data_source) eq 'CODE') {
        return new DS::Importer::Sub( @_ );
    } elsif($data_source->isa('IO::handle')) {
        return new DS::Importer::TabStream( @_ );
    } elsif($data_source->isa('DBI::st')) {
        return new DS::Importer::Sth( @_ );
    }
# TODO This wouldn't work: Needs some kind of IOC-component. A subclass of Transformer::Buffer could do the trick.
#     elsif($data_source->isa('DS::Source')) {
#        return new DS::Transformer( @_ );
#    }
    
    return;
    
}
 
1;
