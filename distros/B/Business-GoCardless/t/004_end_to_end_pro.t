#!perl

use strict;
use warnings;
use utf8;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Business::GoCardless::Pro;
use POSIX qw/ strftime /;

plan skip_all => "GOCARDLESS_ENDTOEND required"
    if ! $ENV{GOCARDLESS_ENDTOEND};

# this is an "end to end" test - it will call the gocardless API
# using the details defined in the ENV variables below. it should
# only be run against the sandbox as it creates (and cancels)
# customers, mandates, payments, and subscriptions
#
# the hosted payment pages that a redirect flow sends the customer to
# are now a javascript app backed by a billing request, so rather than
# filling in a form we play the part of the customer by driving that
# billing request through the API. fulfilling the billing request also
# completes the redirect flow, after which the customer would be sent
# back to the success_redirect_url with the redirect_flow_id
my ( $token,$url,$DEBUG ) = @ENV{qw/
    GOCARDLESS_TOKEN
    GOCARDLESS_URL
    GOCARDLESS_DEBUG
/};

$url //= 'https://api-sandbox.gocardless.com';

BAIL_OUT( "GOCARDLESS_URL must be the sandbox for the end to end test" )
    if $url !~ /sandbox/;

# this makes Business::GoCardless::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{GOCARDLESS_DEV_TESTING} = 1;

my $GoCardless = Business::GoCardless::Pro->new(
    token           => $token,
    # since these are set in %ENV we don't need to pass them
    # but am showing them being passed here for example usage
    client_details  => {
        base_url    => $url,
    },
);

isa_ok( $GoCardless,'Business::GoCardless::Pro' );

# the new_.*_url methods only return the URL, so keep hold of the
# redirect flow that was created so we can act as the customer
my $LastRedirectFlow;
{
    no warnings 'redefine';
    my $orig = \&Business::GoCardless::Client::api_post;
    *Business::GoCardless::Client::api_post = sub {
        my ( $client,$path ) = @_;
        my $data = $orig->( @_ );
        $LastRedirectFlow = $data->{redirect_flows}
            if $path eq '/redirect_flows';
        return $data;
    };
}

my $new_url = $GoCardless->new_bill_url(
    session_token        => 'foo',
    description          => "Test Bill",
    scheme               => 'bacs',
    # not sure about having the amount + currency in the redirect URL (what's
    # to stop user from changing it?) but can't see any other way to be back
    # compat with the Basic API
    success_redirect_url => "http://localhost:3000/rflow/confirm/bill/100/GBP",
);

