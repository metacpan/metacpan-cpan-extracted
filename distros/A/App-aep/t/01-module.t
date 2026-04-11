#!/usr/bin/env perl

use warnings;
use strict;
use v5.28;

use Test::More;

# Test 1: Module loads
use_ok('App::aep');

# Test 2: Module version is set
ok( defined $App::aep::VERSION, 'VERSION is defined' );
like( $App::aep::VERSION, qr/^\d+\.\d+$/, 'VERSION looks like a version number' );

# Test 3: Constructor works
my $obj = App::aep->new( { '_passed_args' => {} } );
isa_ok( $obj, 'App::aep' );

# Test 4: Constructor stores args
my $obj2 = App::aep->new( { '_passed_args' => { 'test' => 1 } } );
is( $obj2->{'_passed_args'}->{'test'}, 1, 'Constructor passes args through' );

done_testing();
