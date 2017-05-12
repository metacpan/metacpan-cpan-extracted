#!/usr/bin/perl

# Testing support methods of various types

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use CPANTS::Weight 0.02;

my $cpants = CPANTS::Weight->new;
isa_ok( $cpants, 'CPANTS::Weight' );

my $source_weight = $cpants->source_weight;
isa_ok( $source_weight, 'Algorithm::Dependency::Source::DBI' );

my $source_volatility = $cpants->source_volatility;
isa_ok( $source_volatility, 'Algorithm::Dependency::Source::Invert' );

my $algorithm_weight = $cpants->algorithm_weight;
isa_ok( $algorithm_weight, 'Algorithm::Dependency::Weight' );

my $algorithm_volatility = $cpants->algorithm_volatility;
isa_ok( $algorithm_volatility, 'Algorithm::Dependency::Weight' );
