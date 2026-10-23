#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::TaxRate' );
isa_ok(
    my $TaxRate = Business::GoCardless::TaxRate->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'GB_VAT_1',
    ),
    'Business::GoCardless::TaxRate'
);

can_ok(
    $TaxRate,
    qw/
        endpoint
        end_date
        id
        jurisdiction
        percentage
        start_date
        type
    /,
);

is( $TaxRate->endpoint,'/tax_rates/%s','endpoint' );
is( $TaxRate->uri,'https://api.gocardless.com/tax_rates/GB_VAT_1','->uri' );

done_testing();

# vim: ts=4:sw=4:et
