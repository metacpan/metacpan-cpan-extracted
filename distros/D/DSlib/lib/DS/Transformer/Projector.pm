#!perl

# ########################################################################## #
# Title:         Field projector
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Make a projection of line
#                Data Stream class
#                Data transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Projector.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::Projector;

use base qw{ DS::Transformer };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub new {
    #TODO Do not just set $self->{typespec} to $typespec. Do the restriction on a copy of the existing typespec and use that.
    my( $class, $typespec, $source, $project_fields ) = @_;

    my $project_fields_result;
    my @new_fields = ();
    if( ref( $project_fields ) eq 'HASH' ) {
        $project_fields_result = $project_fields;
    } else {
        $project_fields_result = {};

        foreach my $field_line ( split /\n/, $project_fields ) {
            next if $field_line =~ /^\s*#/;
            my( $old_field, $new_field ) = $field_line =~ /\s*(\S+)(?:\s+(\S+))?/;     
            $project_fields_result->{$old_field} = $new_field;
            push @new_fields, $new_field;
        }
    }

    my $self;

    if( defined( $project_fields_result ) ) {
        my $projected_typespec = $typespec->project( 'adlines', $project_fields_result );
        $self = $class->SUPER::new( $projected_typespec, $source );
        $self->{project_fields} = $project_fields_result;
    }

    return $self;
}

sub process {
    my( $self, $row ) = @_;

    my $new_row = {};

    foreach my $old_field (keys %$row) {
        if(defined(my $new_field = $self->{project_fields}->{$old_field})) {
            $new_row->{$new_field} = $row->{$old_field};
        }
    }

    $new_row;
}

1;


