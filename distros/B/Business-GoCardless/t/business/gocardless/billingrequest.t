#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;
use JSON ();

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::BillingRequest' );
isa_ok(
    my $BillingRequest = Business::GoCardless::BillingRequest->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'BRQ123',
        links  => {
            customer                                        => 'CU123',
            instalment_schedule_request_instalment_schedule => 'IS123',
            mandate_request_mandate                         => 'MD123',
            payment_request_payment                         => 'PM123',
            subscription_request_subscription               => 'SB123',
        },
    ),
    'Business::GoCardless::BillingRequest'
);

can_ok(
    $BillingRequest,
    qw/
        endpoint
        actions
        auto_fulfil
        created_at
        creditor_address
        creditor_identifier
        creditor_name
        creditor_scheme_identifier
        experimentation
        fallback_enabled
        fallback_occurred
        id
        instalment_schedule_request
        links
        mandate_request
        metadata
        payment_context_code
        payment_purpose_code
        payment_request
        purpose_code
        resources
        sign_flow_url
        status
        subscription_request

        collect_customer_details
        collect_bank_account
        confirm_payer_details
        fulfil
        cancel
        notify
        fallback
        choose_currency
        select_institution

        pending
        ready_to_fulfil
        fulfilling
        fulfilled
        cancelled

        customer_id
        instalment_schedule_id
        mandate_id
        payment_id
        subscription_id

        create_flow
        institutions
    /,
);

is( $BillingRequest->endpoint,'/billing_requests/%s','endpoint' );
is( $BillingRequest->uri,'https://api.gocardless.com/billing_requests/BRQ123','->uri' );

note( "status checks" );

ok( ! $BillingRequest->pending,'! ->pending when no status' );

my @statuses = qw/ pending ready_to_fulfil fulfilling fulfilled cancelled /;

foreach my $status ( @statuses ) {
    $BillingRequest->status( $status );
    ok( $BillingRequest->$status,"->$status" );
    ok( ! $BillingRequest->$_,"! ->$_ when $status" )
        for grep { $_ ne $status } @statuses;
}

note( "links" );

is( $BillingRequest->customer_id,'CU123','->customer_id' );
is( $BillingRequest->instalment_schedule_id,'IS123','->instalment_schedule_id' );
is( $BillingRequest->mandate_id,'MD123','->mandate_id' );
is( $BillingRequest->payment_id,'PM123','->payment_id' );
is( $BillingRequest->subscription_id,'SB123','->subscription_id' );

$BillingRequest->links( undef );
ok( ! $BillingRequest->customer_id,'! ->customer_id when no links' );

note( "operations" );

# monkey patching LWP here to make this test work without
# having to actually hit the endpoints or use credentials
no warnings 'redefine';
no warnings 'once';
my $mock = Test::MockObject->new;
my $request;
$mock->mock( 'is_success',sub { 1 } );
$mock->mock( 'header',sub {} );
*LWP::UserAgent::request = sub { $request = $_[1]; $mock };

$mock->mock( 'content',sub { '{"billing_requests":{"id":"BRQ123","status":"after collect_customer_details"}}' } );

isa_ok(
    $BillingRequest->collect_customer_details( customer => { email => 'lee@example.com' },customer_billing_detail => { country_code => 'GB' } ),
    'Business::GoCardless::BillingRequest',
    '->collect_customer_details'
);
is( $request->method,'POST','->collect_customer_details POSTs' );
like( $request->uri,qr!/billing_requests/BRQ123/actions/collect_customer_details$!,'->collect_customer_details request path' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { data => { customer => { email => 'lee@example.com' },customer_billing_detail => { country_code => 'GB' } } },
    '->collect_customer_details request body'
);
is( $BillingRequest->status,'after collect_customer_details','->collect_customer_details updates the object' );

$mock->mock( 'content',sub { '{"billing_requests":{"id":"BRQ123","status":"after collect_bank_account"}}' } );

isa_ok(
    $BillingRequest->collect_bank_account( account_holder_name => 'Lee Johnson',iban => 'GB60BARC20000055779911' ),
    'Business::GoCardless::BillingRequest',
    '->collect_bank_account'
);
is( $request->method,'POST','->collect_bank_account POSTs' );
like( $request->uri,qr!/billing_requests/BRQ123/actions/collect_bank_account$!,'->collect_bank_account request path' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { data => { account_holder_name => 'Lee Johnson',iban => 'GB60BARC20000055779911' } },
    '->collect_bank_account request body'
);
is( $BillingRequest->status,'after collect_bank_account','->collect_bank_account updates the object' );

$mock->mock( 'content',sub { '{"billing_requests":{"id":"BRQ123","status":"after confirm_payer_details"}}' } );

isa_ok(
    $BillingRequest->confirm_payer_details,
    'Business::GoCardless::BillingRequest',
    '->confirm_payer_details'
);
is( $request->method,'POST','->confirm_payer_details POSTs' );
like( $request->uri,qr!/billing_requests/BRQ123/actions/confirm_payer_details$!,'->confirm_payer_details request path' );
ok( ! length( $request->content ),'->confirm_payer_details has no request body' );
is( $BillingRequest->status,'after confirm_payer_details','->confirm_payer_details updates the object' );

$mock->mock( 'content',sub { '{"billing_requests":{"id":"BRQ123","status":"after fulfil"}}' } );

