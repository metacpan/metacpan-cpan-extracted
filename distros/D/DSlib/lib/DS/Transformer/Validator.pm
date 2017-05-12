#!perl

# ########################################################################## #
# Title:         Row value validator
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Validate data in stream using regular expressions
#                Data Stream class
#                Data transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Validator.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::Validator;

use base qw{ DS::Transformer::TypePassthrough };

use strict;
use warnings;

use DS::Exception::Processing::Validator;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub new {
    my( $class, $constraints, $fail_handler, $source, $target ) = @_;

    my $self = $class->SUPER::new( $source, $target );

    $self->{constraints} = $constraints;
    $self->{fail_handler} = $fail_handler;
        
    return $self;
}

sub process {
    my( $self, $row ) = @_;

    if( $row ) {
        foreach my $field (keys %{$self->{constraints}}) {
    
            my $re = $self->{constraints}->{$field};
            if(not exists $row->{$field}) {
                die "Fatal error: the field $field does not exist.";
            } elsif( defined( $row->{$field} ) ) {
                if($row->{$field} !~ /$re/) {
                    my %error = (
                        message   => "Constraint check failed: field $field with value \"" 
                                         . $row->{$field}
                                         . "\" does not match regex $re",
                        row       => {%$row},
                        field     => $field,
                        regex     => $re,
                        validator => $self
                    );
                    if( $self->{fail_handler} ) {
                        &{$self->{fail_handler}}( {%error} );
                    } else {
                        DS::Exception::Processing::Validator->throw( %error );
                    }
                }
            }
        }
    }
        
    return $row;
}

1;


