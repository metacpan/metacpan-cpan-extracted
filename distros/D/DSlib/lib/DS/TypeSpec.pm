#!perl

# ########################################################################## #
# Title:         Type specification
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Class holding type specifications for data streams
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/TypeSpec.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::TypeSpec;

use base qw{ Clone };

use strict;
use Carp;
use Carp::Assert;
use List::MoreUtils qw{ any all };
use DS::TypeSpec::Field;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.2 $' =~ /(\d+\.\d+)/;


sub new {
    my( $class, $arg1, $arg2 ) = @_;

    my $name;
    my $fields;
    if( $arg1 ) {
        if( ref( $arg1 ) eq '' ) {
            $name = $arg1;
            if( $arg2 ) {
                $fields = $arg2;
            } 
        } else {
           $fields = $arg1;
        }
        if( $fields ) {
            should(ref($fields) , 'ARRAY');
        }
    }

    my $self = bless {
        name    => $name || '',
        fields  => {}
    }, $class;
    
    if( $fields ) {
        $self->add_fields( $fields );
    }
    
    return $self;
}

sub add_fields {
    my( $self, $fields ) = @_;
    
    foreach my $field (@$fields) {
        $self->add_field( $field );
    }
}

sub add_field {
    my( $self, $field ) = @_;
    
    if( ref( $field ) eq '' ) {
        $field = new DS::TypeSpec::Field( $field );
    }
    assert($field->isa('DS::TypeSpec::Field'));
    if( $self->{fields}->{ $field->{name} } ) {
        croak("Can't add field to data stream type spec, since another field with the same name already exists");
    } else {
        $self->{fields}->{ $field->{name} } = $field;
    }
}

sub remove_fields {
    my( $self, $fields ) = @_;
    
    foreach my $field (@$fields) {
        $self->remove_field( $field );
    }
}

sub remove_field {
    my( $self, $field ) = @_;
    
    my $field_name;
    if( not ref($field) eq '' ) {
        should($field->isa, 'DS::TypeSpec::Field');
        $field_name = $field->{name};
    } else {
        $field_name = $field;
    }
    if( not $self->{fields}->{ $field->{name} } ) {
        croak("Can't remove field from data stream type spec - name not recognized. The name is $field_name, but I only have " . join(", ", keys %{$self->{fields}}));
    } else {
        delete $self->{fields}->{ $field->{name} };
    }
}

sub fields {
    my( $self, $fields ) = @_;
    
    my $result = 1;
    if( $fields ) {
        should(ref($fields), 'ARRAY');
        my %remove_fields = ( %{$self->{fields}} );
        foreach my $field ( @$fields ) {
            if( $self->{fields}->{$field} ) {
                $self->add_field( $field );
                delete $remove_fields{ $field };
            }
        }
        $self->{fields} = $fields;
    } else {
        $result = $self->{fields};
    }
    return $result;
}

sub field_names {
    my( $self, $fields ) = @_;
    return keys %{$self->{fields}};
}    

sub keys_locked {
    my( $self, $keys_locked ) = @_;

    my $result = 1;
    if( $keys_locked ) {
       $self->{keys_locked} = $keys_locked ? 1 : 0;
    } else {
        $keys_locked = $self->{keys_locked};
    }
    return $result;
}

sub values_readonly {
    my( $self, $values_readonly ) = @_;

    my $result = 1;
    if( $values_readonly ) {
       $self->{values_readonly} = $values_readonly ? 1 : 0;
    } else {
        $values_readonly = $self->{values_readonly};
    }
    return $result;
}

sub contains {
    my( $self, $other ) = @_;

    my $result;

    if( $other->isa('DS::TypeSpec::Any') ) {
        $result = 1;
    } else {
        # This is equivalent to the subset operator in mathematics
        # For all of the $other fields
        $result = all { 
            my $other = $_;
            # There must be one key with the same name
            any { $_ eq $other } keys %{$self->{fields}}; 
        } keys %{$other->{fields}};
    }
    
    return $result;
}

sub project {
    my( $self, $arg1, $arg2 ) = @_;

    my $name = '';
    my $new_fields;
    if( $arg1 ) {
        if( ref( $arg1 ) eq '' ) {
            $name = $arg1;
            if( $arg2 ) {
                $new_fields = $arg2;
            } 
        } else {
           $new_fields = $arg1;
        }
    }

#    if( ref( $fields ) eq 'ARRAY' ) {
#        my $new_fields = {};
#        foreach my $field ( @$fields ) {
#            $new_fields->{$field} = 1;
#        }
#        $fields = $new_fields;
#    }
    should(ref($new_fields), 'HASH');

    my $new_spec = new DS::TypeSpec( $name );

    foreach my $new_field (keys %$new_fields) {
        if( my $field = $self->{fields}->{ $new_fields->{$new_field} } ) {
             my $new_field_obj = $field->clone();
             $new_field_obj->{name} = $new_field;
             $new_spec->add_field( $new_field_obj );
        } else {
            croak("Can't limit to field $new_field since it is not in the original type");
        }
    }     
    return $new_spec;
}

1;

#TODO Add sorting and unique constraints. Possibly also field order (or maybe not?!?)
