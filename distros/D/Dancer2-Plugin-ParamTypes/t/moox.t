#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib '.';
use t::lib::Utils;
use Plack::Test;
use HTTP::Request::Common;

eval { require MooX::Types::MooseLike::Base; 1; }
or plan 'skip_all' => 'You need MooX::Types::MooseLike::Base for this test';

plan 'tests' => 1;

{
    package MyApp;
    use Dancer2;
    use Dancer2::Plugin::ParamTypes;

    register_type_check(
        'Int' => sub {
            require MooX::Types::MooseLike::Base;

            eval { MooX::Types::MooseLike::Base::Int()->( $_[0] ); 1; }
                or return;

            return 1;
        },
    );

    get '/' => with_types [
        [ 'query', 'id', 'Int' ],
    ] => sub { return 'query'; };
}

my $test = Plack::Test->create( MyApp->to_app );

subtest 'Use type checks from other MooX::Types::MooseLike::Base' => sub {
    successful_test( $test, GET('/?id=30'), 'query' );
    missing_test( $test, GET('/'), 'query', 'id' );
    failing_test( $test, GET('/?id=k'), 'query', 'id', 'Int' );
};
