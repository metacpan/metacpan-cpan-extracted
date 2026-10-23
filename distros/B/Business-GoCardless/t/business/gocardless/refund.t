#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Refund' );
isa_ok(
    my $Refund = Business::GoCardless::Refund->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
			api_version => 2,
        ),
        links => {
            payment => 'PM123',
            mandate => 'MD123',
        },
    ),
    'Business::GoCardless::Refund'
);

can_ok(
    $Refund,
    qw/
        endpoint
        amount
        created_at
        currency
        fx
        id
        links
        metadata
        reference
        status

        created
        pending_submission
        submitted
        paid
        cancelled
        bounced
        funds_returned

        payment_id
        mandate_id
    /,
);

is( $Refund->endpoint,'/refunds/%s','endpoint' );
is( $Refund->payment_id,'PM123','payment_id' );
is( $Refund->mandate_id,'MD123','mandate_id' );

$Refund->status( 'paid' );

ok( ! $Refund->created,'created' );
ok( ! $Refund->pending_submission,'pending_submission' );
ok( ! $Refund->submitted,'submitted' );
ok( $Refund->paid,'paid' );
ok( ! $Refund->cancelled,'cancelled' );
ok( ! $Refund->bounced,'bounced' );
ok( ! $Refund->funds_returned,'funds_returned' );

$Refund->id( 'RF123' );
is( $Refund->uri,'https://api.gocardless.com/refunds/RF123','->uri' );

done_testing();

# vim: ts=4:sw=4:et
