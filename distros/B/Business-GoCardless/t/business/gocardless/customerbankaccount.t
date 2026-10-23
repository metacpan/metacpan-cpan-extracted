#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;
use JSON ();

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::CustomerBankAccount' );
isa_ok(
    my $BankAccount = Business::GoCardless::CustomerBankAccount->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
        links  => {
            customer => 'CU123',
        },
    ),
    'Business::GoCardless::CustomerBankAccount'
);

can_ok(
    $BankAccount,
    qw/
        endpoint
        account_holder_name
        account_number_ending
        account_type
        bank_account_token
        bank_name
        country_code
        created_at
        currency
        enabled
        id
        links
        metadata
        payer_name_verification_result
        trusted_recipient

        update
        disable

        customer_id
    /,
);

is( $BankAccount->endpoint,'/customer_bank_accounts/%s','endpoint' );
is( $BankAccount->uri,'https://api.gocardless.com/customer_bank_accounts/ID123','->uri' );

note( "links" );

is( $BankAccount->customer_id,'CU123','->customer_id' );

$BankAccount->links( undef );
ok( ! $BankAccount->customer_id,'! ->customer_id when no links' );

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

$mock->mock( 'content',sub { '{"customer_bank_accounts":{"id":"ID123","enabled":"after update"}}' } );

isa_ok(
    $BankAccount->update( metadata => { foo => 'bar' } ),
    'Business::GoCardless::CustomerBankAccount',
    '->update'
);
is( $request->method,'PUT','->update PUTs' );
like( $request->uri,qr!/customer_bank_accounts/ID123$!,'->update request path' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { customer_bank_accounts => { metadata => { foo => 'bar' } } },
    '->update request body'
);
is( $BankAccount->enabled,'after update','->update updates the object' );

$mock->mock( 'content',sub { '{"customer_bank_accounts":{"id":"ID123","enabled":"after disable"}}' } );

isa_ok(
    $BankAccount->disable,
    'Business::GoCardless::CustomerBankAccount',
    '->disable'
);
is( $request->method,'POST','->disable POSTs' );
like( $request->uri,qr!/customer_bank_accounts/ID123/actions/disable$!,'->disable request path' );
ok( ! length( $request->content ),'->disable has no request body' );
is( $BankAccount->enabled,'after disable','->disable updates the object' );

done_testing();

# vim: ts=4:sw=4:et
