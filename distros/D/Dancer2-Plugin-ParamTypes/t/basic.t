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

    get '/route/:id' => with_types [
        [ 'route', 'id',  'Int' ],
    ] => sub { return 'route'; };

    get '/query' => with_types [
        [ 'query', 'id', 'Int' ],
    ] => sub { return 'query'; };

    post '/body' => with_types [
        [ 'body', 'id', 'Int' ],
    ] => sub { return 'body' };
}

my $test = Plack::Test->create( MyApp->to_app );

subtest 'Correctly handled proper parameters' => sub {
    successful_test( $test, GET('/route/30'),    'route' );
    successful_test( $test, GET('/query?id=30'), 'query' );
    successful_test( $test, GET('/query?id=30&id=4'), 'query' );
    successful_test( $test, POST( '/body', 'Content' => 'id=30' ), 'body' );
    successful_test( $test, POST( '/body', 'Content' => 'id=30&id=77' ), 'body' );
};

subtest 'Failing missing parameters' => sub {
    missing_test( $test, GET('/query'), 'query', 'id' );
    missing_test( $test, POST('/body'), 'body', 'id' );
};

subtest 'Failing incorrect parameters' => sub {
    failing_test( $test, GET('/route/k'), 'route', 'id', 'Int', );
    failing_test( $test, GET('/query?id=k'), 'query', 'id', 'Int', );
    failing_test( $test, POST( '/body', 'Content' => 'id=k' ), 'body', 'id', 'Int' );
};
