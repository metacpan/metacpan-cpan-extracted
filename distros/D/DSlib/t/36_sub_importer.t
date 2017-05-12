#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS/Importer/Sub.pm
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Runs tests of DS/Importer/Sub.pm
# File:          $Source: /data/cvs/lib/DSlib/t/36_sub_importer.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
        $|  = 1;
        $^W = 1;
}

use_ok( 'DS::Importer::Sub' );

use DS::TypeSpec;
use DS::TypeSpec::Field;
use DS::Target::Sink;

my $typespec = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'pk1' ),
        new DS::TypeSpec::Field( 'another_field' ),
        new DS::TypeSpec::Field( 'pk2' )]
);

#TODO Write tests of this class and then replace clunky CountImporter-thingy in the following tests by a lightweight sub-importer

my $importer;
my $sink = new DS::Target::Sink;

for( $importer ) {
    eval {
        $_ = new DS::Importer::Sub( sub { return undef }, $typespec, $sink );
        $_->execute();
    };
    ok( (not $@), 'No exceptions when setting up trivial tree' );

    eval {
        $_ = new DS::Importer::Sub( sub { return undef }, $typespec );
        $_->execute();
    };
    ok( $@, 'Exception when trying to execute() without target' );

    $_ = new DS::Importer::Sub( sub { return undef }, $typespec );
    $_->attach_target( $sink );
    $_->execute();
}

