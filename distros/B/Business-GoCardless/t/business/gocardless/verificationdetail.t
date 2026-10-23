#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::VerificationDetail' );
isa_ok(
    my $VerificationDetail = Business::GoCardless::VerificationDetail->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
    ),
    'Business::GoCardless::VerificationDetail'
);

can_ok(
    $VerificationDetail,
    qw/
        endpoint
        address_line1
        address_line2
        address_line3
        city
        company_number
        country_code
        description
        directors
        links
        name
        postal_code
        region
    /,
);

is( $VerificationDetail->endpoint,'/verification_details/%s','endpoint' );

done_testing();

# vim: ts=4:sw=4:et
