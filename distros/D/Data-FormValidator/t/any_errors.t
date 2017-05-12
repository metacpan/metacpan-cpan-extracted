#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Data::FormValidator;

my $dfv_standard_any_errors = Data::FormValidator->new( {} );
my $dfv_custom_any_errors =
  Data::FormValidator->new( {}, { msgs => { any_errors => 'some_errors' } } );

my %profile = ( required => 'foo', );

my %good_input = ( 'foo' => 1, );
my %bad_input  = ( 'bar' => 1, );

my ( $results, $msgs );

# standard 'any_errors', good input
$results = $dfv_standard_any_errors->check( \%good_input, \%profile );
$msgs = $results->msgs;

ok( $results,     "[standard any_errors] good input passed" );
ok( !keys %$msgs, "[standard any_errors] no error messages" );

# standard 'any_errors', bad input
$results = $dfv_standard_any_errors->check( \%bad_input, \%profile );
$msgs = $results->msgs;

ok( !$results,   "[standard any_errors] bad input caught" );
ok( keys %$msgs, "[standard any_errors] error messages reported" );

# custom 'any_errors', good input
$results = $dfv_custom_any_errors->check( \%good_input, \%profile );
$msgs = $results->msgs;

ok( $results,                "[custom any_errors] good input passed" );
ok( !keys %$msgs,            "[custom any_errors] no error messages" );
ok( !$msgs->{'some_errors'}, "[custom any_errors] 'some_errors' not reported" );

# custom 'any_errors', bad input
$results = $dfv_custom_any_errors->check( \%bad_input, \%profile );
$msgs = $results->msgs;

ok( !$results,              "[custom any_errors] bad input caught" );
ok( keys %$msgs,            "[custom any_errors] error messages reported" );
ok( $msgs->{'some_errors'}, "[custom any_errors] 'some_errors' reported" );

