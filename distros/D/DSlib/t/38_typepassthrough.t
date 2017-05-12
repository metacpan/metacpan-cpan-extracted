#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS::Transformer::TypePassthrough.pm
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Tests DS::Transformer::TypePassthrough
# File:          $Source: /data/cvs/lib/DSlib/t/38_typepassthrough.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 19;

BEGIN {
        $|  = 1;
        $^W = 1;
}

use_ok('DS::Transformer::TypePassthrough');

use DS::Source;
use DS::Target;

use DS::TypeSpec;
use DS::TypeSpec::Field;

my $typespec = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'pk1' ),
        new DS::TypeSpec::Field( 'monkeys' )]
);

my $other_typespec = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'pk1' ),
        new DS::TypeSpec::Field( 'elephants' )]
);

ok( not $typespec->contains( $other_typespec ) );
ok( not $other_typespec->contains( $typespec ) );

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
    $_ = new DS::Transformer::TypePassthrough;
    ok( $_ );
    isa_ok( $_ => 'DS::Transformer::TypePassthrough' );

    eval {
        $_->in_type( $typespec );
    };
    isnt( $@, '', 'Setting in_type should throw exception' );

    eval {
        $_->out_type( $typespec );
    };
    isnt( $@, '', 'Setting out_type should throw exception' );

    eval {
        $_->attach_source( $source )
    };
    is( $@, '', 'Attaching source should not throw exception'  );

    # Double check that types are the same
    ok( $_->out_type->contains( $source->out_type ) );
    ok( $source->out_type->contains( $_->out_type ) );
    ok( $source->out_type->{name} eq $_->out_type->{name} );

    eval {
        $_->attach_target( $target );
    };
    is( $@, '', 'Attaching target should not throw exception'  );

    # Double check that types are the same
    ok( $_->in_type->contains( $target->in_type ) );
    ok( $target->in_type->contains( $_->in_type ) );
    ok( $target->in_type->{name} eq $_->in_type->{name} );

    # Now attach target first and source second

    $_ = new DS::Transformer::TypePassthrough;

    eval {
        $_->attach_target( $target );
    };
    is( $@, '', 'Attaching target should not throw exception'  );

    eval {
        $_->attach_source( $source )
    };
    is( $@, '', 'Attaching source should not throw exception'  );


    # Second part
    # Testing that incompatible types leads to exceptions.
    $target->in_type( $other_typespec );

    # Start over with a new pt transformer
    $_ = new DS::Transformer::TypePassthrough;
    $_->attach_source( $source );
    eval {
        $_->attach_target( $target );
    };
    isnt( $@, '' );

    # Start over with a new pt transformer
    $_ = new DS::Transformer::TypePassthrough;
    $_->attach_target( $target );
    eval {
        $_->attach_source( $source );
    };
    isnt( $@, '' );

}

