#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;
use Data::FormValidator;

my $input_profile = {
  required    => [qw( email phone likes )],
  optional    => [qq( toppings )],
  constraints => {
    email => "email",
    phone => "phone",
    likes => {
      constraint => sub { return 1; },
      params     => [qw( likes email )],
    },
  },
  dependencies => {
    animal => [qw( species no_legs )],
    plant  => {
      tree   => [qw( trunk root )],
      flower => [qw( petals stem )],
    },
  },
  field_filters => {
    email => sub { return $_[0]; },
  },
};

my $validator = new Data::FormValidator( { default => $input_profile } );

my $input_hashref = {
  email    => 'invalidemail',
  phone    => '201-999-9999',
  likes    => [ 'a', 'b' ],
  toppings => 'foo',
  animal   => 'goat',
  plant    => 'flower'
};

my ( $valids, $missings, $invalids, $unknowns );

eval
{
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $input_hashref, 'default' );
};
is $@, '', 'survives';

ok( exists $valids->{'phone'}, "phone is valid" );

is( $invalids->[0], 'email', 'email is invalid' );

my %missings;
@missings{@$missings} = ();
ok( exists $missings{$_} ) for (qw(species no_legs petals stem));
is( @$missings, 4 );
