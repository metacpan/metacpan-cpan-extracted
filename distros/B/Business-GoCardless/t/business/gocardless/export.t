#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Export' );
isa_ok(
    my $Export = Business::GoCardless::Export->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::Export'
);

can_ok(
    $Export,
    qw/
        endpoint
        created_at
        currency
        download_url
        error_message
        export_type
        id
    /,
);

is( $Export->endpoint,'/exports/%s','endpoint' );
is( $Export->uri,'https://api.gocardless.com/exports/ID123','->uri' );

done_testing();

# vim: ts=4:sw=4:et
