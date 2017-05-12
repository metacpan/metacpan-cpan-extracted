#!/usr/bin/perl

use strict;
use warnings;

use Acme::Sub::Parms;

# Valid example
foo( other_thing => 'Hello' );

# Bad Example (will fail runtime assertion for 'other_thing')
foo();

exit;


#############################################
# function with two parameters
# 
#   'thing'       which is optional and defaults to "Something Blue" if not passed
#   'other_thing' which is required and cannot be the undef value
#
sub foo {
    BindParms : (
        my $thing : thing       [optional, default="Something Red"];
        my $other : other_thing [required, is_defined];
    )

    print "thing       = $thing\n";
    print "other_thing = $other\n";
}

