#!/usr/bin/env perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Data::FormValidator;

{
  local $@ = undef;
  eval {
    my $results = Data::FormValidator->check(
      {},
      {
        msgs => {
          my_field => 'foo',
        },
      } );
  };
  like( $@, qr/Invalid/, 'checking syntax of unknown msgs fields works' );
}

my $results;
eval {
  $results = Data::FormValidator->check(
    {},
    {
      constraints => {
        key => {
          oops => 1,
        },

      },
    } );
};

like( $@, qr/Invalid/, 'checking syntax of constraint hashrefs works' );

eval {
  $results = Data::FormValidator->check(
    {},
    {
      constraint_regexp_map => {
        qr/key/ => {
          oops => 1,
        },

      },
    } );
};
like( $@, qr/Invalid/,
  'checking syntax of constraint_regexp_map hashrefs works' );
