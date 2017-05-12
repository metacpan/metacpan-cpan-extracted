#!perl

# ########################################################################## #
# Title:         Opaque transformer
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Provides opaque bindings between some internal transformers
#                and external transformers
#                Data Stream class
#                Data transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Opaque.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::Opaque;

use base qw{ DS::Transformer };

use strict;
use Carp qw{ confess croak };
use Carp::Assert;
use DS::Source::Push;
use DS::Target::Sub;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub source {
    my( $self, $source ) = @_;
    
    my $result = $self->SUPER::source( $source );
    if( $source ) {
        $self->{internal_source} = new DS::Source::Push( $source->out_type )
            or confess("Fatal error while trying to create source proxy object.");
        $result &&= $self->attach_source_internal( $self->{internal_source} );
    }
    return $result;
}

sub target {
    my( $self, $target ) = @_;
    
    my $result = $self->SUPER::target( $target );
    if( $target ) {
        $self->{internal_target} = new DS::Target::Sub( 
            sub {
                my( undef, $row ) = @_;
                $self->pass_row( $row );
            }, 
            $target->in_type 
        ) or confess("Fatal error while trying to create target proxy object.");
        $result &&= $self->attach_target_internal( $self->{internal_target} );
    }
    return $result;
}

sub validate_source {
    # In DS::Transformer::Stack validation is done elsewhere. 
    # Proxies causes validation to happen at two places:
    # (1) top-of-stack and target and (2) bottom-of-stack and source
    return 1;
}

sub receive_row {
    my( $self, $row ) = @_;
    
    assert( $self->{internal_source}, 'Cannot receive rows from undefined source' );
    $self->{internal_source}->receive_row( $row );
    
    return;
}

# The following methods are delegated to the internal object
foreach my $internal_method ( qw{ target source } ) {
    eval <<"END_METHOD"; ## no critic
sub attach_${internal_method}_internal {
    croak("This method must be overridden. You probably want to proxy it to the internal object that needs to be hidden from the outside.");

}
END_METHOD
}
    
1;
