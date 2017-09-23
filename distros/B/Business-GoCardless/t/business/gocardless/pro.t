#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::MockObject;
use Test::Exception;
use JSON;

# soft requirements of Business::GoCardless::Client
# "soft" in that they're not required => 1 but must
# be set in the ENV var if not passed to constructor
$ENV{GOCARDLESS_APP_ID}         = 'foo';
$ENV{GOCARDLESS_WEBHOOK_SECRET} = 'bar';
$ENV{GOCARDLESS_MERCHANT_ID}    = 'baz';

# this makes Business::GoCardless::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{GOCARDLESS_DEV_TESTING} = 1;

use_ok( 'Business::GoCardless::Pro' );
isa_ok(
    my $GoCardless = Business::GoCardless::Pro->new(
        token       => 'MvYX0i6snRh/1PXfPoc6',
    ),
    'Business::GoCardless::Pro'
);

can_ok(
    $GoCardless,
    qw/
        token
        client_details
        client
        bill

        payment
        payments
        subscription
        pre_authorizations
        customer
        customers
        new_bill_url
        new_pre_authorization_url
        new_subscription_url
        confirm_resource
        users
    /,
);

cmp_deeply(
    $GoCardless->client_details,
    { api_version => 2 },
    'client_details'
);
isa_ok( $GoCardless->client,'Business::GoCardless::Client' );

# monkey patching LWP here to make this test work without
# having to actually hit the endpoints or use credentials
no warnings 'redefine';
no warnings 'once';
my $mock = Test::MockObject->new;
$mock->mock( 'is_success',sub { 1 } );
$mock->mock( 'header',sub {} );
*LWP::UserAgent::request = sub { $mock };

test_payment( $GoCardless,$mock );
test_payout( $GoCardless,$mock );
test_pre_authorization( $GoCardless,$mock );
test_subscription( $GoCardless,$mock );
test_user( $GoCardless,$mock );
test_webhook( $GoCardless,$mock );

done_testing();

sub test_payment {

    my ( $GoCardless,$mock ) = @_;

    $mock->mock(
        'content',
        sub { '{"payments":{' . _payment_json_internal() . '}}' }
    );

    isa_ok(
        my $Payment = $GoCardless->create_payment,
        'Business::GoCardless::Payment',
        '->create_payment',
    );

    $mock->mock( 'content',sub { _redirect_flow_json() } );

    note( "Bill" );
    like(
        my $new_bill_url = $GoCardless->new_bill_url(
            session_token        => 'foo',
            description          => "Test Bill",
            success_redirect_url => "http://localhost:3000/rflow/confirm/bill/100/EUR",
        ),
        qr!http://pay\.gocardless\.dev/flow/RE123!,
        '->new_bill_url returns a url'
    );

    $ENV{GOCARDLESS_DEV_TESTING} = 1;

    my $i = 0;

    $mock->mock(
        'content',
        sub {
            $i++ < 2
                ? _redirect_flow_json()
                : _payment_json()
        }
    );

    cmp_deeply(
        my $Bill = $GoCardless->confirm_resource(
            redirect_flow_id => 1,
            type             => 'bill',
            amount           => 100,
            currency         => 'GBP',
        ),
        _payment_obj(),
        '->confirm_resource returns a Business::GoCardless::Bill object'
    );

    $mock->mock(
        'content',
        sub { '{"payments":[{' . _payment_json_internal() . '},{' . _payment_json_internal() . '}]}' }
    );

    my @bills = $GoCardless->bills;

    cmp_deeply(
        \@bills,
        [ _payment_obj(),_payment_obj() ],
        '->bills returns an array of Business::GoCardless::Payment objects'
    );

    $i = 0;

    $mock->mock(
        'content',
        sub { '{"payments":[{' . _payment_json_internal('cancelled') . '}]}' }
    );

    @bills = $GoCardless->bills( state => 'cancelled' );

    cmp_deeply(
        \@bills,
        [ _payment_obj( 'cancelled' ) ],
        '->bills with filters'
    );

    $mock->mock( 'content',sub { _payment_json() } );
    $Bill = $GoCardless->bill( '123ABCD' );

    cmp_deeply(
        $Bill,
        _payment_obj(),
        '->bill returns a Business::GoCardless::Bill object'
    );

    cmp_deeply(
        $Bill->retry,
        _payment_obj(),
        '->retry returns a Business::GoCardless::Bill object'
    );

    $mock->mock( 'content',sub { _payment_json( 'cancelled' ) } );

    cmp_deeply(
        $Bill = $Bill->cancel,
        _payment_obj( 'cancelled' ),
        '->cancel returns a Business::GoCardless::Bill object'
    );

    ok( $Bill->cancelled,'bill is cancelled' );

    $mock->mock( 'content',sub { _payment_json( 'refunded' ) } );

    ok( ! $Bill->refund,'->refund currently not supported' );
}

