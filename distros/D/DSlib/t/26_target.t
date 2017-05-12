#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS/Target.pm
# Creation date: 22007-04-16
# Author:        Michael Zedeler
# Description:   Runs tests of DS/Target.pm
# File:          $Source: /data/cvs/lib/DSlib/t/26_target.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 9;

BEGIN {
        $|  = 1;
        $^W = 1;
}

use_ok( 'DS::Target' );

use DS::TypeSpec;
use DS::TypeSpec::Field;

my $typespec = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'pk1' ),
        new DS::TypeSpec::Field( 'another_field' ),
        new DS::TypeSpec::Field( 'pk2' )]
);

my $target = new DS::Target();
for( $target ) {
    isnt( $_, undef );
    isa_ok( $_, 'DS::Target');
    is( $_->source, undef );
    is( $_->in_type, undef );
    
    # Must throw exception since method needs to be overridden
    eval {
        $_->receive_row( {} );
    };
    isnt( $@, undef );
    
    eval {
        $_->in_type( 'something invalid' );
    };
    isnt( $@, undef );

    eval {
        $_->attach_source( 'something invalid' );
    };
    isnt( $@, undef );

    $_->in_type( $typespec );
    is( $_->in_type, $typespec );
}

