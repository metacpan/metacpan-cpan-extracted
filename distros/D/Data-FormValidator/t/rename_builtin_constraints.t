#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Data::FormValidator;
use Data::FormValidator::Constraints qw(
  FV_max_length
);

my $result = Data::FormValidator->check( {
    first_names => 'Too long',
  },
  {
    required           => [qw/first_names/],
    constraint_methods => {
      first_names => {
        constraint_method => FV_max_length(3),
        name              => 'custom_length',
      }
    },
    msgs => {
      constraints => {
        custom_length => 'Custom length msg',
      }
    },
  } );

like(
  $result->msgs->{'first_names'},
  qr/Custom length msg/,
  "built-ins can have custom names"
);