sub test_payout {

    my ( $GoCardless,$mock ) = @_;

    note( "Payout" );

    $mock->mock( 'content',sub { _payout_json() } );
    my $Payout = $GoCardless->payout( '0BKR1AZNJF' );

    cmp_deeply(
        $Payout,
        _payout_obj(),
        '->payout returns a Business::GoCardless::Payout object'
    );
}

sub test_pre_authorization {

    my ( $GoCardless,$mock ) = @_;

    $mock->mock( 'content',sub { _redirect_flow_json() } );

    note( "PreAuthorization" );
    like(
        my $new_pre_auth_url = $GoCardless->new_pre_authorization_url(
            session_token        => 'bar',
            description          => "Test Pre Auth",
            success_redirect_url => "http://localhost:3000/rflow/pre_auth/bill/100/EUR",
        ),
        qr!http://pay\.gocardless\.dev/flow/RE123!,
        '->new_pre_authorization_url returns a url'
    );

    my $i = 0;

    $mock->mock(
        'content',
        sub { _redirect_flow_json() }
    );

    cmp_deeply(
        my $PreAuthorization = $GoCardless->confirm_resource(
            redirect_flow_id => 2,
            type             => 'pre_auth',
            amount           => 100,
            currency         => 'GBP',
        ),
        _redirect_flow_obj(),
        '->confirm_resource returns a Business::GoCardless::RedirectFlow object'
    );

    $mock->mock( 'content',sub { _payment_json() } );
    my $Bill = $PreAuthorization->bill( amount => 10 );

    cmp_deeply(
        $Bill,
        _payment_obj(),
        '->bill returns a Business::GoCardless::Bill object'
    );

    $mock->mock( 'content',sub { _redirect_flow_json() } );
    $PreAuthorization = $GoCardless->pre_authorization( '123ABCD' );

    cmp_deeply(
        $PreAuthorization,
        _redirect_flow_obj(),
        '->pre_authorization returns a Business::GoCardless::PreAuthorization object'
    );

    $mock->mock( 'content',sub { _mandate_json() } );
    my $Mandate = $PreAuthorization->mandate;

    cmp_deeply(
        $Mandate,
        _mandate_obj(),
        '->mandate returns a Business::GoCardless::Mandate object'
    );

    is(
        $Mandate->next_possible_charge_date,
        '2017-09-27',
        '->next_possible_charge_date'
    );

    $mock->mock( 'content',sub { _redirect_flow_json() } );
    throws_ok(
        sub { $GoCardless->pre_authorizations },
        'Business::GoCardless::Exception',
        "->pre_authorizations is no longer meaningful in the Pro API",
    );
}

