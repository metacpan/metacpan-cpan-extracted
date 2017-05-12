#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::User' );
isa_ok(
    my $User = Business::GoCardless::User->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
        ),
    ),
    'Business::GoCardless::User'
);

can_ok(
    $User,
    qw/
        created_at
        email
        first_name
        id
        last_name
    /,
);

is( $User->endpoint,'/users/%s','endpoint' );

done_testing();

# vim: ts=4:sw=4:et
