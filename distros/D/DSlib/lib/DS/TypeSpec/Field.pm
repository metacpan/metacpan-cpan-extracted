#!perl

# ########################################################################## #
# Title:         Field specification
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Class holding field specifications for data stream types
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/TypeSpec/Field.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::TypeSpec::Field;

use base qw{ Clone };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub new {
    my( $class, $name ) = @_;

    assert( $name =~ /^\S+/);
    my $self = { 
        name => $name 
    };
    bless $self, $class;

    return $self;
}

# Validator receives this object and the data to validate
sub validator {
    my( $self, $validator ) = @_;

    my $result = 1;
    if( $validator ) {
        my $new_validator;
        if( ref( $validator ) eq 'Regexp' ) {
            $self->{validator} = sub {
                $_[1] =~ /$validator/;
            };
        } else {
            $self->{validator} = $validator;
        }
    } else {
        $result = $self->{validator};
    }
    return $result;
}

sub undef_ok {
    my( $self, $undef_ok ) = @_;

    my $result = 1;
    if( $undef_ok ) {
       $self->{undef_ok} = $undef_ok ? 1 : 0;
    } else {
        $undef_ok = $self->{undef_ok};
    }
    return $result;
}

1;
