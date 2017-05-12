use strict;
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';
use Test::More;
use Test::Deep;
use Test::Fatal;

use Dancer2::Session::DBIC::Serializer::JSON;

my ( $serializer, $result );

# no options

is(
    exception { $serializer = Dancer2::Session::DBIC::Serializer::JSON->new },
    undef, "new with no args lived",
);

isa_ok( $serializer, "Dancer2::Session::DBIC::Serializer::JSON" );

is(
    exception {
        $result = $serializer->serialize( { foo => { camel => 'ラクダ' } } )
    },
    undef,
    "serialize { foo => { camel => 'ラクダ' } } lives",
);

cmp_ok( $result, 'eq', q({"foo":{"camel":"ラクダ"}}),
    "we got the json we expected" );

is(
    exception { $result = $serializer->deserialize(q({"foo":{"camel":"ラクダ"}})) },
    undef,
    'deserialize {"foo":{"camel":"ラクダ"}} lives',
);

cmp_deeply(
    $result,
    { foo => { camel => 'ラクダ' } },
    "we got the hashref we expected"
);

# options

is(
    exception { $serializer = Dancer2::Session::DBIC::Serializer::JSON->new( serialize_options => { pretty => 1 }) },
    undef, "new with serialize_options lived",
);

isa_ok( $serializer, "Dancer2::Session::DBIC::Serializer::JSON" );

is(
    exception {
        $result = $serializer->serialize( { foo => { camel => 'ラクダ' } } )
    },
    undef,
    "serialize { foo => { camel => 'ラクダ' } } lives",
);

like( $result, qr({\n\s+"foo"\s+:\s+{\n\s+"camel"\s+:\s+"ラクダ"\n\s+}\n}),
    "we got the json we expected" );

done_testing;
