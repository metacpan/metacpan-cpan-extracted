#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS/TypeSpec.pm
# Creation date: 2007-04-14
# Author:        Michael Zedeler
# Description:   Runs tests of DS/TypeSpec.pm
# File:          $Source: /data/cvs/lib/DSlib/t/20_typespec.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 20;

BEGIN {
        $|  = 1;
        $^W = 1;
}

use_ok( 'DS::TypeSpec' );

use_ok( 'DS::TypeSpec::Field' );

my $field = new DS::TypeSpec::Field( 'test' );
isnt( $field, undef );
isa_ok( $field, 'DS::TypeSpec::Field' );
is( $field->{name}, 'test' );



my $typespec = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'pk1' ),
        new DS::TypeSpec::Field( 'another_field' ),
        new DS::TypeSpec::Field( 'pk2' )]
);

for( $typespec ) {
    isnt( $_, undef );
    isa_ok( $_, 'DS::TypeSpec' );
    is( $_->{name}, 'mytype' );
    
    is_deeply( [sort keys %{$_->{fields}}], ['another_field', 'pk1', 'pk2']);  
}

# Testing methods

my $subtype = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'another_field' ),
        new DS::TypeSpec::Field( 'pk2' )]
);

my $supertype = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'pk1' ),
        new DS::TypeSpec::Field( 'another_field' ),
        new DS::TypeSpec::Field( 'pk2' ),
        new DS::TypeSpec::Field( 'a_third_field' )]
);

my $incomparable_type = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'pk1' ),
        new DS::TypeSpec::Field( 'another_field' ),
        new DS::TypeSpec::Field( 'a_third_field' )]
);

for( $typespec ) {
    ok( $_->contains( $subtype ) );
    ok( not $_->contains( $supertype ) );
    ok( not $_->contains( $incomparable_type ) );
}

my $field_subset = {'new_pk1' => 'pk1', 'new_another_field' => 'another_field'};
for( $typespec->project( 'p_type', $field_subset ) ) {
    ok( $_ );
    isa_ok( $_, 'DS::TypeSpec' );
    is_deeply( [sort keys %{$_->{fields}}], ['new_another_field', 'new_pk1']);
}

my $field_duplicate_set = {'new_pk1' => 'pk1', 'new_pk1_2' => 'pk1'};
for( $typespec->project( 'p_type', $field_duplicate_set ) ) {
    ok( $_ );
    isa_ok( $_, 'DS::TypeSpec' );
    is_deeply( [sort keys %{$_->{fields}}], ['new_pk1', 'new_pk1_2']);
}

# Check that asking for non existing fields results in an error
my $field_superset = {'new_pk1' => 'pk1', 'new_another_field' => 'another_field', 'new_a_nonexisting_field' => 'a_nonexisting_field'};
eval {
    my $typespec = $typespec->project( 'p_type', $field_superset );
    ok( not $typespec );
};
isnt( $@, undef );

# Check that asking for non existing fields results in an error
my $field_incompatible_set = {'new_pk1' => 'pk1', 'new_a_nonexisting_field' => 'a_nonexisting_field'};
eval {
    my $typespec = $typespec->project( 'p_type', $field_incompatible_set );
    ok( not $typespec );
};
isnt( $@, undef );

