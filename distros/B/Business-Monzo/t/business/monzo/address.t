#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Monzo::Client;

$Business::Monzo::Resource::client = Business::Monzo::Client->new(
    token      => 'foo',
);

use_ok( 'Business::Monzo::Address' );
isa_ok(
    my $Address = Business::Monzo::Address->new(
        "address"   => "98 Southgate Road",
        "city"      => "London",
        "country"   => "GB",
        "latitude"  => 51.54151,
        "longitude" => -0.08482400000002599,
        "postcode"  => "N1 3JD",
        "region"    => "Greater London",
        'client'   => Business::Monzo::Client->new(
            token      => 'foo',
        ),
    ),
    'Business::Monzo::Address'
);

can_ok(
    $Address,
    qw/
        url
        get
        to_hash
        as_json
        TO_JSON

        address
        city
        country
        latitude
        longitude
        postcode
        region
    /,
);

throws_ok(
    sub { $Address->get },
    'Business::Monzo::Exception'
);

is(
    $@->message,
    'Monzo API does not currently support getting address data',
    ' ... with expected message'
);

throws_ok(
    sub { $Address->url },
    'Business::Monzo::Exception'
);

is(
    $@->message,
    'Monzo API does not currently support getting address data',
    ' ... with expected message'
);

ok( $Address->to_hash,'to_hash' );
ok( $Address->as_json,'as_json' );
ok( $Address->TO_JSON,'TO_JSON' );

done_testing();

# vim: ts=4:sw=4:et
