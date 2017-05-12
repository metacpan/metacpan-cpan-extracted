#!perl

# ########################################################################## #
# Title:         Sub reference to datastream importer
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Produces a datastream from a sub reference
#                Data Stream class
#                Data importer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Importer/Sub.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Importer::Sub;

use base qw{ DS::Importer };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub new {
    my( $class, $sub, $typespec, $target, $row ) = @_;

    my $self = $class->SUPER::new( $typespec, $target, $row );
    assert(ref($sub) eq 'CODE');
    $self->{sub} = $sub;

    return $self;
}

sub _fetch {
    my($self) = @_;
    return &{$self->{sub}}($self);
}

sub target {
    my( $self, $target ) = @_;
    $self->SUPER::target( $target );
}

1;
