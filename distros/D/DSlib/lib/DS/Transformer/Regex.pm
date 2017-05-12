#!perl

# ########################################################################## #
# Title:         Regex-field-rewriter
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Rewrite data stream with regular expressions
#                Data Stream class
#                Data transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Regex.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::Regex;

use base qw{ DS::Transformer };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

require DS::TypeSpec;

sub new {
    my( $class, $rewrite_rules, $source, $target ) = @_;

    my $fields = {};
    foreach my $field (keys %$rewrite_rules) {
        $fields->{$field} = 0;
    }    

    my $in_type = new DS::TypeSpec( $fields );

    my $self = $class->SUPER::new( $in_type, undef, $source, $target );

    $self->{rewrite_rules} = $rewrite_rules;
        
    return $self;
}

sub process {
    my( $self, $row ) = @_;

    foreach my $field (keys %{$self->{rewrite_rules}}) {
        my( $from, $to) = @{${$self->{rewrite_rules}}{$field}};
        $row->{$field} =~ /$from/;
        $row->{$field} = eval("\"$to\""); ## no critic
    }
    
    return $row;
}

sub source {
    my( $self, $source ) = @_;
    if( defined( $source ) ) {
        if( defined( $source->out_type ) ) {
            $self->out_type( $source->out_type );
        } else {
            cluck("Can't determine what type to use as out_type, since sink $source has no out_type");
        }
    }
    return $self->SUPER::source( @_ );
}

1;


