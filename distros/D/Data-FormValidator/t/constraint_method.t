
use strict;
use warnings;
use Test::More qw/no_plan/;
use Data::FormValidator;

my $result = Data::FormValidator->check(
  { field => 'value' },
  {
    required    => 'field',
    constraints => {
      field => {
        constraint_method => sub {
          my $dfv  = shift;
          my $name = $dfv->get_current_constraint_name;
          is( $name, 'test_name', "get_current_constraint_name works" );
        },
        name => 'test_name',
      }
    },
  } );

{
  my $result = Data::FormValidator->check( {
      to_pass     => 'value',
      to_fail     => 'value',
      map_to_pass => 'value',
      map_to_fail => 'value',
    },
    {
      required => [
        qw/
          to_pass
          to_fail
          map_to_pass
          map_to_fail
          /
      ],
      constraint_methods => {
        to_pass => qr/value/,
        to_fail => qr/wrong/,
      },
      constraint_method_regexp_map => {
        qr/map_to_p.*/ => qr/value/,
        qr/map_to_f.*/ => qr/fail/,

      },
    } );

  ok( $result->invalid('to_fail'),
    "using qr with constraint_method fails as expected" );
  ok( $result->valid('to_pass'),
    "using qr with constraint_method succeeds as expected" );
  ok( $result->invalid('map_to_fail'),
    "using qr with constraint_method_regexp_map fails as expected" );
  ok( $result->valid('map_to_pass'),
    "using qr with constraint_method_regexp_map succeeds as expected" );
}