isa_ok(
    $BillingRequest->fulfil,
    'Business::GoCardless::BillingRequest',
    '->fulfil'
);
is( $request->method,'POST','->fulfil POSTs' );
like( $request->uri,qr!/billing_requests/BRQ123/actions/fulfil$!,'->fulfil request path' );
ok( ! length( $request->content ),'->fulfil has no request body' );
is( $BillingRequest->status,'after fulfil','->fulfil updates the object' );

$mock->mock( 'content',sub { '{"billing_requests":{"id":"BRQ123","status":"after cancel"}}' } );

isa_ok(
    $BillingRequest->cancel( metadata => { reason => 'test' } ),
    'Business::GoCardless::BillingRequest',
    '->cancel'
);
is( $request->method,'POST','->cancel POSTs' );
like( $request->uri,qr!/billing_requests/BRQ123/actions/cancel$!,'->cancel request path' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { data => { metadata => { reason => 'test' } } },
    '->cancel request body'
);
is( $BillingRequest->status,'after cancel','->cancel updates the object' );

$mock->mock( 'content',sub { '{"billing_requests":{"id":"BRQ123","status":"after notify"}}' } );

isa_ok(
    $BillingRequest->notify( notification_type => 'email' ),
    'Business::GoCardless::BillingRequest',
    '->notify'
);
is( $request->method,'POST','->notify POSTs' );
like( $request->uri,qr!/billing_requests/BRQ123/actions/notify$!,'->notify request path' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { data => { notification_type => 'email' } },
    '->notify request body'
);
is( $BillingRequest->status,'after notify','->notify updates the object' );

$mock->mock( 'content',sub { '{"billing_requests":{"id":"BRQ123","status":"after fallback"}}' } );

isa_ok(
    $BillingRequest->fallback,
    'Business::GoCardless::BillingRequest',
    '->fallback'
);
is( $request->method,'POST','->fallback POSTs' );
like( $request->uri,qr!/billing_requests/BRQ123/actions/fallback$!,'->fallback request path' );
ok( ! length( $request->content ),'->fallback has no request body' );
is( $BillingRequest->status,'after fallback','->fallback updates the object' );

$mock->mock( 'content',sub { '{"billing_requests":{"id":"BRQ123","status":"after choose_currency"}}' } );

isa_ok(
    $BillingRequest->choose_currency( currency => 'EUR' ),
    'Business::GoCardless::BillingRequest',
    '->choose_currency'
);
is( $request->method,'POST','->choose_currency POSTs' );
like( $request->uri,qr!/billing_requests/BRQ123/actions/choose_currency$!,'->choose_currency request path' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { data => { currency => 'EUR' } },
    '->choose_currency request body'
);
is( $BillingRequest->status,'after choose_currency','->choose_currency updates the object' );

$mock->mock( 'content',sub { '{"billing_requests":{"id":"BRQ123","status":"after select_institution"}}' } );

isa_ok(
    $BillingRequest->select_institution( country_code => 'GB',institution => 'monzo' ),
    'Business::GoCardless::BillingRequest',
    '->select_institution'
);
is( $request->method,'POST','->select_institution POSTs' );
like( $request->uri,qr!/billing_requests/BRQ123/actions/select_institution$!,'->select_institution request path' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { data => { country_code => 'GB',institution => 'monzo' } },
    '->select_institution request body'
);
is( $BillingRequest->status,'after select_institution','->select_institution updates the object' );

note( "create_flow" );

$mock->mock( 'content',sub {
    '{"billing_request_flows":{"id":"BRF123","authorisation_url":"https://pay.gocardless.com/flow/BRF123"}}'
} );

isa_ok(
    my $Flow = $BillingRequest->create_flow(
        redirect_uri => 'https://example.com/complete',
        links        => { creditor => 'CR123' },
    ),
    'Business::GoCardless::BillingRequestFlow',
    '->create_flow'
);

is( $Flow->authorisation_url,'https://pay.gocardless.com/flow/BRF123',' ... authorisation_url' );
is( $request->method,'POST',' ... POSTs' );
like( $request->uri,qr!/billing_request_flows$!,' ... to billing request flows' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { billing_request_flows => {
        redirect_uri => 'https://example.com/complete',
        links        => { creditor => 'CR123',billing_request => 'BRQ123' },
    } },
    ' ... linked to the billing request'
);

note( "institutions" );

$mock->mock( 'content',sub {
    '{"institutions":[{"id":"monzo","name":"Monzo","status":"enabled"},{"id":"barclays","name":"Barclays","status":"disabled"}]}'
} );

my @institutions = $BillingRequest->institutions( country_code => 'GB',search => 'mon' );
is( scalar( @institutions ),2,'->institutions' );
isa_ok( $institutions[0],'Business::GoCardless::Institution',' ... returns institutions' );
ok( $institutions[0]->enabled,' ... with details' );
is( $request->method,'GET',' ... GETs' );
like(
    $request->uri,
    qr!/billing_requests/BRQ123/institutions\?country_code=GB&search=mon$!,
    ' ... for the billing request'
);

$mock->mock( 'content',sub { '{"institutions":[]}' } );
is( scalar( $BillingRequest->institutions ),0,'->institutions (none)' );

done_testing();

# vim: ts=4:sw=4:et