sub test_subscription {

    my ( $GoCardless,$mock ) = @_;

    note( "Subscription" );
    like(
        my $new_subscription_url = $GoCardless->new_subscription_url(
            session_token        => 'baz',
            description          => "Test Pre Auth",
            success_redirect_url => "http://localhost:3000/rflow/pre_auth/bill/100/EUR",
        ),
        qr!http://pay\.gocardless\.dev/flow/RE123!,
        '->new_subscription_url returns a url'
    );

    my $i = 0;

    $mock->mock(
        'content',
        sub {
            $i++ < 2
                ? _redirect_flow_json()
                : _subscription_json()
        }
    );

    cmp_deeply(
        my $Subscription = $GoCardless->confirm_resource(
            redirect_flow_id => 2,
            type             => 'subscription',
            amount           => 100,
            currency         => 'GBP',
            interval_unit    => 'monthly',
            interval         => '1',
            start_at         => '2017-05-22',
        ),
        _subscription_obj(),
        '->confirm_resource returns a Business::GoCardless::Subscription object'
    );

    $i = 0;

    $mock->mock(
        'content',
        sub { '{"subscriptions":[{' . _subscription_json_internal() . '},{' . _subscription_json_internal() . '}]}' },
    );

    my @subs = $GoCardless->subscriptions;

    cmp_deeply(
        \@subs,
        [ _subscription_obj(),_subscription_obj() ],
        '->subscriptions returns an array of Business::GoCardless::Subscription objects'
    );

    $mock->mock( 'content',sub { _subscription_json() } );
    $Subscription = $GoCardless->subscription( '123ABCD' );

    cmp_deeply(
        $Subscription,
        _subscription_obj(),
        '->subscription returns a Business::GoCardless::Subscription object'
    );

    $mock->mock( 'content',sub { _subscription_json( 'cancelled' ) } );

    cmp_deeply(
        $Subscription = $Subscription->cancel,
        _subscription_obj( 'cancelled' ),
        '->cancel returns a Business::GoCardless::Subscription object'
    );

    ok( $Subscription->cancelled,'pre_authorization is cancelled' );

}

sub test_user {

    my ( $GoCardless,$mock ) = @_;

    note( "User" );
    my $i = 0;

    $mock->mock(
        'content',
        sub { '{"customers":[' . _user_json() . ',' . _user_json() . ']}' }
    );

    my @customers = $GoCardless->customers;
    my @users = $GoCardless->users;

    cmp_deeply( [ @customers ],[ @users ],'->customers === ->users' );

    cmp_deeply(
        \@users,
        [ _user_obj(),_user_obj() ],
        '->users returns an array of Business::GoCardless::User objects'
    );

    isa_ok(
        $GoCardless->customer( 1 ),
        'Business::GoCardless::Customer',
        '->customer'
    );
}

sub test_webhook {

    my ( $GoCardless,$mock ) = @_;

    $ENV{GOCARDLESS_DEV_TESTING} = 0;

    note( "Webhook" );

    my $Webhook = $GoCardless->webhook(
        _webhook_payload(),
        '07525beb4617490b433bd9036b97e856cefb041a6401e4f18b228345d34f5fc5'
    );
    isa_ok( $Webhook,'Business::GoCardless::Webhook' );

    ok( my @events = $Webhook->events,'->events' );

    throws_ok(
        sub { $GoCardless->webhook( _webhook_payload(),"bad signature" ) },
        'Business::GoCardless::Exception',
        '->webhook checks signature',
    );
}

sub _user_json {

    return qq{
  {
"id": "CU123",
    "created_at": "2014-05-08T17:01:06.000Z",
    "email": "user\@example.com",
    "given_name": "Frank",
    "family_name": "Osborne",
    "address_line1": "27 Acer Road",
    "address_line2": "Apt 2",
    "address_line3": null,
    "city": "London",
    "region": null,
    "postal_code": "E8 3GX",
    "country_code": "GB",
    "language": "en",
    "swedish_identity_number": null,
    "metadata": {
      "salesforce_id": "ABCD1234"
    }
  } }

}

sub _user_obj {

    return bless( {
  'address_line1' => '27 Acer Road',
  'address_line2' => 'Apt 2',
  'address_line3' => undef,
  'city' => 'London',
  'client' => bless( {
    'api_path' => '',
    'api_version' => 2,
    'base_url' => 'https://api.gocardless.com',
    'token' => 'MvYX0i6snRh/1PXfPoc6',
    'user_agent' => ignore(),
  }, 'Business::GoCardless::Client' ),
  'country_code' => 'GB',
  'created_at' => '2014-05-08T17:01:06.000Z',
  'email' => 'user@example.com',
  'endpoint' => '/customers/%s',
  'family_name' => 'Osborne',
  'given_name' => 'Frank',
  'id' => 'CU123',
  'language' => 'en',
  'metadata' => {
    'salesforce_id' => 'ABCD1234'
  },
  'postal_code' => 'E8 3GX',
  'region' => undef,
  'swedish_identity_number' => undef
}, 'Business::GoCardless::Customer' );

}

