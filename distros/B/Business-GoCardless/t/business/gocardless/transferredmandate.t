#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::TransferredMandate' );
isa_ok(
    my $TransferredMandate = Business::GoCardless::TransferredMandate->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
        links  => {
            customer_bank_account => 'BA123',
            mandate               => 'MD123',
        },
    ),
    'Business::GoCardless::TransferredMandate'
);

can_ok(
    $TransferredMandate,
    qw/
        endpoint
        encrypted_customer_bank_details
        encrypted_decryption_key
        id
        links
        public_key_id

        customer_bank_account_id
        mandate_id
    /,
);

is( $TransferredMandate->endpoint,'/transferred_mandates/%s','endpoint' );
is( $TransferredMandate->uri,'https://api.gocardless.com/transferred_mandates/ID123','->uri' );

note( "links" );

is( $TransferredMandate->customer_bank_account_id,'BA123','->customer_bank_account_id' );
is( $TransferredMandate->mandate_id,'MD123','->mandate_id' );

$TransferredMandate->links( undef );
ok( ! $TransferredMandate->customer_bank_account_id,'! ->customer_bank_account_id when no links' );

done_testing();

# vim: ts=4:sw=4:et
