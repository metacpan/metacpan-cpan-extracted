#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Logo' );
isa_ok(
    my $Logo = Business::GoCardless::Logo->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::Logo'
);

can_ok(
    $Logo,
    qw/
        endpoint
        id
    /,
);

is( $Logo->endpoint,'/logos/%s','endpoint' );
is( $Logo->uri,'https://api.gocardless.com/logos/ID123','->uri' );

done_testing();

# vim: ts=4:sw=4:et
