#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::BankDetailsLookup' );
isa_ok(
    my $Lookup = Business::GoCardless::BankDetailsLookup->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
    ),
    'Business::GoCardless::BankDetailsLookup'
);

can_ok(
    $Lookup,
    qw/
        endpoint
        available_debit_schemes
        bank_name
        bic
        payer_name_verification_result
    /,
);

is( $Lookup->endpoint,'/bank_details_lookups/%s','endpoint' );

done_testing();

# vim: ts=4:sw=4:et
