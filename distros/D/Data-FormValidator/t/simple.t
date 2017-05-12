#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use Data::FormValidator;

my $input_profile = {
  required    => [qw( email phone likes )],
  optional    => [qq( toppings )],
  constraints => {
    email => "email",
    phone => "phone",
  } };

my $validator = new Data::FormValidator( { default => $input_profile } );

my $input_hashref = {
  email    => 'invalidemail',
  phone    => '201-999-9999',
  likes    => [ 'a', 'b' ],
  toppings => 'foo'
};

my ( $valids, $missings, $invalids, $unknowns ) = ( {}, [], [], [] );

eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $input_hashref, 'default' );
};
is( $@, '', 'survived eval' );

ok( exists $valids->{'phone'}, "phone is valid" );

is( $invalids->[0], 'email' )
