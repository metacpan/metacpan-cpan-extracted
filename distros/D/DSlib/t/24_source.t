#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS/Source.pm
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Runs tests of DS/Source.pm
# File:          $Source: /data/cvs/lib/DSlib/t/24_source.t,v $
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

use_ok( 'DS::Source' );

use DS::TypeSpec;
use DS::TypeSpec::Field;

my $typespec = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'pk1' ),
        new DS::TypeSpec::Field( 'another_field' ),
        new DS::TypeSpec::Field( 'pk2' )]
);

my $source = new DS::Source();
for( $source ) {
    isnt( $_, undef );
    isa_ok( $_, 'DS::Source');
    is( $_->target, undef );
    is( $_->out_type, undef );

    # Must throw exception when no target to pass row to
    eval {
        $_->pass_row( {} );
    };
    isnt( $@, undef );

    eval {
        $_->in_type( 'something invalid' );
    };
    isnt( $@, undef );

    eval {
        $_->attach_target( 'something invalid' );
    };
    isnt( $@, undef );

    $_->out_type( $typespec );
    is( $_->out_type, $typespec );
}
