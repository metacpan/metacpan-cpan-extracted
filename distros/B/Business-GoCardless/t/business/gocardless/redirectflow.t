#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::RedirectFlow' );
isa_ok(
    my $RedirectFlow = Business::GoCardless::RedirectFlow->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
        ),
    ),
    'Business::GoCardless::RedirectFlow'
);

can_ok(
    $RedirectFlow,
    qw/
        created_at
        currency
        description
        expires_at
        id
        interval_length
        interval_unit
        max_amount
        merchant_id
        name
        next_interval_start
        remaining_amount
        setup_fee
        status
        uri
        user_id

        cancel

        inactive
        active
        cancelled
        expired
    /,
);

is( $RedirectFlow->endpoint,'/redirect_flows/%s','endpoint' );

$RedirectFlow->status( 'unknown' );

ok( ! $RedirectFlow->inactive,'inactive' );
ok( ! $RedirectFlow->active,'active' );
ok( ! $RedirectFlow->cancelled,'cancelled' );
ok( ! $RedirectFlow->expired,'expired' );

throws_ok(
    sub { $RedirectFlow->cancel },
    'Business::GoCardless::Exception',
    "->cancel on a RedirectFlow is not meaningful in the Pro API",
);

# monkey patching LWP here to make this test work without
# having to actually hit the endpoints or use credentials
no warnings 'redefine';
no warnings 'once';
my $mock = Test::MockObject->new;
$mock->mock( 'is_success',sub { 1 } );
$mock->mock( 'header',sub {} );
*LWP::UserAgent::request = sub { $mock };
my $i = 0;
$mock->mock( 'content',sub { ! $i++ ? _redirect_flow_json() : _mandate_json() } );

is( $RedirectFlow->mandate->next_possible_charge_date,'2017-09-27','->mandate' );

done_testing();

sub _mandate_json {
    return qq!{
        "mandates":{
            "id":"MD000660000000",
            "created_at":"2017-09-12T20:37:07.787Z",
            "reference":"MAND-RZ000S",
            "status":"active",
            "scheme":"bacs",
            "next_possible_charge_date":"2017-09-27",
            "payments_require_approval":false,
            "metadata":{},
            "links":{
                "customer_bank_account":"BA00060000000W",
                "creditor":"CR000020000008",
                "customer":"CU0006J00000TV"
            }
        }
    }!;
}

sub _redirect_flow_json {

    return qq!{
          "redirect_flows": {
            "id": "RE123",
            "description": "Wine boxes",
            "session_token": "SESS_wSs0uGYMISxzqOBq",
            "scheme": null,
            "success_redirect_url": "https://example.com/pay/confirm",
            "redirect_url": "http://pay.gocardless.dev/flow/RE123",
            "created_at": "2014-10-22T13:10:06.000Z",
            "links": {
              "mandate": "MD123",
              "creditor": "CR123"
            }
          }
        }!;
}

# vim: ts=4:sw=4:et
