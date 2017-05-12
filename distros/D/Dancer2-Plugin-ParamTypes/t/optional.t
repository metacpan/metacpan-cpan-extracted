#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'tests' => 2;
use t::lib::Utils;
use Plack::Test;
use HTTP::Request::Common;

{
    package MyApp;
    use Dancer2;
    use Dancer2::Plugin::ParamTypes;

    register_type_check(
        'Int' => sub { Scalar::Util::looks_like_number( $_[0] ) } );

    register_type_check( 'Str' => sub { defined $_[0] && length $_[0] > 1 } );

    get '/query' => with_types [
        [ 'query', 'id', 'Int' ],
        'optional' => [ 'query', 'name', 'Str' ],
    ] => sub { return 'query'; };
}

my $test = Plack::Test->create( MyApp->to_app );

subtest 'Successful optional parameters' => sub {
    successful_test( $test, GET('/query?id=30'), 'query' );
    successful_test( $test, GET('/query?id=30&name=Sawyer'), 'query' );
};

subtest 'Failing optional parameter' => sub {
    failing_test( $test, GET('/query?id=30&name='), 'query', 'name', 'Str', );
};
