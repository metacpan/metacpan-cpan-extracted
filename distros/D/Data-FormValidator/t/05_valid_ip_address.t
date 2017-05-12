#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use Data::FormValidator;

# performs a basic check to make sure valid_ip_address routine
# succeeds and fails when it should.
# by Mark Stosberg <mark@stosberg.com>

my $input_profile = {
  required    => [qw( good_ip bad_ip )],
  constraints => {
    good_ip => 'ip_address',
    bad_ip  => 'ip_address',
  } };

my $validator = new Data::FormValidator( { default => $input_profile } );

my $input_hashref = {
  'good_ip' => '127.0.0.1',
  'bad_ip'  => '300.23.1.1',
};

my ( $valids, $missings, $invalids, $unknowns );

eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $input_hashref, 'default' );
};

ok( exists $valids->{'good_ip'} );

is( $invalids->[0], 'bad_ip' );
