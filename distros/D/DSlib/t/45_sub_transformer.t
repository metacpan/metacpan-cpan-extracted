#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS/Transformer/Sub.pm
# Creation date: 22007-04-16
# Author:        Michael Zedeler
# Description:   Runs tests of DS/Transformer/Sub.pm
# File:          $Source: /data/cvs/lib/DSlib/t/45_sub_transformer.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
        $|  = 1;
        $^W = 1;
}

use_ok( 'DS::Transformer::Sub' );

use DS::TypeSpec;
use DS::TypeSpec::Field;

my $typespec = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'pk1' ),
        new DS::TypeSpec::Field( 'another_field' ),
        new DS::TypeSpec::Field( 'pk2' )]
);

#TODO Test sub transformer...
