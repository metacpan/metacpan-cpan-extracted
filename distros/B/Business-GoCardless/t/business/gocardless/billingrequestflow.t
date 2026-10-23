#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;
use JSON ();

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::BillingRequestFlow' );
isa_ok(
    my $Flow = Business::GoCardless::BillingRequestFlow->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::BillingRequestFlow'
);

can_ok(
    $Flow,
    qw/
        endpoint
        authorisation_url
        auto_fulfil
        created_at
        customer_details_captured
        exit_uri
        expires_at
        id
        language
        links
        lock_bank_account
        lock_currency
        lock_customer_details
        prefilled_bank_account
        prefilled_customer
        redirect_uri
        session_token
        show_redirect_buttons
        show_success_redirect_button
        skip_success_screen

        initialise
    /,
);

is( $Flow->endpoint,'/billing_request_flows/%s','endpoint' );
is( $Flow->uri,'https://api.gocardless.com/billing_request_flows/ID123','->uri' );

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

$mock->mock( 'content',sub { '{"billing_request_flows":{"id":"ID123","session_token":"after initialise"}}' } );

isa_ok(
    $Flow->initialise,
    'Business::GoCardless::BillingRequestFlow',
    '->initialise'
);
is( $request->method,'POST','->initialise POSTs' );
like( $request->uri,qr!/billing_request_flows/ID123/actions/initialise$!,'->initialise request path' );
ok( ! length( $request->content ),'->initialise has no request body' );
is( $Flow->session_token,'after initialise','->initialise updates the object' );

done_testing();

# vim: ts=4:sw=4:et
