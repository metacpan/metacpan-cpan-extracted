#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Customer' );
isa_ok(
    my $Customer = Business::GoCardless::Customer->new(
        given_name => 'Lee',
        family_name => 'Johnson',
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
        ),
    ),
    'Business::GoCardless::Customer'
);

can_ok(
    $Customer,
    qw/
        created_at
        email
        first_name
        id
        last_name
    /,
);

is( $Customer->endpoint,'/customers/%s','endpoint' );
is( $Customer->first_name,$Customer->given_name,'->first_name' );
is( $Customer->last_name,$Customer->family_name,'->last_name' );

done_testing();

# vim: ts=4:sw=4:et
