#!perl

# ########################################################################## #
# Title:         Catch transformer
# Creation date: 2007-04-18
# Author:        Michael Zedeler
# Description:   Catch exceptions and pass them to subroutine
#                Data Stream class
#                Data transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Catch.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::Catch;

use base qw{ DS::Transformer::TypePassthrough };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub new {
    my( $class, $catch, $source, $target ) = @_;

    my $self = $class->SUPER::new( $source, $target );

    $self->{catch} = $catch;

    return $self;
}

sub pass_row {
    my( $self, $row ) = @_;
    eval {
        $self->SUPER::pass_row( $row );
    };
    if( $@ ) {
        &{$self->{catch}}($self, $@);
    }
}

sub catch {
    my( $self, $catch ) = @_;

    my $result;    
    
    if( $catch ) {
        assert( ref( $catch ) eq 'CODE' );
        $self->{catch} = $catch;
    } else {
        $result = $self->{catch};
    }
    
    return $result;
}

1;


