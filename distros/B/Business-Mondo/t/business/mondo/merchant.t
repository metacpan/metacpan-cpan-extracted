#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Mojo::JSON;

use Business::Mondo::Client;

$Business::Mondo::Resource::client = Business::Mondo::Client->new(
    token      => 'foo',
);

use_ok( 'Business::Mondo::Merchant' );
isa_ok(
    my $Merchant = Business::Mondo::Merchant->new(
        "emoji"    => "💵",
        "updated"  => "2016-04-23T09:22:45.005Z",
        "online"   => Mojo::JSON::false,
        "category" => "cash",
        "metadata" => {
            "suggested_tags"      => "#money #ATM #cashpoint #cash ",
            "google_places_id"    => "ChIJzXdG2omVjkcRqXc-9o1QxZI",
            "foursquare_category" => "ATM",
            "foursquare_id"       => "",
            "foursquare_website"  => "",
            "suggested_name"      => "Caixa 24 Horas",
            "foursquare_category_icon" => "https://ss3.4sqi.net/img/categories_v2/shops/financial_88.png",
            "google_places_icon"       => "https://maps.gstatic.com/mapfiles/place_api/icons/bank_dollar-71.png",
            "google_places_name"       => "UBS",
            "created_for_merchant"     => "merch_0000000000000000000001",
            "created_for_transaction"  => "1",
            "twitter_id"               => "",
            "website"                  => ""
        },
        "disable_feedback" => Mojo::JSON::false,
        "atm"              => Mojo::JSON::true,
        "logo"             => "",
        "group_id"         => "grp_0000000000000000000001",
        "id"               => "merch_0000000000000000000001",
        "name"             => "ATM",
        "created"          => "2016-04-23T09:22:45.005Z",
        "address"          => {
            "country"         => "CHE",
            "city"            => "Villars-sur-o",
            "longitude"       => 7.076864,
            "address"         => "",
            "region"          => "",
            "formatted"       => "Villars-sur-o, 1884, Switzerland",
            "latitude"        => 46.3118929,
            "approximate"     => Mojo::JSON::false,
            "zoom_level"      => 17,
            "short_formatted" => "Villars-sur-o, 1884, Switzerland",
            "postcode"        => "1884"
        },
        'client' => Business::Mondo::Client->new( token => 'foo', ),
    ),
    'Business::Mondo::Merchant'
);

can_ok(
    $Merchant,
    qw/
        url
        get
        to_hash
        as_json
        TO_JSON

        id
        emoji
        updated
        online
        category
        metadata
        disable_feedback
        atm
        logo
        group_id
        id
        name
        created
        address
    /,
);

is(
    $Merchant->url,
    'https://api.getmondo.co.uk/merchants/merch_0000000000000000000001',
    'url'
);

throws_ok(
    sub { $Merchant->get },
    'Business::Mondo::Exception'
);

is(
    $@->message,
    'Mondo API does not currently support getting merchant data',
    ' ... with expected message'
);

isa_ok( $Merchant->address,'Business::Mondo::Address' );
isa_ok( $Merchant->created,'DateTime' );

ok( $Merchant->to_hash,'to_hash' );
ok( $Merchant->as_json,'as_json' );
ok( $Merchant->TO_JSON,'TO_JSON' );

done_testing();

# vim: ts=4:sw=4:et
