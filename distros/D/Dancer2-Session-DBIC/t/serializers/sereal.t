use strict;
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';
use Test::More;
use Test::Deep;
use Test::Fatal;

BEGIN {
    eval "use Sereal::Decoder";
    plan skip_all => "Sereal::Decoder required to run these tests" if $@;
    eval "use Sereal::Encoder";
    plan skip_all => "Sereal::Encoder required to run these tests" if $@;
}

use Dancer2::Session::DBIC::Serializer::Sereal;

my ( $serializer, $result );

my $decoder = Sereal::Decoder->new;

# no options

is(
    exception { $serializer = Dancer2::Session::DBIC::Serializer::Sereal->new },
    undef,
    "new with no args lived",
);

isa_ok( $serializer, "Dancer2::Session::DBIC::Serializer::Sereal" );

is(
    exception {
        $result = $serializer->serialize( { foo => { camel => 'ラクダ' } } )
    },
    undef,
    "serialize { foo => { camel => 'ラクダ' } } lives",
);

ok $decoder->looks_like_sereal($result), "result looks like sereal";

cmp_deeply(
    $decoder->decode($result),
    { foo => { camel => 'ラクダ' } },
    "we got what we expected"
);

is(
    exception {
        $result = $serializer->deserialize($result)
    },
    undef,
    'deserialize lives',
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
          Dancer2::Session::DBIC::Serializer::Sereal->new(
            serialize_options => { compress => 1 } )
    },
    undef,
    "new with serialize_options lived",
);

isa_ok( $serializer, "Dancer2::Session::DBIC::Serializer::Sereal" );

is(
    exception {
        $result = $serializer->serialize( { foo => { camel => 'ラクダ' } } )
    },
    undef,
    "serialize { foo => { camel => 'ラクダ' } } lives",
);

ok $decoder->looks_like_sereal($result), "result looks like sereal";

cmp_deeply(
    $decoder->decode($result),
    { foo => { camel => 'ラクダ' } },
    "we got what we expected"
);

done_testing;
