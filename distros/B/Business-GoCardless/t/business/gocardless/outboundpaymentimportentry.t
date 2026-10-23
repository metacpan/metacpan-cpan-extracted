#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::OutboundPaymentImportEntry' );
isa_ok(
    my $Entry = Business::GoCardless::OutboundPaymentImportEntry->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::OutboundPaymentImportEntry'
);

can_ok(
    $Entry,
    qw/
        endpoint
        amount
        created_at
        id
        links
        metadata
        processed_at
        reference
        scheme
        validation_errors
        verification_result
    /,
);

is( $Entry->endpoint,'/outbound_payment_import_entries/%s','endpoint' );
is( $Entry->uri,'https://api.gocardless.com/outbound_payment_import_entries/ID123','->uri' );

done_testing();

# vim: ts=4:sw=4:et
