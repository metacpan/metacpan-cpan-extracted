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
$ENV{GOCARDLESS_APP_ID}      = 'foo';
$ENV{GOCARDLESS_APP_SECRET}  = 'bar';
$ENV{GOCARDLESS_MERCHANT_ID} = 'baz';

# this makes Business::GoCardless::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{GOCARDLESS_DEV_TESTING} = 1;

use_ok( 'Business::GoCardless::Basic' );
isa_ok(
    my $GoCardless = Business::GoCardless::Basic->new(
        token       => 'MvYX0i6snRh/1PXfPoc6',
        merchant_id => 'MID',
    ),
    'Business::GoCardless'
);

can_ok(
    $GoCardless,
    qw/
        token
        client_details
        client
        bill
    /,
);

cmp_deeply(
    $GoCardless->client_details,
    { api_version => 1 },
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

test_bill( $GoCardless,$mock );
test_merchant( $GoCardless,$mock );
test_payout( $GoCardless,$mock );
test_pre_authorization( $GoCardless,$mock );
test_subscription( $GoCardless,$mock );
test_user( $GoCardless,$mock );
test_webhook( $GoCardless,$mock );

done_testing();

sub test_bill {

    my ( $GoCardless,$mock ) = @_;

    note( "Bill" );
    like(
        my $new_bill_url = $GoCardless->new_bill_url(
            amount       => 100,
            name         => "Test Bill",
            description  => "Test Bill for testing",
            redirect_uri => "http://localhost/success",
            cancel_uri   => "http://localhost/cancel",
            state        => "id_9SX5G36",
            user         => {
                first_name       => "Lee",
            }
        ),
        qr!https://gocardless\.com/connect/bills/new\?bill%5Bamount%5D=100&bill%5Bdescription%5D=Test%20Bill%20for%20testing&bill%5Bmerchant_id%5D=baz&bill%5Bname%5D=Test%20Bill&bill%5Buser%5D%5Bfirst_name%5D=Lee&cancel_uri=http%3A%2F%2Flocalhost%2Fcancel&client_id=foo&nonce=.*?&redirect_uri=http%3A%2F%2Flocalhost%2Fsuccess&signature=.*?&timestamp=\d{4}-\d{2}-\d{2}T\d{2}%3A\d{2}%3A\d{2}Z!,
        '->new_bill_url returns a url'
    );

    $ENV{GOCARDLESS_DEV_TESTING} = 0;
    
    throws_ok(
        sub { $GoCardless->confirm_resource( signature => 'foo' ) },
        'Business::GoCardless::Exception',
        '->confirm_resource checks signature',
    );

    like(
        $@->message,
        qr/Invalid signature for confirm_resource/,
        ' ... and throws expected error',
    );

    $ENV{GOCARDLESS_DEV_TESTING}    = 1;
    $ENV{GOCARDLESS_SKIP_SIG_CHECK} = 1;

    $mock->mock( 'content',sub { _bill_json() } );

    cmp_deeply(
        my $Bill = $GoCardless->confirm_resource(
            resource_id   => 'foo',
            resource_type => 'bill'
        ),
        _bill_obj(),
        '->confirm_resource returns a Business::GoCardless::Bill object'
    );

    my $i = 0;

    $mock->mock(
        'content',
        sub {
            # first time return a merchant object, next time a list of bills
            $i++
                ? '[' . _bill_json() . ',' . _bill_json() . ']'
                : _merchant_json()
        }
    );

    my @bills = $GoCardless->bills;

    cmp_deeply(
        \@bills,
        [ _bill_obj(),_bill_obj() ],
        '->bills returns an array of Business::GoCardless::Bill objects'
    );

    $i = 0;

    $mock->mock(
        'content',
        sub {
            # first time return a merchant object, next time a list of bills
            $i++
                ? '[' . _bill_json( 'cancelled' ) . ']'
                : _merchant_json()
        }
    );

    @bills = $GoCardless->bills( state => 'cancelled' );

    cmp_deeply(
        \@bills,
        [ _bill_obj( 'cancelled' ) ],
        '->bills with filters'
    );

    $mock->mock( 'content',sub { _bill_json() } );
    $Bill = $GoCardless->bill( '123ABCD' );

    cmp_deeply(
        $Bill,
        _bill_obj(),
        '->bill returns a Business::GoCardless::Bill object'
    );

    cmp_deeply(
        $Bill->retry,
        _bill_obj(),
        '->retry returns a Business::GoCardless::Bill object'
    );

    $mock->mock( 'content',sub { _bill_json( 'cancelled' ) } );

    cmp_deeply(
        $Bill = $Bill->cancel,
        _bill_obj( 'cancelled' ),
        '->cancel returns a Business::GoCardless::Bill object'
    );

    ok( $Bill->cancelled,'bill is cancelled' );

    $mock->mock( 'content',sub { _bill_json( 'refunded' ) } );

    cmp_deeply(
        $Bill = $Bill->refund,
        _bill_obj( 'refunded' ),
        '->refund returns a Business::GoCardless::Bill object'
    );

    ok( $Bill->refunded,'bill is refunded' );
}

sub test_merchant {

    my ( $GoCardless,$mock ) = @_;

    note( "Merchant" );

    $mock->mock( 'content',sub { _merchant_json() } );
    cmp_deeply(
        my $Merchant = $GoCardless->merchant,
        _merchant_obj(),
        '->merchant returns a Business::GoCardless::Merchant object',
    );

    my $i = 0;

    $mock->mock(
        'content',
        sub {
            # first time return a merchant object, next time a list of pre_auths
            $i++
                ? _payouts_json()
                : _merchant_json()
        }
    );

    my @payouts = $GoCardless->payouts;
    cmp_deeply(
        \@payouts,
        [ _payout_obj( { 'app_ids' => [ 'ABC' ] } ) ],
        '->payouts returns an array of Business::GoCardless::Payout objects'
    );
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

    note( "PreAuthorization" );
    like(
        my $new_pre_auth_url = $GoCardless->new_pre_authorization_url(
            max_amount         => 100,
            interval_length    => 10,
            interval_unit      => 'day',
            expires_at         => '2020-01-01',
            name               => "Test PreAuthorization",
            description        => "Test PreAuthorization for testing",
            interval_count     => 10,
            setup_fee          => 500,
            calendar_intervals => 0,
            redirect_uri       => "http://localhost/success",
            cancel_uri         => "http://localhost/cancel",
            state              => "id_9SX5G36",
            user               => {
                first_name     => "Lee",
            }
        ),
        qr!https://gocardless\.com/connect/pre_authorizations/new\?cancel_uri=http%3A%2F%2Flocalhost%2Fcancel&client_id=foo&nonce=.*?&pre_authorization%5Bcalendar_intervals%5D=0&pre_authorization%5Bdescription%5D=Test%20PreAuthorization%20for%20testing&pre_authorization%5Bexpires_at%5D=2020-01-01&pre_authorization%5Binterval_count%5D=10&pre_authorization%5Binterval_length%5D=10&pre_authorization%5Binterval_unit%5D=day&pre_authorization%5Bmax_amount%5D=100&pre_authorization%5Bmerchant_id%5D=baz&pre_authorization%5Bname%5D=Test%20PreAuthorization&pre_authorization%5Bsetup_fee%5D=500&pre_authorization%5Buser%5D%5Bfirst_name%5D=Lee&redirect_uri=http%3A%2F%2Flocalhost%2Fsuccess&signature=.*?&state=id_9SX5G36&timestamp=\d{4}-\d{2}-\d{2}T\d{2}%3A\d{2}%3A\d{2}Z!,
        '->new_pre_authorization_url returns a url'
    );

    $mock->mock( 'content',sub { _pre_auth_json() } );
    cmp_deeply(
        my $PreAuthorization = $GoCardless->confirm_resource(
            resource_id   => 'foo',
            resource_type => 'pre_authorization',
        ),
        _pre_auth_obj(),
        '->confirm_resource returns a Business::GoCardless::PreAuthorization object'
    );

    $mock->mock( 'content',sub { _bill_json() } );
    my $Bill = $PreAuthorization->bill( amount => 10 );

    cmp_deeply(
        $Bill,
        _bill_obj(),
        '->bill returns a Business::GoCardless::Bill object'
    );
    
    my $i = 0;

    $mock->mock(
        'content',
        sub {
            # first time return a merchant object, next time a list of pre_auths
            $i++
                ? '[' . _pre_auth_json() . ',' . _pre_auth_json() . ']'
                : _merchant_json()
        }
    );

    my @pre_auths = $GoCardless->pre_authorizations;

    cmp_deeply(
        \@pre_auths,
        [ _pre_auth_obj(),_pre_auth_obj() ],
        '->pre_authorizations returns an array of Business::GoCardless::PreAuthorization objects'
    );

    $mock->mock( 'content',sub { _pre_auth_json() } );
    $PreAuthorization = $GoCardless->pre_authorization( '123ABCD' );

    cmp_deeply(
        $PreAuthorization,
        _pre_auth_obj(),
        '->pre_authorization returns a Business::GoCardless::PreAuthorization object'
    );

    $mock->mock( 'content',sub { _pre_auth_json( 'cancelled' ) } );

    cmp_deeply(
        $PreAuthorization = $PreAuthorization->cancel,
        _pre_auth_obj( 'cancelled' ),
        '->cancel returns a Business::GoCardless::PreAuthorization object'
    );

    ok( $PreAuthorization->cancelled,'pre_authorization is cancelled' );

}

sub test_subscription {

    my ( $GoCardless,$mock ) = @_;

    note( "Subscription" );
    like(
        my $new_subscription_url = $GoCardless->new_subscription_url(
            amount             => 100,
            interval_length    => 10,
            interval_unit      => 'day',
            name               => "Test Subscription",
            description        => "Test Subscription for testing",
            start_at           => '2010-01-01',
            expires_at         => '2020-01-01',
            interval_count     => 10,
            setup_fee          => 500,
            redirect_uri       => "http://localhost/success",
            cancel_uri         => "http://localhost/cancel",
            state              => "id_9SX5G36",
            user               => {
                first_name     => "Lee",
            }
        ),
        qr!https://gocardless\.com/connect/subscriptions/new\?cancel_uri=http%3A%2F%2Flocalhost%2Fcancel&client_id=foo&nonce=.*?&redirect_uri=http%3A%2F%2Flocalhost%2Fsuccess&signature=.*?&state=id_9SX5G36&subscription%5Bamount%5D=100&subscription%5Bdescription%5D=Test%20Subscription%20for%20testing&subscription%5Bexpires_at%5D=2020-01-01&subscription%5Binterval_count%5D=10&subscription%5Binterval_length%5D=10&subscription%5Binterval_unit%5D=day&subscription%5Bmerchant_id%5D=baz&subscription%5Bname%5D=Test%20Subscription&subscription%5Bsetup_fee%5D=500&subscription%5Bstart_at%5D=2010-01-01&subscription%5Buser%5D%5Bfirst_name%5D=Lee&timestamp=\d{4}-\d{2}-\d{2}T\d{2}%3A\d{2}%3A\d{2}Z!,
        '->new_subscription_url returns a url'
    );

    $mock->mock( 'content',sub { _subscription_json() } );
    cmp_deeply(
        my $Subscription = $GoCardless->confirm_resource(
            resource_id   => 'foo',
            resource_type => 'subscription',
        ),
        _subscription_obj(),
        '->confirm_resource returns a Business::GoCardless::Subscription object'
    );

    my $i = 0;

    $mock->mock(
        'content',
        sub {
            # first time return a merchant object, next time a list of pre_auths
            $i++
                ? '[' . _subscription_json() . ',' . _subscription_json() . ']'
                : _merchant_json()
        }
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
        sub {
            # first time return a merchant object, next time a list of pre_auths
            $i++
                ? '[' . _user_json() . ',' . _user_json() . ']'
                : _user_json()
        }
    );

    my @users = $GoCardless->users;

    cmp_deeply(
        \@users,
        [ _user_obj(),_user_obj() ],
        '->users returns an array of Business::GoCardless::User objects'
    );

}

sub test_webhook {

    my ( $GoCardless,$mock ) = @_;

    $ENV{GOCARDLESS_SKIP_SIG_CHECK} = 0;
    $ENV{GOCARDLESS_DEV_TESTING} = 0;

    note( "Webhook" );

    my $Webhook = $GoCardless->webhook( _webhook_payload() );
    isa_ok( $Webhook,'Business::GoCardless::Webhook' );

    throws_ok(
        sub { $GoCardless->webhook( _webhook_payload( "bad signature" ) ) },
        'Business::GoCardless::Exception',
        '->webhook checks signature',
    );
}

sub _user_json {

    return qq{
  {
    "created_at":"2011-11-18T17:06:15Z",
    "email":"customer40\@gocardless.com",
    "id": "JKH8HGKL9H",
    "first_name":"Frank",
    "last_name":"Smith"
  } }

}

sub _user_obj {

    return bless( {
   'client' => ignore(),
   'created_at' => '2011-11-18T17:06:15Z',
   'email' => 'customer40@gocardless.com',
   'endpoint' => '/users/%s',
   'first_name' => 'Frank',
   'id' => 'JKH8HGKL9H',
   'last_name' => 'Smith'
 }, 'Business::GoCardless::User' );

}

sub _subscription_json {

    my ( $status ) = @_;

    $status //= 'active';

    return qq{
{
  "currency": "GBP",
  "created_at": "2014-08-20T21:41:25Z",
  "expires_at": "2016-08-20T21:41:25Z",
  "id": "0NZ71WBMVF",
  "name": "Membership subscription",
  "description": "GoCardless magazine",
  "amount": "7.50",
  "setup_fee": "0.00",
  "interval_unit": "month",
  "interval_length": "1",
  "start_at": "2014-12-31T00:00:00Z",
  "status": "$status",
  "sub_resource_uris": {
    "bills": "https://sandbox.gocardless.com/api/v1/merchants/0HMARBD8H1/bills?source_id=0PWCDRPCWN"
  },
  "next_interval_start": "2014-09-20T00:00:00Z",
  "merchant_id": "06Z06JWQW1",
  "user_id": "FIVWCCVEST6S4D",
  "uri": "https://gocardless.com/api/v1/subscriptions/0NZ71WBMVF"
} }

}

sub _subscription_obj {

    my ( $status ) = @_;

    $status //= 'active';

    return bless( {
   'amount' => '7.50',
   'client' => ignore(),
   'created_at' => '2014-08-20T21:41:25Z',
   'currency' => 'GBP',
   'description' => 'GoCardless magazine',
   'endpoint' => '/subscriptions/%s',
   'expires_at' => '2016-08-20T21:41:25Z',
   'id' => '0NZ71WBMVF',
   'interval_length' => '1',
   'interval_unit' => 'month',
   'merchant_id' => '06Z06JWQW1',
   'name' => 'Membership subscription',
   'next_interval_start' => '2014-09-20T00:00:00Z',
   'setup_fee' => '0.00',
   'start_at' => '2014-12-31T00:00:00Z',
   'status' => $status,
   'sub_resource_uris' => {
     'bills' => 'https://sandbox.gocardless.com/api/v1/merchants/0HMARBD8H1/bills?source_id=0PWCDRPCWN'
   },
   'uri' => 'https://gocardless.com/api/v1/subscriptions/0NZ71WBMVF',
   'user_id' => 'FIVWCCVEST6S4D'
}, 'Business::GoCardless::Subscription' );

}

sub _pre_auth_obj {

    my ( $status ) = @_;

    $status //= 'active';

    return bless( {
  'client' => ignore(),
  'created_at' => '2014-08-20T21:41:25Z',
  'currency' => 'GBP',
  'description' => 'GoCardless magazine',
  'endpoint' => '/pre_authorizations/%s',
  'expires_at' => '2016-08-20T21:41:25Z',
  'id' => '1234ABCD',
  'interval_length' => '1',
  'interval_unit' => 'month',
  'max_amount' => '750.00',
  'merchant_id' => '06Z06JWQW1',
  'name' => 'Computer support invoices',
  'next_interval_start' => '2014-09-20T00:00:00Z',
  'remaining_amount' => '750.00',
  'setup_fee' => '10.00',
  'status' => $status,
  'sub_resource_uris' => {
    'bills' => 'https://sandbox.gocardless.com/api/v1/merchants/0HMARBD8H1/bills?source_id=0PWCDRPCWN'
  },
  'uri' => 'https://gocardless.com/api/v1/pre-authorisations/1234ABCD',
  'user_id' => 'FIVWCCVEST6S4D'
}, 'Business::GoCardless::PreAuthorization' );
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

    return qq{
  {
    $extra
    "amount": "12.37",
    "bank_reference": "JOHNSMITH-Z5DRM",
    "created_at": "2013-05-10T16:34:34Z",
    "id": "0BKR1AZNJF",
    "paid_at": "2013-05-10T17:00:26Z",
    "transaction_fees": "0.13"
  }}

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

    return qq{{
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
}};
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

sub _bill_json {

    my ( $status,$amount ) = @_;

    $status //= 'pending';
    $amount //= '44.0';

    return qq{{
  "amount": "$amount",
  "gocardless_fees": "0.44",
  "partner_fees": "0",
  "currency": "GBP",
  "created_at": "2014-08-20T21:41:25Z",
  "description": "Month 2 payment",
  "id": "123ABCD",
  "name": "Bill 2 for Subscription description",
  "paid_at":  null,
  "status": "$status",
  "merchant_id": "06Z06JWQW1",
  "user_id": "FIVWCCVEST6S4D",
  "source_type": "ad_hoc_authorization",
  "source_id": "YH1VEVQHYVB1UT",
  "uri": "https://gocardless.com/api/v1/bills/123ABCD",
  "can_be_retried": false,
  "payout_id": null,
  "is_setup_fee": false,
  "charge_customer_at": "2014-09-01"
}};
}

sub _bill_obj {

    my ( $status ) = @_;

    $status //= 'pending';

    return bless({
        'amount'             => '44.0',
        'can_be_retried'     => JSON::false,
        'charge_customer_at' => '2014-09-01',
        'client' => ignore(),
        'created_at'      => '2014-08-20T21:41:25Z',
        'currency'        => 'GBP',
        'description'     => 'Month 2 payment',
        'endpoint'        => '/bills/%s',
        'gocardless_fees' => '0.44',
        'id'              => '123ABCD',
        'is_setup_fee'    => JSON::false,
        'merchant_id'     => '06Z06JWQW1',
        'name'            => 'Bill 2 for Subscription description',
        'paid_at'         => undef,
        'partner_fees'    => '0',
        'payout_id'       => undef,
        'source_id'       => 'YH1VEVQHYVB1UT',
        'source_type'     => 'ad_hoc_authorization',
        'status'          => $status,
        'user_id'         => 'FIVWCCVEST6S4D',
        'uri'             => 'https://gocardless.com/api/v1/bills/123ABCD',
    },'Business::GoCardless::Bill'
    );
}

sub _webhook_payload {

    my ( $signature ) = @_;

    $signature //= 'c6e7ea99cfb52b98a04a36a79920fff71ce851ca38e1f5a1e487f8c92417350e';

    return qq{{
        "payload": {
            "resource_type": "bill",
            "action": "paid",
            "bills": [
                {
                    "id": "AKJ398H8KA",
                    "status": "paid",
                    "source_type": "subscription",
                    "source_id": "KKJ398H8K8",
                    "amount": "20.0",
                    "amount_minus_fees": "19.8",
                    "paid_at": "2011-12-01T12:00:00Z",
                    "uri": "https://gocardless.com/api/v1/bills/AKJ398H8KA"
                },
                {
                    "id": "AKJ398H8KB",
                    "status": "paid",
                    "source_type": "subscription",
                    "source_id": "8AKJ398H78",
                    "amount": "20.0",
                    "amount_minus_fees": "19.8",
                    "paid_at": "2011-12-09T12:00:00Z",
                    "uri": "https://gocardless.com/api/v1/bills/AKJ398H8KB"
                }
            ],
            "signature": "$signature"
        }
    }};
}

# vim: ts=4:sw=4:et
