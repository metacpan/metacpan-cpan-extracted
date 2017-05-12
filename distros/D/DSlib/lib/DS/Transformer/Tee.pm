#!perl

# ########################################################################## #
# Title:         Data stream tee
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   ...
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Tee.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# #TODO Clean this class and test it
# ########################################################################## #

package DS::Transformer::Tee;

use strict;
use warnings;

use Carp::Assert;

use base qw{ DS::Transformer::TypePassthrough };

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;
our ($STATE) = '$State: Exp $' =~ /:\s+(.+\S)\s+\$$/;


sub new {
    my( $class, $extra_targets ) = @_;

    my $self = {
        extra_targets => [],
        row => {}
    };
    bless $self, $class;

    if( defined( $extra_targets ) ) {
        $self->attach_extra_targets( @$extra_targets );
    }

    return $self;
}

sub attach_extra_targets {
    my( $self, @extra_targets ) = @_;

    #TODO Error handling: if trying to attach target that throws exception (or returns error), restore old extra_targets before re-throwing exception or somehow mark state as undefined
    my $position = 0;
    foreach my $target (@extra_targets) {
        assert( $target->isa('DS::Target') );
        if( $target->source( $self ) ) {
            $self->add_extra_targets( $target );
        }
    }
    return;
}

sub extra_targets {
    my( $self, @extra_targets ) = @_;

    my @result;
    if( $#extra_targets == -1 ) {
        @result = @{$self->{extra_targets}};
    } else {
        $self->remove_extra_targets;
        $self->add_extra_targets(@extra_targets);
        @result = (1);
    }

    return @result;
}

sub add_extra_targets {
    my( $self, @extra_targets ) = @_;
    foreach my $target (@extra_targets) {
        assert($target->isa('DS::Target'));
    }
    push @{$self->{extra_targets}}, @extra_targets;
}

sub remove_extra_targets {
    my( $self, @extra_targets ) = @_;

    my @new_extra_targets;
    
    if( @extra_targets ) {
        foreach my $target (@{$self->{extra_targets}}) {
            push @new_extra_targets, $target if none { $target == $_ } @extra_targets;
        }
        $self->{extra_targets} = [@new_extra_targets];
    } 
    $self->{extra_targets} = [@new_extra_targets];
    
    return;
}

sub process {
    my( $self, $row ) = @_;

    foreach my $target ($self->extra_targets) {
        $target->receive_row( $row );
    }

    return $row;
}

1;
