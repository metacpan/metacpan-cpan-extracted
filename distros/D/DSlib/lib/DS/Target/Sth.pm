#!perl

# ########################################################################## #
# Title:         Data stream sink
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Receives data, binds to statement handle parameters and 
#                executes statement handle for each row.
#                Data Stream class
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Target/Sth.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Target::Sth;

use base qw{ DS::Target };

use strict;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;
our ($STATE) = '$State: Exp $' =~ /:\s+(.+\S)\s+\$$/;

sub new {
    my( $class, $in_type, $source, $sth, $bind_map ) = @_;

    my $self = $class->SUPER::new( $in_type, $source );

    #TODO Make sure that $bind_map and $in_type corresponds

    should( ref( $sth ) => 'DBI::st' );
    should( ref( $bind_map ) => 'HASH' );

    $self->{sth} = $bind_map;
    $self->{bind_map} = $bind_map;

    return $self;
}

sub receive_row {
    my( $self, $row ) = @_;
    
    foreach my $parnum ( keys %{$self->{bind_map}} ) {
        my $field = $self->{bind_map}->{$parnum};
        $self->{sth}->bind_param( $parnum, $row->{ $field } );
    }
    
    $self->{sth}->execute();
}

1;
