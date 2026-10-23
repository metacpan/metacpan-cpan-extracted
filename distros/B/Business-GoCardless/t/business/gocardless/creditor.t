#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;
use JSON ();

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Creditor' );
isa_ok(
    my $Creditor = Business::GoCardless::Creditor->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::Creditor'
);

can_ok(
    $Creditor,
    qw/
        endpoint
        address_line1
        address_line2
        address_line3
        bank_reference_prefix
        can_create_refunds
        city
        country_code
        created_at
        creditor_type
        custom_payment_pages_enabled
        fx_payout_currency
        id
        links
        logo_url
        mandate_imports_enabled
        merchant_responsible_for_notifications
        name
        postal_code
        region
        scheme_identifiers
        verification_status

        update
    /,
);

is( $Creditor->endpoint,'/creditors/%s','endpoint' );
is( $Creditor->uri,'https://api.gocardless.com/creditors/ID123','->uri' );

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

$mock->mock( 'content',sub { '{"creditors":{"id":"ID123","name":"after update"}}' } );

isa_ok(
    $Creditor->update( links => { default_gbp_payout_account => 'BA123' },name => 'New name' ),
    'Business::GoCardless::Creditor',
    '->update'
);
is( $request->method,'PUT','->update PUTs' );
like( $request->uri,qr!/creditors/ID123$!,'->update request path' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { creditors => { links => { default_gbp_payout_account => 'BA123' },name => 'New name' } },
    '->update request body'
);
is( $Creditor->name,'after update','->update updates the object' );

done_testing();

# vim: ts=4:sw=4:et
