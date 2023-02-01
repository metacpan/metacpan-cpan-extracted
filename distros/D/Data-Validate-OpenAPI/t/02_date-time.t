#!/usr/bin/perl -T

use strict;
use warnings;

use Data::Validate::OpenAPI;
use JSON;
use Test::Deep;
use Test::More;
use Test::Taint;

my @valid_datetimes = ( '2002-07-01T13:50:05Z' );
my @invalid_datetimes = ( '2002-07-01T13:50:05' );

plan tests => 2 * @valid_datetimes + @invalid_datetimes + 1;

taint_checking_ok();

my $api = Data::Validate::OpenAPI->new( decode_json '
{
  "openapi": "3.0.2",
  "paths": {
    "/": {
      "get": {
        "parameters": [
          {
            "name": "date-time",
            "in": "query",
            "schema": {
              "format": "date-time",
              "type": "string"
            }
          }
        ]
      }
    }
  }
}
' );

for (@valid_datetimes) {
    my $input = { 'date-time' => $_ };
    taint( values %$input );

    my $parameters = $api->validate( '/', 'get', $input );

    cmp_deeply( $parameters, { 'date-time' => $_ } );
    untainted_ok_deeply( $parameters );
}

for (@invalid_datetimes) {
    my $input = { id => $_ };
    taint( values %$input );

    my $parameters = $api->validate( '/', 'get', $input );
    is( scalar keys %$parameters, 0 );
}
