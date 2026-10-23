#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::MandatePdf' );
isa_ok(
    my $Pdf = Business::GoCardless::MandatePdf->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
    ),
    'Business::GoCardless::MandatePdf'
);

can_ok(
    $Pdf,
    qw/
        endpoint
        expires_at
        url
    /,
);

is( $Pdf->endpoint,'/mandate_pdfs/%s','endpoint' );

done_testing();

# vim: ts=4:sw=4:et
