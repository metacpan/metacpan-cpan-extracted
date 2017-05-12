#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

{
  my $test_name = "checks for correct behavior when 'required'
         is not specified; fails if _arrayify() does not return an empty list";

  use Data::FormValidator;
  my $input_profile = { optional => [qw( email )] };
  my $validator = Data::FormValidator->new( { default => $input_profile } );

  my $input_hashref = { email => 'bob@example.com' };

  my ( $valids, $missings, $invalids, $unknowns );
  eval
  {
    ( $valids, $missings, $invalids, $unknowns ) =
      $validator->validate( $input_hashref, 'default' );
  };
  is( $@,         '', $test_name );
  is( @$missings, 0,  $test_name );
}

{
  my $test_name = "arrayref with first element undef";
  use Data::FormValidator::Results;

  my $inputs = [ undef, 1, 2, 3, "Echo", "Foxtrot" ];
  my $retval = Data::FormValidator::Results::_arrayify($inputs);
  my @retval = Data::FormValidator::Results::_arrayify($inputs);

  is( $retval, 6, "$test_name... in scalar context" );
  is_deeply( \@retval, $inputs, "$test_name..in list context" );

}
