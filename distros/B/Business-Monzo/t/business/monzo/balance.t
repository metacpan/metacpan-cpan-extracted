#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Monzo::Client;

use_ok( 'Business::Monzo::Balance' );
isa_ok(
    my $Balance = Business::Monzo::Balance->new(
        'account_id'      => 1,
        'client'          => Business::Monzo::Client->new(
            token      => 'foo',
        ),
    ),
    'Business::Monzo::Balance'
);

can_ok(
    $Balance,
    qw/
        url
        get
        to_hash
        as_json
        TO_JSON

        account_id
        balance
        currency
        spend_today
    /,
);

is( $Balance->url,'https://api.monzo.com/balance?account_id=1','url' );

no warnings 'redefine';

*Business::Monzo::Client::api_get = sub {
    {
        "balance"     => 5000,
        "currency"    => 'GBP',
        "soend_today" => 0,
    };
};

ok( $Balance = $Balance->get,'->get' );
isa_ok( $Balance->currency,'Data::Currency' );

ok( $Balance->to_hash,'to_hash' );
ok( $Balance->as_json,'as_json' );
ok( $Balance->TO_JSON,'TO_JSON' );

done_testing();

# vim: ts=4:sw=4:et
