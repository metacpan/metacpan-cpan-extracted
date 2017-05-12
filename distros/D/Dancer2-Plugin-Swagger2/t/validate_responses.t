#!/usr/bin/env perl

use strict;
use warnings;

use Hash::MultiValue;
use Test::Most tests => 3;
use Test::MockObject;

use Dancer2::Plugin::Swagger2;

sub mock_response {
    my ( $status, %headers ) = @_;

    my $response = Test::MockObject->new;

    $response->mock(
        header => sub {
            my $class = shift;
            my $value = $headers{ +shift };
            return ref $value eq 'ARRAY' ? @$value : $value;
        }
    );
    $response->set_always( status => $status );

    return $response;
}

sub first_error {
    my $method_spec = shift;
    my $result      = shift;
    my $response    = mock_response(@_);

    my @errors =
      Dancer2::Plugin::Swagger2::_validate_response( $method_spec, $response,
        $result );

    return $errors[0];
}

is first_error(
    {
        responses =>
          { 200 => { headers => { Expires => { type => 'integer' } } } }
    },
    undef, 200,
    Expires => 42
  ) => undef,
  "valid header, no errors";

like first_error(
    {
        responses => {
            200 =>
              { schema => { properties => { id => { type => 'integer' } } } }
        }
    },
    { id => 'string!' },
    200
  ) => qr/string/,
  "schema property of wrong type";

like first_error(
    {
        responses =>
          { 200 => { headers => { Expires => { type => 'integer' } } } }
    },
    undef, 200,
    Expires => 'string!'
  ) => qr/string/,
  "header value of wrong type";
