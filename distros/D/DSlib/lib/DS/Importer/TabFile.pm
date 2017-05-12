#!perl

# ########################################################################## #
# Title:         Tabular file to datastream importer
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Produces a datastream from a tab separated file (filename)
#                Data Stream class
#                Data importer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Importer/TabFile.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Importer::TabFile;

use base qw{ DS::Importer::TabStream };

use strict;
use Carp::Assert;
use IO::File;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

sub new {
    my( $class, $filename, $target, $typespec, $row ) = @_;

    my $self = undef;

    assert(ref($filename) eq ''); 

    if( my $fh = new IO::File ) {
        if( $fh->open($filename) ) {
            $self = $class->SUPER::new( $fh, $target, $typespec, $row );
            $self->{filename} = $filename;
        }
    }

    return $self;
}

sub _fetch {
    my($self) = @_;
    
    my $result = $self->SUPER::_fetch();

    $self->{fh}->close() unless $result;
    
    return $result;
}

1;
