#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Plack::Test;
use HTTP::Request::Common;

BEGIN { use_ok('Dancer2::Serializer::CBOR') }

use Dancer2::Logger::Console;

my $serializer = Dancer2::Serializer::CBOR->new();

{
    package App;
    use Dancer2;
    set serializer => 'CBOR';

    get  '/'       => sub { +{ foo => 'bar' } };
    get  '/single' => sub { 42 };

    post '/' => sub {
        my $params = params;
        ::is_deeply( $params, { foo => 1 }, 'Correct parameters' );
        return $params;
    };
}

my $test = Plack::Test->create( App->to_app );

subtest 'basic' => sub {
    my $res = $test->request( GET '/' );

    is(
        $res->header('Content-Type'),
        'application/cbor',
        'Content-Type set up correctly',
    );

    is(
        $res->content,
        chr(0xa1).chr(0x40 + 3).'foo'.chr(0x40 + 3).'bar',
        'Serializer serializes correctly',
    );

};

subtest 'POST' => sub {
    my $res = $test->request(
        POST '/',
            'Content-Type' => 'application/cbor',
            'Content'      => $serializer->serialize(
                { foo => 1 }
            ),
    );

    is_deeply(
        $serializer->deserialize( $res->content ),
        { foo => 1 },
        'Data correctly deserialized',
    );

    is(
        $res->header('Content-Type'),
        'application/cbor',
        'Content-Type set up correctly',
    );
};

subtest 'Single parameter' => sub {
    my $res = $test->request( GET '/single' );

    is(
        $serializer->deserialize( $res->content ),
        '42',
        'Correct deserialization of a single paramter',
    );

    is(
        $res->header('Content-Type'),
        'application/cbor',
        'Content-Type set up correctly',
    );
};

