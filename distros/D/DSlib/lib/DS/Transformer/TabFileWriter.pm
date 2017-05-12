#!perl

# ########################################################################## #
# Title:         Write stream to tabular file
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Writes data stream to file
#                Data Stream class
#                Transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/TabFileWriter.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::TabFileWriter;

use base qw{ DS::Transformer::TabStreamWriter };

use strict;
use Carp;
use Carp::Assert;
use IO::File;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub new { 
    my( $class, $filename, $field_order, $source, $target ) = @_;

    my $self = undef;
    assert(ref($filename) eq '', "Must be scalar but is " . ref( $filename ));
    my $fh;
    if( not defined( $filename ) ) {
        $fh = new_tmpfile IO::File;
    } elsif( not -f $filename ) {
        $fh = new IO::File;
        $fh->open( $filename, ">" );
    } else {
        croak("The file $filename already exists.");
    }
    
    if( $fh ) {
        $self = $class->SUPER::new( $fh, $field_order, $source, $target );
        $self->{filename} = $filename;
    } else {
        $self = undef;
    }
    
    return $self;
}

sub process {
    my( $self, $row ) = @_;
    
    my $result;

    # TODO (V3) Writing header this late is not a good thing. Move to post-attach, pre-process stage. 
    unless( $self->{header_written} ) {
        $self->{header_written} = 1;
        $self->write_header;
    }

    $result = $self->SUPER::process( $row );
    $self->{fh}->close() unless $row;

    return $result;
}
    
1;
