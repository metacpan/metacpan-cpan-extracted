#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS/Source.pm and DS/Target.pm
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Tests attaching DS::Source and DS::Target objects to each other
# File:          $Source: /data/cvs/lib/DSlib/t/30_source_target.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 13;

BEGIN {
        $|  = 1;
        $^W = 1;
}

use DS::Source;
use DS::Target;

use DS::TypeSpec;
use DS::TypeSpec::Field;

my $typespec = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'pk1' ),
        new DS::TypeSpec::Field( 'another_field' ),
        new DS::TypeSpec::Field( 'pk2' )]
);


my $source;
my $target;

#
# Tests that tries to attach and detach connectors
# checking that they are properly detached
#

$source = new DS::Source();
$source->out_type( $typespec );
$target = new DS::Target();
$target->in_type( $typespec );

# Check that attach_target connects the two objects correctly
$source->attach_target( $target );
ok( $source->target == $target );
ok( $target->source == $source );

ok( $source->out_type );

# Check that breaking attachment through attach_target (with new object) is done in both objects
$source->attach_target( new DS::Target( $typespec ) );
# Target should have been set to something new.
ok( $source->target != $target );
isa_ok( $source->target, 'DS::Target' );
# Source should have been reset to undef
is( $target->source, undef );

# Check that breaking attachment through attach_source (with new object) is done in both objects
$source->attach_target( $target );
$target->attach_source( new DS::Source( $typespec ) );
# Source should have been reset to undef
is( $source->target, undef );
# Target should have been set to something new
ok( $target->source != $source );
isa_ok( $target->source, 'DS::Source' );

#
# Tests that makes sure that type checks are done
#

my $larger_typespec = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'pk1' ),
        new DS::TypeSpec::Field( 'another_field' ),
        new DS::TypeSpec::Field( 'pk2' ),
        new DS::TypeSpec::Field( 'a_third_field' )]
);

# Check if possible to connect to source with a superset (should be okay)
$source = new DS::Source();
$source->out_type( $larger_typespec );
$target = new DS::Target();
$target->in_type( $typespec );
eval {
    $source->attach_target( $target );
};
ok( not defined( $@ ) or $@ eq '' ) or diag("Error was: _$@_");
ok( $source->target == $target );

# Check if possible to connect to source with a subset (should throw exception)
$source = new DS::Source();
$source->out_type( $typespec );
$target = new DS::Target();
$target->in_type( $larger_typespec );
eval {
    $source->attach_target( $target );
};
ok( defined( $@ ) and $@ ne '' );
is( $source->target, undef );