sub _subscription_json {

    my ( $status ) = @_;

    my $internal = _subscription_json_internal( $status );

    return qq!{
  "subscriptions": {
    $internal
  }
}!;

}

sub _subscription_json_internal {
    my ( $status ) = @_;

    $status //= 'active';

    return qq!
    "id": "SB123",
    "created_at": "2014-10-20T17:01:06.000Z",
    "amount": 2500,
    "currency": "GBP",
    "status": "$status",
    "name": "Monthly Magazine",
    "start_date": "2014-11-03",
    "end_date": null,
    "interval": 1,
    "interval_unit": "monthly",
    "day_of_month": 1,
    "month": null,
    "payment_reference": null,
    "upcoming_payments": [
      { "charge_date": "2014-11-03", "amount": 2500 },
      { "charge_date": "2014-12-01", "amount": 2500 },
      { "charge_date": "2015-01-02", "amount": 2500 },
      { "charge_date": "2015-02-02", "amount": 2500 },
      { "charge_date": "2015-03-02", "amount": 2500 },
      { "charge_date": "2015-04-01", "amount": 2500 },
      { "charge_date": "2015-05-01", "amount": 2500 },
      { "charge_date": "2015-06-01", "amount": 2500 },
      { "charge_date": "2015-07-01", "amount": 2500 },
      { "charge_date": "2015-08-03", "amount": 2500 }
    ],
    "metadata": {
      "order_no": "ABCD1234"
    },
    "links": {
      "mandate": "MA123"
    }
!;

}

sub _subscription_obj {

    my ( $status ) = @_;

    $status //= 'active';

return bless( {
  'amount' => 2500,
  'client' => bless( {
    'api_path' => '',
    'api_version' => 2,
    'base_url' => 'https://api.gocardless.com',
    'token' => 'MvYX0i6snRh/1PXfPoc6',
    'user_agent' => ignore(),
  }, 'Business::GoCardless::Client' ),
  'created_at' => '2014-10-20T17:01:06.000Z',
  'currency' => 'GBP',
  'day_of_month' => 1,
  'end_date' => undef,
  'endpoint' => '/subscriptions/%s',
  'id' => 'SB123',
  'interval' => 1,
  'interval_unit' => 'monthly',
  'links' => {
    'mandate' => 'MA123'
  },
  'metadata' => {
    'order_no' => 'ABCD1234'
  },
  'month' => undef,
  'name' => 'Monthly Magazine',
  'payment_reference' => undef,
  'start_date' => '2014-11-03',
  'status' => $status,
  'upcoming_payments' => [
    {
      'amount' => 2500,
      'charge_date' => '2014-11-03'
    },
    {
      'amount' => 2500,
      'charge_date' => '2014-12-01'
    },
    {
      'amount' => 2500,
      'charge_date' => '2015-01-02'
    },
    {
      'amount' => 2500,
      'charge_date' => '2015-02-02'
    },
    {
      'amount' => 2500,
      'charge_date' => '2015-03-02'
    },
    {
      'amount' => 2500,
      'charge_date' => '2015-04-01'
    },
    {
      'amount' => 2500,
      'charge_date' => '2015-05-01'
    },
    {
      'amount' => 2500,
      'charge_date' => '2015-06-01'
    },
    {
      'amount' => 2500,
      'charge_date' => '2015-07-01'
    },
    {
      'amount' => 2500,
      'charge_date' => '2015-08-03'
    }
  ]
}, 'Business::GoCardless::Subscription' );

}

