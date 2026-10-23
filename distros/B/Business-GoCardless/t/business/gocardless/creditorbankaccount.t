#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;
use JSON ();

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::CreditorBankAccount' );
isa_ok(
    my $BankAccount = Business::GoCardless::CreditorBankAccount->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
        links  => {
            creditor => 'CR123',
        },
    ),
    'Business::GoCardless::CreditorBankAccount'
);

can_ok(
    $BankAccount,
    qw/
        endpoint
        account_holder_name
        account_number_ending
        account_type
        bank_name
        country_code
        created_at
        currency
        enabled
        id
        links
        metadata
        verification_status

        disable

        creditor_id
    /,
);

is( $BankAccount->endpoint,'/creditor_bank_accounts/%s','endpoint' );
is( $BankAccount->uri,'https://api.gocardless.com/creditor_bank_accounts/ID123','->uri' );

note( "links" );

is( $BankAccount->creditor_id,'CR123','->creditor_id' );

$BankAccount->links( undef );
ok( ! $BankAccount->creditor_id,'! ->creditor_id when no links' );

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

$mock->mock( 'content',sub { '{"creditor_bank_accounts":{"id":"ID123","enabled":"after disable"}}' } );

isa_ok(
    $BankAccount->disable,
    'Business::GoCardless::CreditorBankAccount',
    '->disable'
);
is( $request->method,'POST','->disable POSTs' );
like( $request->uri,qr!/creditor_bank_accounts/ID123/actions/disable$!,'->disable request path' );
ok( ! length( $request->content ),'->disable has no request body' );
is( $BankAccount->enabled,'after disable','->disable updates the object' );

done_testing();

# vim: ts=4:sw=4:et
