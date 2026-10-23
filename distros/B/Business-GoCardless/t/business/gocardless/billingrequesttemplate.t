#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;
use JSON ();

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::BillingRequestTemplate' );
isa_ok(
    my $Template = Business::GoCardless::BillingRequestTemplate->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::BillingRequestTemplate'
);

can_ok(
    $Template,
    qw/
        endpoint
        authorisation_url
        created_at
        id
        mandate_request_constraints
        mandate_request_currency
        mandate_request_description
        mandate_request_metadata
        mandate_request_scheme
        mandate_request_verify
        metadata
        name
        payment_request_amount
        payment_request_currency
        payment_request_description
        payment_request_metadata
        payment_request_scheme
        redirect_uri
        updated_at

        update
    /,
);

is( $Template->endpoint,'/billing_request_templates/%s','endpoint' );
is( $Template->uri,'https://api.gocardless.com/billing_request_templates/ID123','->uri' );

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

$mock->mock( 'content',sub { '{"billing_request_templates":{"id":"ID123","name":"after update"}}' } );

isa_ok(
    $Template->update( name => 'New name' ),
    'Business::GoCardless::BillingRequestTemplate',
    '->update'
);
is( $request->method,'PUT','->update PUTs' );
like( $request->uri,qr!/billing_request_templates/ID123$!,'->update request path' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { billing_request_templates => { name => 'New name' } },
    '->update request body'
);
is( $Template->name,'after update','->update updates the object' );

done_testing();

# vim: ts=4:sw=4:et
