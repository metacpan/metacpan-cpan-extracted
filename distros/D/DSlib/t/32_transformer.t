#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS/Transformer.pm
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Tests DS::Transformer
# File:          $Source: /data/cvs/lib/DSlib/t/32_transformer.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
        $|  = 1;
        $^W = 1;
}

use_ok('DS::Transformer');

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

my $transformer;

for( $transformer ) {
    $_ = new DS::Transformer();
    ok( $_ );
    isa_ok( $_ => 'DS::Transformer' );

    $_ = new DS::Transformer( $typespec );
    is( $_->in_type, $typespec, 'Set in_type through constructor' );
    
    $_ = new DS::Transformer( undef, $typespec );
    is( $_->out_type, $typespec, 'Set out_type through constructor' );
    
    $_ = new DS::Transformer( $typespec, undef, $source );
    is( $_->source, $source, 'Set source through constructor' );
    
    $_ = new DS::Transformer( undef, $typespec, undef, $target );
    is( $_->target, $target, 'Set target through constructor' );
}

# TODO Handle passing of eos correctly
