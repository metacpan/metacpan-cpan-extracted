#!perl

# ########################################################################## #
# Title:         Write data stream to tab separated stream
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Writes data stream to a handle (IO::Handle)
#                Data Stream class
#                Transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/TabStreamWriter.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# #TODO Must store field order internally. Ask not where to get it from.
# ########################################################################## #

package DS::Transformer::TabStreamWriter;

use base qw{ DS::Transformer::TypePassthrough };

use strict;
use Carp;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.2 $' =~ /(\d+\.\d+)/;

sub new {
    my( $class, $fh, $field_order, $source, $target ) = @_;

    my $self = $class->SUPER::new( $source, $target );

    assert($fh->isa('IO::Handle')); 
    $self->{fh} = $fh;

    $self->{field_order} = $field_order;

    return $self;
}

sub receive_row {
    my( $self, $row ) = @_;
    
    # TODO (V3) This needs to be rewritten once a new typing system is in place
    # Trying to figure out field order here is just plain ugly and only
    # something we do to allow TabFileWriter to work (it needs field order to be
    # set before process is called.
    unless( $self->{field_order} ) {
        $self->{field_order} = [sort keys %$row];
    }
    
    return $self->SUPER::receive_row( $row );
}

sub include_header {
    my( $self ) = @_;
    $self->{include_header} = 1;
    return;
}

sub exclude_header {
    my( $self ) = @_;
    $self->{include_header} = 0;
    return;
}

sub process {
    my( $self, $row) = @_;

    if( $row ) {
        if( $self->{include_header} and not $self->{header_included} ) {
            $self->write_header;
            $self->{header_included} = 1;
        }
        $self->{fh}->print(join("\t", @$row{@{$self->{field_order}}}), "\r\n");
    }

    return $row;
}

sub write_header {
    my( $self ) = @_;
    assert( $self->{field_order} );
    $self->{fh}->print(join("\t", @{$self->{field_order}}), "\r\n");
}

1;

