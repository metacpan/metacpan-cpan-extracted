#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::MandateImportEntry' );
isa_ok(
    my $Entry = Business::GoCardless::MandateImportEntry->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        links  => {
            customer              => 'CU123',
            customer_bank_account => 'BA123',
            mandate               => 'MD123',
            mandate_import        => 'IM123',
        },
    ),
    'Business::GoCardless::MandateImportEntry'
);

can_ok(
    $Entry,
    qw/
        endpoint
        created_at
        links
        processing_errors
        record_identifier

        customer_bank_account_id
        customer_id
        mandate_id
        mandate_import_id
    /,
);

is( $Entry->endpoint,'/mandate_import_entries/%s','endpoint' );

note( "links" );

is( $Entry->customer_bank_account_id,'BA123','->customer_bank_account_id' );
is( $Entry->customer_id,'CU123','->customer_id' );
is( $Entry->mandate_id,'MD123','->mandate_id' );
is( $Entry->mandate_import_id,'IM123','->mandate_import_id' );

$Entry->links( undef );
ok( ! $Entry->customer_bank_account_id,'! ->customer_bank_account_id when no links' );

done_testing();

# vim: ts=4:sw=4:et
