#!/usr/bin/env perl

use strict;
use warnings;

use Hash::MultiValue;
use Test::Most tests => 6;
use Test::MockObject;

use Dancer2::Plugin::Swagger2;

sub mock_request {
    my %data = @_;

    my $request = Test::MockObject->new;

    $request->mock( header => sub { shift; @{ $data{header}{ +shift } } } );
    for (qw<query path formData>) {
        my $hash = Hash::MultiValue->from_mixed( $data{$_} );
        $request->set_always( "${_}_parameters" => $hash );
    }

    return $request;
}

sub first_error {
    my ( $method_spec, $request_data ) = @_;

    my $request = mock_request(%$request_data);

    my @errors =
      Dancer2::Plugin::Swagger2::_validate_request( $method_spec, $request );

    return $errors[0];
}

# test mock objects
is_deeply [ mock_request( header => { foo => ['bar'] } )->header("foo") ] =>
  ["bar"];
is_deeply [ mock_request( query => { foo => [qw<bar baz>] } )
      ->query_parameters->get_all("foo") ] => [qw<bar baz>];

like first_error(
    { parameters => [ { in => 'query', name => 'foo', required => 1 } ] } ) =>
  qr/no value/i,
  "no value";

like first_error(
    { parameters => [ { in => 'query', name => 'foo', required => 1 } ] },
    { query => { foo => [qw<bar baz>] } } ) => qr/multiple values/i,
  "multiple values";

is first_error( { parameters => [ { in => 'query', name => 'foo' } ] } ) =>
  undef,
  "no errors";

like first_error(
    { parameters => [ { in => 'query', name => 'foo', type => 'string' } ] },
    { query => { foo => 42 } } ) => qr/string/i,
  "wrong type";

# TODO test body input specified by schema
