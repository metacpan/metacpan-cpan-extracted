#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'tests' => 3;
use lib '.';
use t::lib::Utils;
use Plack::Test;
use HTTP::Request::Common;

{
    package MyApp;
    use Dancer2;
    use Dancer2::Plugin::ParamTypes;

    register_type_check(
        'Int' => sub { Scalar::Util::looks_like_number( $_[0] ) } );

    any [ 'get', 'post' ] => '/query_or_body' => with_types [
        [ ['query', 'body'], 'id', 'Int' ],
    ] => sub {
        my $method = request->method;
        return $method eq 'GET' ? 'query' : 'body';
    };
}

my $test = Plack::Test->create( MyApp->to_app );

subtest 'Correctly handled proper parameters' => sub {
    successful_test( $test, GET('/query_or_body?id=30'), 'query' );
    successful_test( $test, POST( '/query_or_body', 'Content' => 'id=30' ),
        'body' );
};

subtest 'Failing missing parameters' => sub {
    missing_test( $test, GET('/query_or_body'), 'query', 'id' );
    missing_test( $test, POST('/query_or_body'), 'body', 'id' );
};

subtest 'Failing incorrect parameters' => sub {
    failing_test( $test, GET('/query_or_body?id=k'), 'query', 'id', 'Int', );
    failing_test( $test, POST( '/query_or_body', 'Content' => 'id=k' ),
        'body', 'id', 'Int' );
};
