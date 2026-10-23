#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::PayerTheme' );
isa_ok(
    my $Theme = Business::GoCardless::PayerTheme->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::PayerTheme'
);

can_ok(
    $Theme,
    qw/
        endpoint
        id
    /,
);

is( $Theme->endpoint,'/payer_themes/%s','endpoint' );
is( $Theme->uri,'https://api.gocardless.com/payer_themes/ID123','->uri' );

done_testing();

# vim: ts=4:sw=4:et