sub _redirect_flow_obj {

    my ( $status ) = @_;

    $status //= 'active';

    return 
bless( {
  'client' => bless( {
    'api_path' => '',
    'api_version' => 2,
    'base_url' => 'https://api.gocardless.com',
    'token' => 'MvYX0i6snRh/1PXfPoc6',
    'user_agent' => ignore(),
  }, 'Business::GoCardless::Client' ),
  'created_at' => '2014-10-22T13:10:06.000Z',
  'description' => 'Wine boxes',
  'endpoint' => '/redirect_flows/%s',
  'id' => 'RE123',
  'links' => {
    'creditor' => 'CR123',
    'mandate' => 'MD123'
  },
  'redirect_url' => 'http://pay.gocardless.dev/flow/RE123',
  'scheme' => undef,
  'session_token' => 'SESS_wSs0uGYMISxzqOBq',
  'success_redirect_url' => 'https://example.com/pay/confirm'
}, 'Business::GoCardless::RedirectFlow' );

}

sub _mandate_obj {

    my ( $status ) = @_;

    $status //= 'active';

    return 
bless( {
  'client' => bless( {
    'api_path' => '',
    'api_version' => 2,
    'base_url' => 'https://api.gocardless.com',
    'token' => 'MvYX0i6snRh/1PXfPoc6',
    'user_agent' => ignore(),
  }, 'Business::GoCardless::Client' ),
  'endpoint' => '/mandates/%s',
    "id" => "MD000660000000",
    "created_at" => "2017-09-12T20:37:07.787Z",
    "reference" => "MAND-RZ000S",
    "status" => "active",
    "scheme" => "bacs",
    "next_possible_charge_date" => "2017-09-27",
    "payments_require_approval" => JSON::false,
    "metadata" => {},
    "links" => {
        "customer_bank_account" => "BA00060000000W",
        "creditor" => "CR000020000008",
        "customer" => "CU0006J00000TV"
    }
}, 'Business::GoCardless::Mandate' );

}

sub _pre_auth_json {

    my ( $status ) = @_;

    $status //= 'active';

    return qq{
{
  "currency": "GBP",
  "created_at": "2014-08-20T21:41:25Z",
  "expires_at": "2016-08-20T21:41:25Z",
  "id": "1234ABCD",
  "name": "Computer support invoices",
  "description": "GoCardless magazine",
  "max_amount": "750.00",
  "setup_fee": "10.00",
  "remaining_amount": "750.00",
  "interval_unit": "month",
  "interval_length": "1",
  "status": "$status",
  "sub_resource_uris": {
    "bills": "https://sandbox.gocardless.com/api/v1/merchants/0HMARBD8H1/bills?source_id=0PWCDRPCWN"
  },
  "next_interval_start": "2014-09-20T00:00:00Z",
  "merchant_id": "06Z06JWQW1",
  "user_id": "FIVWCCVEST6S4D",
  "uri": "https://gocardless.com/api/v1/pre-authorisations/1234ABCD"
} }

}

sub _payout_json {

    my ( $extra ) = @_;

    $extra //= '';

    return qq!{
    $extra
    "amount": "12.37",
    "bank_reference": "JOHNSMITH-Z5DRM",
    "created_at": "2013-05-10T16:34:34Z",
    "id": "0BKR1AZNJF",
    "paid_at": "2013-05-10T17:00:26Z",
    "transaction_fees": "0.13"
  }!;

}

sub _payouts_json {

    my $payout = _payout_json( '"app_ids": [ "ABC" ],' );
    return qq{ [ $payout ] };
}

sub _payout_obj {

    my ( $extra ) = @_;

    $extra //= {};

    return bless( {
     %{ $extra },
     'amount' => '12.37',
     'bank_reference' => 'JOHNSMITH-Z5DRM',
     'client' => ignore(),
     'created_at' => '2013-05-10T16:34:34Z',
     'endpoint' => '/payouts/%s',
     'id' => '0BKR1AZNJF',
     'paid_at' => '2013-05-10T17:00:26Z',
     'transaction_fees' => '0.13'
   }, 'Business::GoCardless::Payout' );
}

