#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::BankAccountDetail' );
isa_ok(
    my $Detail = Business::GoCardless::BankAccountDetail->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::BankAccountDetail'
);

can_ok(
    $Detail,
    qw/
        endpoint
        ciphertext
        encrypted_key
        id
        iv
        protected
        tag
    /,
);

is( $Detail->endpoint,'/bank_account_details/%s','endpoint' );
is( $Detail->uri,'https://api.gocardless.com/bank_account_details/ID123','->uri' );

done_testing();

# vim: ts=4:sw=4:et
