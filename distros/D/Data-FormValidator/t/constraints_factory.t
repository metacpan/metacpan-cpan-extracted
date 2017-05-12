#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Data::FormValidator;
use Data::FormValidator::ConstraintsFactory 'make_length_constraint';

{
  my $results = Data::FormValidator->check( {
      short_enough => 'doh',
      too_long     => "So long she's happy",
    },
    {
      required    => [qw/too_long short_enough/],
      constraints => {
        too_long     => make_length_constraint(5),
        short_enough => make_length_constraint(5),
      } } );

  ok( $results->valid('short_enough'),
    'positive test for make_length_constraint()' );
  ok( !$results->valid('too_long'),
    'negative test for make_length_constraint()' );

}