sub _merchant_json {

    return qq!{
  "id":"06Z06JWQW1",
  "name":"Company Ltd",
  "description":"We do stuff.",
  "created_at":"2014-01-22T10:27:42Z",
  "first_name":"Lee",
  "last_name":"Johnson",
  "email":"lee\@foo.com",
  "uri":"https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1",
  "balance":"0.0",
  "pending_balance":"0.0",
  "next_payout_date":null,
  "next_payout_amount":null,
  "hide_variable_amount":false,
  "sub_resource_uris":{
    "users":"https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/users",
    "bills":"https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/bills",
    "pre_authorizations":"https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/pre_authorizations",
    "subscriptions":"https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/subscriptions",
    "payouts":"https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/payouts"
  },
  "gbp_balance":"0.0",
  "eur_balance":"0.0",
  "gbp_pending_balance":"0.0",
  "eur_pending_balance":"0.0"
 }!;
}

sub _merchant_obj {

    return bless(
        {
            'balance' => '0.0',
            'client' => ignore(),
            'created_at'           => '2014-01-22T10:27:42Z',
            'description'          => 'We do stuff.',
            'email'                => 'lee@foo.com',
            'endpoint'             => '/merchants/%s',
            'eur_balance'          => '0.0',
            'eur_pending_balance'  => '0.0',
            'first_name'           => 'Lee',
            'gbp_balance'          => '0.0',
            'gbp_pending_balance'  => '0.0',
            'hide_variable_amount' => JSON::false,
            'id'                   => '06Z06JWQW1',
            'last_name'            => 'Johnson',
            'name'                 => 'Company Ltd',
            'next_payout_amount'   => undef,
            'next_payout_date'     => undef,
            'pending_balance'      => '0.0',
            'sub_resource_uris'    => {
                'bills'   => 'https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/bills',
                'payouts' => 'https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/payouts',
                'pre_authorizations' =>
                    'https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/pre_authorizations',
                'subscriptions' =>
                    'https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/subscriptions',
                'users' => 'https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/users'
            },
            'uri' => 'https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1'
        },
        'Business::GoCardless::Merchant'
        );
}

sub _payment_json {

    my ( $status,$amount ) = @_;

    my $internal = _payment_json_internal( $status,$amount );

return qq!{
  "payments": {
    $internal
  }
  }!;
}

sub _payment_json_internal {

    my ( $status,$amount ) = @_;

    $status //= 'pending_submission';
    $amount //= '44.0';

return qq!
    "id": "PM123",
    "created_at": "2014-05-08T17:01:06.000Z",
    "charge_date": "2014-05-15",
    "amount": $amount,
    "description": null,
    "currency": "GBP",
    "status": "$status",
    "reference": "WINEBOX001",
    "metadata": {
      "order_dispatch_date": "2014-05-22"
    },
    "amount_refunded": 0,
    "links": {
      "mandate": "MD123",
      "creditor": "CR123"
    }
!;

}

sub _payment_obj {

    my ( $status ) = @_;

    $status //= 'pending_submission';

    return bless({
        'client'          => ignore(),
        "id"              => "PM123",
        "created_at"      => "2014-05-08T17:01:06.000Z",
        "charge_date"     => "2014-05-15",
        "amount"          => 44.0,
        "amount_refunded" => 0,
        "description"     => undef,
        "currency"        => "GBP",
        "status"          => $status,
        "reference"       => "WINEBOX001",
        "metadata"        => {
          "order_dispatch_date" => "2014-05-22"
        },
        "links" => {
          "mandate"  => "MD123",
          "creditor" => "CR123",
        },
        'endpoint' => '/payments/%s',
    },'Business::GoCardless::Payment'
    );
}

sub _webhook_payload {

    my ( $signature ) = @_;

    $signature //= '07525beb4617490b433bd9036b97e856cefb041a6401e4f18b228345d34f5fc5';

    return qq!{
  "events": [
    {
      "id": "EV123",
      "created_at": "2014-08-04T12:00:00.000Z",
      "action": "paid",
      "resource_type": "payouts",
      "links": {
        "payout": "PO123"
      }
    }
  ]
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

# vim: ts=4:sw=4:et
