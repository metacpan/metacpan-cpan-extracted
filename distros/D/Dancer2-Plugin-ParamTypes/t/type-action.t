#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'tests' => 3;
use t::lib::Utils;
use Plack::Test;
use HTTP::Request::Common;

{
    package MyApp;
    use Dancer2;
    use Dancer2::Plugin::ParamTypes;

    my $log;

    register_type_check(
        'Int' => sub { Scalar::Util::looks_like_number( $_[0] ) } );

    register_type_action(
        'log_and_error' => sub {
            $log++;
            send_error( 'Parameter id must be Int' => 400 );
        },
    );

    get '/query' => with_types [
        [ 'query', 'id', 'Int', 'log_and_error' ],
    ] => sub { return 'query'; };
}

my $test = Plack::Test->create( MyApp->to_app );

subtest 'Correctly handled proper parameters' => sub {
    successful_test( $test, GET('/query?id=30'), 'query' );
};

subtest 'Failing missing parameters' => sub {
    missing_test( $test, GET('/query'), 'query', 'id' );
};

subtest 'Failing incorrect parameters' => sub {
    failing_test( $test, GET('/query?id=k'), 'query', 'id', 'Int', );
};
