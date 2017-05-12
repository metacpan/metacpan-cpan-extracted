#!/usr/bin/perl

use strict;
use warnings;

# Valid example
my $obj = MyObject->new( other_thing => 'Hello' );
print 'thing       = ' . $obj->thing . "\n";
print 'other_thing = ' . $obj->other_thing . "\n";

# Bad Example (will fail runtime assertion for 'other_thing')
my $other_obj = MyObject->new;
print 'thing       = ' . $other_obj->thing . "\n";
print 'other_thing = ' . $other_obj->other_thing . "\n";

exit;

#########################################################
#
# A simple example of an object using BindParms blocks

package MyObject;

use strict;
use warnings;

use Acme::Sub::Parms;

#############################################
# object instance constructor with two parameters
# 
#   'thing'       which is optional and defaults to "Something Blue" if not passed
#   'other_thing' which is required and cannot be the undef value
#
sub new {
    my $proto   = shift;
    my $package = __PACKAGE__;
    my $class   = ref($proto) || $proto || $package;
    my $self    = bless {}, $class;

    BindParms : (
        my $thing : thing       [optional, default="Something Blue"];
        my $other : other_thing [required, is_defined];
    )
    $self->thing($thing);
    $self->other_thing($other);
    return $self;
}

###

# Get/Set accessors for instance values
sub thing       { return shift->_property('thing',       @_); } 
sub other_thing { return shift->_property('other_thing', @_); }

###

#########################################
# Simple generic get/set utility method
# Expects either 1 or 2 parameters.
#
# If passed a single string value, returns the associated instance value
#
# If passed a string and a second parameter, sets the the associated instance value to the value of the
# second parameter.
#
sub _property {
    my $self        = shift;
    my $package     = __PACKAGE__;
    my $property_id = shift;
    if (0 == @_) {
        return $self->{$package}->{$property_id};
    } elsif (1 == @_) {
        $self->{$package}->{$property_id} = $_[0];
        return $_[0];
    } else {
        require Carp;
        Carp::confess("Wrong number of calling parameters\n");
    }
}

1;
