use strict;
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';
use Test::More;
use Test::Deep;
use Test::Fatal;

BEGIN {
    eval "use YAML 1.15";
    plan skip_all => "YAML 1.15 required to run these tests" if $@;
}

use Dancer2::Session::DBIC::Serializer::YAML;

my ( $serializer, $result );

# no options

is(
    exception { $serializer = Dancer2::Session::DBIC::Serializer::YAML->new },
    undef, "new with no args lived",
);

isa_ok( $serializer, "Dancer2::Session::DBIC::Serializer::YAML" );

is(
    exception {
        $result = $serializer->serialize( { foo => { camel => 'ラクダ' } } )
    },
    undef,
    "serialize { foo => { camel => 'ラクダ' } } lives",
);

like( $result, qr{foo:\n camel: ラクダ}, "we got the yaml we expected" );

is(
    exception {
        $result = $serializer->deserialize(qq{---\nfoo:\n camel: ラクダ})
    },
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
    exception {
        $serializer =
          Dancer2::Session::DBIC::Serializer::YAML->new(
            serialize_options => { indent_width => 3 } )
    },
    undef,
    "new with serialize_options lived",
);

isa_ok( $serializer, "Dancer2::Session::DBIC::Serializer::YAML" );

is(
    exception {
        $result = $serializer->serialize( { foo => { camel => 'ラクダ' } } )
    },
    undef,
    "serialize { foo => { camel => 'ラクダ' } } lives",
);

like( $result, qr{foo:\n   camel: ラクダ}, "we got the yaml we expected" );

done_testing;