like( $new_url,qr/^https:\/\//,'->new_bill_url' );
note( $new_url ) if $DEBUG;

isa_ok(
    my $Bill = $GoCardless->confirm_resource(
        %{ _complete_redirect_flow( type => 'bill',amount => 100,currency => 'GBP' ) }
    ),
    'Business::GoCardless::Payment'
);

ok( $Bill->cancel,'cancel bill' );
ok( $Bill->cancelled,'bill cancelled' );

my $NewBill = $GoCardless->bill( $Bill->id );
is( $NewBill->id,$Bill->id,'getting bill with same id gives same bill' );

my $Paginator = $GoCardless->bills(
    limit => 50,
);

note explain $Paginator->info if $DEBUG;

# don't page through the whole sandbox account, just check that we can
# get more than one page (assuming there is more than one page)
my $pages = 0;
while ( my @bills = $Paginator->next ) {
    pass( 'Paginator->next' );
    if ( $DEBUG ) {
        note scalar( @bills );
        note explain [ map { $_->id } @bills ];
    }
    last if ++$pages >= 3;
}

ok( $pages,'Paginator returned at least one page' );

my $new_pre_auth_url = $GoCardless->new_pre_authorization_url(
    session_token        => 'bar',
    description          => "Test Pre Auth",
    scheme               => 'bacs',
    success_redirect_url => "http://localhost:3000/rflow/confirm/pre_auth/100/GBP",
    user => {
          'billing_address1' => '',
          'billing_address2' => '',
          'billing_postcode' => '',
          'billing_town' => '',
          'company_name' => '',
          'country_code' => '',
          'email' => 'foo@hotmail.com',
          'first_name' => 'Lee',
          'last_name' => "Perez de Armiñan",
    }
);

like( $new_pre_auth_url,qr/^https:\/\//,'->new_pre_authorization_url' );

isa_ok(
    my $PreAuthorization = $GoCardless->confirm_resource(
        %{ _complete_redirect_flow( type => 'pre_auth',amount => 100,currency => 'GBP' ) }
    ),
    'Business::GoCardless::RedirectFlow'
);

isa_ok(
    my $Payment = $GoCardless->create_payment(
        amount   => 100,
        currency => 'GBP',
        links    => { mandate => $PreAuthorization->mandate->id },
    ),
    'Business::GoCardless::Payment',
    '->create_payment',
);

note explain $Payment->to_hash if $DEBUG;

throws_ok(
    sub { $Payment->refund },
    'Business::GoCardless::Exception',
    '->refund requires an amount',
);

ok( $Payment->cancel,'->cancel payment' );

# creating a payment twice with the same idempotency key gives the same payment
my $idempotency_key = 'business-gocardless-e2e-' . time . "-$$";
my @idempotent_payments = map {
    $GoCardless->client->api_post(
        '/payments',
        { payments => {
            amount   => 200,
            currency => 'GBP',
            links    => { mandate => $PreAuthorization->mandate->id },
        } },
        { 'Idempotency-Key' => $idempotency_key },
    )->{payments}
} 1 .. 2;

is(
    $idempotent_payments[1]{id},
    $idempotent_payments[0]{id},
    'idempotency key conflict returns the existing payment'
);

ok( $GoCardless->payment( $idempotent_payments[0]{id} )->cancel,'->cancel idempotent payment' );

my $rate_limit = $GoCardless->client->rate_limit;
ok( $rate_limit && $rate_limit->{limit},'->rate_limit populated' );
ok( defined $rate_limit->{remaining},' ... with remaining' );
ok( $rate_limit->{reset_at},' ... with reset_at' );
note explain $rate_limit if $DEBUG;

throws_ok(
    sub { $GoCardless->create_payment(
        amount   => 100,
        currency => 'GBP',
        links    => { mandate => 'MD000NOTREAL' },
    ) },
    'Business::GoCardless::Exception',
    '->create_payment with unknown mandate throws',
);

is( $@->code,422,' ... with code' );
is( $@->type,'invalid_api_usage',' ... with type' );
ok( $@->request_id,' ... with request_id' );
ok( $@->has_reason( 'link_not_found' ),' ... with reason' );

ok( $Bill = $PreAuthorization->bill(
    amount   => 100,
    currency => 'GBP',
),'PreAuthorization->bill' );
ok( $Bill->cancel,'->cancel' );

my $Mandate = $PreAuthorization->mandate;
ok( !$Mandate->active,'mandate is not active' );
ok( $Mandate->pending_submission,'mandate is pending_submission' );

isa_ok(
    $Mandate->update( metadata => { foo => "bar" } ),
    'Business::GoCardless::Mandate',
    '->update mandate'
);
cmp_deeply( $Mandate->metadata,{ foo => 'bar' },' ... mandate was updated' );

ok( $Mandate->cancel,'->cancel mandate' );
ok( $Mandate->cancelled,' ... mandate was cancelled' );

# start the subscription next month so the date is always in the future
my ( undef,undef,undef,undef,$mon,$year ) = gmtime;
my $start_at = sprintf( "%04d-%02d-15",
    $mon == 11 ? ( $year + 1901,1 ) : ( $year + 1900,$mon + 2 )
);

my $new_subscription_url = $GoCardless->new_subscription_url(
    session_token        => 'baz',
    description          => "Test Subscription",
    scheme               => 'bacs',
    success_redirect_url => "http://localhost:3000/rflow/confirm/subscription"
        . "/100/GBP/monthly/1/$start_at",
);

like( $new_subscription_url,qr/^https:\/\//,'->new_subscription_url' );

isa_ok(
    my $Subscription = $GoCardless->confirm_resource(
        %{ _complete_redirect_flow(
            type          => 'subscription',
            amount        => 100,
            currency      => 'GBP',
            interval_unit => 'monthly',
            interval      => 1,
            start_at      => $start_at,
        ) }
    ),
    'Business::GoCardless::Subscription'
);

isa_ok(
    $Subscription = $GoCardless->subscription( $Subscription->id ),
    'Business::GoCardless::Subscription'
);

is( $Subscription->start_date,$start_at,'subscription start_date' );
ok( $Subscription->cancel,'->cancel' );
ok( $Subscription->cancelled,' ... subscription was cancelled' );

my $Customer = $GoCardless->customer(
    $GoCardless->mandate( $Mandate->id )->links->{customer}
);
isa_ok( $Customer,'Business::GoCardless::Customer' );
is( $Customer->family_name,'Jøhñsön','->customer (with wide chars)' );

my @users = $GoCardless->users;
my $User = $users[0];
isa_ok( $User,'Business::GoCardless::Customer' );

note( "Billing Requests" );

# the recommended way to set up a mandate now, rather than redirect flows. as
# with the redirect flows above we play the part of the customer via the API
isa_ok(
    my $BillingRequest = $GoCardless->create_billing_request(
        mandate_request => { scheme => 'bacs' },
        metadata        => { test => 'business-gocardless' },
    ),
    'Business::GoCardless::BillingRequest',
    '->create_billing_request'
);
ok( $BillingRequest->pending,' ... is pending' );

isa_ok(
    my $Flow = $BillingRequest->create_flow(
        redirect_uri => 'https://example.com/complete',
        exit_uri     => 'https://example.com/exit',
    ),
    'Business::GoCardless::BillingRequestFlow',
    '->create_flow'
);
like( $Flow->authorisation_url,qr/^https:\/\//,' ... with authorisation_url' );

ok( $BillingRequest->collect_customer_details(
    customer => {
        email       => 'lee@example.com',
        given_name  => 'Lee',
        family_name => 'Jøhñsön',
    },
    customer_billing_detail => {
        address_line1 => '1 Test Street',
        city          => 'London',
        postal_code   => 'E1 1AA',
        country_code  => 'GB',
    },
),'->collect_customer_details' );

ok( $BillingRequest->collect_bank_account(
    account_holder_name => 'Lee Jøhñsön',
    account_number      => '55779911',
    branch_code         => '200000',
    country_code        => 'GB',
),'->collect_bank_account' );

ok( $BillingRequest->confirm_payer_details,'->confirm_payer_details' );
ok( $BillingRequest->ready_to_fulfil,' ... is ready_to_fulfil' );
ok( $BillingRequest->fulfil,'->fulfil' );
ok( $BillingRequest->fulfilled,' ... is fulfilled' );

is(
    $GoCardless->billing_request( $BillingRequest->id )->status,
    'fulfilled',
    '->billing_request'
);
ok( scalar( $GoCardless->billing_requests( limit => 1 ) ),'->billing_requests' );

ok( my $mandate_id = $BillingRequest->mandate_id,' ... created a mandate' );
ok( my $customer_id = $BillingRequest->customer_id,' ... for a customer' );

$Mandate = $GoCardless->mandate( $mandate_id );
is( $Mandate->scheme,'bacs','->mandate' );
cmp_deeply(
    [ map { $_->id } $GoCardless->mandates( customer => $customer_id ) ],
    [ $mandate_id ],
    '->mandates'
);

ok( $GoCardless->run_scenario_simulator( 'mandate_activated',$mandate_id ),'->run_scenario_simulator' );
ok( $GoCardless->mandate( $mandate_id )->active,' ... mandate is active' );

note( "Instalment Schedules" );

# the month after $start_at, instalment dates must be in ascending order
my ( $start_year,$start_month ) = $start_at =~ /^(\d{4})-(\d{2})/;
my $instalment_date = $start_month == 12
    ? sprintf( "%04d-01-15",$start_year + 1 )
    : sprintf( "%04d-%02d-15",$start_year,$start_month + 1 );

isa_ok(
    my $Schedule = $GoCardless->create_instalment_schedule_with_dates(
        name         => 'Test instalments',
        currency     => 'GBP',
        total_amount => 300,
        instalments  => [
            { charge_date => $start_at,amount => 100 },
            { charge_date => $instalment_date,amount => 200 },
        ],
        links => { mandate => $mandate_id },
    ),
    'Business::GoCardless::InstalmentSchedule',
    '->create_instalment_schedule_with_dates'
);

isa_ok(
    $GoCardless->create_instalment_schedule_with_schedule(
        name         => 'Test instalments (schedule)',
        currency     => 'GBP',
        total_amount => 300,
        instalments  => {
            start_date    => $start_at,
            interval      => 1,
            interval_unit => 'monthly',
            amounts       => [ 100,200 ],
        },
        links => { mandate => $mandate_id },
    ),
    'Business::GoCardless::InstalmentSchedule',
    '->create_instalment_schedule_with_schedule'
);

is( $GoCardless->instalment_schedule( $Schedule->id )->id,$Schedule->id,'->instalment_schedule' );
is( scalar( my @schedules = $GoCardless->instalment_schedules( mandate => $mandate_id ) ),2,'->instalment_schedules' );
cmp_deeply( $Schedule->update( metadata => { foo => 'bar' } )->metadata,{ foo => 'bar' },'InstalmentSchedule->update' );
ok( $Schedule->cancel->cancelled,'InstalmentSchedule->cancel' );

note( "Subscriptions and Payments" );

isa_ok(
    $Subscription = $GoCardless->create_subscription(
        amount        => 100,
        currency      => 'GBP',
        interval_unit => 'monthly',
        day_of_month  => 15,
        links         => { mandate => $mandate_id },
    ),
    'Business::GoCardless::Subscription',
    '->create_subscription'
);
is( $Subscription->update( name => 'Updated' )->name,'Updated','Subscription->update' );
ok( $Subscription->pause->paused,'Subscription->pause' );
ok( $Subscription->resume->active,'Subscription->resume' );
ok( $Subscription->cancel->cancelled,'Subscription->cancel' );

$Payment = $GoCardless->create_payment(
    amount   => 100,
    currency => 'GBP',
    links    => { mandate => $mandate_id },
);
cmp_deeply( $Payment->update( metadata => { foo => 'bar' } )->metadata,{ foo => 'bar' },'Payment->update' );
ok( $Payment->cancel( metadata => { reason => 'test' } )->cancelled,'Payment->cancel with metadata' );

note( "Customers and Bank Accounts" );

$Customer = $GoCardless->customer( $customer_id );
is( $Customer->family_name,'Jøhñsön','->customer' );
cmp_deeply( $Customer->update( metadata => { foo => 'bar' } )->metadata,{ foo => 'bar' },'Customer->update' );

my @bank_accounts = $GoCardless->customer_bank_accounts( customer => $customer_id );
isa_ok( $bank_accounts[0],'Business::GoCardless::CustomerBankAccount','->customer_bank_accounts' );
is( $bank_accounts[0]->customer_id,$customer_id,' ... customer_id' );
is( $GoCardless->customer_bank_account( $bank_accounts[0]->id )->id,$bank_accounts[0]->id,'->customer_bank_account' );
cmp_deeply(
    $bank_accounts[0]->update( metadata => { foo => 'bar' } )->metadata,
    { foo => 'bar' },
    'CustomerBankAccount->update'
);

my $Lookup = $GoCardless->create_bank_details_lookup(
    account_number => '55779911',
    branch_code    => '200000',
    country_code   => 'GB',
);
isa_ok( $Lookup,'Business::GoCardless::BankDetailsLookup','->create_bank_details_lookup' );
ok( ( grep { $_ eq 'bacs' } @{ $Lookup->available_debit_schemes } ),' ... available_debit_schemes' );

like(
    $GoCardless->create_mandate_pdf( links => { mandate => $mandate_id } )->url,
    qr/^https:\/\//,
    '->create_mandate_pdf'
);

ok( $Mandate->cancel->cancelled,'Mandate->cancel' );
ok( ! $Mandate->reinstate->cancelled,'Mandate->reinstate' );

note( "Creditors, Events, and other resources" );

my @creditors = $GoCardless->creditors;
isa_ok( $creditors[0],'Business::GoCardless::Creditor','->creditors' );
my $creditor_id = $creditors[0]->id;
is( $GoCardless->creditor( $creditor_id )->id,$creditor_id,'->creditor' );
isa_ok(
    ( $GoCardless->creditor_bank_accounts( creditor => $creditor_id ) )[0],
    'Business::GoCardless::CreditorBankAccount',
    '->creditor_bank_accounts'
);
isa_ok(
    ( $GoCardless->balances( creditor => $creditor_id ) )[0],
    'Business::GoCardless::Balance',
    '->balances'
);

my @events = $GoCardless->events( resource_type => 'billing_requests',limit => 2 );
isa_ok( $events[0],'Business::GoCardless::Webhook::Event','->events' );
ok( $events[0]->is_billing_request,' ... is_billing_request' );
is( $GoCardless->event( $events[0]->id )->id,$events[0]->id,'->event' );

my @tax_rates = $GoCardless->tax_rates( jurisdiction => 'GB' );
isa_ok( $tax_rates[0],'Business::GoCardless::TaxRate','->tax_rates' );
is( $GoCardless->tax_rate( $tax_rates[0]->id )->jurisdiction,'GB','->tax_rate' );

isa_ok(
    ( $GoCardless->currency_exchange_rates( source => 'GBP',limit => 1 ) )[0],
    'Business::GoCardless::CurrencyExchangeRate',
    '->currency_exchange_rates'
);
isa_ok(
    ( $GoCardless->institutions( country_code => 'GB',limit => 1 ) )[0],
    'Business::GoCardless::Institution',
    '->institutions'
);

isa_ok(
    my $Template = $GoCardless->create_billing_request_template(
        name                     => 'business-gocardless test',
        mandate_request_currency => 'GBP',
        mandate_request_scheme   => 'bacs',
    ),
    'Business::GoCardless::BillingRequestTemplate',
    '->create_billing_request_template'
);
like( $Template->authorisation_url,qr/^https:\/\//,' ... with authorisation_url' );
is( $Template->update( name => 'business-gocardless test 2' )->name,'business-gocardless test 2','BillingRequestTemplate->update' );
is( $GoCardless->billing_request_template( $Template->id )->id,$Template->id,'->billing_request_template' );

throws_ok(
    sub { $GoCardless->funds_available( $mandate_id,100 ) },
    'Business::GoCardless::Exception',
    '->funds_available is only for VRP mandates',
);
is( $@->code,422,' ... with code' );

done_testing();

# act as the customer completing the hosted payment pages for the last
# redirect flow created, returning the params that would be passed to
# the success_redirect_url (and thus to ->confirm_resource)
sub _complete_redirect_flow {
    my ( %params ) = @_;

    my $redirect_flow_id   = $LastRedirectFlow->{id};
    my $billing_request_id = $LastRedirectFlow->{links}{billing_request}
        || BAIL_OUT( "Redirect flow $redirect_flow_id has no billing request" );

    note( "Completing $redirect_flow_id via $billing_request_id" ) if $DEBUG;

    my $Client = $GoCardless->client;

    # sandbox bank details: https://developer.gocardless.com/getting-started/developer-tools/test-bank-details
    foreach my $action (
        [ collect_customer_details => {
            customer => {
                email       => 'lee@example.com',
                given_name  => 'Lee',
                family_name => 'Jøhñsön',
            },
            customer_billing_detail => {
                address_line1 => '1 Test Street',
                city          => 'London',
                postal_code   => 'E1 1AA',
                country_code  => 'GB',
            },
        } ],
        [ collect_bank_account => {
            account_holder_name => 'Lee Jøhñsön',
            account_number      => '55779911',
            branch_code         => '200000',
            country_code        => 'GB',
        } ],
        [ confirm_payer_details => {} ],
        [ fulfil => {} ],
    ) {
        my ( $name,$data ) = @{ $action };

        my $res = $Client->api_post(
            "/billing_requests/$billing_request_id/actions/$name",
            { data => $data },
        );

        note( "$name: $res->{billing_requests}{status}" ) if $DEBUG;
    }

    pass( "customer completed redirect flow ($params{type})" );

    return {
        redirect_flow_id => $redirect_flow_id,
        %params,
    };
}

# vim: ts=4:sw=4:et
