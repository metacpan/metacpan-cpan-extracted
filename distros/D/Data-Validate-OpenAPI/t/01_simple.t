#!/usr/bin/perl -T

use strict;
use warnings;

use Data::Validate::OpenAPI;
use JSON;
use Test::Deep;
use Test::More;
use Test::Taint;

my @valid_ids = ( '0', '123', '0123' );
my @invalid_ids = ( '', 'a' );

plan tests => 2 * @valid_ids + @invalid_ids + 1;

taint_checking_ok();

my $api = Data::Validate::OpenAPI->new( decode_json '
{
  "openapi": "3.0.2",
  "paths": {
    "/": {
      "get": {
        "parameters": [
          {
            "name": "id",
            "in": "query",
            "required": true,
            "schema": {
              "format": "integer",
              "type": "integer"
            }
          }
        ]
      }
    }
  }
}
' );

for (@valid_ids) {
    my $input = { id => $_ };
    taint( values %$input );

    my $parameters = $api->validate( '/', 'get', $input );

    cmp_deeply( $parameters, { id => int $_ } );
    untainted_ok_deeply( $parameters );
}

for (@invalid_ids) {
    my $input = { id => $_ };
    taint( values %$input );

    my $parameters = $api->validate( '/', 'get', $input );
    is( scalar keys %$parameters, 0 );
}
